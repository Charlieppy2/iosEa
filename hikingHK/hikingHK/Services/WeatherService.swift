//
//  WeatherService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

protocol WeatherServiceProtocol {
    func fetchSnapshot(language: String) async throws -> WeatherSnapshot
}

struct WeatherService: WeatherServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // Base endpoint - language will be appended
    private let baseEndpoint = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang="

    init(session: URLSession? = nil, decoder: JSONDecoder? = nil) {
        // 配置 URLSession 使用超时设置
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0 // 10秒超时
        configuration.timeoutIntervalForResource = 15.0 // 15秒资源超时
        configuration.waitsForConnectivity = true
        
        self.session = session ?? URLSession(configuration: configuration)
        
        // 配置 JSONDecoder 忽略未知键
        let jsonDecoder = decoder ?? JSONDecoder()
        // Swift 的 Decodable 默认会忽略未知键，但我们需要确保正确配置
        self.decoder = jsonDecoder
    }
    
    private func endpointURL(language: String) -> URL {
        // Map language codes: en -> en, zh-Hant -> tc
        let langCode = language == "zh-Hant" ? "tc" : "en"
        return URL(string: "\(baseEndpoint)\(langCode)")!
    }

    func fetchSnapshot(language: String = "en") async throws -> WeatherSnapshot {
        let endpoint = endpointURL(language: language)
        print("🌤️ WeatherService: Fetching weather from \(endpoint.absoluteString)")
        
        do {
            let (data, response) = try await session.data(from: endpoint)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ WeatherService: Invalid response type")
                throw WeatherServiceError.invalidResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                print("❌ WeatherService: HTTP \(httpResponse.statusCode)")
                throw WeatherServiceError.invalidResponse
            }
            
            print("✅ WeatherService: Received response (HTTP \(httpResponse.statusCode))")
            
            // 打印 JSON 用于调试
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 WeatherService: JSON length: \(jsonString.count) characters")
                // 打印关键部分
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📄 WeatherService: Top-level keys: \(json.keys.sorted())")
                    if let temp = json["temperature"] as? [String: Any] {
                        print("📄 WeatherService: temperature keys: \(temp.keys.sorted())")
                    }
                    if let humidity = json["humidity"] as? [String: Any] {
                        print("📄 WeatherService: humidity keys: \(humidity.keys.sorted())")
                    }
                    if let uvindex = json["uvindex"] as? [String: Any] {
                        print("📄 WeatherService: uvindex keys: \(uvindex.keys.sorted())")
                    }
                }
            }
            
            let payload = try decoder.decode(HKORealTimeWeather.self, from: data)
            
            guard let temperatureEntry = payload.temperature.data.first,
                  let temperature = temperatureEntry.value,
                  let humidityEntry = payload.humidity.data.first,
                  let humidityValue = humidityEntry.value
            else {
                print("❌ WeatherService: Missing required fields in response")
                throw WeatherServiceError.missingKeyFields
            }

            let uvIndex = payload.uvindex?.data?.compactMap { $0.value }.first ?? 0
            let warningMessage = payload.warningMessage?.filter { !$0.isEmpty }.joined(separator: "\n")
            let suggestion = WeatherSuggestionBuilder.suggestion(
                uvIndex: uvIndex,
                humidity: Int(humidityValue),
                hasWarning: warningMessage != nil
            )

            print("✅ WeatherService: Successfully parsed weather data - Temp: \(temperature)°C, Humidity: \(humidityValue)%")
            
            return WeatherSnapshot(
                location: temperatureEntry.place,
                temperature: temperature,
                humidity: Int(humidityValue),
                uvIndex: uvIndex,
                warningMessage: warningMessage,
                suggestion: suggestion,
                updatedAt: Date()
            )
        } catch let urlError as URLError {
            print("❌ WeatherService: Network error - \(urlError.localizedDescription)")
            print("   Code: \(urlError.code.rawValue)")
            print("   Description: \(urlError.localizedDescription)")
            throw WeatherServiceError.networkError(urlError)
        } catch let decodingError as DecodingError {
            print("❌ WeatherService: Decoding error - \(decodingError.localizedDescription)")
            // 打印详细的解码错误信息
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("   Type mismatch: Expected \(type), at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Debug description: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found: Expected \(type), at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Debug description: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("   Key not found: \(key.stringValue), at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Debug description: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("   Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Debug description: \(context.debugDescription)")
            @unknown default:
                print("   Unknown decoding error")
            }
            throw WeatherServiceError.decodingError(decodingError)
        } catch {
            print("❌ WeatherService: Unknown error - \(error.localizedDescription)")
            throw error
        }
    }
}

