//
//  LocationSharingViewModel.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
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
    private let emergencyContactFileStore = EmergencyContactFileStore()
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
    
    /// Lazily configures the underlying stores and loads contacts/session.
    /// Emergency contacts are now loaded from FileManager + JSON (like journals).
    func configureIfNeeded(context: ModelContext, accountId: UUID? = nil) {
        guard store == nil else { return }
        let newStore = LocationSharingStore(context: context)
        store = newStore
        
        do {
            // Load emergency contacts from FileStore (like journals)
            // BaseFileStore will automatically recover from corrupted files by returning empty array
            let allContacts = try emergencyContactFileStore.loadAll()
            
            // Filter by accountId if provided
            if let accountId = accountId {
                emergencyContacts = allContacts.filter { $0.accountId == accountId }
            } else {
                emergencyContacts = allContacts
            }
            
            print("✅ LocationSharingViewModel: Loaded \(emergencyContacts.count) emergency contacts from JSON store (accountId: \(accountId?.uuidString ?? "nil"))")
            
            // Load session from SwiftData
            if let accountId = accountId {
                shareSession = try? newStore.loadActiveSession(accountId: accountId)
                if shareSession == nil {
                    // Create a new session if none exists
                    shareSession = LocationShareSession(accountId: accountId)
                }
            } else {
                shareSession = nil
            }
            
            isSharing = shareSession?.isActive ?? false
            
            if isSharing {
                startLocationSharing()
            }
        } catch let loadError {
            // If loading failed (e.g., corrupted file), BaseFileStore should have recovered automatically
            // But if there's still an error, just log it and continue with empty contacts
            print("⚠️ Location sharing load error: \(loadError)")
            print("   Continuing with empty emergency contacts list")
            // Set to empty array so the UI can still function
            emergencyContacts = []
            shareSession = nil
            isSharing = false
        }
    }
    
    /// Refreshes emergency contacts from the JSON file store.
    func refreshEmergencyContacts(accountId: UUID? = nil) {
        do {
            // BaseFileStore will automatically recover from corrupted files by returning empty array
            let allContacts = try emergencyContactFileStore.loadAll()
            
            // Filter by accountId if provided
            if let accountId = accountId {
                emergencyContacts = allContacts.filter { $0.accountId == accountId }
            } else {
                emergencyContacts = allContacts
            }
            
            print("✅ LocationSharingViewModel: Refreshed \(emergencyContacts.count) emergency contacts (accountId: \(accountId?.uuidString ?? "nil"))")
        } catch let err {
            // If loading failed, just log it and continue with empty contacts
            print("⚠️ LocationSharingViewModel: Failed to refresh emergency contacts: \(err)")
            emergencyContacts = []
            self.error = "Failed to load emergency contacts: \(err.localizedDescription)"
            print("❌ LocationSharingViewModel: Failed to refresh contacts: \(err)")
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
        // If no session exists, we need accountId to create one
        // For now, if shareSession is nil, we can't start sharing
        guard let session = shareSession else {
            print("⚠️ LocationSharingViewModel: Cannot start sharing without a session. Please configure with accountId first.")
            error = "Cannot start sharing without a session"
            isSharing = false
            return
        }
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
    
    /// Adds a new emergency contact and persists it to JSON file store (like journals).
    func addEmergencyContact(_ contact: EmergencyContact) {
        do {
            try emergencyContactFileStore.saveOrUpdate(contact)
            // Reload all contacts and filter by accountId
            let allContacts = try emergencyContactFileStore.loadAll()
            emergencyContacts = allContacts.filter { $0.accountId == contact.accountId }
            print("✅ LocationSharingViewModel: Added emergency contact '\(contact.name)' to JSON store")
        } catch let addError {
            self.error = "Failed to add emergency contact: \(addError.localizedDescription)"
            print("❌ LocationSharingViewModel: Failed to add contact: \(addError)")
        }
    }
    
    /// Removes an emergency contact and deletes it from the JSON file store.
    func removeEmergencyContact(_ contact: EmergencyContact) {
        do {
            let accountId = contact.accountId
            try emergencyContactFileStore.delete(contact)
            // Reload all contacts and filter by accountId
            let allContacts = try emergencyContactFileStore.loadAll()
            emergencyContacts = allContacts.filter { $0.accountId == accountId }
            print("✅ LocationSharingViewModel: Deleted emergency contact '\(contact.name)' from JSON store")
        } catch let deleteError {
            self.error = "Failed to delete emergency contact: \(deleteError.localizedDescription)"
            print("❌ LocationSharingViewModel: Failed to delete contact: \(deleteError)")
        }
    }
    
    /// Updates an existing emergency contact in the JSON file store.
    func updateEmergencyContact(_ contact: EmergencyContact) {
        do {
            try emergencyContactFileStore.saveOrUpdate(contact)
            emergencyContacts = try emergencyContactFileStore.loadAll()
            print("✅ LocationSharingViewModel: Updated emergency contact '\(contact.name)' in JSON store")
        } catch let updateError {
            self.error = "Failed to update emergency contact: \(updateError.localizedDescription)"
            print("❌ LocationSharingViewModel: Failed to update contact: \(updateError)")
        }
    }
    
    /// Sets a contact as primary and unmarks others.
    func setPrimaryContact(_ contact: EmergencyContact) {
        do {
            try emergencyContactFileStore.setPrimaryContact(contact)
            emergencyContacts = try emergencyContactFileStore.loadAll()
            print("✅ LocationSharingViewModel: Set '\(contact.name)' as primary contact")
        } catch let error {
            self.error = "Failed to set primary contact: \(error.localizedDescription)"
            print("❌ LocationSharingViewModel: Failed to set primary contact: \(error)")
        }
    }
    
    /// Generates a shareable map link for the user's current location.
    func generateShareLink() -> String? {
        guard let location = currentLocation ?? locationManager.currentLocation else { return nil }
        
        // Check if location is the iOS Simulator default (San Francisco)
        // This is a common issue when testing on simulator
        let isSimulatorDefault = abs(location.coordinate.latitude - 37.785834) < 0.0001 &&
                                 abs(location.coordinate.longitude - (-122.406417)) < 0.0001
        
        if isSimulatorDefault {
            print("⚠️ LocationSharingViewModel: Detected iOS Simulator default location (San Francisco)")
            print("⚠️ Please set a custom location in the Simulator: Features > Location > Custom Location")
        }
        
        return sharingService.generateShareLink(location: location.coordinate)
    }
    
    /// Checks if the current location is valid (not simulator default or invalid).
    var isLocationValid: Bool {
        guard let location = currentLocation ?? locationManager.currentLocation else { return false }
        
        // Check if location is the iOS Simulator default (San Francisco)
        let isSimulatorDefault = abs(location.coordinate.latitude - 37.785834) < 0.0001 &&
                                 abs(location.coordinate.longitude - (-122.406417)) < 0.0001
        
        // Check if location is in Hong Kong area (rough bounds)
        let isInHongKong = location.coordinate.latitude >= 22.0 && location.coordinate.latitude <= 23.0 &&
                           location.coordinate.longitude >= 113.0 && location.coordinate.longitude <= 115.0
        
        // Location is valid if it's not the simulator default, or if it's actually in Hong Kong
        return !isSimulatorDefault || isInHongKong
    }
}

