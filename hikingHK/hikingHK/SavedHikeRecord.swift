//
//  SavedHikeRecord.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@Model
final class SavedHikeRecord {
    @Attribute(.unique) var id: UUID
    var trailId: UUID
    var scheduledDate: Date
    var note: String

    init(id: UUID, trailId: UUID, scheduledDate: Date, note: String) {
        self.id = id
        self.trailId = trailId
        self.scheduledDate = scheduledDate
        self.note = note
    }
}

