//
//  ServicesStatusViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import CoreLocation
import Combine
import SwiftData

@MainActor
final class ServicesStatusViewModel: NSObject, ObservableObject {
    @Published var weatherServiceStatus: ServiceStatus = .unknown
    @Published var gpsStatus: ServiceStatus = .unknown
    @Published var offlineMapsStatus: ServiceStatus = .unknown
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkGPSStatus()
        checkOfflineMapsStatus()
    }
    
    enum ServiceStatus {
        case connected
        case disconnected
        case unavailable
        case unknown
        
        var icon: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "xmark.circle.fill"
            case .unavailable: return "exclamationmark.triangle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .connected: return "green"
            case .disconnected: return "red"
            case .unavailable: return "orange"
            case .unknown: return "gray"
            }
        }
    }
    
    func checkWeatherServiceStatus(weatherError: String?, hasWeatherData: Bool) {
        if hasWeatherData && weatherError == nil {
            weatherServiceStatus = .connected
        } else if weatherError != nil {
            weatherServiceStatus = .disconnected
        } else {
            weatherServiceStatus = .unknown
        }
    }
    
    func checkGPSStatus() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            gpsStatus = .connected
        case .denied, .restricted:
            gpsStatus = .unavailable
        case .notDetermined:
            gpsStatus = .unknown
        @unknown default:
            gpsStatus = .unknown
        }
    }
    
    func checkOfflineMapsStatus(context: ModelContext? = nil) {
        // Check if any offline maps are downloaded
        if let context = context {
            do {
                let store = OfflineMapsStore(context: context)
                let regions = try store.loadAllRegions()
                let hasDownloaded = regions.contains { $0.downloadStatus == .downloaded }
                offlineMapsStatus = hasDownloaded ? .connected : .unavailable
            } catch {
                offlineMapsStatus = .unknown
            }
        } else {
            offlineMapsStatus = .unavailable
        }
    }
    
    func refreshAllStatuses(weatherError: String?, hasWeatherData: Bool, context: ModelContext? = nil) {
        checkWeatherServiceStatus(weatherError: weatherError, hasWeatherData: hasWeatherData)
        checkGPSStatus()
        checkOfflineMapsStatus(context: context)
    }
}

extension ServicesStatusViewModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            checkGPSStatus()
        }
    }
}

