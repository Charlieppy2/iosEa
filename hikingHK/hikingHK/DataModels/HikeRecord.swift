//
//  HikeRecord.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation

/// Summary of a recorded hike, including distance, elevation and derived statistics.
@Model
final class HikeRecord {
    var id: UUID
    var trailId: UUID?
    var trailName: String?
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool
    var totalDistance: Double
    var totalDuration: TimeInterval
    var averageSpeed: Double
    var maxSpeed: Double
    var elevationGain: Double
    var elevationLoss: Double
    var minAltitude: Double
    var maxAltitude: Double
    var notes: String?
    var trackPoints: [HikeTrackPoint]
    
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

