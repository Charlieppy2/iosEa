//
//  LocationManager.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import CoreLocation
import Combine

/// Shared location manager for the app, exposing authorization and current location.
@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?

    private let manager = CLLocationManager()

    /// Configure the underlying CLLocationManager and delegate.
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Ask the user for "When In Use" location permission.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Start receiving continuous location updates.
    func startUpdates() {
        manager.startUpdatingLocation()
    }

    /// Stop receiving continuous location updates.
    func stopUpdates() {
        manager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            startUpdates()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let latest = locations.last {
            currentLocation = latest
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

