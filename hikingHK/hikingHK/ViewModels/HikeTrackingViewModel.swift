//
//  HikeTrackingViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation
import Combine

@MainActor
final class HikeTrackingViewModel: ObservableObject {
    @Published var isTracking: Bool = false
    @Published var currentRecord: HikeRecord?
    @Published var trackPoints: [HikeTrackPoint] = []
    @Published var currentLocation: CLLocation?
    @Published var currentSpeed: Double = 0 // 米/秒
    @Published var currentAltitude: Double = 0
    @Published var totalDistance: Double = 0 // 米
    @Published var elapsedTime: TimeInterval = 0
    @Published var error: String?
    
    private var store: HikeRecordStore?
    private let locationManager: LocationManager
    private let trackingService: HikeTrackingServiceProtocol
    private var locationUpdateTask: Task<Void, Never>?
    private var statisticsUpdateTask: Task<Void, Never>?
    private var startTime: Date?
    private var lastLocation: CLLocation?
    
    init(
        locationManager: LocationManager,
        trackingService: HikeTrackingServiceProtocol = HikeTrackingService()
    ) {
        self.locationManager = locationManager
        self.trackingService = trackingService
    }
    
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        store = HikeRecordStore(context: context)
    }
    
    func startTracking(trailId: UUID? = nil, trailName: String? = nil) {
        guard !isTracking else { return }
        
        // 請求位置權限
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        }
        
        // 請求高精度位置
        locationManager.startUpdates()
        
        isTracking = true
        startTime = Date()
        trackPoints = []
        totalDistance = 0
        elapsedTime = 0
        lastLocation = nil
        
        // 創建新記錄
        currentRecord = HikeRecord(
            trailId: trailId,
            trailName: trailName,
            startTime: startTime!,
            isCompleted: false
        )
        
        // 開始位置更新循環
        startLocationUpdateLoop()
        
        // 開始統計更新循環
        startStatisticsUpdateLoop()
    }
    
    func stopTracking() {
        guard isTracking else { return }
        
        isTracking = false
        locationManager.stopUpdates()
        locationUpdateTask?.cancel()
        statisticsUpdateTask?.cancel()
        
        // 完成記錄
        finishRecord()
    }
    
    func pauseTracking() {
        guard isTracking else { return }
        isTracking = false
        locationUpdateTask?.cancel()
        statisticsUpdateTask?.cancel()
    }
    
    func resumeTracking() {
        guard !isTracking, currentRecord != nil else { return }
        isTracking = true
        locationManager.startUpdates()
        startLocationUpdateLoop()
        startStatisticsUpdateLoop()
    }
    
    private func startLocationUpdateLoop() {
        locationUpdateTask?.cancel()
        locationUpdateTask = Task {
            while isTracking && !Task.isCancelled {
                if let location = locationManager.currentLocation {
                    await processLocationUpdate(location)
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 每 5 秒更新一次
            }
        }
    }
    
    private func processLocationUpdate(_ location: CLLocation) async {
        currentLocation = location
        currentSpeed = location.speed >= 0 ? location.speed : 0
        currentAltitude = location.altitude
        
        // 創建軌跡點
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
        
        // 計算距離
        if let last = lastLocation {
            let distance = trackingService.calculateDistance(from: last, to: location)
            totalDistance += distance
        }
        
        lastLocation = location
    }
    
    private func startStatisticsUpdateLoop() {
        statisticsUpdateTask?.cancel()
        statisticsUpdateTask = Task {
            while isTracking && !Task.isCancelled {
                if let start = startTime {
                    elapsedTime = Date().timeIntervalSince(start)
                }
                updateRecordStatistics()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 每秒更新一次
            }
        }
    }
    
    private func updateRecordStatistics() {
        guard let record = currentRecord, !trackPoints.isEmpty else { return }
        
        // 計算統計數據
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
    
    private func finishRecord() {
        guard let record = currentRecord else { return }
        
        record.endTime = Date()
        record.isCompleted = true
        updateRecordStatistics()
        
        // 保存記錄
        do {
            try store?.saveRecord(record)
        } catch let saveError {
            self.error = "Failed to save hike record: \(saveError.localizedDescription)"
            print("Save hike record error: \(saveError)")
        }
    }
    
    func saveCurrentRecord() {
        guard let record = currentRecord else { return }
        do {
            try store?.saveRecord(record)
        } catch let saveError {
            self.error = "Failed to save hike record: \(saveError.localizedDescription)"
        }
    }
    
    func deleteRecord(_ record: HikeRecord) {
        do {
            try store?.deleteRecord(record)
        } catch let deleteError {
            self.error = "Failed to delete hike record: \(deleteError.localizedDescription)"
        }
    }
    
    var currentSpeedKmh: Double {
        currentSpeed * 3.6
    }
    
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
    
    var formattedDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.2f km", totalDistance / 1000.0)
        } else {
            return String(format: "%.0f m", totalDistance)
        }
    }
}

