//
//  WeatherForecastService.swift
//  hikingHK
//
//  Created for weather forecast functionality
//

import Foundation

/// Abstraction for fetching a multi-day weather forecast used in the planner and journal.
protocol WeatherForecastServiceProtocol {
    /// Returns a multi-day forecast for a specific hiking trail.
    func fetchForecast(for trail: Trail) async throws -> WeatherForecast
}

/// Simple mock-backed implementation of the forecast service.
/// In production this should call the real HKO 9-day forecast API.
struct WeatherForecastService: WeatherForecastServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // Using HKO 9-day weather forecast API endpoint (currently unused in mock mode).
    // Note: This is a simulated implementation. In production, this would call and decode the real HKO API.
    private let endpoint = URL(string: "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=fnd&lang=en")!
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    /// Returns a weather forecast; currently generated from mock data
    /// to keep the UI functional without depending on the live API.
    /// Each trail gets its OWN forecast by using the trail's ID to vary the baseline.
    func fetchForecast(for trail: Trail) async throws -> WeatherForecast {
        return generateMockForecast(for: trail)
    }
    
    private func generateMockForecast(for trail: Trail) -> WeatherForecast {
        let calendar = Calendar.current
        let now = Date()
        var dailyForecasts: [DailyForecast] = []
        
        // Derive a stable offset from the trail ID so that each trail feels different
        let hash = trail.id.uuidString.hashValue
        let tempOffset = Double((hash % 6) - 3)          // -3 ... +2
        let humidityOffset = Int((hash % 11) - 5)        // -5 ... +5
        let windOffset = Double((hash % 9) - 4)          // -4 ... +4
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            // Generate baseline weather; vary by trail-specific offsets
            let baseTemp = 22.0 + tempOffset + Double.random(in: -3...5)
            let highTemp = baseTemp + Double.random(in: 3...7)
            let lowTemp = baseTemp - Double.random(in: 2...5)
            let humidity = max(40, min(95, Int.random(in: 60...85) + humidityOffset))
            let uvIndex = dayOffset < 2 ? Int.random(in: 5...8) : Int.random(in: 3...7)
            let windSpeed = max(2, Double.random(in: 10...25) + windOffset)
            let precipitationChance = Int.random(in: 0...40)
            
            // Determine condition based on precipitation chance
            let condition: WeatherCondition = {
                if precipitationChance > 60 {
                    return .heavyRain
                } else if precipitationChance > 40 {
                    return .moderateRain
                } else if precipitationChance > 20 {
                    return .lightRain
                } else if uvIndex > 7 {
                    return .sunny
                } else if uvIndex > 5 {
                    return .partlyCloudy
                } else {
                    return .cloudy
                }
            }()
            
            // Generate hourly forecasts (every 3 hours from 6 AM to 9 PM)
            var hourlyForecasts: [HourlyForecast] = []
            for hour in stride(from: 6, through: 21, by: 3) {
                guard let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) else { continue }
                
                let hourTemp = lowTemp + (highTemp - lowTemp) * Double(hour - 6) / 15.0
                let hourUV = hour >= 9 && hour <= 15 ? uvIndex : max(0, uvIndex - 2)
                let hourPrecip = hour >= 12 && hour <= 18 ? precipitationChance : max(0, precipitationChance - 10)
                
                hourlyForecasts.append(HourlyForecast(
                    time: hourDate,
                    temperature: hourTemp,
                    humidity: humidity + Int.random(in: -5...5),
                    uvIndex: hourUV,
                    windSpeed: windSpeed + Double.random(in: -5...5),
                    precipitationChance: hourPrecip,
                    condition: condition
                ))
            }
            
            dailyForecasts.append(DailyForecast(
                date: date,
                highTemperature: highTemp,
                lowTemperature: lowTemp,
                humidity: humidity,
                uvIndex: uvIndex,
                windSpeed: windSpeed,
                precipitationChance: precipitationChance,
                condition: condition,
                hourlyForecasts: hourlyForecasts
            ))
        }
        
        // We keep using WeatherRegion for now by mapping rough area based on district;
        // this is mainly for future UI labeling and is not critical for the mock data itself.
        let roughRegion: WeatherRegion = {
            let district = trail.district.lowercased()
            if district.contains("kowloon") {
                return .kowloon
            } else if district.contains("lantau") {
                return .lantau
            } else if district.contains("new territories") || district.contains("tai po") || district.contains("tsuen wan") || district.contains("sha tin") {
                return .newTerritories
            } else {
                return .hongKongIsland
            }
        }()
        
        return WeatherForecast(
            region: roughRegion,
            dailyForecasts: dailyForecasts,
            updatedAt: now
        )
    }
}

enum WeatherForecastServiceError: Error {
    case invalidResponse
    case missingKeyFields
    case networkError
}

