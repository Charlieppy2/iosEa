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
            case .low: return "低"
            case .medium: return "中"
            case .high: return "高"
            case .critical: return "嚴重"
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
                    message: "已經 \(Int(timeSinceUpdate / 60)) 分鐘沒有收到位置更新。可能失去 GPS 信號。",
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
                message: "已經 \(Int(timeSinceLastUpdate / 60)) 分鐘沒有移動。可能遇到困難或需要協助。",
                detectedAt: now
            )
        }
        
        // 檢查 3: 位置卡住（位置幾乎相同）
        if distance < locationStuckDistance && timeSinceLastUpdate > 5 * 60 { // 5 分鐘
            return Anomaly(
                type: .locationStuck,
                severity: .medium,
                message: "位置似乎沒有變化。請確認是否正常。",
                detectedAt: now
            )
        }
        
        return nil
    }
}

