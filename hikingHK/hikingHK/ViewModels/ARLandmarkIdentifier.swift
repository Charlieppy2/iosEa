//
//  ARLandmarkIdentifier.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class ARLandmarkIdentifier: ObservableObject {
    @Published var identifiedLandmarks: [IdentifiedLandmark] = []
    @Published var isScanning = false
    
    let locationManager: LocationManager
    private var scanTask: Task<Void, Never>?
    
    struct IdentifiedLandmark: Identifiable, Equatable {
        let id: UUID
        let landmark: Landmark
        let distance: Double
        let bearing: Double
        let identifiedAt: Date
        
        init(landmark: Landmark, from location: CLLocation) {
            self.id = UUID()
            self.landmark = landmark
            self.distance = landmark.distance(from: location)
            self.bearing = landmark.bearing(from: location)
            self.identifiedAt = Date()
        }
    }
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
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
    
    func stopScanning() {
        isScanning = false
        scanTask?.cancel()
        scanTask = nil
    }
    
    private func identifyNearbyLandmarks() async {
        guard let currentLocation = locationManager.currentLocation else {
            // Request location if not available
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                locationManager.startUpdates()
            }
            return
        }
        
        // Identify landmarks within 50km
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

