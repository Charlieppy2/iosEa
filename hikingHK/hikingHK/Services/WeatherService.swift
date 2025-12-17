//
//  WeatherService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

/// Abstraction for fetching a lightweight real-time weather snapshot for the app.
protocol WeatherServiceProtocol {
    func fetchSnapshot(language: String) async throws -> WeatherSnapshot
}

struct WeatherService: WeatherServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let warningService: WeatherWarningServiceProtocol
    
    // Base endpoint - language will be appended
    private let baseEndpoint = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang="

    init(session: URLSession? = nil, decoder: JSONDecoder? = nil, warningService: WeatherWarningServiceProtocol? = nil) {
        // Configure URLSession with reasonable timeouts for mobile networks
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0 // 10 seconds request timeout
        configuration.timeoutIntervalForResource = 15.0 // 15 seconds resource timeout
        configuration.waitsForConnectivity = true
        
        self.session = session ?? URLSession(configuration: configuration)
        
        // Configure JSONDecoder – by default Decodable ignores unknown keys,
        // but we keep a dedicated instance for clarity and future customization.
        let jsonDecoder = decoder ?? JSONDecoder()
        self.decoder = jsonDecoder
        self.warningService = warningService ?? WeatherWarningService()
    }
    
    private func endpointURL(language: String) -> URL {
        // Map language codes: en -> en, zh-Hant -> tc
        let langCode = language == "zh-Hant" ? "tc" : "en"
        return URL(string: "\(baseEndpoint)\(langCode)")!
    }

    /// Fetches and builds a `WeatherSnapshot` from HKO real-time weather
    /// plus warning summaries, with defensive decoding and logging.
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
            
            // Print JSON shape for debugging when needed
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
            
            // Prefer values from "Hong Kong Observatory" when available, otherwise fall back to the first entry.
            let temperatureEntry = payload.temperature.data.first { $0.place == "Hong Kong Observatory" } ?? payload.temperature.data.first
            let humidityEntry = payload.humidity.data.first { $0.place == "Hong Kong Observatory" } ?? payload.humidity.data.first
            
            guard let temperatureEntry = temperatureEntry,
                  let temperature = temperatureEntry.value,
                  let humidityEntry = humidityEntry,
                  let humidityValue = humidityEntry.value
            else {
                print("❌ WeatherService: Missing required fields in response")
                throw WeatherServiceError.missingKeyFields
            }

            let uvIndex = payload.uvindex?.data?.compactMap { $0.value }.first ?? 0
            
            // Build warning messages from both real‑time API and warning summary API
            var warningMessages: [String] = []
            
            // Step 1: warnings from real‑time rhrread API
            if let messages = payload.warningMessage, !messages.isEmpty {
                print("📋 WeatherService: Found \(messages.count) warning message(s) from rhrread: \(messages)")
                // Prefix each message with a warning symbol
                warningMessages.append(contentsOf: messages.filter { !$0.isEmpty }.map { "⚠️ \($0)" })
            }
            
            // Step 2: warnings from warnsum API
            do {
                let warnings = try await warningService.fetchWarnings(language: language)
                let activeWarnings = warnings.filter { $0.isActive }
                if !activeWarnings.isEmpty {
                    print("📋 WeatherService: Found \(activeWarnings.count) active warning(s) from warnsum")
                    for warning in activeWarnings {
                        let warningText = "⚠️ \(warning.name) (\(warning.code))"
                        // Avoid duplicates (compare without relying on the leading symbol)
                        let exists = warningMessages.contains { $0.contains(warning.name) && $0.contains(warning.code) }
                        if !exists {
                            warningMessages.append(warningText)
                        }
                    }
                }
            } catch {
                print("⚠️ WeatherService: Failed to fetch warnings from warnsum API: \(error)")
            }
            
            // Merge all warning messages into a single string, ensuring each line has the symbol.
            let warningMessage: String? = {
                guard !warningMessages.isEmpty else {
                    print("📋 WeatherService: No warning messages found")
                    return nil
                }
                // Ensure each message is prefixed with ⚠️ exactly once.
                let messagesWithSymbol = warningMessages.map { message in
                    message.contains("⚠️") ? message : "⚠️ \(message)"
                }
                let joined = messagesWithSymbol.joined(separator: "\n")
                print("📋 WeatherService: Final warning message with symbols: \(joined)")
                return joined
            }()
            
            let suggestion = WeatherSuggestionBuilder.suggestion(
                uvIndex: uvIndex,
                humidity: Int(humidityValue),
                hasWarning: warningMessage != nil && !warningMessage!.isEmpty
            )

            print("✅ WeatherService: Successfully parsed weather data - Temp: \(temperature)°C, Humidity: \(humidityValue)%, Location: \(temperatureEntry.place), Warning: \(warningMessage ?? "none")")
            
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
    
    // The API returns many other fields we do not need, but we declare
    // only the keys we care about via CodingKeys to avoid decoding issues.
    enum CodingKeys: String, CodingKey {
        case temperature
        case humidity
        case uvindex
        case warningMessage
        // Other fields from the API (rainfall, icon, iconUpdateTime, updateTime, tcmessage, etc.) are intentionally ignored.
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        temperature = try container.decode(WeatherDataset.self, forKey: .temperature)
        humidity = try container.decode(WeatherDataset.self, forKey: .humidity)
        
        // Handle `warningMessage` which may be a string, an array of strings, or null.
        if container.contains(.warningMessage) {
            // First, try to decode as an array of strings.
            if let warningArray = try? container.decode([String].self, forKey: .warningMessage) {
                print("📋 WeatherService: warningMessage decoded as array: \(warningArray)")
                warningMessage = warningArray
            } else if let warningString = try? container.decode(String.self, forKey: .warningMessage) {
                // If it is a single string, convert to an array (empty string becomes empty array).
                print("📋 WeatherService: warningMessage decoded as string: '\(warningString)'")
                if warningString.isEmpty {
                    warningMessage = []
                } else {
                    warningMessage = [warningString]
                }
            } else {
                // If it is neither array nor string, treat as empty.
                print("📋 WeatherService: warningMessage could not be decoded as array or string")
                warningMessage = []
            }
        } else {
            print("📋 WeatherService: warningMessage key not found in response")
            warningMessage = []
        }
        
        // Handle `uvindex` which may be a dictionary, empty string, or null.
        if container.contains(.uvindex) {
            // Try to decode as the expected dictionary model first.
            if let uvindexDict = try? container.decode(UVIndexDataset.self, forKey: .uvindex) {
                uvindex = uvindexDict
            } else {
                // If it is not a dictionary, try decoding as a string (often an empty string).
                if let uvindexString = try? container.decode(String.self, forKey: .uvindex) {
                    // Empty or invalid strings are treated as `nil`.
                    if uvindexString.isEmpty {
                        uvindex = nil
                    } else {
                        // If non-empty, log and ignore – API should usually send an empty string here.
                        print("⚠️ WeatherService: uvindex is a non-empty string: \(uvindexString)")
                        uvindex = nil
                    }
                } else {
                    // If it is neither dictionary nor string, treat as nil.
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
    let recordTime: String? // Both temperature and humidity objects include this field.
}

struct WeatherEntry: Decodable {
    let place: String
    let value: Double?
    let unit: String?
    // Elements inside temperature.data do not expose recordTime, so it is not defined here.
}

struct UVIndexDataset: Decodable {
    let data: [UVIndexEntry]?
    let recordDesc: String? // uvindex object provides this description field.
}

struct UVIndexEntry: Decodable {
    let place: String?
    let value: Int? // API returns this as a number, not a string.
    let desc: String? // API uses `desc` here instead of something like `recordTime`.
}

