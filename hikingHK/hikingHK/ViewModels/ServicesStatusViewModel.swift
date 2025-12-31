//
//  ServicesStatusViewModel.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import CoreLocation
import Combine
import SwiftData

/// View model that reports the status of key services on the Home screen:
/// - Weather API connectivity
/// - GPS / location permission
/// - Offline maps availability
@MainActor
final class ServicesStatusViewModel: NSObject, ObservableObject {
    @Published var weatherServiceStatus: ServiceStatus = .unknown
    @Published var gpsStatus: ServiceStatus = .unknown
    @Published var offlineMapsStatus: ServiceStatus = .unknown
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkGPSStatus()
        checkOfflineMapsStatus()
    }
    
    /// High-level connectivity / availability state for a service.
    enum ServiceStatus {
        case connected
        case disconnected
        case unavailable
        case unknown
        
        /// SF Symbol name that represents this status.
        var icon: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "xmark.circle.fill"
            case .unavailable: return "exclamationmark.triangle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
        
        /// A semantic color name that can be mapped to UI theme colors.
        var color: String {
            switch self {
            case .connected: return "green"
            case .disconnected: return "red"
            case .unavailable: return "orange"
            case .unknown: return "gray"
            }
        }
    }
    
    /// Updates `weatherServiceStatus` based on whether we have valid data and/or an error.
    func checkWeatherServiceStatus(weatherError: String?, hasWeatherData: Bool) {
        if hasWeatherData && weatherError == nil {
            weatherServiceStatus = .connected
        } else if weatherError != nil {
            weatherServiceStatus = .disconnected
        } else {
            weatherServiceStatus = .unknown
        }
    }
    
    /// Updates `gpsStatus` based on the current CoreLocation authorization state.
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
    
    /// Updates `offlineMapsStatus` by checking both SwiftData metadata and actual files on disk.
    /// - Parameters:
    ///   - context: Optional SwiftData `ModelContext` used to read `OfflineMapRegion` records.
    ///   - accountId: Optional user account ID to filter regions for the current user.
    func checkOfflineMapsStatus(context: ModelContext? = nil, accountId: UUID? = nil) {
        // First, try to decide based on SwiftData records for downloaded regions.
        var hasDownloaded = false
        
        if let context = context, let accountId = accountId {
            do {
                let store = OfflineMapsStore(context: context)
                let regions = try store.loadAllRegions(accountId: accountId)
                
                // 1️⃣ Check if any region in the database is marked as downloaded.
                hasDownloaded = regions.contains { $0.downloadStatus == .downloaded }
                
                // 2️⃣ If none are marked as downloaded but files exist, fall back to file system check.
                if !hasDownloaded {
                    hasDownloaded = hasAnyOfflineMapFilesOnDisk()
                }
            } catch {
                // If SwiftData fails, fall back to a pure file system check.
                hasDownloaded = hasAnyOfflineMapFilesOnDisk()
            }
        } else {
            // When no context or accountId is provided, rely only on the file system check.
            hasDownloaded = hasAnyOfflineMapFilesOnDisk()
        }
        
        offlineMapsStatus = hasDownloaded ? .connected : .unavailable
    }
    
    /// Checks the file system to see if any offline map directory (with `metadata.json`) exists.
    private func hasAnyOfflineMapFilesOnDisk() -> Bool {
        // Use the same base path as `OfflineMapsDownloadService`: Documents/OfflineMaps
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        let offlineDir = documentsDir.appendingPathComponent("OfflineMaps", isDirectory: true)
        
        // If there is no OfflineMaps directory, treat as "no offline maps".
        guard fileManager.fileExists(atPath: offlineDir.path) else {
            return false
        }
        
        do {
            let subdirs = try fileManager.contentsOfDirectory(
                at: offlineDir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            for dir in subdirs {
                let metadataPath = dir.appendingPathComponent("metadata.json")
                if fileManager.fileExists(atPath: metadataPath.path) {
                    return true
                }
            }
        } catch {
            // On error, assume no offline maps and log for debugging.
            print("⚠️ ServicesStatusViewModel: Failed to scan offline maps directory: \(error.localizedDescription)")
        }
        
        return false
    }
    
    /// Convenience helper to refresh all service statuses in one call.
    /// - Parameters:
    ///   - weatherError: Optional weather API error message.
    ///   - hasWeatherData: Whether valid weather data exists.
    ///   - context: Optional SwiftData model context.
    ///   - accountId: Optional user account ID to filter offline maps for.
    func refreshAllStatuses(weatherError: String?, hasWeatherData: Bool, context: ModelContext? = nil, accountId: UUID? = nil) {
        checkWeatherServiceStatus(weatherError: weatherError, hasWeatherData: hasWeatherData)
        checkGPSStatus()
        checkOfflineMapsStatus(context: context, accountId: accountId)
    }
}

extension ServicesStatusViewModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            checkGPSStatus()
        }
    }
}

