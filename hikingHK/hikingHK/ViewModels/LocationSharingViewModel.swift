//
//  LocationSharingViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation
import Combine

@MainActor
final class LocationSharingViewModel: ObservableObject {
    @Published var isSharing: Bool = false
    @Published var currentLocation: CLLocation?
    @Published var lastAnomaly: Anomaly?
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var shareSession: LocationShareSession?
    @Published var error: String?
    @Published var isSendingSOS: Bool = false
    
    private var store: LocationSharingStore?
    private let locationManager: LocationManager
    private let sharingService: LocationSharingServiceProtocol
    private let anomalyService: AnomalyDetectionServiceProtocol
    private var locationUpdateTask: Task<Void, Never>?
    private var anomalyCheckTask: Task<Void, Never>?
    private var lastCheckedLocation: CLLocation?
    private var lastAnomalyCheckTime: Date?
    
    init(
        locationManager: LocationManager,
        sharingService: LocationSharingServiceProtocol = LocationSharingService(),
        anomalyService: AnomalyDetectionServiceProtocol = AnomalyDetectionService()
    ) {
        self.locationManager = locationManager
        self.sharingService = sharingService
        self.anomalyService = anomalyService
    }
    
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        let newStore = LocationSharingStore(context: context)
        store = newStore
        
        do {
            try newStore.seedDefaultsIfNeeded()
            emergencyContacts = try newStore.loadAllContacts()
            shareSession = try newStore.loadActiveSession()
            isSharing = shareSession?.isActive ?? false
            
            if isSharing {
                startLocationSharing()
            }
        } catch let loadError {
            self.error = "載入位置分享設置失敗：\(loadError.localizedDescription)"
            print("Location sharing load error: \(loadError)")
        }
    }
    
    func startLocationSharing() {
        guard !isSharing else { return }
        
        // 請求位置權限
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        }
        
        // 請求後台位置權限（用於持續追蹤）
        if locationManager.authorizationStatus != .authorizedAlways {
            // 在實際應用中，需要請求 .authorizedAlways 權限
            print("需要後台位置權限以持續分享位置")
        }
        
        locationManager.startUpdates()
        isSharing = true
        
        // 創建或更新分享會話
        let session = shareSession ?? LocationShareSession()
        session.isActive = true
        session.startedAt = Date()
        session.expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 小時後過期
        shareSession = session
        
        do {
            try store?.saveSession(session)
        } catch let saveError {
            self.error = "保存分享會話失敗：\(saveError.localizedDescription)"
        }
        
        // 開始位置更新循環
        startLocationUpdateLoop()
        
        // 開始異常檢測循環
        startAnomalyDetectionLoop()
    }
    
    func stopLocationSharing() {
        guard isSharing else { return }
        
        isSharing = false
        locationManager.stopUpdates()
        locationUpdateTask?.cancel()
        anomalyCheckTask?.cancel()
        
        shareSession?.isActive = false
        do {
            if let session = shareSession {
                try store?.saveSession(session)
            }
        } catch let stopError {
            self.error = "停止分享會話失敗：\(stopError.localizedDescription)"
        }
    }
    
    private func startLocationUpdateLoop() {
        locationUpdateTask?.cancel()
        locationUpdateTask = Task {
            while isSharing && !Task.isCancelled {
                if let location = locationManager.currentLocation {
                    currentLocation = location
                    shareSession?.updateLocation(location)
                    lastCheckedLocation = location
                    lastAnomalyCheckTime = Date()
                    
                    // 保存位置更新
                    do {
                        if let session = shareSession {
                            try store?.saveSession(session)
                        }
                    } catch let updateError {
                        print("保存位置更新失敗：\(updateError)")
                    }
                }
                
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 每 30 秒更新一次
            }
        }
    }
    
    private func startAnomalyDetectionLoop() {
        anomalyCheckTask?.cancel()
        anomalyCheckTask = Task {
            while isSharing && !Task.isCancelled {
                let anomaly = anomalyService.checkForAnomalies(
                    currentLocation: currentLocation,
                    lastLocation: lastCheckedLocation,
                    lastUpdateTime: lastAnomalyCheckTime,
                    sessionStartTime: shareSession?.startedAt
                )
                
                if let detectedAnomaly = anomaly {
                    lastAnomaly = detectedAnomaly
                    
                    // 如果是嚴重異常，自動發送警報
                    if detectedAnomaly.severity == .critical {
                        await sendAutomaticAlert(for: detectedAnomaly)
                    }
                }
                
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 每 60 秒檢查一次
            }
        }
    }
    
    func sendEmergencySOS(message: String = "我需要緊急協助！") async {
        guard let location = currentLocation ?? locationManager.currentLocation else {
            error = "無法獲取當前位置"
            return
        }
        
        guard !emergencyContacts.isEmpty else {
            error = "請先添加緊急聯繫人"
            return
        }
        
        isSendingSOS = true
        error = nil
        
        do {
            try await sharingService.sendEmergencySOS(
                contacts: emergencyContacts,
                location: location.coordinate,
                message: message
            )
        } catch let sosError {
            self.error = "發送緊急求救失敗：\(sosError.localizedDescription)"
        }
        
        isSendingSOS = false
    }
    
    private func sendAutomaticAlert(for anomaly: Anomaly) async {
        guard let location = currentLocation ?? locationManager.currentLocation else { return }
        guard !emergencyContacts.isEmpty else { return }
        
        let message = "自動檢測到異常情況：\(anomaly.message)"
        
        do {
            try await sharingService.sendLocationViaMessage(
                contacts: emergencyContacts,
                location: location.coordinate,
                message: message
            )
        } catch let alertError {
            print("自動發送警報失敗：\(alertError)")
        }
    }
    
    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        do {
            try store?.saveContact(contact)
        } catch let addError {
            self.error = "添加緊急聯繫人失敗：\(addError.localizedDescription)"
        }
    }
    
    func removeEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        do {
            try store?.deleteContact(contact)
        } catch let deleteError {
            self.error = "刪除緊急聯繫人失敗：\(deleteError.localizedDescription)"
        }
    }
    
    func generateShareLink() -> String? {
        guard let location = currentLocation ?? locationManager.currentLocation else { return nil }
        return sharingService.generateShareLink(location: location.coordinate)
    }
}

