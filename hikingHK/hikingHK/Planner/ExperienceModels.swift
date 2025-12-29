//
//  ExperienceModels.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

/// Lightweight snapshot of weather conditions used across the app.
struct WeatherSnapshot: Equatable {
    let location: String
    let temperature: Double
    let humidity: Int
    let uvIndex: Int
    let warningMessage: String?
    let suggestion: String
    let updatedAt: Date

    static let hongKongMorning = WeatherSnapshot(
        location: "Hong Kong Observatory",
        temperature: 24.5,
        humidity: 78,
        uvIndex: 5,
        warningMessage: nil,
        suggestion: "Partly cloudy with light easterlies. Great time to start ridge hikes before noon heat.",
        updatedAt: Date()
    )
}

/// Planned or completed hike associated with a specific trail and date.
struct SavedHike: Identifiable, Equatable {
    let id: UUID
    let trail: Trail
    var scheduledDate: Date
    var note: String
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        trail: Trail,
        scheduledDate: Date,
        note: String = "",
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.trail = trail
        self.scheduledDate = scheduledDate
        self.note = note
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
    
    /// Example data used for previews and initial UI testing.
    static let sampleData: [SavedHike] = [
        SavedHike(
            trail: Trail.sampleData[1],
            scheduledDate: Date().addingTimeInterval(60 * 60 * 24 * 3),
            note: "Sunrise hike with film crew"
        ),
        SavedHike(
            trail: Trail.sampleData[0],
            scheduledDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
            note: "Paced climb with club",
            isCompleted: true,
            completedAt: Date().addingTimeInterval(-60 * 60 * 24 * 2)
        )
    ]
}

