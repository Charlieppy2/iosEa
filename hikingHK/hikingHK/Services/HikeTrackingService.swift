//
//  HikeTrackingService.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import CoreLocation

/// Defines the core calculation APIs used by the hike tracking feature.
protocol HikeTrackingServiceProtocol {
    func calculateDistance(from: CLLocation, to: CLLocation) -> Double
    func calculateElevationGain(points: [HikeTrackPoint]) -> (gain: Double, loss: Double, min: Double, max: Double)
    func calculateStatistics(points: [HikeTrackPoint]) -> (distance: Double, avgSpeed: Double, maxSpeed: Double)
}

/// Concrete implementation that calculates distance, elevation gain/loss
/// and basic speed statistics from recorded hike points.
final class HikeTrackingService: HikeTrackingServiceProtocol {
    
    /// Returns the straight-line distance in meters between two locations.
    func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to)
    }
    
    /// Calculates total elevation gain, loss, and min/max altitude from a sequence of track points.
    func calculateElevationGain(points: [HikeTrackPoint]) -> (gain: Double, loss: Double, min: Double, max: Double) {
        guard points.count > 1 else {
            let altitude = points.first?.altitude ?? 0
            return (gain: 0, loss: 0, min: altitude, max: altitude)
        }
        
        var gain: Double = 0
        var loss: Double = 0
        var minAlt = points[0].altitude
        var maxAlt = points[0].altitude
        
        for i in 1..<points.count {
            let prevAlt = points[i-1].altitude
            let currAlt = points[i].altitude
            let diff = currAlt - prevAlt
            
            if diff > 0 {
                gain += diff
            } else {
                loss += abs(diff)
            }
            
            minAlt = min(minAlt, currAlt)
            maxAlt = max(maxAlt, currAlt)
        }
        
        return (gain: gain, loss: loss, min: minAlt, max: maxAlt)
    }
    
    /// Calculates total distance (meters), average speed (m/s) and max speed (m/s) from track points.
    func calculateStatistics(points: [HikeTrackPoint]) -> (distance: Double, avgSpeed: Double, maxSpeed: Double) {
        guard points.count > 1 else {
            return (distance: 0, avgSpeed: 0, maxSpeed: points.first?.speed ?? 0)
        }
        
        var totalDistance: Double = 0
        var totalSpeed: Double = 0
        var maxSpeed: Double = 0
        var validSpeedCount = 0
        
        for i in 1..<points.count {
            let prev = points[i-1].location
            let curr = points[i].location
            let distance = prev.distance(from: curr)
            totalDistance += distance
            
            let speed = curr.speed
            if speed > 0 {
                totalSpeed += speed
                validSpeedCount += 1
            }
            maxSpeed = max(maxSpeed, speed)
        }
        
        let avgSpeed = validSpeedCount > 0 ? totalSpeed / Double(validSpeedCount) : 0
        
        return (distance: totalDistance, avgSpeed: avgSpeed, maxSpeed: maxSpeed)
    }
}

