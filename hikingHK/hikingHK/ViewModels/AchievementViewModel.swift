//
//  AchievementViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class AchievementViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var newlyUnlockedAchievements: [Achievement] = []
    
    private var store: AchievementStore?
    private var modelContext: ModelContext?
    private let trackingService: AchievementTrackingServiceProtocol
    
    init(trackingService: AchievementTrackingServiceProtocol = AchievementTrackingService()) {
        self.trackingService = trackingService
    }
    
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        self.modelContext = context
        store = AchievementStore(context: context)
        
        do {
            try store?.seedDefaultsIfNeeded()
            achievements = try store?.loadAllAchievements() ?? []
        } catch {
            self.error = "載入成就失敗：\(error.localizedDescription)"
        }
    }
    
    func refreshAchievements(from hikeRecords: [HikeRecord]) {
        guard let store = store else { return }
        
        // 計算統計數據
        let totalDistance = hikeRecords
            .filter { $0.isCompleted }
            .map { $0.distanceKm }
            .reduce(0, +)
        
        let completedPeaks = extractPeakNames(from: hikeRecords)
        let currentStreak = calculateCurrentStreak(from: hikeRecords)
        let exploredDistricts = extractDistricts(from: hikeRecords)
        
        // 更新成就進度
        var updatedAchievements = achievements
        updatedAchievements = trackingService.updateDistanceAchievements(
            achievements: updatedAchievements,
            totalDistance: totalDistance
        )
        updatedAchievements = trackingService.updatePeakAchievements(
            achievements: updatedAchievements,
            completedPeaks: completedPeaks
        )
        updatedAchievements = trackingService.updateStreakAchievements(
            achievements: updatedAchievements,
            currentStreak: currentStreak
        )
        updatedAchievements = trackingService.updateExplorationAchievements(
            achievements: updatedAchievements,
            exploredDistricts: exploredDistricts
        )
        
        // 檢查新解鎖的成就
        let newlyUnlocked = updatedAchievements.filter { achievement in
            achievement.isUnlocked && !(achievements.first(where: { $0.id == achievement.id })?.isUnlocked ?? false)
        }
        
        if !newlyUnlocked.isEmpty {
            newlyUnlockedAchievements = newlyUnlocked
        }
        
        achievements = updatedAchievements
        
        // 保存更新
        do {
            try store.saveAchievements(achievements)
        } catch {
            self.error = "保存成就失敗：\(error.localizedDescription)"
        }
    }
    
    private func extractPeakNames(from records: [HikeRecord]) -> [String] {
        records
            .filter { $0.isCompleted }
            .compactMap { $0.trailName }
            .filter { name in
                // 檢查是否包含山峰關鍵詞
                let lowercased = name.lowercased()
                return lowercased.contains("peak") ||
                       lowercased.contains("mountain") ||
                       lowercased.contains("山") ||
                       lowercased.contains("峰")
            }
    }
    
    private func calculateCurrentStreak(from records: [HikeRecord]) -> Int {
        let completedRecords = records
            .filter { $0.isCompleted }
            .sorted { ($0.endTime ?? $0.startTime) > ($1.endTime ?? $1.startTime) }
        
        guard !completedRecords.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())
        
        // 檢查今天是否有行山記錄
        let today = calendar.startOfDay(for: Date())
        let hasToday = completedRecords.contains { record in
            let recordDate = calendar.startOfDay(for: record.endTime ?? record.startTime)
            return calendar.isDate(recordDate, inSameDayAs: today)
        }
        
        if !hasToday {
            // 如果今天沒有，從昨天開始計算
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
        }
        
        // 計算連續天數
        for record in completedRecords {
            let recordDate = calendar.startOfDay(for: record.endTime ?? record.startTime)
            
            if calendar.isDate(recordDate, inSameDayAs: expectedDate) {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else if recordDate < expectedDate {
                // 如果記錄日期早於預期日期，說明有間斷
                break
            }
        }
        
        return streak
    }
    
    private func extractDistricts(from records: [HikeRecord]) -> Set<String> {
        // 從路線名稱中提取地區信息
        // 這裡簡化處理，實際可以從 Trail 數據中獲取
        var districts = Set<String>()
        
        for record in records.filter({ $0.isCompleted }) {
            if let trailName = record.trailName {
                // 簡單的地區提取邏輯
                if trailName.contains("Sai Kung") || trailName.contains("西貢") {
                    districts.insert("Sai Kung")
                } else if trailName.contains("Lantau") || trailName.contains("大嶼山") {
                    districts.insert("Lantau")
                } else if trailName.contains("Hong Kong Island") || trailName.contains("香港島") {
                    districts.insert("Hong Kong Island")
                } else if trailName.contains("Kowloon") || trailName.contains("九龍") {
                    districts.insert("Kowloon")
                } else if trailName.contains("New Territories") || trailName.contains("新界") {
                    districts.insert("New Territories")
                }
            }
        }
        
        return districts
    }
    
    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var totalCount: Int {
        achievements.count
    }
    
    var achievementsByType: [Achievement.BadgeType: [Achievement]] {
        Dictionary(grouping: achievements) { $0.badgeType }
    }
}

