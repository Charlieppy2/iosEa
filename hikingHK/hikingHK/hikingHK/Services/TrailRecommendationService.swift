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
        userHistory: [HikeRecord],
        recommendationHistory: [RecommendationRecord]?
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
    
    /// Machine learning weights for different scoring factors
    /// These weights are learned from user behavior feedback
    private struct ScoringWeights {
        var preferenceWeight: Double = 1.0      // User preference matching
        var weatherWeight: Double = 1.0         // Weather suitability
        var timeWeight: Double = 1.0            // Time of day
        var availableTimeWeight: Double = 1.0   // Available time matching
        var historyWeight: Double = 1.0         // Historical patterns
        var diversityWeight: Double = 1.0       // Diversity bonus
        
        /// Default weights (equal importance)
        static let `default` = ScoringWeights()
    }
    
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
        userHistory: [HikeRecord],
        recommendationHistory: [RecommendationRecord]? = nil
    ) -> [TrailRecommendation] {
        var recommendations: [TrailRecommendation] = []
        
        // Learn weights from user behavior (machine learning)
        let weights = learnWeightsFromHistory(recommendationHistory: recommendationHistory)
        
        for trail in trails {
            var score: Double = 0.5 // Base score
            var reasons: [String] = []
            
            // 1. Score based on explicit user hiking preferences (with learned weight)
            if let preference = userPreference {
                let preferenceScore = scoreBasedOnPreference(trail: trail, preference: preference, reasons: &reasons)
                score += preferenceScore * weights.preferenceWeight
            }
            
            // 2. Score based on current / recent weather snapshot (with learned weight)
            if let weather = weatherSnapshot {
                let weatherScore = scoreBasedOnWeather(trail: trail, weather: weather, reasons: &reasons)
                score += weatherScore * weights.weatherWeight
            }
            
            // 3. Score based on current time of day (with learned weight)
            let timeScore = scoreBasedOnTime(trail: trail, currentTime: currentTime, reasons: &reasons)
            score += timeScore * weights.timeWeight
            
            // 4. Score based on how much time the user has available (with learned weight)
            if let time = availableTime {
                let availableTimeScore = scoreBasedOnAvailableTime(trail: trail, availableTime: time, reasons: &reasons)
                score += availableTimeScore * weights.availableTimeWeight
                
                // If the trail clearly exceeds available time, significantly penalize it
                let trailDuration = TimeInterval(trail.estimatedDurationMinutes * 60)
                if trailDuration > time * 1.15 { // More than 15% over available time
                    score -= 0.5 // Heavy penalty
                }
            }
            
            // 5. Score based on past hiking history (with learned weight)
            let historyScore = scoreBasedOnHistory(trail: trail, history: userHistory, reasons: &reasons)
            score += historyScore * weights.historyWeight
            
            // 6. Score for diversity (with learned weight)
            let diversityScore = scoreBasedOnDiversity(trail: trail, history: userHistory, reasons: &reasons)
            score += diversityScore * weights.diversityWeight
            
            // Clamp score into 0–1 range
            score = min(max(score, 0), 1)
            
            // Filter out trails that clearly exceed available time
            // Allow trails up to 10% over available time to account for buffer time
            var shouldRecommend = score > 0.3
            if let time = availableTime {
                let trailDuration = TimeInterval(trail.estimatedDurationMinutes * 60)
                // Only exclude trails that are more than 10% over available time
                // This allows 1-hour trails to show when user selects 1 hour
                if trailDuration > time * 1.1 {
                    shouldRecommend = false
                }
            }
            
            if shouldRecommend {
                recommendations.append(
                    TrailRecommendation(trail: trail, score: score, reasons: reasons)
                )
            }
        }
        
        // Sort by time proximity first (if availableTime is provided), then by score
        let sortedRecommendations: [TrailRecommendation]
        
        if let availableTime = availableTime {
            // Sort by how close the trail duration is to available time
            // Trails closer to available time come first
            sortedRecommendations = recommendations.sorted { lhs, rhs in
                let lhsDuration = TimeInterval(lhs.trail.estimatedDurationMinutes * 60)
                let rhsDuration = TimeInterval(rhs.trail.estimatedDurationMinutes * 60)
                
                // Calculate time difference from available time (absolute value)
                let lhsTimeDiff = abs(lhsDuration - availableTime)
                let rhsTimeDiff = abs(rhsDuration - availableTime)
                
                // If time differences are similar (within 10%), sort by score
                if abs(lhsTimeDiff - rhsTimeDiff) < availableTime * 0.1 {
                    return lhs.score > rhs.score
                }
                
                // Otherwise, sort by time proximity (closer = better)
                return lhsTimeDiff < rhsTimeDiff
            }
        } else {
            // No available time specified, sort by score
            sortedRecommendations = recommendations.sorted { lhs, rhs in
                return lhs.score > rhs.score
            }
        }
        
        // Normalize scores to relative percentages (highest score = 100%, others relative to it)
        // This ensures we have a better distribution of match percentages instead of all showing 100%
        guard let maxScore = sortedRecommendations.first?.score, maxScore > 0 else {
            return sortedRecommendations
        }
        
        // If all scores are very close (within 5%), don't normalize to avoid all showing similar percentages
        let minScore = sortedRecommendations.last?.score ?? maxScore
        if maxScore - minScore < 0.05 {
            // Scores are too close, use original scores
            return sortedRecommendations
        }
        
        // Normalize: scale all scores so the highest becomes 1.0, others proportionally
        // This creates a relative ranking where the best match is 100% and others are relative to it
        return sortedRecommendations.map { recommendation in
            let normalizedScore = recommendation.score / maxScore
            // Clamp to ensure it's between 0 and 1
            let clampedScore = min(max(normalizedScore, 0), 1)
            
            return TrailRecommendation(
                trail: recommendation.trail,
                score: clampedScore,
                reasons: recommendation.reasons
            )
        }
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
        // Allow a small buffer (5%) to account for variations in hiking pace
        if availableTime >= trailDuration * 0.95 {
            score += 0.15 // Increased score for perfect time match
            reasons.append(
                localizedReason(
                    "recommendations.reason.time.enough",
                    fallback: "You have enough time to complete this trail"
                )
            )
        } else if availableTime >= trailDuration * 0.8 {
            // Time is slightly tight but still feasible
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
            score -= 0.2
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
    
    /// Returns the sort order for difficulty (lower number = higher priority)
    /// Easy = 0, Moderate = 1, Challenging = 2
    private func difficultyOrder(_ difficulty: Trail.Difficulty) -> Int {
        switch difficulty {
        case .easy: return 0
        case .moderate: return 1
        case .challenging: return 2
        }
    }
    
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
    
    // MARK: - Machine Learning: Weight Learning from User Behavior
    
    /// Learns scoring weights from user behavior feedback (machine learning approach)
    /// Analyzes recommendation history to determine which factors are most important to the user
    private func learnWeightsFromHistory(recommendationHistory: [RecommendationRecord]?) -> ScoringWeights {
        guard let history = recommendationHistory, !history.isEmpty else {
            // No history available, return default weights
            return ScoringWeights.default
        }
        
        // Separate accepted vs rejected recommendations
        let accepted = history.filter { record in
            record.userAction == .planned || record.userAction == .completed
        }
        let rejected = history.filter { record in
            record.userAction == .dismissed
        }
        
        // Need at least some feedback to learn from
        guard accepted.count + rejected.count >= 3 else {
            return ScoringWeights.default
        }
        
        var weights = ScoringWeights.default
        
        // Analyze which factors correlate with user acceptance
        // Extract features from recommendation reasons (split by separator)
        let acceptedReasons = accepted.flatMap { record in
            record.reason.components(separatedBy: "；").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        let rejectedReasons = rejected.flatMap { record in
            record.reason.components(separatedBy: "；").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        // Count feature occurrences
        func countFeature(_ keyword: String, in reasons: [String]) -> Int {
            reasons.filter { $0.contains(keyword) || $0.lowercased().contains(keyword.lowercased()) }.count
        }
        
        // Learn preference weight
        let preferenceKeywords = ["難度", "體能", "距離", "時間", "風景", "difficulty", "fitness", "distance", "duration", "scenery"]
        let preferenceInAccepted = preferenceKeywords.map { countFeature($0, in: acceptedReasons) }.reduce(0, +)
        let preferenceInRejected = preferenceKeywords.map { countFeature($0, in: rejectedReasons) }.reduce(0, +)
        if preferenceInAccepted + preferenceInRejected > 0 {
            let acceptanceRate = Double(preferenceInAccepted) / Double(preferenceInAccepted + preferenceInRejected)
            // If preference factors appear more in accepted recommendations, increase weight
            weights.preferenceWeight = 0.5 + (acceptanceRate * 1.0) // Range: 0.5 to 1.5
        }
        
        // Learn weather weight
        let weatherKeywords = ["氣溫", "天氣", "溫度", "temperature", "weather", "uv", "紫外線"]
        let weatherInAccepted = weatherKeywords.map { countFeature($0, in: acceptedReasons) }.reduce(0, +)
        let weatherInRejected = weatherKeywords.map { countFeature($0, in: rejectedReasons) }.reduce(0, +)
        if weatherInAccepted + weatherInRejected > 0 {
            let acceptanceRate = Double(weatherInAccepted) / Double(weatherInAccepted + weatherInRejected)
            weights.weatherWeight = 0.5 + (acceptanceRate * 1.0)
        }
        
        // Learn time weight
        let timeKeywords = ["時間", "足夠", "緊湊", "time", "enough", "tight", "sunrise", "sunset", "日出", "日落"]
        let timeInAccepted = timeKeywords.map { countFeature($0, in: acceptedReasons) }.reduce(0, +)
        let timeInRejected = timeKeywords.map { countFeature($0, in: rejectedReasons) }.reduce(0, +)
        if timeInAccepted + timeInRejected > 0 {
            let acceptanceRate = Double(timeInAccepted) / Double(timeInAccepted + timeInRejected)
            weights.timeWeight = 0.5 + (acceptanceRate * 1.0)
            weights.availableTimeWeight = 0.5 + (acceptanceRate * 1.0)
        }
        
        // Learn history weight
        let historyKeywords = ["未試過", "經常", "相似", "haven't", "often", "similar", "history"]
        let historyInAccepted = historyKeywords.map { countFeature($0, in: acceptedReasons) }.reduce(0, +)
        let historyInRejected = historyKeywords.map { countFeature($0, in: rejectedReasons) }.reduce(0, +)
        if historyInAccepted + historyInRejected > 0 {
            let acceptanceRate = Double(historyInAccepted) / Double(historyInAccepted + historyInRejected)
            weights.historyWeight = 0.5 + (acceptanceRate * 1.0)
        }
        
        // Diversity weight: if user often accepts new trails, increase diversity weight
        let newTrailCount = accepted.filter { $0.reason.contains("未試過") || $0.reason.contains("haven't") }.count
        if accepted.count > 0 {
            let newTrailRate = Double(newTrailCount) / Double(accepted.count)
            weights.diversityWeight = 0.5 + (newTrailRate * 1.0)
        }
        
        // Normalize weights to prevent extreme values
        let maxWeight = max(weights.preferenceWeight, weights.weatherWeight, weights.timeWeight, 
                           weights.availableTimeWeight, weights.historyWeight, weights.diversityWeight)
        if maxWeight > 2.0 {
            let scale = 2.0 / maxWeight
            weights.preferenceWeight *= scale
            weights.weatherWeight *= scale
            weights.timeWeight *= scale
            weights.availableTimeWeight *= scale
            weights.historyWeight *= scale
            weights.diversityWeight *= scale
        }
        
        return weights
    }
}


