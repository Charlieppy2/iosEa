//
//  AnomalyDetectionService.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import CoreLocation

/// Describes the anomaly detection operations for hiking sessions.
protocol AnomalyDetectionServiceProtocol {
    func checkForAnomalies(
        currentLocation: CLLocation?,
        lastLocation: CLLocation?,
        lastUpdateTime: Date?,
        sessionStartTime: Date?
    ) -> Anomaly?
}

/// An anomaly detected during a hiking session (type, severity, and message).
struct Anomaly {
    let type: AnomalyType
    let severity: Severity
    let message: String
    let detectedAt: Date
    
    enum AnomalyType {
        case noMovement // Long period without movement
        case locationStuck // Location appears stuck
        case noLocationUpdate // Long period without any location updates
        case batteryLow // Battery level is low (optional trigger)
    }
    
    enum Severity {
        case low
        case medium
        case high
        case critical
        
        var severityText: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
        
        func localizedSeverityText(languageManager: LanguageManager) -> String {
            let key = "anomaly.severity.\(severityText.lowercased())"
            return languageManager.localizedString(for: key)
        }
    }
}

final class AnomalyDetectionService: AnomalyDetectionServiceProtocol {
    
    // Configuration thresholds for anomaly detection
    private let noMovementThreshold: TimeInterval = 15 * 60 // No movement for 15 minutes
    private let locationStuckDistance: CLLocationDistance = 50 // Within 50 meters considered "stuck"
    private let noUpdateThreshold: TimeInterval = 10 * 60 // No location update for 10 minutes
    private let criticalNoMovementThreshold: TimeInterval = 30 * 60 // No movement for 30 minutes (critical)
    
    func checkForAnomalies(
        currentLocation: CLLocation?,
        lastLocation: CLLocation?,
        lastUpdateTime: Date?,
        sessionStartTime: Date?
    ) -> Anomaly? {
        let now = Date()
        
        // Check 1: long period without any location updates
        if let lastUpdate = lastUpdateTime {
            let timeSinceUpdate = now.timeIntervalSince(lastUpdate)
            if timeSinceUpdate > noUpdateThreshold {
                let severity: Anomaly.Severity = timeSinceUpdate > criticalNoMovementThreshold ? .critical : .high
                return Anomaly(
                    type: .noLocationUpdate,
                    severity: severity,
                    message: "No location update received for \(Int(timeSinceUpdate / 60)) minutes. GPS signal may be lost.",
                    detectedAt: now
                )
            }
        }
        
        // Check 2: long period without movement
        guard let current = currentLocation, let last = lastLocation else {
            return nil
        }
        
        let distance = current.distance(from: last)
        let timeSinceLastUpdate = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 0
        
        // If the user has barely moved and the elapsed time exceeds the threshold
        if distance < locationStuckDistance && timeSinceLastUpdate > noMovementThreshold {
            let severity: Anomaly.Severity = timeSinceLastUpdate > criticalNoMovementThreshold ? .critical : .high
            return Anomaly(
                type: .noMovement,
                severity: severity,
                message: "No movement detected for \(Int(timeSinceLastUpdate / 60)) minutes. May need assistance.",
                detectedAt: now
            )
        }
        
        // Check 3: location appears stuck (position almost unchanged)
        if distance < locationStuckDistance && timeSinceLastUpdate > 5 * 60 { // 5 minutes
            return Anomaly(
                type: .locationStuck,
                severity: .medium,
                message: "Location appears unchanged. Please confirm if everything is normal.",
                detectedAt: now
            )
        }
        
        return nil
    }
}

