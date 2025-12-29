//
//  WeatherWarningHistory.swift
//  hikingHK
//
//  Created for weather warning history tracking
//

import Foundation

/// Represents a historical weather warning record
struct WeatherWarningHistory: Identifiable, Codable, Equatable {
    let id: UUID
    let code: String
    let name: String
    let actionCode: String
    let issueTime: Date
    let updateTime: Date?
    let cancelledAt: Date?
    
    init(
        id: UUID = UUID(),
        code: String,
        name: String,
        actionCode: String,
        issueTime: Date,
        updateTime: Date? = nil,
        cancelledAt: Date? = nil
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.actionCode = actionCode
        self.issueTime = issueTime
        self.updateTime = updateTime
        self.cancelledAt = cancelledAt
    }
    
    /// Convert from WeatherWarning to history record
    init(from warning: WeatherWarning, cancelledAt: Date? = nil) {
        self.id = UUID()
        self.code = warning.code
        self.name = warning.name
        self.actionCode = warning.actionCode
        
        // Parse dates from strings
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.issueTime = formatter.date(from: warning.issueTime) ?? Date()
        self.updateTime = formatter.date(from: warning.updateTime)
        self.cancelledAt = cancelledAt
    }
}

