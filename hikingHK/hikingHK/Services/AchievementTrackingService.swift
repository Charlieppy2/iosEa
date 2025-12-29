//
//  AchievementTrackingService.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation

/// Contract for services that can update achievement progress from user activity data.
protocol AchievementTrackingServiceProtocol {
    func updateDistanceAchievements(achievements: [Achievement], totalDistance: Double) -> [Achievement]
    func updatePeakAchievements(achievements: [Achievement], completedPeaks: [String]) -> [Achievement]
    func updateStreakAchievements(achievements: [Achievement], currentStreak: Int) -> [Achievement]
    func updateExplorationAchievements(achievements: [Achievement], exploredDistricts: Set<String>) -> [Achievement]
}

final class AchievementTrackingService: AchievementTrackingServiceProtocol {
    
    func updateDistanceAchievements(achievements: [Achievement], totalDistance: Double) -> [Achievement] {
        var updated = achievements
        let distanceAchievements = updated.filter { $0.badgeType == .distance }
        
        for achievement in distanceAchievements {
            achievement.updateProgress(totalDistance)
        }
        
        return updated
    }
    
    func updatePeakAchievements(achievements: [Achievement], completedPeaks: [String]) -> [Achievement] {
        var updated = achievements
        let peakAchievements = updated.filter { $0.badgeType == .peak }
        
        for achievement in peakAchievements {
            switch achievement.id {
            case "peak_lion_rock":
                if completedPeaks.contains(where: { $0.localizedCaseInsensitiveContains("獅子山") || $0.localizedCaseInsensitiveContains("Lion Rock") }) {
                    achievement.updateProgress(1.0)
                }
            case "peak_tai_mo_shan":
                if completedPeaks.contains(where: { $0.localizedCaseInsensitiveContains("大帽山") || $0.localizedCaseInsensitiveContains("Tai Mo Shan") }) {
                    achievement.updateProgress(1.0)
                }
            case "peak_sunset_peak":
                if completedPeaks.contains(where: { $0.localizedCaseInsensitiveContains("鳳凰山") || $0.localizedCaseInsensitiveContains("Sunset Peak") || $0.localizedCaseInsensitiveContains("Lantau Peak") }) {
                    achievement.updateProgress(1.0)
                }
            case "peak_sharp_peak":
                if completedPeaks.contains(where: { $0.localizedCaseInsensitiveContains("蚺蛇尖") || $0.localizedCaseInsensitiveContains("Sharp Peak") }) {
                    achievement.updateProgress(1.0)
                }
            case "peak_4_peaks":
                achievement.updateProgress(Double(completedPeaks.count))
            default:
                break
            }
        }
        
        return updated
    }
    
    func updateStreakAchievements(achievements: [Achievement], currentStreak: Int) -> [Achievement] {
        var updated = achievements
        let streakAchievements = updated.filter { $0.badgeType == .streak }
        
        for achievement in streakAchievements {
            achievement.updateProgress(Double(currentStreak))
        }
        
        return updated
    }
    
    func updateExplorationAchievements(achievements: [Achievement], exploredDistricts: Set<String>) -> [Achievement] {
        var updated = achievements
        let explorationAchievements = updated.filter { $0.badgeType == .exploration }
        
        for achievement in explorationAchievements {
            achievement.updateProgress(Double(exploredDistricts.count))
        }
        
        return updated
    }
}

