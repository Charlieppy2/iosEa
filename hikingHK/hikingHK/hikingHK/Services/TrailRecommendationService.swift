//
//  TrailRecommendationService.swift
//  hikingHK
//
//  Intelligent trail recommendation service with fully localized reasons
//  so the English UI never shows leftover Chinese text (and vice versa).
//

import Foundation
import CoreLocation

/// Contract for services that can generate trail recommendations.
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

/// A single recommendation result for a trail, including score and explanation reasons.
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
    
    /// Mapping of recommendation reason keys to Traditional Chinese strings
    /// so that we never fall back to English text in the Traditional Chinese UI.
    private let tcReasonMap: [String: String] = [
        "recommendations.reason.difficulty.match": "符合你設定的難度偏好",
        "recommendations.reason.fitness.level": "適合你目前的體能水平",
        "recommendations.reason.distance.match": "路線距離符合你的偏好",
        "recommendations.reason.duration.match": "行程時間符合你的偏好",
        "recommendations.reason.scenery.match": "包含你喜歡的風景類型",
        "recommendations.reason.weather.temperature.good": "目前氣溫適合行山",
        "recommendations.reason.weather.hot.shade": "天氣較熱，這條路線有樹蔭或近水較清涼",
        "recommendations.reason.weather.uv.high": "紫外線偏高，記得做好防曬",
        "recommendations.reason.time.sunrise": "適合清晨出發觀賞日出",
        "recommendations.reason.time.sunset": "適合黃昏時分觀賞日落",
        "recommendations.reason.time.enough": "你有足夠時間完成這條路線",
        "recommendations.reason.time.tight": "時間有點緊湊，需要較快步伐",
        "recommendations.reason.history.new.trail": "你未試過這條路線，適合探索新路",
        "recommendations.reason.history.often.completed": "與你經常完成的路線相似",
        "recommendations.reason.history.distance.similar": "距離和你平時行的路線相近"
    ]
    
    /// Resolve a localized recommendation reason string for the current app language,
    /// falling back to the provided `fallback` text if no localization is available.
    private func localizedReason(_ key: String, fallback: String) -> String {
        // For Traditional Chinese, prefer the explicit tcReasonMap to avoid English fallbacks.
        let currentLanguage = MainActor.assumeIsolated { LanguageManager.shared.currentLanguage }
        if currentLanguage == .traditionalChinese, let tc = tcReasonMap[key] {
            return tc
        }
        
        let value = LanguageManager.shared.localizedString(for: key)
        // If the key is missing, avoid showing the raw key; use the provided fallback instead.
        return value == key ? fallback : value
    }
    
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
            var score: Double = 0.5 // Base score
            var reasons: [String] = []
            
            // 1. Score based on explicit user hiking preferences
            if let preference = userPreference {
                score += scoreBasedOnPreference(trail: trail, preference: preference, reasons: &reasons)
            }
            
            // 2. Score based on current / recent weather snapshot
            if let weather = weatherSnapshot {
                score += scoreBasedOnWeather(trail: trail, weather: weather, reasons: &reasons)
            }
            
            // 3. Score based on current time of day (sunrise / sunset, etc.)
            score += scoreBasedOnTime(trail: trail, currentTime: currentTime, reasons: &reasons)
            
            // 4. Score based on how much time the user has available
            if let time = availableTime {
                score += scoreBasedOnAvailableTime(trail: trail, availableTime: time, reasons: &reasons)
            }
            
            // 5. Score based on past hiking history (learning user habits)
            score += scoreBasedOnHistory(trail: trail, history: userHistory, reasons: &reasons)
            
            // 6. Score for diversity so we don't always recommend the same trail
            score += scoreBasedOnDiversity(trail: trail, history: userHistory, reasons: &reasons)
            
            // Clamp score into 0–1 range
            score = min(max(score, 0), 1)
            
            if score > 0.3 { // Only recommend trails with a score above a minimum threshold
                recommendations.append(
                    TrailRecommendation(trail: trail, score: score, reasons: reasons)
                )
            }
        }
        
        // Sort by final score (highest first)
        return recommendations.sorted { $0.score > $1.score }
    }
    
    // MARK: - Scoring functions
    
    private func scoreBasedOnPreference(
        trail: Trail,
        preference: UserPreference,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0
        
        // Difficulty match
        if let preferredDifficulty = preference.preferredDifficulty {
            if trail.difficulty == preferredDifficulty {
                score += 0.2
                reasons.append(
                    localizedReason(
                        "recommendations.reason.difficulty.match",
                        fallback: "Matches your preferred difficulty"
                    )
                )
            }
        } else {
            // If no explicit difficulty preference, fall back to fitness level based suggestion
            if preference.fitnessLevel.recommendedDifficulty.contains(trail.difficulty) {
                score += 0.15
                reasons.append(
                    localizedReason(
                        "recommendations.reason.fitness.level",
                        fallback: "Suitable for your fitness level"
                    )
                )
            }
        }
        
        // Distance match
        if let distanceRange = preference.preferredDistance {
            if trail.lengthKm >= distanceRange.minKm && trail.lengthKm <= distanceRange.maxKm {
                score += 0.15
                reasons.append(
                    localizedReason(
                        "recommendations.reason.distance.match",
                        fallback: "Distance fits your preference"
                    )
                )
            }
        }
        
        // Duration match
        if let durationRange = preference.preferredDuration {
            let trailDuration = trail.estimatedDurationMinutes
            if trailDuration >= durationRange.minMinutes && trailDuration <= durationRange.maxMinutes {
                score += 0.15
                reasons.append(
                    localizedReason(
                        "recommendations.reason.duration.match",
                        fallback: "Duration fits your preference"
                    )
                )
            }
        }
        
        // Scenery type match (heuristic based on trail name and summary)
        let trailText = (trail.name + " " + trail.summary).lowercased()
        for scenery in preference.preferredScenery {
            if matchesScenery(trailText: trailText, scenery: scenery) {
                score += 0.1
                reasons.append(
                    localizedReason(
                        "recommendations.reason.scenery.match",
                        fallback: "Includes scenery you like"
                    )
                )
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
        
        // Temperature suitability (15–25°C is considered ideal)
        let temp = weather.temperature
        if temp >= 15 && temp <= 25 {
            score += 0.1
            reasons.append(
                localizedReason(
                    "recommendations.reason.weather.temperature.good",
                    fallback: "Comfortable temperature for hiking"
                )
            )
        } else if temp > 25 {
            // On hot days, slightly favor shaded or coastal / near-water routes
            let trailText = (trail.name + " " + trail.summary).lowercased()
            if trailText.contains("海") || trailText.contains("水") || trailText.contains("樹") {
                score += 0.05
                reasons.append(
                    localizedReason(
                        "recommendations.reason.weather.hot.shade",
                        fallback: "Hot weather – recommended trail with shade or near water"
                    )
                )
            }
        }
        
        // UV index information (adds a reason but does not change score)
        if weather.uvIndex >= 8 {
            reasons.append(
                localizedReason(
                    "recommendations.reason.weather.uv.high",
                    fallback: "High UV index – remember sun protection"
                )
            )
        }
        
        // Rain probability / precipitation hook – reserved for future enhancement.
        
        return score
    }
    
    private func scoreBasedOnTime(
        trail: Trail,
        currentTime: Date,
        reasons: inout [String]
    ) -> Double {
        var score: Double = 0
        let hour = Calendar.current.component(.hour, from: currentTime)
        
        // Recommend based on time of day (early morning vs evening)
        if hour >= 5 && hour < 9 {
            // Early morning – prioritize sunrise-friendly trails
            let trailText = (trail.name + " " + trail.summary).lowercased()
            if trailText.contains("日出") || trailText.contains("東") {
                score += 0.1
                reasons.append(
                    localizedReason(
                        "recommendations.reason.time.sunrise",
                        fallback: "Great for an early-morning sunrise hike"
                    )
                )
            }
        } else if hour >= 16 && hour < 19 {
            // Late afternoon / early evening – prioritize sunset-friendly trails
            let trailText = (trail.name + " " + trail.summary).lowercased()
            if trailText.contains("日落") || trailText.contains("西") {
                score += 0.1
                reasons.append(
                    localizedReason(
                        "recommendations.reason.time.sunset",
                        fallback: "Great for an evening sunset hike"
                    )
                )
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
        
        // If the available time is enough to comfortably complete the trail
        if availableTime >= trailDuration {
            score += 0.1
            reasons.append(
                localizedReason(
                    "recommendations.reason.time.enough",
                    fallback: "You have enough time to complete this trail"
                )
            )
        } else if availableTime >= trailDuration * 0.7 {
            // Time is a bit tight but still feasible
            score += 0.05
            reasons.append(
                localizedReason(
                    "recommendations.reason.time.tight",
                    fallback: "Time is a bit tight – consider a faster pace"
                )
            )
        } else {
            // Clearly not enough time – penalize this trail
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
        
        // Count how often the user has completed the same or very similar trails
        let similarTrails = history.filter { record in
            record.trailId == trail.id ||
            (record.trailName?.lowercased().contains(trail.name.lowercased()) ?? false)
        }
        
        if similarTrails.isEmpty {
            // Reward new, unexplored trails to encourage variety
            score += 0.1
            reasons.append(
                localizedReason(
                    "recommendations.reason.history.new.trail",
                    fallback: "You haven't tried this trail yet"
                )
            )
        } else {
            // If the user often completes similar trails successfully, reward that pattern
            let completionRate = Double(similarTrails.filter { $0.isCompleted }.count) / Double(max(similarTrails.count, 1))
            if completionRate > 0.7 {
                score += 0.15
                reasons.append(
                    localizedReason(
                        "recommendations.reason.history.often.completed",
                        fallback: "You often complete similar trails"
                    )
                )
            }
        }
        
        // Look at average distance of completed hikes to infer preferred distance zone
        let completedTrails = history.filter { $0.isCompleted }
        if !completedTrails.isEmpty {
            let avgDistance = completedTrails.map { $0.distanceKm }.reduce(0, +) / Double(completedTrails.count)
            let distanceDiff = abs(trail.lengthKm - avgDistance) / max(avgDistance, 1)
            
            if distanceDiff < 0.3 {
                score += 0.1
                reasons.append(
                    localizedReason(
                        "recommendations.reason.history.distance.similar",
                        fallback: "Distance is similar to your usual hikes"
                    )
                )
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
        
        // Check whether user has done this exact trail recently
        let recentHistory = history.filter { record in
            record.trailId == trail.id &&
            record.startTime > Date().addingTimeInterval(-30 * 24 * 60 * 60) // within last 30 days
        }
        
        if recentHistory.isEmpty {
            // Not recently done – small bonus to promote diversity
            score += 0.05
        } else {
            // Recently done – small penalty to avoid repetition
            score -= 0.1
        }
        
        return score
    }
    
    // MARK: - Helper functions
    
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


