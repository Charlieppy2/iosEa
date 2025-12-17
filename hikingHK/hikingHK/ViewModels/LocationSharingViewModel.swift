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

/// View model for live location sharing, anomaly detection, and SOS alerts.
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
    
    /// Creates a new location sharing view model with injectable services for testing.
    init(
        locationManager: LocationManager,
        sharingService: LocationSharingServiceProtocol = LocationSharingService(),
        anomalyService: AnomalyDetectionServiceProtocol = AnomalyDetectionService()
    ) {
        self.locationManager = locationManager
        self.sharingService = sharingService
        self.anomalyService = anomalyService
    }
    
    /// Lazily configures the underlying `LocationSharingStore` and loads contacts/session.
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
            self.error = "Failed to load location sharing settings: \(loadError.localizedDescription)"
            print("Location sharing load error: \(loadError)")
        }
    }
    
    /// Starts a location sharing session and begins background updates + anomaly checks.
    func startLocationSharing() {
        guard !isSharing else { return }
        
        // Request location permission if needed.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        }
        
        // Request background location permission for continuous tracking (if applicable).
        if locationManager.authorizationStatus != .authorizedAlways {
            // 在實際應用中，需要請求 .authorizedAlways 權限
            print("需要後台位置權限以持續分享位置")
        }
        
        locationManager.startUpdates()
        isSharing = true
        
        // Create or update the active sharing session metadata.
        let session = shareSession ?? LocationShareSession()
        session.isActive = true
        session.startedAt = Date()
        session.expiresAt = Date().addingTimeInterval(24 * 60 * 60) // Expires after 24 hours
        shareSession = session
        
        do {
            try store?.saveSession(session)
        } catch let saveError {
            self.error = "Failed to save sharing session: \(saveError.localizedDescription)"
        }
        
        // Start the periodic location update loop.
        startLocationUpdateLoop()
        
        // Start the anomaly detection loop.
        startAnomalyDetectionLoop()
    }
    
    /// Stops location sharing and persists the final session state.
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
            self.error = "Failed to stop sharing session: \(stopError.localizedDescription)"
        }
    }
    
    /// Starts a background task that periodically reads the latest location
    /// and updates the active share session.
    private func startLocationUpdateLoop() {
        locationUpdateTask?.cancel()
        locationUpdateTask = Task {
            while isSharing && !Task.isCancelled {
                if let location = locationManager.currentLocation {
                    currentLocation = location
                    shareSession?.updateLocation(location)
                    lastCheckedLocation = location
                    lastAnomalyCheckTime = Date()
                    
                    // Persist the updated session with the new location.
                    do {
                        if let session = shareSession {
                            try store?.saveSession(session)
                        }
                    } catch let updateError {
                        print("保存位置更新失敗：\(updateError)")
                    }
                }
                
                try? await Task.sleep(nanoseconds: 30_000_000_000) // Update every 30 seconds
            }
        }
    }
    
    /// Starts a background task that periodically checks for movement / GPS anomalies.
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
                    
                    // Automatically send an alert if a critical anomaly is detected.
                    if detectedAnomaly.severity == .critical {
                        await sendAutomaticAlert(for: detectedAnomaly)
                    }
                }
                
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Check every 60 seconds
            }
        }
    }
    
    /// Sends an emergency SOS message with the user's current location
    /// to all configured emergency contacts.
    func sendEmergencySOS(message: String = "I need emergency assistance!") async {
        guard let location = currentLocation ?? locationManager.currentLocation else {
            error = "Unable to get current location"
            return
        }
        
        guard !emergencyContacts.isEmpty else {
            error = "Please add at least one emergency contact first"
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
            self.error = "Failed to send emergency SOS: \(sosError.localizedDescription)"
        }
        
        isSendingSOS = false
    }
    
    /// Sends an automatic SMS alert when a critical anomaly is detected.
    private func sendAutomaticAlert(for anomaly: Anomaly) async {
        guard let location = currentLocation ?? locationManager.currentLocation else { return }
        guard !emergencyContacts.isEmpty else { return }
        
        let message = "Automatically detected anomaly: \(anomaly.message)"
        
        do {
            try await sharingService.sendLocationViaMessage(
                contacts: emergencyContacts,
                location: location.coordinate,
                message: message
            )
        } catch let alertError {
            print("Automatic alert failed: \(alertError)")
        }
    }
    
    /// Adds a new emergency contact and persists it.
    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        do {
            try store?.saveContact(contact)
        } catch let addError {
            self.error = "Failed to add emergency contact: \(addError.localizedDescription)"
        }
    }
    
    /// Removes an emergency contact and deletes it from the store.
    func removeEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        do {
            try store?.deleteContact(contact)
        } catch let deleteError {
            self.error = "Failed to delete emergency contact: \(deleteError.localizedDescription)"
        }
    }
    
    /// Generates a shareable map link for the user's current location.
    func generateShareLink() -> String? {
        guard let location = currentLocation ?? locationManager.currentLocation else { return nil }
        return sharingService.generateShareLink(location: location.coordinate)
    }
}

