//
//  AchievementSeeder.swift
//  hikingHK
//
//  用於保證在任何裝置上都會有預設的成就資料，避免出現「0 / 0 成就」而沒有列表的情況。
//

import Foundation
import SwiftData

@MainActor
enum AchievementSeeder {
    /// Ensures the database contains at least the default set of achievements.
    /// - Parameter context: The shared app `ModelContext`.
    static func ensureDefaults(in context: ModelContext) {
        do {
            var descriptor = FetchDescriptor<Achievement>()
            let existing = try context.fetch(descriptor)
            
            if existing.isEmpty {
                // No achievements at all: insert the full default set.
                for achievement in Achievement.defaultAchievements {
                    context.insert(achievement)
                }
                try context.save()
                return
            }
            
            // When achievements already exist, backfill any missing defaults by ID.
            let existingIds = Set(existing.map { $0.id })
            let missing = Achievement.defaultAchievements.filter { !existingIds.contains($0.id) }
            guard !missing.isEmpty else { return }
            
            for achievement in missing {
                context.insert(achievement)
            }
            try context.save()
        } catch {
            print("⚠️ AchievementSeeder: Failed to ensure default achievements: \(error.localizedDescription)")
        }
    }
}


