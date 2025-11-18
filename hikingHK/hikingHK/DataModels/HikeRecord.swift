//
//  HikeRecord.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class HikeRecord {
    var id: UUID
    var trailId: UUID? // 關聯的路線 ID（可選）
    var trailName: String? // 路線名稱
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool
    var totalDistance: Double // 總距離（米）
    var totalDuration: TimeInterval // 總時長（秒）
    var averageSpeed: Double // 平均速度（米/秒）
    var maxSpeed: Double // 最大速度（米/秒）
    var elevationGain: Double // 海拔上升（米）
    var elevationLoss: Double // 海拔下降（米）
    var minAltitude: Double // 最低海拔（米）
    var maxAltitude: Double // 最高海拔（米）
    var notes: String? // 備註
    var trackPoints: [HikeTrackPoint] // 軌跡點
    
    init(
        id: UUID = UUID(),
        trailId: UUID? = nil,
        trailName: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        isCompleted: Bool = false,
        totalDistance: Double = 0,
        totalDuration: TimeInterval = 0,
        averageSpeed: Double = 0,
        maxSpeed: Double = 0,
        elevationGain: Double = 0,
        elevationLoss: Double = 0,
        minAltitude: Double = 0,
        maxAltitude: Double = 0,
        notes: String? = nil,
        trackPoints: [HikeTrackPoint] = []
    ) {
        self.id = id
        self.trailId = trailId
        self.trailName = trailName
        self.startTime = startTime
        self.endTime = endTime
        self.isCompleted = isCompleted
        self.totalDistance = totalDistance
        self.totalDuration = totalDuration
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.elevationGain = elevationGain
        self.elevationLoss = elevationLoss
        self.minAltitude = minAltitude
        self.maxAltitude = maxAltitude
        self.notes = notes
        self.trackPoints = trackPoints
    }
    
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
    
    var distanceKm: Double {
        totalDistance / 1000.0
    }
    
    var averageSpeedKmh: Double {
        averageSpeed * 3.6
    }
    
    var maxSpeedKmh: Double {
        maxSpeed * 3.6
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var routeCoordinates: [CLLocationCoordinate2D] {
        trackPoints.map { $0.coordinate }
    }
    
    var routeLocations: [CLLocation] {
        trackPoints.map { $0.location }
    }
}

