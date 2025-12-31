//
//  HikeTrackingViewModel.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation
import Combine

/// View model that manages live hike tracking, statistics and persistence.
@MainActor
final class HikeTrackingViewModel: ObservableObject {
    @Published var isTracking: Bool = false
    @Published var currentRecord: HikeRecord?
    @Published var trackPoints: [HikeTrackPoint] = []
    @Published var currentLocation: CLLocation?
    @Published var currentSpeed: Double = 0 // meters per second
    @Published var currentAltitude: Double = 0
    @Published var totalDistance: Double = 0 // meters
    @Published var elapsedTime: TimeInterval = 0
    @Published var error: String?
    
    private var store: HikeRecordStore?
    private let locationManager: LocationManager
    private let trackingService: HikeTrackingServiceProtocol
    private var locationUpdateTask: Task<Void, Never>?
    private var statisticsUpdateTask: Task<Void, Never>?
    private var startTime: Date?
    private var lastLocation: CLLocation?
    
    /// Creates a new tracking view model using the given `LocationManager`
    /// and an optional injectable tracking service (defaults to `HikeTrackingService`).
    init(
        locationManager: LocationManager,
        trackingService: HikeTrackingServiceProtocol = HikeTrackingService()
    ) {
        self.locationManager = locationManager
        self.trackingService = trackingService
    }
    
    /// Lazily configures the underlying `HikeRecordStore`.
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        store = HikeRecordStore(context: context)
    }
    
    /// Starts a new hike tracking session, optionally associated with a trail.
    /// - Parameters:
    ///   - trailId: Optional trail ID to associate with this hike.
    ///   - trailName: Optional trail name.
    ///   - accountId: The user account ID to associate this record with.
    func startTracking(trailId: UUID? = nil, trailName: String? = nil, accountId: UUID) {
        guard !isTracking else { return }
        
        // Request location permission if not determined.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        }
        
        // Start high-accuracy location updates.
        locationManager.startUpdates()
        
        isTracking = true
        startTime = Date()
        trackPoints = []
        totalDistance = 0
        elapsedTime = 0
        lastLocation = nil
        
        // Create a new hike record.
        currentRecord = HikeRecord(
            accountId: accountId,
            trailId: trailId,
            trailName: trailName,
            startTime: startTime!,
            isCompleted: false
        )
        
        // Start the periodic location update loop.
        startLocationUpdateLoop()
        
        // Start the statistics update loop.
        startStatisticsUpdateLoop()
    }
    
    /// Stops tracking, finalizes the current record and persists it.
    func stopTracking() {
        guard isTracking else { return }
        
        isTracking = false
        locationManager.stopUpdates()
        locationUpdateTask?.cancel()
        statisticsUpdateTask?.cancel()
        
        // 完成記錄
        finishRecord()
    }
    
    /// Pauses tracking without finalizing the record (can be resumed).
    func pauseTracking() {
        guard isTracking else { return }
        isTracking = false
        locationUpdateTask?.cancel()
        statisticsUpdateTask?.cancel()
    }
    
    /// Resumes tracking if a record is already in progress.
    func resumeTracking() {
        guard !isTracking, currentRecord != nil else { return }
        isTracking = true
        locationManager.startUpdates()
        startLocationUpdateLoop()
        startStatisticsUpdateLoop()
    }
    
    /// Starts a background task that periodically reads location updates.
    private func startLocationUpdateLoop() {
        locationUpdateTask?.cancel()
        locationUpdateTask = Task {
            while isTracking && !Task.isCancelled {
                if let location = locationManager.currentLocation {
                    await processLocationUpdate(location)
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000) // Update every 5 seconds
            }
        }
    }
    
    /// Processes a new location update and appends a `HikeTrackPoint`.
    private func processLocationUpdate(_ location: CLLocation) async {
        currentLocation = location
        currentSpeed = location.speed >= 0 ? location.speed : 0
        currentAltitude = location.altitude
        
        // Create and append a new track point.
        let trackPoint = HikeTrackPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            speed: currentSpeed,
            timestamp: location.timestamp,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy
        )
        
        trackPoints.append(trackPoint)
        currentRecord?.trackPoints.append(trackPoint)
        
        // Accumulate distance since the last location.
        if let last = lastLocation {
            let distance = trackingService.calculateDistance(from: last, to: location)
            totalDistance += distance
        }
        
        lastLocation = location
    }
    
    /// Starts a background task that periodically refreshes time and statistics.
    private func startStatisticsUpdateLoop() {
        statisticsUpdateTask?.cancel()
        statisticsUpdateTask = Task {
            while isTracking && !Task.isCancelled {
                if let start = startTime {
                    elapsedTime = Date().timeIntervalSince(start)
                }
                updateRecordStatistics()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // Update every second
            }
        }
    }
    
    /// Recomputes aggregate statistics on the current record from collected track points.
    private func updateRecordStatistics() {
        guard let record = currentRecord, !trackPoints.isEmpty else { return }
        
        // Compute distance/speed statistics and elevation gains/losses.
        let stats = trackingService.calculateStatistics(points: trackPoints)
        let elevation = trackingService.calculateElevationGain(points: trackPoints)
        
        record.totalDistance = stats.distance
        record.totalDuration = elapsedTime
        record.averageSpeed = stats.avgSpeed
        record.maxSpeed = stats.maxSpeed
        record.elevationGain = elevation.gain
        record.elevationLoss = elevation.loss
        record.minAltitude = elevation.min
        record.maxAltitude = elevation.max
    }
    
    /// Marks the current record as completed and persists it via the store.
    private func finishRecord() {
        guard let record = currentRecord else { return }
        
        record.endTime = Date()
        record.isCompleted = true
        updateRecordStatistics()
        
        // Save the finished record.
        do {
            try store?.saveRecord(record)
        } catch let saveError {
            self.error = "Failed to save hike record: \(saveError.localizedDescription)"
            print("Save hike record error: \(saveError)")
        }
    }
    
    /// Saves the current record without ending the tracking session.
    func saveCurrentRecord() {
        guard let record = currentRecord else { return }
        do {
            try store?.saveRecord(record)
        } catch let saveError {
            self.error = "Failed to save hike record: \(saveError.localizedDescription)"
        }
    }
    
    /// Deletes a persisted hike record.
    func deleteRecord(_ record: HikeRecord) {
        do {
            try store?.deleteRecord(record)
        } catch let deleteError {
            self.error = "Failed to delete hike record: \(deleteError.localizedDescription)"
        }
    }
    
    /// Current speed converted from m/s to km/h.
    var currentSpeedKmh: Double {
        currentSpeed * 3.6
    }
    
    /// Human-readable formatted elapsed time as `HH:mm:ss` or `mm:ss`.
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Human-readable formatted distance in meters or kilometers.
    var formattedDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.2f km", totalDistance / 1000.0)
        } else {
            return String(format: "%.0f m", totalDistance)
        }
    }
}

