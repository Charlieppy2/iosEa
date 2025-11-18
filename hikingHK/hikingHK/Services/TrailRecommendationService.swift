//
//  TrailRecommendationService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import CoreLocation

protocol TrailRecommendationServiceProtocol {
    func recommendTrails(
        from trails: [Trail],
        userPreference: UserPreference?,
        weatherSnapshot: WeatherSnapshot?,
        currentTime: Date,
        availableTime: TimeInterval?,
        userHistory: [HikeRecord]
    ) -> [TrailRecommendation]
}

struct TrailRecommendation: Identifiable {
    let id: UUID
    let trail: Trail
    let score: Double
    let reasons: [String]
    let matchPercentage: Int
    
    init(trail: Trail, score: Double, reasons: [String]) {
        self.id = trail.id
        self.trail = trail
        self.score = score
        self.reasons = reasons
        self.matchPercentage = min(Int(score * 100), 100)
    }
}

final class TrailRecommendationService: TrailRecommendationServiceProtocol {
    
    func recommendTrails(
        from trails: [Trail],
        userPreference: UserPreference?,
        weatherSnapshot: WeatherSnapshot?,
        currentTime: Date,
        availableTime: TimeInterval?,
        userHistory: [HikeRecord]
    ) -> [TrailRecommendation] {
        var recommendations: [TrailRecommendation] = []
        
        for trail in trails {
            var score: Double = 0.5 // 基礎分數
            var reasons: [String] = []
            
            // 1. 基於用戶偏好評分
            if let preference = userPreference {
                score += scoreBasedOnPreference(trail: trail, preference: preference, reasons: &reasons)
            }
            
            // 2. 基於天氣評分
            if let weather = weatherSnapshot {
                score += scoreBasedOnWeather(trail: trail, weather: weather, reasons: &reasons)
            }
            
            // 3. 基於時間評分
            score += scoreBasedOnTime(trail: trail, currentTime: currentTime, reasons: &reasons)
            
            // 4. 基於可用時間評分
            if let time = availableTime {
                score += scoreBasedOnAvailableTime(trail: trail, availableTime: time, reasons: &reasons)
            }
            
            // 5. 基於歷史數據評分（學習用戶偏好）
            score += scoreBasedOnHistory(trail: trail, history: userHistory, reasons: &reasons)
            
            // 6. 多樣性評分（避免總是推薦相同的路線）
            score += scoreBasedOnDiversity(trail: trail, history: userHistory, reasons: &reasons)
            
            // 正規化分數到 0-1 範圍
            score = min(max(score, 0), 1)
            
            if score > 0.3 { // 只推薦分數大於 0.3 的路線
                recommendations.append(TrailRecommendation(
                    trail: trail,
                    score: score,
                    reasons: reasons
                ))
            }
        }
        
        // 按分數排序
        return recommendations.sorted { $0.score > $1.score }
    }
    
    // MARK: - 評分函數
    
    private func scoreBasedOnPreference(
        trail: Trail,
        preference: UserPreference,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0
        
        // 難度匹配
        if let preferredDifficulty = preference.preferredDifficulty {
            if trail.difficulty == preferredDifficulty {
                score += 0.2
                reasons.append("符合您偏好的難度")
            }
        } else {
            // 根據體能水平推薦
            if preference.fitnessLevel.recommendedDifficulty.contains(trail.difficulty) {
                score += 0.15
                reasons.append("適合您的體能水平")
            }
        }
        
        // 距離匹配
        if let distanceRange = preference.preferredDistance {
            if trail.lengthKm >= distanceRange.minKm && trail.lengthKm <= distanceRange.maxKm {
                score += 0.15
                reasons.append("距離符合您的偏好")
            }
        }
        
        // 時長匹配
        if let durationRange = preference.preferredDuration {
            let trailDuration = trail.estimatedDurationMinutes
            if trailDuration >= durationRange.minMinutes && trailDuration <= durationRange.maxMinutes {
                score += 0.15
                reasons.append("時長符合您的偏好")
            }
        }
        
        // 風景類型匹配（基於路線名稱和描述推斷）
        let trailText = (trail.name + " " + trail.summary).lowercased()
        for scenery in preference.preferredScenery {
            if matchesScenery(trailText: trailText, scenery: scenery) {
                score += 0.1
                reasons.append("包含您喜歡的\(scenery.rawValue)")
            }
        }
        
        return score
    }
    
