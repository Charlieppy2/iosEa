//
//  Achievement.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@Model
final class Achievement {
    var id: String
    var badgeType: BadgeType
    var title: String
    var achievementDescription: String  // 重命名為 achievementDescription，避免與 @Model 宏衝突
    var icon: String
    var targetValue: Double
    var currentValue: Double
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
    
    enum BadgeType: String, Codable, CaseIterable {
        case distance = "Distance"
        case peak = "Peaks"
        case streak = "Streak"
        case exploration = "Exploration"
        
        var icon: String {
            switch self {
            case .distance: return "ruler.fill"
            case .peak: return "mountain.2.fill"
            case .streak: return "flame.fill"
            case .exploration: return "map.fill"
            }
        }
        
        func localizedRawValue(languageManager: LanguageManager) -> String {
            let key = "achievement.badge.type.\(rawValue.lowercased())"
            return languageManager.localizedString(for: key)
        }
    }
    
    func localizedTitle(languageManager: LanguageManager) -> String {
        let key = "achievement.\(id).title"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : title
    }
    
    func localizedDescription(languageManager: LanguageManager) -> String {
        let key = "achievement.\(id).description"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : achievementDescription
    }
    
    init(
        id: String,
        badgeType: BadgeType,
        title: String,
        achievementDescription: String,
        icon: String,
        targetValue: Double,
        currentValue: Double = 0,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.badgeType = badgeType
        self.title = title
        self.achievementDescription = achievementDescription
        self.icon = icon
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
    
    func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedAt = Date()
    }
    
    func updateProgress(_ value: Double) {
        currentValue = value
        if currentValue >= targetValue && !isUnlocked {
            unlock()
        }
    }
}

extension Achievement {
    static let defaultAchievements: [Achievement] = [
        // Distance Badges
        Achievement(
            id: "distance_10km",
            badgeType: .distance,
            title: "Beginner Hiker",
            achievementDescription: "Complete 10 km of hiking",
            icon: "figure.walk",
            targetValue: 10.0
        ),
        Achievement(
            id: "distance_50km",
            badgeType: .distance,
            title: "Hiking Enthusiast",
            achievementDescription: "Complete 50 km of hiking",
            icon: "figure.hiking",
            targetValue: 50.0
        ),
        Achievement(
            id: "distance_100km",
            badgeType: .distance,
            title: "Hiking Expert",
            achievementDescription: "Complete 100 km of hiking",
            icon: "figure.climbing",
            targetValue: 100.0
        ),
        Achievement(
            id: "distance_500km",
            badgeType: .distance,
            title: "Hiking Master",
            achievementDescription: "Complete 500 km of hiking",
            icon: "crown.fill",
            targetValue: 500.0
        ),
        
        // Peak Badges
        Achievement(
            id: "peak_lion_rock",
            badgeType: .peak,
            title: "Lion Rock Conqueror",
            achievementDescription: "Summit Lion Rock",
            icon: "mountain.2.fill",
            targetValue: 1.0
        ),
        Achievement(
            id: "peak_tai_mo_shan",
            badgeType: .peak,
            title: "Tai Mo Shan Conqueror",
            achievementDescription: "Summit Tai Mo Shan (Hong Kong's highest peak)",
            icon: "mountain.2.fill",
            targetValue: 1.0
        ),
        Achievement(
            id: "peak_sunset_peak",
            badgeType: .peak,
            title: "Sunset Peak Conqueror",
            achievementDescription: "Summit Sunset Peak (Lantau Island)",
            icon: "mountain.2.fill",
            targetValue: 1.0
        ),
        Achievement(
            id: "peak_sharp_peak",
            badgeType: .peak,
            title: "Sharp Peak Conqueror",
            achievementDescription: "Summit Sharp Peak",
            icon: "mountain.2.fill",
            targetValue: 1.0
        ),
        Achievement(
            id: "peak_4_peaks",
            badgeType: .peak,
            title: "Four Peaks Conqueror",
            achievementDescription: "Summit 4 different peaks",
            icon: "mountain.2.fill",
            targetValue: 4.0
        ),
        
        // Streak Badges
        Achievement(
            id: "streak_1_week",
            badgeType: .streak,
            title: "One Week Streak",
            achievementDescription: "Hike for 7 consecutive days",
            icon: "calendar",
            targetValue: 7.0
        ),
        Achievement(
            id: "streak_2_weeks",
            badgeType: .streak,
            title: "Two Week Streak",
            achievementDescription: "Hike for 14 consecutive days",
            icon: "calendar.badge.clock",
            targetValue: 14.0
        ),
        Achievement(
            id: "streak_1_month",
            badgeType: .streak,
            title: "Monthly Streak",
            achievementDescription: "Hike for 30 consecutive days",
            icon: "calendar.badge.checkmark",
            targetValue: 30.0
        ),
        
        // Exploration Badges
        Achievement(
            id: "explore_3_districts",
            badgeType: .exploration,
            title: "Explorer",
            achievementDescription: "Explore 3 different districts",
            icon: "map",
            targetValue: 3.0
        ),
        Achievement(
            id: "explore_5_districts",
            badgeType: .exploration,
            title: "Adventurer",
            achievementDescription: "Explore 5 different districts",
            icon: "map.circle.fill",
            targetValue: 5.0
        ),
        Achievement(
            id: "explore_10_districts",
            badgeType: .exploration,
            title: "Exploration Master",
            achievementDescription: "Explore 10 different districts",
            icon: "map.fill",
            targetValue: 10.0
        )
    ]
}

