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
    /// 確保資料庫中至少包含一份預設成就集合。
    /// - Parameter context: App 共用的 `ModelContext`
    static func ensureDefaults(in context: ModelContext) {
        do {
            var descriptor = FetchDescriptor<Achievement>()
            let existing = try context.fetch(descriptor)
            
            if existing.isEmpty {
                // 完全沒有成就：插入全部預設成就
                for achievement in Achievement.defaultAchievements {
                    context.insert(achievement)
                }
                try context.save()
                return
            }
            
            // 已有成就時：檢查是否缺少某些預設成就，如果缺少就補齊
            let existingIds = Set(existing.map { $0.id })
            let missing = Achievement.defaultAchievements.filter { !existingIds.contains($0.id) }
            guard !missing.isEmpty else { return }
            
            for achievement in missing {
                context.insert(achievement)
            }
            try context.save()
        } catch {
            print("⚠️ AchievementSeeder: 無法確保預設成就：\(error.localizedDescription)")
        }
    }
}


