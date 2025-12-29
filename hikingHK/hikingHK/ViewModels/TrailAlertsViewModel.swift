//
//  TrailAlertsViewModel.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import Combine
#if canImport(UserNotifications)
import UserNotifications
#endif

/// View model for fetching, filtering, and auto-refreshing trail alerts.
@MainActor
final class TrailAlertsViewModel: ObservableObject {
    @Published var alerts: [TrailAlert] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var history: [WeatherWarningHistory] = []
    
    private let alertsService: TrailAlertsServiceProtocol
    private let warningService: WeatherWarningServiceProtocol
    private let historyService = WeatherWarningHistoryService.shared
    private var languageManager: LanguageManager?
    private var autoRefreshTask: Task<Void, Never>?
    /// Interval in seconds for automatically refreshing trail alerts (default: 5 minutes).
    private let autoRefreshInterval: TimeInterval = 300
    private var previousWarningCodes: Set<String> = []
    
    /// Creates a new trail alerts view model with injectable service and language manager.
    init(
        alertsService: TrailAlertsServiceProtocol = TrailAlertsService(),
        warningService: WeatherWarningServiceProtocol = WeatherWarningService(),
        languageManager: LanguageManager? = nil
    ) {
        self.alertsService = alertsService
        self.warningService = warningService
        self.languageManager = languageManager
    }
    
    /// Updates the language manager, used when the app language changes at runtime.
    func updateLanguageManager(_ languageManager: LanguageManager) {
        self.languageManager = languageManager
    }
    
    /// Loads trail alerts from the backend, keeping only active alerts and sorting by severity and time.
    func fetchAlerts() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        let language = languageManager?.currentLanguage.rawValue ?? "en"
        
        do {
            let fetchedAlerts = try await alertsService.fetchAlerts(language: language)
            // Filter to only show active alerts.
            alerts = fetchedAlerts.filter { $0.isActive }
            // Sort by severity (critical first) and then by issued date (newest first).
            alerts.sort { lhs, rhs in
                if lhs.severity != rhs.severity {
                    return lhs.severity.rawValue > rhs.severity.rawValue
                }
                return lhs.issuedAt > rhs.issuedAt
            }
            
            // 更新歷史記錄和推送通知
            await updateHistoryAndNotifications(language: language)
            
            // 加載歷史記錄
            history = historyService.loadHistory()
            
            print("✅ TrailAlertsViewModel: Fetched \(alerts.count) active alerts")
        } catch {
            self.error = "Failed to load alerts"
            print("❌ Trail alerts fetch error: \(error)")
        }
    }
    
    /// 更新歷史記錄並發送推送通知
    private func updateHistoryAndNotifications(language: String) async {
        do {
            let warnings = try await warningService.fetchWarnings(language: language)
            
            let currentWarningCodes = Set(warnings.map { $0.code })
            
            // 保存所有警告到歷史記錄
            for warning in warnings {
                historyService.saveWarning(warning)
            }
            
            // 檢查是否有新警告（需要發送通知）
            let newWarningCodes = currentWarningCodes.subtracting(previousWarningCodes)
            if !newWarningCodes.isEmpty {
                // 發送推送通知
                await sendNotificationForNewWarnings(warnings.filter { newWarningCodes.contains($0.code) })
            }
            
            // 檢查是否有已取消的警告
            let cancelledWarningCodes = previousWarningCodes.subtracting(currentWarningCodes)
            for code in cancelledWarningCodes {
                historyService.cancelWarning(code: code)
            }
            
            previousWarningCodes = currentWarningCodes
        } catch {
            print("⚠️ TrailAlertsViewModel: Failed to update history: \(error)")
        }
    }
    
    /// 發送推送通知
    private func sendNotificationForNewWarnings(_ warnings: [WeatherWarning]) async {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        
        // 請求通知權限
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted == true else {
            print("⚠️ TrailAlertsViewModel: Notification permission not granted")
            return
        }
        
        // 為每個新警告發送通知
        for warning in warnings {
            let content = UNMutableNotificationContent()
            content.title = warning.name
            content.body = "\(warning.name) (\(warning.code))"
            content.sound = UNNotificationSound.default
            content.badge = NSNumber(value: alerts.count + 1)
            
            let request = UNNotificationRequest(
                identifier: "weather-warning-\(warning.code)",
                content: content,
                trigger: nil // 立即發送
            )
            
            try? await center.add(request)
            print("📱 TrailAlertsViewModel: Sent notification for warning: \(warning.name)")
        }
        #else
        print("⚠️ TrailAlertsViewModel: UserNotifications framework not available")
        #endif
    }
    
    /// 加載歷史記錄
    func loadHistory() {
        history = historyService.loadHistory()
    }
    
    /// Starts the auto-refresh task that periodically fetches the latest alerts.
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
    
    /// Stops the auto-refresh task, if any.
    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }
    
    /// Number of currently active alerts.
    var activeAlertsCount: Int {
        alerts.filter { $0.isActive }.count
    }
    
    /// All active alerts with critical severity.
    var criticalAlerts: [TrailAlert] {
        alerts.filter { $0.severity == .critical && $0.isActive }
    }
}