    private func scoreBasedOnWeather(
        trail: Trail,
        weather: WeatherSnapshot,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0
        
        // 溫度適宜性（15-25°C 最適宜）
        let temp = weather.temperature
        if temp >= 15 && temp <= 25 {
            score += 0.1
            reasons.append("天氣溫度適宜")
        } else if temp > 25 {
            // 高溫時推薦有遮陰或海邊路線
            let trailText = (trail.name + " " + trail.summary).lowercased()
            if trailText.contains("海") || trailText.contains("水") || trailText.contains("樹") {
                score += 0.05
                reasons.append("高溫天氣，推薦有遮陰或近水路線")
            }
        }
        
        // UV 指數
        if weather.uvIndex >= 8 {
            reasons.append("UV 指數較高，請注意防曬")
        }
        
        // 降雨概率（如果有數據）
        // 這裡可以根據實際天氣 API 數據調整
        
        return score
    }
    
    private func scoreBasedOnTime(
        trail: Trail,
        currentTime: Date,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0
        let hour = Calendar.current.component(.hour, from: currentTime)
        
        // 根據當前時間推薦
        if hour >= 5 && hour < 9 {
            // 清晨 - 推薦看日出的路線
            let trailText = (trail.name + " " + trail.summary).lowercased()
            if trailText.contains("日出") || trailText.contains("東") {
                score += 0.1
                reasons.append("適合清晨觀看日出")
            }
        } else if hour >= 16 && hour < 19 {
            // 傍晚 - 推薦看日落的路線
            let trailText = (trail.name + " " + trail.summary).lowercased()
            if trailText.contains("日落") || trailText.contains("西") {
                score += 0.1
                reasons.append("適合傍晚觀看日落")
            }
        }
        
        return score
    }
    
    private func scoreBasedOnAvailableTime(
        trail: Trail,
        availableTime: TimeInterval,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0
        let trailDuration = TimeInterval(trail.estimatedDurationMinutes * 60)
        
        // 如果可用時間足夠完成路線
        if availableTime >= trailDuration {
            score += 0.1
            reasons.append("時間充足，可以完成")
        } else if availableTime >= trailDuration * 0.7 {
            // 時間稍緊但可以完成
            score += 0.05
            reasons.append("時間稍緊，建議加快速度")
        } else {
            // 時間不足
            score -= 0.1
        }
        
        return score
    }
    
    private func scoreBasedOnHistory(
        trail: Trail,
        history: [HikeRecord],
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0
        
        // 計算用戶完成類似路線的次數
        let similarTrails = history.filter { record in
            record.trailId == trail.id ||
            (record.trailName?.lowercased().contains(trail.name.lowercased()) ?? false)
        }
        
        if similarTrails.isEmpty {
            // 新路線加分（鼓勵探索）
            score += 0.1
            reasons.append("您尚未嘗試過此路線")
        } else {
            // 如果用戶完成過且喜歡（可以根據完成率判斷）
            let completionRate = Double(similarTrails.filter { $0.isCompleted }.count) / Double(max(similarTrails.count, 1))
            if completionRate > 0.7 {
                score += 0.15
                reasons.append("您經常完成此類路線")
            }
        }
        
        // 分析用戶偏好的路線特徵
        let completedTrails = history.filter { $0.isCompleted }
        if !completedTrails.isEmpty {
            let avgDistance = completedTrails.map { $0.distanceKm }.reduce(0, +) / Double(completedTrails.count)
            let distanceDiff = abs(trail.lengthKm - avgDistance) / max(avgDistance, 1)
            
            if distanceDiff < 0.3 {
                score += 0.1
                reasons.append("距離接近您常走的路線")
            }
        }
        
        return score
    }
    
    private func scoreBasedOnDiversity(
        trail: Trail,
        history: [HikeRecord],
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0
        
        // 檢查最近是否走過相同路線
        let recentHistory = history.filter { record in
            record.trailId == trail.id &&
            record.startTime > Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 天內
        }
        
        if recentHistory.isEmpty {
            // 最近沒走過，加分（鼓勵多樣性）
            score += 0.05
        } else {
            // 最近走過，減分（避免重複）
            score -= 0.1
        }
        
        return score
    }
    
    // MARK: - 輔助函數
    
    private func matchesScenery(trailText: String, scenery: UserPreference.SceneryType) -> Bool {
        let keywords: [UserPreference.SceneryType: [String]] = [
            .sea: ["海", "海邊", "海岸", "beach", "coast", "sea"],
            .mountain: ["山", "峰", "嶺", "mountain", "peak", "ridge"],
            .forest: ["林", "樹", "森", "forest", "tree", "wood"],
            .reservoir: ["水庫", "湖", "reservoir", "lake"],
            .city: ["城市", "市區", "city", "urban"],
            .sunset: ["日落", "夕陽", "sunset", "evening"],
            .sunrise: ["日出", "晨曦", "sunrise", "dawn"]
        ]
        
        guard let keywordsList = keywords[scenery] else { return false }
        return keywordsList.contains { trailText.contains($0) }
    }
}

