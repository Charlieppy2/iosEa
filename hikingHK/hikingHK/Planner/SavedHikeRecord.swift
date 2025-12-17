//
//  SavedHikeRecord.swift
//  hikingHK
//
//  SwiftData model storing planned or completed hikes
//  created from the Planner screen.
//

import Foundation
import SwiftData

/// Persisted record of a single planned hike, including completion status.
@Model
final class SavedHikeRecord {
    @Attribute(.unique) var id: UUID
    var trailId: UUID
    var scheduledDate: Date
    var note: String
    var isCompleted: Bool = false
    var completedAt: Date?

    init(id: UUID, trailId: UUID, scheduledDate: Date, note: String, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.trailId = trailId
        self.scheduledDate = scheduledDate
        self.note = note
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

