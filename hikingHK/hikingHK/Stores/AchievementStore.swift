//
//  AchievementStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

/// Store responsible for querying and seeding `Achievement` models.
@MainActor
final class AchievementStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// Inserts the default achievements if the store is currently empty.
    func seedDefaultsIfNeeded() throws {
        let descriptor = FetchDescriptor<Achievement>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else { return }
        
        // Insert the full default achievement set when none exist yet.
        for achievement in Achievement.defaultAchievements {
            context.insert(achievement)
        }
        try context.save()
    }
    
    /// Loads all achievements, ordered by badge type then target value.
    func loadAllAchievements() throws -> [Achievement] {
        // SwiftData's SortDescriptor has limitations with @Model, so we sort in memory.
        let descriptor = FetchDescriptor<Achievement>()
        let achievements = try context.fetch(descriptor)
        
        // Sort manually: first by badge type, then by target value.
        return achievements.sorted { achievement1, achievement2 in
            if achievement1.badgeType.rawValue != achievement2.badgeType.rawValue {
                return achievement1.badgeType.rawValue < achievement2.badgeType.rawValue
            }
            return achievement1.targetValue < achievement2.targetValue
        }
    }
    
    /// Loads only unlocked achievements, sorted by unlock date descending (newest first).
    func loadUnlockedAchievements() throws -> [Achievement] {
        var descriptor = FetchDescriptor<Achievement>()
        descriptor.predicate = #Predicate { $0.isUnlocked == true }
        let achievements = try context.fetch(descriptor)
        
        // Sort manually by unlock date (newest first).
        return achievements.sorted { achievement1, achievement2 in
            guard let date1 = achievement1.unlockedAt, let date2 = achievement2.unlockedAt else {
                // If only one has a date, the one with a date should come first.
                if achievement1.unlockedAt != nil { return true }
                if achievement2.unlockedAt != nil { return false }
                return false
            }
            return date1 > date2
        }
    }
    
    func saveAchievement(_ achievement: Achievement) throws {
        try context.save()
    }
    
    func saveAchievements(_ achievements: [Achievement]) throws {
        try context.save()
    }
}

