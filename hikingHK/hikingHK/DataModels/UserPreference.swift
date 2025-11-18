//
//  UserPreference.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@Model
final class UserPreference {
    var id: UUID
    var preferredScenery: [SceneryType] // 偏好的風景類型
    var preferredDifficultyRawValue: String? // 偏好的難度（存儲為 String）
    
    var preferredDifficulty: Trail.Difficulty? {
        get {
            guard let rawValue = preferredDifficultyRawValue else { return nil }
            return Trail.Difficulty(rawValue: rawValue)
        }
        set {
            preferredDifficultyRawValue = newValue?.rawValue
        }
    }
    var preferredDuration: TimeRange? // 偏好的時長範圍
    var preferredDistance: DistanceRange? // 偏好的距離範圍
    var preferredTimeOfDay: [TimeOfDay] // 偏好的時間段
    var fitnessLevel: FitnessLevel // 體能水平
    var lastUpdated: Date
    
    enum SceneryType: String, Codable, CaseIterable {
        case sea = "海景"
        case mountain = "山景"
        case forest = "森林"
        case reservoir = "水庫"
        case city = "城市景觀"
        case sunset = "日落"
        case sunrise = "日出"
        
        var icon: String {
            switch self {
            case .sea: return "water.waves"
            case .mountain: return "mountain.2.fill"
            case .forest: return "tree.fill"
            case .reservoir: return "drop.fill"
            case .city: return "building.2.fill"
            case .sunset: return "sun.horizon.fill"
            case .sunrise: return "sunrise.fill"
            }
        }
        
        func localizedRawValue(languageManager: LanguageManager) -> String {
            let key = "preferences.scenery.\(rawValue)"
            let localized = languageManager.localizedString(for: key)
            return localized != key ? localized : rawValue
        }
    }
    
    enum TimeOfDay: String, Codable, CaseIterable {
        case earlyMorning = "清晨"
        case morning = "上午"
        case afternoon = "下午"
        case evening = "傍晚"
        
        var icon: String {
            switch self {
            case .earlyMorning: return "sunrise.fill"
            case .morning: return "sun.max.fill"
            case .afternoon: return "sun.horizon.fill"
            case .evening: return "moon.stars.fill"
            }
        }
    }
    
    enum FitnessLevel: String, Codable, CaseIterable {
        case beginner = "初學者"
        case intermediate = "中級"
        case advanced = "高級"
        case expert = "專家"
        
        var recommendedDifficulty: [Trail.Difficulty] {
            switch self {
            case .beginner:
                return [.easy]
            case .intermediate:
                return [.easy, .moderate]
            case .advanced:
                return [.moderate, .challenging]
            case .expert:
                return [.moderate, .challenging]
            }
        }
        
        func localizedRawValue(languageManager: LanguageManager) -> String {
            let key = "preferences.fitness.level.\(rawValue)"
            let localized = languageManager.localizedString(for: key)
            return localized != key ? localized : rawValue
        }
    }
    
    struct TimeRange: Codable {
        var minMinutes: Int
        var maxMinutes: Int
    }
    
    struct DistanceRange: Codable {
        var minKm: Double
        var maxKm: Double
    }
    
    init(
        id: UUID = UUID(),
        preferredScenery: [SceneryType] = [],
        preferredDifficulty: Trail.Difficulty? = nil,
        preferredDuration: TimeRange? = nil,
        preferredDistance: DistanceRange? = nil,
        preferredTimeOfDay: [TimeOfDay] = [],
        fitnessLevel: FitnessLevel = .intermediate,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.preferredScenery = preferredScenery
        self.preferredDifficultyRawValue = preferredDifficulty?.rawValue
        self.preferredDuration = preferredDuration
        self.preferredDistance = preferredDistance
        self.preferredTimeOfDay = preferredTimeOfDay
        self.fitnessLevel = fitnessLevel
        self.lastUpdated = lastUpdated
    }
}