enum WeatherServiceError: Error, LocalizedError {
    case invalidResponse
    case missingKeyFields
    case networkError(URLError)
    case decodingError(DecodingError)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from weather API"
        case .missingKeyFields:
            return "Missing required fields in weather data"
        case .networkError(let urlError):
            return "Network error: \(urlError.localizedDescription)"
        case .decodingError(let decodingError):
            return "Failed to decode weather data: \(decodingError.localizedDescription)"
        }
    }
}

struct WeatherSuggestionBuilder {
    static func suggestion(uvIndex: Int, humidity: Int, hasWarning: Bool) -> String {
        if hasWarning {
            return "Weather warning in force. Re-plan or carry full rain gear."
        }
        if uvIndex >= 8 {
            return "Extreme UV. Start pre-dawn and bring SPF/umbrella."
        }
        if humidity >= 85 {
            return "Humid conditions. Hydrate frequently and rest more often."
        }
        return "Conditions look stable—great time to tackle exposed ridges."
    }
}

// MARK: - DTOs

struct HKORealTimeWeather: Decodable {
    let temperature: WeatherDataset
    let humidity: WeatherDataset
    let uvindex: UVIndexDataset?
    let warningMessage: [String]?
    
    // API 返回的其他字段，我们不需要但需要声明以避免解码错误
    // 使用 CodingKeys 来只解码我们需要的字段
    enum CodingKeys: String, CodingKey {
        case temperature
        case humidity
        case uvindex
        case warningMessage
        // 忽略其他字段：rainfall, icon, iconUpdateTime, updateTime, tcmessage 等
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        temperature = try container.decode(WeatherDataset.self, forKey: .temperature)
        humidity = try container.decode(WeatherDataset.self, forKey: .humidity)
        warningMessage = try container.decodeIfPresent([String].self, forKey: .warningMessage)
        
        // 处理 uvindex 字段：可能是字典、空字符串或 null
        if container.contains(.uvindex) {
            // 尝试解码为字典
            if let uvindexDict = try? container.decode(UVIndexDataset.self, forKey: .uvindex) {
                uvindex = uvindexDict
            } else {
                // 如果不是字典，尝试解码为字符串（可能是空字符串）
                if let uvindexString = try? container.decode(String.self, forKey: .uvindex) {
                    // 如果是空字符串或无效值，设置为 nil
                    if uvindexString.isEmpty {
                        uvindex = nil
                    } else {
                        // 如果不是空字符串，尝试解析（虽然通常应该是空字符串）
                        print("⚠️ WeatherService: uvindex is a non-empty string: \(uvindexString)")
                        uvindex = nil
                    }
                } else {
                    // 如果既不是字典也不是字符串，设置为 nil
                    uvindex = nil
                }
            }
        } else {
            uvindex = nil
        }
    }
}

struct WeatherDataset: Decodable {
    let data: [WeatherEntry]
    let recordTime: String? // temperature 和 humidity 对象都有这个字段
}

struct WeatherEntry: Decodable {
    let place: String
    let value: Double?
    let unit: String?
    // temperature.data 中的元素没有 recordTime，所以不在这里定义
}

struct UVIndexDataset: Decodable {
    let data: [UVIndexEntry]?
    let recordDesc: String? // uvindex 对象有这个字段
}

struct UVIndexEntry: Decodable {
    let place: String?
    let value: Int? // API 返回的是数字，不是字符串
    let desc: String? // API 返回的字段名是 desc，不是 recordTime
}

