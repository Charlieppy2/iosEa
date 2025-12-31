//
//  AchievementSeeder.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
enum AchievementSeeder {
    /// Ensures the database contains at least the default set of achievements for a specific user.
    /// - Parameters:
    ///   - context: The shared app `ModelContext`.
    ///   - accountId: The user account ID to create achievements for.
    static func ensureDefaults(in context: ModelContext, accountId: UUID) {
        do {
            var descriptor = FetchDescriptor<Achievement>(
                predicate: #Predicate { $0.accountId == accountId }
            )
            let existing = try context.fetch(descriptor)
            
            if existing.isEmpty {
                // No achievements at all for this user: insert the full default set.
                for template in Achievement.defaultAchievementTemplates {
                    let achievement = template.createAchievement(accountId: accountId)
                    context.insert(achievement)
                }
                try context.save()
                return
            }
            
            // When achievements already exist, backfill any missing defaults by ID.
            let existingIds = Set(existing.map { $0.id })
            let missing = Achievement.defaultAchievementTemplates.filter { !existingIds.contains($0.id) }
            guard !missing.isEmpty else { return }
            
            for template in missing {
                let achievement = template.createAchievement(accountId: accountId)
                context.insert(achievement)
            }
            try context.save()
        } catch {
            print("⚠️ AchievementSeeder: Failed to ensure default achievements: \(error.localizedDescription)")
        }
    }
}


