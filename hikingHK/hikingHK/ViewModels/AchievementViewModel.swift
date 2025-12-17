//
//  AchievementViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import Combine

/// View model responsible for loading, tracking and updating user achievements.
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
    
    /// Lazily configures the underlying `AchievementStore` and loads initial data.
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        self.modelContext = context
        store = AchievementStore(context: context)
        
        do {
            try store?.seedDefaultsIfNeeded()
            achievements = try store?.loadAllAchievements() ?? []
        } catch {
            self.error = "Failed to load achievements: \(error.localizedDescription)"
        }
    }
    
    /// Recomputes achievement progress from the latest hike records
    /// and persists any changes, tracking newly unlocked achievements.
    func refreshAchievements(from hikeRecords: [HikeRecord]) {
        guard let store = store else { return }
        
        // Compute aggregate statistics from completed hikes.
        let totalDistance = hikeRecords
            .filter { $0.isCompleted }
            .map { $0.distanceKm }
            .reduce(0, +)
        
        let completedPeaks = extractPeakNames(from: hikeRecords)
        let currentStreak = calculateCurrentStreak(from: hikeRecords)
        let exploredDistricts = extractDistricts(from: hikeRecords)
        
        // Update progress across all achievement dimensions.
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
        
        // Detect which achievements have just transitioned to unlocked.
        let newlyUnlocked = updatedAchievements.filter { achievement in
            achievement.isUnlocked && !(achievements.first(where: { $0.id == achievement.id })?.isUnlocked ?? false)
        }
        
        if !newlyUnlocked.isEmpty {
            newlyUnlockedAchievements = newlyUnlocked
        }
        
        achievements = updatedAchievements
        
        // Persist updated achievements back to the store.
        do {
            try store.saveAchievements(achievements)
        } catch {
            self.error = "Failed to save achievements: \(error.localizedDescription)"
        }
    }
    
    /// Extracts peak-like trail names from completed hike records.
    private func extractPeakNames(from records: [HikeRecord]) -> [String] {
        records
            .filter { $0.isCompleted }
            .compactMap { $0.trailName }
            .filter { name in
                // Check for keywords that indicate a peak or mountain.
                let lowercased = name.lowercased()
                return lowercased.contains("peak") ||
                       lowercased.contains("mountain") ||
                       lowercased.contains("山") ||
                       lowercased.contains("峰")
            }
    }
    
    /// Calculates the current streak of consecutive days with completed hikes.
    private func calculateCurrentStreak(from records: [HikeRecord]) -> Int {
        let completedRecords = records
            .filter { $0.isCompleted }
            .sorted { ($0.endTime ?? $0.startTime) > ($1.endTime ?? $1.startTime) }
        
        guard !completedRecords.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())
        
        // Check whether there is a hike record for today.
        let today = calendar.startOfDay(for: Date())
        let hasToday = completedRecords.contains { record in
            let recordDate = calendar.startOfDay(for: record.endTime ?? record.startTime)
            return calendar.isDate(recordDate, inSameDayAs: today)
        }
        
        if !hasToday {
            // If there is no record today, start streak counting from yesterday.
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
        }
        
        // Walk backwards through records to count consecutive days.
        for record in completedRecords {
            let recordDate = calendar.startOfDay(for: record.endTime ?? record.startTime)
            
            if calendar.isDate(recordDate, inSameDayAs: expectedDate) {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else if recordDate < expectedDate {
                // If the record date is earlier than expected, the streak is broken.
                break
            }
        }
        
        return streak
    }
    
    /// Extracts a simplified set of districts from completed hike trail names.
    /// This is a heuristic; in the future this could come directly from `Trail` metadata.
    private func extractDistricts(from records: [HikeRecord]) -> Set<String> {
        var districts = Set<String>()
        
        for record in records.filter({ $0.isCompleted }) {
            if let trailName = record.trailName {
                // Simple keyword-based district extraction.
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

