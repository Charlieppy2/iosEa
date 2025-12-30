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

/// Implementation that fetches 9-day weather forecast from HKO API.
struct WeatherForecastService: WeatherForecastServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private let baseEndpoint = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=fnd&lang="
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    private func endpointURL(language: String) -> URL {
        // Map language codes: en -> en, zh-Hant -> tc, zh-Hans -> sc
        let langCode: String
        if language == "zh-Hant" {
            langCode = "tc"
        } else if language == "zh-Hans" {
            langCode = "sc"
        } else {
            langCode = "en"
        }
        return URL(string: "\(baseEndpoint)\(langCode)")!
    }
    
    /// Fetches 9-day weather forecast from HKO API.
    func fetchForecast(for trail: Trail) async throws -> WeatherForecast {
        // Use app's current language preference
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let endpoint = endpointURL(language: savedLanguage)
        
        print("🌤️ WeatherForecastService: Fetching 9-day forecast from \(endpoint.absoluteString)")
        
        do {
            let (data, response) = try await session.data(from: endpoint)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ WeatherForecastService: Invalid response type")
                throw WeatherForecastServiceError.invalidResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                print("❌ WeatherForecastService: HTTP \(httpResponse.statusCode)")
                throw WeatherForecastServiceError.invalidResponse
            }
            
            print("✅ WeatherForecastService: Received response (HTTP \(httpResponse.statusCode))")
            
            let payload = try decoder.decode(HKO9DayForecast.self, from: data)
            return try convertToWeatherForecast(payload, for: trail)
        } catch let urlError as URLError {
            print("❌ WeatherForecastService: Network error - \(urlError.localizedDescription)")
            throw WeatherForecastServiceError.networkError
        } catch let decodingError as DecodingError {
            print("❌ WeatherForecastService: Decoding error - \(decodingError.localizedDescription)")
            throw WeatherForecastServiceError.decodingError
        } catch {
            print("❌ WeatherForecastService: Unknown error - \(error.localizedDescription)")
            // Fallback to mock data if API fails
            print("⚠️ WeatherForecastService: Falling back to mock data")
        return generateMockForecast(for: trail)
        }
    }
    
    /// Converts HKO API response to app's WeatherForecast model.
    private func convertToWeatherForecast(_ payload: HKO9DayForecast, for trail: Trail) throws -> WeatherForecast {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Hong_Kong")
        
        var dailyForecasts: [DailyForecast] = []
        
        for forecastData in payload.weatherForecast {
            guard let date = dateFormatter.date(from: forecastData.forecastDate) else {
                print("⚠️ WeatherForecastService: Failed to parse date: \(forecastData.forecastDate)")
                continue
            }
            
            let highTemp = Double(forecastData.forecastMaxtemp.value)
            let lowTemp = Double(forecastData.forecastMintemp.value)
            let maxHumidity = forecastData.forecastMaxrh.value
            let minHumidity = forecastData.forecastMinrh.value
            let avgHumidity = (maxHumidity + minHumidity) / 2
            
            // Map ForecastIcon to WeatherCondition
            let condition = mapForecastIconToCondition(forecastData.ForecastIcon)
            
            // Estimate UV index from weather description (simplified)
            let uvIndex = estimateUVIndex(from: forecastData.forecastWeather, icon: forecastData.ForecastIcon)
            
            // Estimate precipitation chance from PSR and weather description
            let precipitationChance = estimatePrecipitationChance(psr: forecastData.PSR, weather: forecastData.forecastWeather)
            
            // Estimate wind speed from forecastWind string
            let windSpeed = estimateWindSpeed(from: forecastData.forecastWind)
            
            // Generate hourly forecasts (every 3 hours from 6 AM to 9 PM)
            var hourlyForecasts: [HourlyForecast] = []
            for hour in stride(from: 6, through: 21, by: 3) {
                guard let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) else { continue }
                
                // Interpolate temperature throughout the day
                let hourTemp = lowTemp + (highTemp - lowTemp) * Double(hour - 6) / 15.0
                let hourUV = hour >= 9 && hour <= 15 ? uvIndex : max(0, uvIndex - 2)
                let hourPrecip = hour >= 12 && hour <= 18 ? precipitationChance : max(0, precipitationChance - 10)
                
                hourlyForecasts.append(HourlyForecast(
                    time: hourDate,
                    temperature: hourTemp,
                    humidity: avgHumidity + Int.random(in: -5...5), // Add small variation
                    uvIndex: hourUV,
                    windSpeed: windSpeed + Double.random(in: -2...2),
                    precipitationChance: hourPrecip,
                    condition: condition
                ))
            }
            
            dailyForecasts.append(DailyForecast(
                date: date,
                highTemperature: highTemp,
                lowTemperature: lowTemp,
                humidity: avgHumidity,
                uvIndex: uvIndex,
                windSpeed: windSpeed,
                precipitationChance: precipitationChance,
                condition: condition,
                hourlyForecasts: hourlyForecasts
            ))
        }
        
        // Determine region based on trail district
        let region: WeatherRegion = {
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
        
        let updateTime = parseUpdateTime(payload.updateTime) ?? Date()
        
        return WeatherForecast(
            region: region,
            dailyForecasts: dailyForecasts,
            updatedAt: updateTime
        )
    }
    
    private func mapForecastIconToCondition(_ icon: Int) -> WeatherCondition {
        // Map HKO ForecastIcon codes to WeatherCondition
        // Common codes: 50=sunny, 51=partly cloudy, 52=cloudy, 60-67=rain, 70-77=thunderstorm, 80-82=windy, 90-99=cold
        switch icon {
        case 50, 51:
            return .sunny
        case 52, 53:
            return .partlyCloudy
        case 60...67:
            return .moderateRain
        case 70...77:
            return .heavyRain
        case 80...82:
            return .windy
        case 90...99:
            return .cloudy
        default:
            return .partlyCloudy
        }
    }
    
    private func estimateUVIndex(from weather: String, icon: Int) -> Int {
        let weatherLower = weather.lowercased()
        if weatherLower.contains("sunny") || weatherLower.contains("fine") || icon == 50 {
            return Int.random(in: 6...9)
        } else if weatherLower.contains("cloudy") || icon == 52 {
            return Int.random(in: 3...6)
        } else {
            return Int.random(in: 2...5)
        }
    }
    
    private func estimatePrecipitationChance(psr: String, weather: String) -> Int {
        let weatherLower = weather.lowercased()
        if weatherLower.contains("rain") || weatherLower.contains("shower") {
            return Int.random(in: 60...90)
        } else if psr.lowercased() == "high" {
            return Int.random(in: 40...60)
        } else {
            return Int.random(in: 0...30)
        }
    }
    
    private func estimateWindSpeed(from windString: String) -> Double {
        // Extract wind force from string like "Northeast force 4 to 5"
        let windLower = windString.lowercased()
        if windLower.contains("force 7") || windLower.contains("force 8") {
            return Double.random(in: 30...40)
        } else if windLower.contains("force 6") {
            return Double.random(in: 25...30)
        } else if windLower.contains("force 5") {
            return Double.random(in: 18...25)
        } else if windLower.contains("force 4") {
            return Double.random(in: 12...18)
        } else if windLower.contains("force 3") {
            return Double.random(in: 8...12)
        } else {
            return Double.random(in: 5...10)
        }
    }
    
    private func parseUpdateTime(_ timeString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timeString) ?? ISO8601DateFormatter().date(from: timeString)
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
    case decodingError
}

// MARK: - HKO 9-Day Forecast API Models

struct HKO9DayForecast: Decodable {
    let generalSituation: String
    let weatherForecast: [HKOForecastDay]
    let updateTime: String
    let seaTemp: HKOSeaTemp?
    let soilTemp: [HKOSoilTemp]?
}

struct HKOForecastDay: Decodable {
    let forecastDate: String
    let week: String
    let forecastWind: String
    let forecastWeather: String
    let forecastMaxtemp: HKOTemperature
    let forecastMintemp: HKOTemperature
    let forecastMaxrh: HKOHumidity
    let forecastMinrh: HKOHumidity
    let ForecastIcon: Int
    let PSR: String
}

struct HKOTemperature: Decodable {
    let value: Int
    let unit: String
}

struct HKOHumidity: Decodable {
    let value: Int
    let unit: String
}

struct HKOSeaTemp: Decodable {
    let place: String
    let value: Int
    let unit: String
    let recordTime: String
}

struct HKOSoilTemp: Decodable {
    let place: String
    let value: Double
    let unit: String
    let recordTime: String
    let depth: HKODepth
}

struct HKODepth: Decodable {
    let unit: String
    let value: Double
}

