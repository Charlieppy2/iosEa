//
//  TrailAlert.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation

/// In-memory model representing an alert affecting one or more hiking trails.
struct TrailAlert: Identifiable, Equatable {
    let id: UUID
    let title: String
    let detail: String
    let category: Category
    let severity: Severity
    let issuedAt: Date
    let updatedAt: Date? // 更新時間（從 warnsum API 獲取）
    let expiresAt: Date?
    
    var isActive: Bool {
        guard let expiresAt = expiresAt else { return true }
        return Date() < expiresAt
    }
    
    func timeAgo(languageManager: LanguageManager) -> String {
        let interval = Date().timeIntervalSince(issuedAt)
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) \(languageManager.localizedString(for: "alert.time.minutes.ago"))"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) \(languageManager.localizedString(for: "alert.time.hours.ago"))"
        } else {
            let days = Int(interval / 86400)
            return "\(days) \(languageManager.localizedString(for: "alert.time.days.ago"))"
        }
    }
    
    enum Category: String, CaseIterable {
        case weather = "Weather"
        case maintenance = "Maintenance"
        case safety = "Safety"
        case closure = "Closure"
        
        var icon: String {
            switch self {
            case .weather: return "cloud.bolt.fill"
            case .maintenance: return "hammer.fill"
            case .safety: return "exclamationmark.triangle.fill"
            case .closure: return "xmark.circle.fill"
            }
        }
        
        func localizedRawValue(languageManager: LanguageManager) -> String {
            let key = "alert.category.\(rawValue.lowercased())"
            return languageManager.localizedString(for: key)
        }
    }
    
    enum Severity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .low: return "blue"
            case .medium: return "orange"
            case .high: return "red"
            case .critical: return "purple"
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "info.circle.fill"
            case .medium: return "exclamationmark.triangle.fill"
            case .high: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
        
        func localizedRawValue(languageManager: LanguageManager) -> String {
            let key = "alert.severity.\(rawValue.lowercased())"
            return languageManager.localizedString(for: key)
        }
    }
}

