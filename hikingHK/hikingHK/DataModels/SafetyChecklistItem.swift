//
//  SafetyChecklistItem.swift
//  hikingHK
//
//  Created by user on 17/11/2025.

import Foundation
import SwiftData

/// Single checklist row used in the Safety Checklist section on the home screen.
@Model
final class SafetyChecklistItem {
    var id: String
    var accountId: UUID // User account ID to associate this record with a specific user
    var iconName: String
    var title: String
    var isCompleted: Bool
    var lastUpdated: Date
    
    init(id: String, accountId: UUID, iconName: String, title: String, isCompleted: Bool = false) {
        self.id = id
        self.accountId = accountId
        self.iconName = iconName
        self.title = title
        self.isCompleted = isCompleted
        self.lastUpdated = Date()
    }
}

