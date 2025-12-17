//
//  WeatherForecastService.swift
//  hikingHK
//
//  Created for weather forecast functionality
//

import Foundation

/// Abstraction for fetching a multi-day weather forecast used in the planner and journal.
protocol WeatherForecastServiceProtocol {
    func fetchForecast() async throws -> WeatherForecast
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
    func fetchForecast() async throws -> WeatherForecast {
        return generateMockForecast()
    }
    
    private func generateMockForecast() -> WeatherForecast {
        let calendar = Calendar.current
        let now = Date()
        var dailyForecasts: [DailyForecast] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            // Generate realistic weather data for Hong Kong
            let baseTemp = 22.0 + Double.random(in: -3...5)
            let highTemp = baseTemp + Double.random(in: 3...7)
            let lowTemp = baseTemp - Double.random(in: 2...5)
            let humidity = Int.random(in: 60...85)
            let uvIndex = dayOffset < 2 ? Int.random(in: 5...8) : Int.random(in: 3...7)
            let windSpeed = Double.random(in: 10...25)
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
        
        return WeatherForecast(
            location: "Hong Kong",
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

