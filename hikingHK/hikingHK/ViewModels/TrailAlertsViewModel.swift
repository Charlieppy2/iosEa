//
//  TrailAlertsViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import Combine

@MainActor
final class TrailAlertsViewModel: ObservableObject {
    @Published var alerts: [TrailAlert] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let alertsService: TrailAlertsServiceProtocol
    private var languageManager: LanguageManager?
    private var autoRefreshTask: Task<Void, Never>?
    private let autoRefreshInterval: TimeInterval = 300 // 5分钟自动刷新
    
    init(alertsService: TrailAlertsServiceProtocol = TrailAlertsService(), languageManager: LanguageManager? = nil) {
        self.alertsService = alertsService
        self.languageManager = languageManager
    }
    
    func updateLanguageManager(_ languageManager: LanguageManager) {
        self.languageManager = languageManager
    }
    
    func fetchAlerts() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        let language = languageManager?.currentLanguage.rawValue ?? "en"
        
        do {
            let fetchedAlerts = try await alertsService.fetchAlerts(language: language)
            // Filter to only show active alerts
            alerts = fetchedAlerts.filter { $0.isActive }
            // Sort by severity (critical first) and then by issued date (newest first)
            alerts.sort { lhs, rhs in
                if lhs.severity != rhs.severity {
                    return lhs.severity.rawValue > rhs.severity.rawValue
                }
                return lhs.issuedAt > rhs.issuedAt
            }
            print("✅ TrailAlertsViewModel: Fetched \(alerts.count) active alerts")
        } catch {
            self.error = "Failed to load alerts"
            print("❌ Trail alerts fetch error: \(error)")
        }
    }
    
    func startAutoRefresh() {
        stopAutoRefresh()
        autoRefreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(autoRefreshInterval * 1_000_000_000))
                if !Task.isCancelled {
                    await fetchAlerts()
                }
            }
        }
        print("🔄 TrailAlertsViewModel: Started auto-refresh (every \(Int(autoRefreshInterval)) seconds)")
    }
    
    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }
    
    var activeAlertsCount: Int {
        alerts.filter { $0.isActive }.count
    }
    
    var criticalAlerts: [TrailAlert] {
        alerts.filter { $0.severity == .critical && $0.isActive }
    }
}

