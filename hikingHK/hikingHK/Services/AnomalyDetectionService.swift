//
//  AnomalyDetectionService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import CoreLocation

protocol AnomalyDetectionServiceProtocol {
    func checkForAnomalies(
        currentLocation: CLLocation?,
        lastLocation: CLLocation?,
        lastUpdateTime: Date?,
        sessionStartTime: Date?
    ) -> Anomaly?
}

struct Anomaly {
    let type: AnomalyType
    let severity: Severity
    let message: String
    let detectedAt: Date
    
    enum AnomalyType {
        case noMovement // 長時間不動
        case locationStuck // 位置卡住
        case noLocationUpdate // 長時間沒有位置更新
        case batteryLow // 電量低（可選）
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
    }
}

final class AnomalyDetectionService: AnomalyDetectionServiceProtocol {
    
    // 配置參數
    private let noMovementThreshold: TimeInterval = 15 * 60 // 15 分鐘不動
    private let locationStuckDistance: CLLocationDistance = 50 // 50 米內視為卡住
    private let noUpdateThreshold: TimeInterval = 10 * 60 // 10 分鐘沒有更新
    private let criticalNoMovementThreshold: TimeInterval = 30 * 60 // 30 分鐘不動（嚴重）
    
    func checkForAnomalies(
        currentLocation: CLLocation?,
        lastLocation: CLLocation?,
        lastUpdateTime: Date?,
        sessionStartTime: Date?
    ) -> Anomaly? {
        let now = Date()
        
        // 檢查 1: 長時間沒有位置更新
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
        
        // 檢查 2: 長時間不動
        guard let current = currentLocation, let last = lastLocation else {
            return nil
        }
        
        let distance = current.distance(from: last)
        let timeSinceLastUpdate = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 0
        
        // 如果位置幾乎沒有變化，且時間超過閾值
        if distance < locationStuckDistance && timeSinceLastUpdate > noMovementThreshold {
            let severity: Anomaly.Severity = timeSinceLastUpdate > criticalNoMovementThreshold ? .critical : .high
            return Anomaly(
                type: .noMovement,
                severity: severity,
                message: "No movement detected for \(Int(timeSinceLastUpdate / 60)) minutes. May need assistance.",
                detectedAt: now
            )
        }
        
        // 檢查 3: 位置卡住（位置幾乎相同）
        if distance < locationStuckDistance && timeSinceLastUpdate > 5 * 60 { // 5 分鐘
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

