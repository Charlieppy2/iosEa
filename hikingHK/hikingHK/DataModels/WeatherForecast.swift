//
//  WeatherForecast.swift
//  hikingHK
//
//  Created for weather forecast functionality
//

import Foundation

/// High-level daily and hourly weather forecast used by the Hiking HK UI.
struct WeatherForecast {
    let location: String
    let dailyForecasts: [DailyForecast]
    let updatedAt: Date
    
    var bestHikingDays: [BestHikingTime] {
        BestHikingTimeRecommender.recommendBestTimes(from: dailyForecasts)
    }
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let highTemperature: Double
    let lowTemperature: Double
    let humidity: Int
    let uvIndex: Int
    let windSpeed: Double // km/h
    let precipitationChance: Int // 0-100
    let condition: WeatherCondition
    let hourlyForecasts: [HourlyForecast]
    
    var comfortIndex: Double {
        ComfortIndexCalculator.calculate(
            temperature: (highTemperature + lowTemperature) / 2,
            humidity: humidity,
            uvIndex: uvIndex,
            windSpeed: windSpeed,
            precipitationChance: precipitationChance
        )
    }
    
    var isGoodForHiking: Bool {
        comfortIndex >= 70 && precipitationChance < 30 && uvIndex < 10
    }
}

struct HourlyForecast: Identifiable {
    let id = UUID()
    let time: Date
    let temperature: Double
    let humidity: Int
    let uvIndex: Int
    let windSpeed: Double
    let precipitationChance: Int
    let condition: WeatherCondition
    
    var comfortIndex: Double {
        ComfortIndexCalculator.calculate(
            temperature: temperature,
            humidity: humidity,
            uvIndex: uvIndex,
            windSpeed: windSpeed,
            precipitationChance: precipitationChance
        )
    }
}

enum WeatherCondition: String, Codable {
    case sunny = "Sunny"
    case partlyCloudy = "Partly Cloudy"
    case cloudy = "Cloudy"
    case overcast = "Overcast"
    case lightRain = "Light Rain"
    case moderateRain = "Moderate Rain"
    case heavyRain = "Heavy Rain"
    case thunderstorm = "Thunderstorm"
    case foggy = "Foggy"
    case windy = "Windy"
    
    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .overcast: return "cloud.fill"
        case .lightRain: return "cloud.drizzle.fill"
        case .moderateRain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
        }
    }
    
    func localizedName(languageManager: LanguageManager) -> String {
        let key = "weather.condition.\(rawValue.lowercased().replacingOccurrences(of: " ", with: "."))"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : rawValue
    }
}

struct BestHikingTime: Identifiable {
    let id = UUID()
    let date: Date
    let timeSlot: TimeSlot
    let comfortIndex: Double
    let reason: String
    
    enum TimeSlot: String {
        case earlyMorning = "Early Morning" // 6-9
        case morning = "Morning" // 9-12
        case afternoon = "Afternoon" // 12-15
        case lateAfternoon = "Late Afternoon" // 15-18
        case evening = "Evening" // 18-21
        
        var displayTime: String {
            switch self {
            case .earlyMorning: return "6:00 - 9:00"
            case .morning: return "9:00 - 12:00"
            case .afternoon: return "12:00 - 15:00"
            case .lateAfternoon: return "15:00 - 18:00"
            case .evening: return "18:00 - 21:00"
            }
        }
        
        func localizedDisplayTime(languageManager: LanguageManager) -> String {
            // Time range text itself does not need localization, but labels could be localized if needed.
            return displayTime
        }
    }
}

// MARK: - Comfort Index Calculator

struct ComfortIndexCalculator {
    /// Calculate comfort index (0-100) based on weather conditions
    /// Higher score = better conditions for hiking
    static func calculate(
        temperature: Double,
        humidity: Int,
        uvIndex: Int,
        windSpeed: Double,
        precipitationChance: Int
    ) -> Double {
        var score: Double = 100.0
        
        // Temperature scoring (optimal: 18-25°C)
        if temperature < 10 {
            score -= (10 - temperature) * 3 // Too cold
        } else if temperature > 30 {
            score -= (temperature - 30) * 2 // Too hot
        } else if temperature >= 18 && temperature <= 25 {
            // Perfect range
        } else if temperature < 18 {
            score -= (18 - temperature) * 1.5
        } else {
            score -= (temperature - 25) * 1.5
        }
        
        // Humidity scoring (optimal: 40-70%)
        if humidity < 40 {
            score -= (40 - Double(humidity)) * 0.3
        } else if humidity > 80 {
            score -= (Double(humidity) - 80) * 1.5
        }
        
        // UV Index scoring (optimal: 0-6)
        if uvIndex > 6 {
            score -= Double(uvIndex - 6) * 3
        }
        
        // Wind speed scoring (optimal: 5-20 km/h)
        if windSpeed < 5 {
            score -= 2 // Too calm, might be stuffy
        } else if windSpeed > 30 {
            score -= (windSpeed - 30) * 0.5 // Too windy
        }
        
        // Precipitation scoring
        score -= Double(precipitationChance) * 0.5
        
        return max(0, min(100, score))
    }
}

