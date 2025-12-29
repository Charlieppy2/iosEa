//
//  WeatherService.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation

/// Abstraction for fetching a lightweight real-time weather snapshot for the app.
protocol WeatherServiceProtocol {
    func fetchSnapshot(language: String) async throws -> WeatherSnapshot
    func fetchSnapshotsForAllLocations(language: String) async throws -> [WeatherSnapshot]
}

struct WeatherService: WeatherServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let warningService: WeatherWarningServiceProtocol
    
    // Base endpoint - language will be appended
    private let baseEndpoint = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang="
    // UV Index API endpoint
    private let uvIndexEndpoint = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=uvindex&lang="

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
    
    private func uvIndexEndpointURL(language: String) -> URL {
        // Map language codes: en -> en, zh-Hant -> tc
        let langCode = language == "zh-Hant" ? "tc" : "en"
        return URL(string: "\(uvIndexEndpoint)\(langCode)")!
    }
    
    /// 檢查當前時間是否在 UV 測量時間範圍內（早上 7 點到下午 6 點）
    private func isWithinUVMeasurementHours() -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        return hour >= 7 && hour < 18
    }
    
    /// 從專門的 UV Index API 獲取紫外線指數
    /// 注意：UV 指數通常在早上 7 點到下午 6 點之間才有數據，其他時間可能返回 0 或空
    private func fetchUVIndexFromDedicatedAPI(language: String) async -> Int {
        let isDaytime = isWithinUVMeasurementHours()
        
        if !isDaytime {
            print("ℹ️ WeatherService: Current time is outside UV measurement hours (7:00-18:00), UV index is expected to be 0")
        }
        
        let endpoint = uvIndexEndpointURL(language: language)
        print("🌤️ WeatherService: Fetching UV index from dedicated API: \(endpoint.absoluteString)")
        
        do {
            let (data, response) = try await session.data(from: endpoint)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ WeatherService: UV API invalid response type")
                return 0
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                print("❌ WeatherService: UV API HTTP error: \(httpResponse.statusCode)")
                // 檢查是否是 HTML 響應（表示 API 需要參數）
                if let responseString = String(data: data, encoding: .utf8),
                   responseString.contains("Please include valid parameters") {
                    print("⚠️ WeatherService: UV API requires additional parameters, using rhrread data only")
                }
                return 0
            }
            
            // 檢查響應是否為 HTML（表示 API 格式錯誤）
            if let responseString = String(data: data, encoding: .utf8),
               responseString.contains("<!DOCTYPE") || responseString.contains("<html") {
                print("⚠️ WeatherService: UV API returned HTML instead of JSON, API may require different parameters")
                return 0
            }
            
            // 嘗試解析 UV API 響應
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📊 WeatherService: UV API response keys: \(json.keys.sorted())")
                
                // 嘗試解析為與 rhrread 類似的結構
                if let uvindexDict = json["uvindex"] as? [String: Any],
                   let dataArray = uvindexDict["data"] as? [[String: Any]] {
                    for entry in dataArray {
                        if let value = entry["value"] as? Int {
                            print("✅ WeatherService: Found UV index from dedicated API: \(value)")
                            return value
                        } else if let valueString = entry["value"] as? String,
                                  let value = Int(valueString) {
                            print("✅ WeatherService: Found UV index from dedicated API (string): \(value)")
                            return value
                        }
                    }
                }
                
                // 嘗試其他可能的結構：{"data": [{"place": "...", "value": 5, ...}], ...}
                if let dataArray = json["data"] as? [[String: Any]] {
                    for entry in dataArray {
                        if let value = entry["value"] as? Int {
                            print("✅ WeatherService: Found UV index from dedicated API: \(value)")
                            return value
                        } else if let valueString = entry["value"] as? String,
                                  let value = Int(valueString) {
                            print("✅ WeatherService: Found UV index from dedicated API (string): \(value)")
                            return value
                        }
                    }
                }
                
                // 嘗試直接值
                if let value = json["value"] as? Int {
                    print("✅ WeatherService: Found UV index from dedicated API (direct): \(value)")
                    return value
                }
            }
            
            print("⚠️ WeatherService: Could not parse UV index from dedicated API")
            if !isDaytime {
                print("ℹ️ WeatherService: This is expected outside UV measurement hours (7:00-18:00)")
            }
            return 0
        } catch {
            print("❌ WeatherService: Failed to fetch UV index from dedicated API: \(error)")
            if !isDaytime {
                print("ℹ️ WeatherService: UV index unavailable outside measurement hours (7:00-18:00) is normal")
            }
            return 0
        }
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

            // 調試 UV 指數數據
            if let uvData = payload.uvindex {
                print("📊 WeatherService: UV index data found - recordDesc: \(uvData.recordDesc ?? "nil")")
                if let uvEntries = uvData.data, !uvEntries.isEmpty {
                    print("📊 WeatherService: UV index entries count: \(uvEntries.count)")
                    for (index, entry) in uvEntries.enumerated() {
                        print("📊 WeatherService: UV entry \(index): place=\(entry.place ?? "nil"), value=\(entry.value?.description ?? "nil"), desc=\(entry.desc ?? "nil")")
                    }
                } else {
                    print("⚠️ WeatherService: UV index data array is nil or empty")
                }
            } else {
                print("⚠️ WeatherService: UV index dataset is nil (可能因為是晚上/早上，沒有太陽)")
            }
            
            // 獲取 UV 指數：先從 rhrread API 嘗試，如果沒有則從專門的 UV API 獲取
            var uvIndex: Int = {
                guard let uvData = payload.uvindex,
                      let uvEntries = uvData.data, !uvEntries.isEmpty else {
                    print("⚠️ WeatherService: No UV index data in rhrread response (可能是晚上/早上，沒有太陽)")
                    return -1 // 使用 -1 表示需要從專門的 API 獲取
                }
                
                // 查找第一個非 nil 且非 0 的 value（0 可能是有效值，但我們優先選擇非 0 的值）
                var foundValue: Int? = nil
                for entry in uvEntries {
                    if let value = entry.value {
                        print("📊 WeatherService: Found UV entry - place: \(entry.place ?? "unknown"), value: \(value)")
                        if value > 0 {
                            print("✅ WeatherService: Found UV index from rhrread: \(value) from place: \(entry.place ?? "unknown")")
                            return value
                        } else {
                            // 記錄 0 值，但繼續查找
                            if foundValue == nil {
                                foundValue = value
                            }
                        }
                    }
                }
                
                // 如果所有值都是 0，返回 0（這可能是有效的，表示晚上/早上）
                if let zeroValue = foundValue {
                    print("⚠️ WeatherService: All UV index entries are 0 (可能是晚上/早上，沒有太陽)")
                    return zeroValue
                }
                
                print("⚠️ WeatherService: All UV index entries have nil values in rhrread")
                return -1
            }()
            
            // 如果 rhrread API 沒有 UV 數據，嘗試從專門的 UV API 獲取
            if uvIndex == -1 {
                print("🔄 WeatherService: Attempting to fetch UV index from dedicated API...")
                uvIndex = await fetchUVIndexFromDedicatedAPI(language: language)
                if uvIndex > 0 {
                    print("✅ WeatherService: Successfully got UV index \(uvIndex) from dedicated API")
                } else {
                    print("⚠️ WeatherService: UV index is 0 or unavailable (可能是晚上/早上，沒有太陽)")
                }
            }
            
            // Build warning messages from both real‑time API and warning summary API
            var warningMessages: [String] = []
            
            // Step 1: warnings from real‑time rhrread API
            if let messages = payload.warningMessage, !messages.isEmpty {
                print("📋 WeatherService: Found \(messages.count) warning message(s) from rhrread: \(messages)")
                // Add messages without warning symbol prefix
                warningMessages.append(contentsOf: messages.filter { !$0.isEmpty })
            }
            
            // Step 2: warnings from warnsum API
            do {
                let warnings = try await warningService.fetchWarnings(language: language)
                let activeWarnings = warnings.filter { $0.isActive }
                if !activeWarnings.isEmpty {
                    print("📋 WeatherService: Found \(activeWarnings.count) active warning(s) from warnsum")
                    for warning in activeWarnings {
                        let warningText = "\(warning.name) (\(warning.code))"
                        // Avoid duplicates
                        let exists = warningMessages.contains { $0.contains(warning.name) && $0.contains(warning.code) }
                        if !exists {
                            warningMessages.append(warningText)
                        }
                    }
                }
            } catch {
                print("⚠️ WeatherService: Failed to fetch warnings from warnsum API: \(error)")
            }
            
            // Merge all warning messages into a single string
            let warningMessage: String? = {
                guard !warningMessages.isEmpty else {
                    print("📋 WeatherService: No warning messages found")
                    return nil
                }
                let joined = warningMessages.joined(separator: "\n")
                print("📋 WeatherService: Final warning message: \(joined)")
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
    
    /// Fetches weather snapshots for all available locations from the API.
    func fetchSnapshotsForAllLocations(language: String = "en") async throws -> [WeatherSnapshot] {
        let endpoint = endpointURL(language: language)
        print("🌤️ WeatherService: Fetching weather for all locations from \(endpoint.absoluteString)")
        
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
            
            let payload = try decoder.decode(HKORealTimeWeather.self, from: data)
            
            // Build warning messages (same for all locations)
            var warningMessages: [String] = []
            
            if let messages = payload.warningMessage, !messages.isEmpty {
                warningMessages.append(contentsOf: messages.filter { !$0.isEmpty })
            }
            
            do {
                let warnings = try await warningService.fetchWarnings(language: language)
                let activeWarnings = warnings.filter { $0.isActive }
                if !activeWarnings.isEmpty {
                    for warning in activeWarnings {
                        let warningText = "\(warning.name) (\(warning.code))"
                        let exists = warningMessages.contains { $0.contains(warning.name) && $0.contains(warning.code) }
                        if !exists {
                            warningMessages.append(warningText)
                        }
                    }
                }
            } catch {
                print("⚠️ WeatherService: Failed to fetch warnings from warnsum API: \(error)")
            }
            
            let warningMessage: String? = warningMessages.isEmpty ? nil : warningMessages.joined(separator: "\n")
            
            // 調試 UV 指數數據
            if let uvData = payload.uvindex {
                print("📊 WeatherService (all locations): UV index data found - recordDesc: \(uvData.recordDesc ?? "nil")")
                if let uvEntries = uvData.data, !uvEntries.isEmpty {
                    print("📊 WeatherService (all locations): UV index entries count: \(uvEntries.count)")
                    for (index, entry) in uvEntries.enumerated() {
                        print("📊 WeatherService (all locations): UV entry \(index): place=\(entry.place ?? "nil"), value=\(entry.value?.description ?? "nil"), desc=\(entry.desc ?? "nil")")
                    }
                } else {
                    print("⚠️ WeatherService (all locations): UV index data array is nil or empty")
                }
            } else {
                print("⚠️ WeatherService (all locations): UV index dataset is nil (可能因為是晚上/早上，沒有太陽)")
            }
            
            // 獲取 UV 指數：先從 rhrread API 嘗試，如果沒有則從專門的 UV API 獲取
            var uvIndex: Int = {
                guard let uvData = payload.uvindex,
                      let uvEntries = uvData.data, !uvEntries.isEmpty else {
                    print("⚠️ WeatherService (all locations): No UV index data in rhrread response (可能是晚上/早上，沒有太陽)")
                    return -1 // 使用 -1 表示需要從專門的 API 獲取
                }
                
                // 查找第一個非 nil 且非 0 的 value（0 可能是有效值，但我們優先選擇非 0 的值）
                var foundValue: Int? = nil
                for entry in uvEntries {
                    if let value = entry.value {
                        print("📊 WeatherService (all locations): Found UV entry - place: \(entry.place ?? "unknown"), value: \(value)")
                        if value > 0 {
                            print("✅ WeatherService (all locations): Found UV index from rhrread: \(value) from place: \(entry.place ?? "unknown")")
                            return value
                        } else {
                            // 記錄 0 值，但繼續查找
                            if foundValue == nil {
                                foundValue = value
                            }
                        }
                    }
                }
                
                // 如果所有值都是 0，返回 0（這可能是有效的，表示晚上/早上）
                if let zeroValue = foundValue {
                    print("⚠️ WeatherService (all locations): All UV index entries are 0 (可能是晚上/早上，沒有太陽)")
                    return zeroValue
                }
                
                print("⚠️ WeatherService (all locations): All UV index entries have nil values in rhrread")
                return -1
            }()
            
            // 如果 rhrread API 沒有 UV 數據，嘗試從專門的 UV API 獲取
            if uvIndex == -1 {
                print("🔄 WeatherService (all locations): Attempting to fetch UV index from dedicated API...")
                uvIndex = await fetchUVIndexFromDedicatedAPI(language: language)
                if uvIndex > 0 {
                    print("✅ WeatherService (all locations): Successfully got UV index \(uvIndex) from dedicated API")
                } else {
                    print("⚠️ WeatherService (all locations): UV index is 0 or unavailable (可能是晚上/早上，沒有太陽)")
                }
            }
            
            // Get unique locations from temperature data
            let uniqueLocations = Array(Set(payload.temperature.data.map { $0.place }))
            
            var snapshots: [WeatherSnapshot] = []
            
            // Create a snapshot for each location
            for location in uniqueLocations {
                guard let tempEntry = payload.temperature.data.first(where: { $0.place == location }),
                      let temperature = tempEntry.value else {
                    continue
                }
                
                // Try to find matching humidity entry, fallback to first available
                let humidityEntry = payload.humidity.data.first(where: { $0.place == location }) ?? payload.humidity.data.first
                guard let humidityValue = humidityEntry?.value else {
                    continue
                }
                
                let suggestion = WeatherSuggestionBuilder.suggestion(
                    uvIndex: uvIndex,
                    humidity: Int(humidityValue),
                    hasWarning: warningMessage != nil && !warningMessage!.isEmpty
                )
                
                let snapshot = WeatherSnapshot(
                    location: location,
                    temperature: temperature,
                    humidity: Int(humidityValue),
                    uvIndex: uvIndex,
                    warningMessage: warningMessage,
                    suggestion: suggestion,
                    updatedAt: Date()
                )
                
                snapshots.append(snapshot)
            }
            
            // Sort by location name for consistent ordering
            snapshots.sort { $0.location < $1.location }
            
            print("✅ WeatherService: Successfully fetched \(snapshots.count) location snapshots")
            return snapshots
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

