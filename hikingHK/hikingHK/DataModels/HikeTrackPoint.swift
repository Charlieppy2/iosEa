//
//  HikeTrackPoint.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation

/// Single GPS sample point used to construct a recorded hike route.
@Model
final class HikeTrackPoint {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var altitude: Double // Altitude in meters
    var speed: Double // Speed in meters per second
    var timestamp: Date
    var horizontalAccuracy: Double
    var verticalAccuracy: Double
    
    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        altitude: Double,
        speed: Double,
        timestamp: Date = Date(),
        horizontalAccuracy: Double = 0,
        verticalAccuracy: Double = 0
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.speed = speed
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: -1,
            speed: speed,
            timestamp: timestamp
        )
    }
    
    var speedKmh: Double {
        speed * 3.6 // Convert to kilometres per hour
    }
}