// MARK: - Best Hiking Time Recommender

struct BestHikingTimeRecommender {
    static func recommendBestTimes(from forecasts: [DailyForecast]) -> [BestHikingTime] {
        var recommendations: [BestHikingTime] = []
        
        for forecast in forecasts {
            // Check each time slot in the day
            let calendar = Calendar.current
            let dayStart = calendar.startOfDay(for: forecast.date)
            
            // Early Morning (6-9)
            if let earlyMorning = findBestHourlyForecast(
                in: forecast.hourlyForecasts,
                timeRange: 6...9,
                dayStart: dayStart
            ) {
                recommendations.append(BestHikingTime(
                    date: forecast.date,
                    timeSlot: .earlyMorning,
                    comfortIndex: earlyMorning.comfortIndex,
                    reason: reasonForTimeSlot(forecast: earlyMorning, slot: .earlyMorning)
                ))
            }
            
            // Morning (9-12)
            if let morning = findBestHourlyForecast(
                in: forecast.hourlyForecasts,
                timeRange: 9...12,
                dayStart: dayStart
            ) {
                recommendations.append(BestHikingTime(
                    date: forecast.date,
                    timeSlot: .morning,
                    comfortIndex: morning.comfortIndex,
                    reason: reasonForTimeSlot(forecast: morning, slot: .morning)
                ))
            }
            
            // Afternoon (12-15)
            if let afternoon = findBestHourlyForecast(
                in: forecast.hourlyForecasts,
                timeRange: 12...15,
                dayStart: dayStart
            ) {
                recommendations.append(BestHikingTime(
                    date: forecast.date,
                    timeSlot: .afternoon,
                    comfortIndex: afternoon.comfortIndex,
                    reason: reasonForTimeSlot(forecast: afternoon, slot: .afternoon)
                ))
            }
            
            // Late Afternoon (15-18)
            if let lateAfternoon = findBestHourlyForecast(
                in: forecast.hourlyForecasts,
                timeRange: 15...18,
                dayStart: dayStart
            ) {
                recommendations.append(BestHikingTime(
                    date: forecast.date,
                    timeSlot: .lateAfternoon,
                    comfortIndex: lateAfternoon.comfortIndex,
                    reason: reasonForTimeSlot(forecast: lateAfternoon, slot: .lateAfternoon)
                ))
            }
        }
        
        // Sort by comfort index (highest first) and take top 5
        return Array(recommendations.sorted { $0.comfortIndex > $1.comfortIndex }.prefix(5))
    }
    
    private static func findBestHourlyForecast(
        in forecasts: [HourlyForecast],
        timeRange: ClosedRange<Int>,
        dayStart: Date
    ) -> HourlyForecast? {
        let calendar = Calendar.current
        let relevantForecasts = forecasts.filter { forecast in
            let hour = calendar.component(.hour, from: forecast.time)
            return timeRange.contains(hour)
        }
        
        return relevantForecasts.max { $0.comfortIndex < $1.comfortIndex }
    }
    
    private static func reasonForTimeSlot(forecast: HourlyForecast, slot: BestHikingTime.TimeSlot) -> String {
        var reasons: [String] = []
        
        if forecast.comfortIndex >= 80 {
            reasons.append("Excellent conditions")
        } else if forecast.comfortIndex >= 70 {
            reasons.append("Good conditions")
        }
        
        if forecast.uvIndex < 6 {
            reasons.append("Low UV")
        }
        
        if forecast.precipitationChance < 20 {
            reasons.append("Low rain chance")
        }
        
        if forecast.temperature >= 18 && forecast.temperature <= 25 {
            reasons.append("Comfortable temperature")
        }
        
        if forecast.humidity < 70 {
            reasons.append("Low humidity")
        }
        
        return reasons.isEmpty ? "Moderate conditions" : reasons.joined(separator: ", ")
    }
}

