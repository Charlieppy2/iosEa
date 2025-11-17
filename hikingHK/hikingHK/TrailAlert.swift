//
//  TrailAlert.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

struct TrailAlert: Identifiable, Equatable {
    let id: UUID
    let title: String
    let detail: String
    let category: Category
    let severity: Severity
    let issuedAt: Date
    let expiresAt: Date?
    
    var isActive: Bool {
        guard let expiresAt = expiresAt else { return true }
        return Date() < expiresAt
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(issuedAt)
        if interval < 3600 {
            return "\(Int(interval / 60)) min ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600)) hours ago"
        } else {
            return "\(Int(interval / 86400)) days ago"
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
    }
}

