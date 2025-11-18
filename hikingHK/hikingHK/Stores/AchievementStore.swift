//
//  AchievementStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class AchievementStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func seedDefaultsIfNeeded() throws {
        let descriptor = FetchDescriptor<Achievement>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else { return }
        
        // 插入默認成就
        for achievement in Achievement.defaultAchievements {
            context.insert(achievement)
        }
        try context.save()
    }
    
    func loadAllAchievements() throws -> [Achievement] {
        // SwiftData 的 SortDescriptor 對 @Model 類有限制，手動排序
        let descriptor = FetchDescriptor<Achievement>()
        let achievements = try context.fetch(descriptor)
        
        // 手動排序：先按類型，再按目標值
        return achievements.sorted { achievement1, achievement2 in
            if achievement1.badgeType.rawValue != achievement2.badgeType.rawValue {
                return achievement1.badgeType.rawValue < achievement2.badgeType.rawValue
            }
            return achievement1.targetValue < achievement2.targetValue
        }
    }
    
    func loadUnlockedAchievements() throws -> [Achievement] {
        var descriptor = FetchDescriptor<Achievement>()
        descriptor.predicate = #Predicate { $0.isUnlocked == true }
        let achievements = try context.fetch(descriptor)
        
        // 手動排序：按解鎖時間降序（最新的在前）
        return achievements.sorted { achievement1, achievement2 in
            guard let date1 = achievement1.unlockedAt, let date2 = achievement2.unlockedAt else {
                // 如果一個有日期一個沒有，有日期的排在前面
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

