//
//  ARLandmarkIdentifier.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import CoreLocation
import Combine

/// View model for AR landmark identification, exposing nearby landmarks
/// relative to the user's current location.
@MainActor
final class ARLandmarkIdentifier: ObservableObject {
    @Published var identifiedLandmarks: [IdentifiedLandmark] = []
    @Published var isScanning = false
    
    let locationManager: LocationManager
    private var scanTask: Task<Void, Never>?
    
    /// Lightweight model describing a landmark that has been identified
    /// in the current AR scanning session.
    struct IdentifiedLandmark: Identifiable, Equatable {
        let id: UUID
        let landmark: Landmark
        let distance: Double
        let bearing: Double
        let identifiedAt: Date
        
        /// Pre-computes distance and bearing from the given location.
        init(landmark: Landmark, from location: CLLocation) {
            self.id = UUID()
            self.landmark = landmark
            self.distance = landmark.distance(from: location)
            self.bearing = landmark.bearing(from: location)
            self.identifiedAt = Date()
        }
    }
    
    /// Creates a new identifier bound to a shared `LocationManager`.
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    /// Starts periodic scanning for nearby landmarks.
    func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        identifiedLandmarks = []
        
        scanTask = Task {
            while isScanning && !Task.isCancelled {
                await identifyNearbyLandmarks()
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Update every 2 seconds
            }
        }
    }
    
    /// Stops scanning and cancels any in-flight tasks.
    func stopScanning() {
        isScanning = false
        scanTask?.cancel()
        scanTask = nil
    }
    
    /// Finds all landmarks within a 50 km radius of the current location.
    private func identifyNearbyLandmarks() async {
        guard let currentLocation = locationManager.currentLocation else {
            // Request location if it is not yet available.
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                locationManager.startUpdates()
            }
            return
        }
        
        // Identify landmarks within 50km.
        let nearbyLandmarks = Landmark.hongKongLandmarks
            .filter { landmark in
                let distance = landmark.distance(from: currentLocation)
                return distance <= 50.0 // Within 50km
            }
            .map { IdentifiedLandmark(landmark: $0, from: currentLocation) }
            .sorted { $0.distance < $1.distance } // Sort by distance
        
        identifiedLandmarks = nearbyLandmarks
    }
    
    var closestLandmark: IdentifiedLandmark? {
        identifiedLandmarks.first
    }
}

