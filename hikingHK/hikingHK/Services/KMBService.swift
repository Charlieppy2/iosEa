//
//  KMBService.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation

/// KMB/LWB route list response
struct KMBRouteListResponse: Codable {
    let type: String
    let version: String
    let generated_timestamp: String
    let data: [KMBRoute]
}

/// KMB/LWB route information
struct KMBRoute: Codable, Identifiable, Hashable {
    let route: String
    let bound: String // "O" for outbound, "I" for inbound
    let service_type: String
    let orig_en: String
    let orig_tc: String
    let orig_sc: String
    let dest_en: String
    let dest_tc: String
    let dest_sc: String
    
    var id: String {
        "\(route)-\(bound)-\(service_type)"
    }
    
    func localizedOrigin(languageManager: LanguageManager) -> String {
        // Localize based on app language
        switch languageManager.currentLanguage {
        case .english:
            return orig_en
        case .traditionalChinese:
            return orig_tc
        }
    }
    
    func localizedDestination(languageManager: LanguageManager) -> String {
        switch languageManager.currentLanguage {
        case .english:
            return dest_en
        case .traditionalChinese:
            return dest_tc
        }
    }
}

/// KMB/LWB route detail response
struct KMBRouteDetailResponse: Codable {
    let type: String
    let version: String
    let generated_timestamp: String
    let data: KMBRouteDetail?
}

struct KMBRouteDetail: Codable {
    let route: String
    let bound: String
    let service_type: String
    let orig_en: String
    let orig_tc: String
    let orig_sc: String
    let dest_en: String
    let dest_tc: String
    let dest_sc: String
    let stops: [KMBStop]?
}

struct KMBStop: Codable, Identifiable, Hashable {
    let stop: String
    let name_en: String
    let name_tc: String
    let name_sc: String
    let lat: String
    let long: String
    
    var id: String {
        stop
    }
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch languageManager.currentLanguage {
        case .english:
            return name_en
        case .traditionalChinese:
            return name_tc
        }
    }
}

/// KMB/LWB ETA response
struct KMBETAResponse: Codable {
    let type: String
    let version: String
    let generated_timestamp: String
    let data: [KMBETA]?
}

struct KMBETA: Codable, Identifiable, Hashable {
    let co: String? // Company (KMB or LWB)
    let route: String
    let dir: String
    let service_type: String
    let seq: String
    let stop: String? // Note: API may not return this field, we'll set it from stopId
    let dest_tc: String?
    let dest_en: String?
    let dest_sc: String?
    let eta_seq: String?
    let eta: String?
    let rmk_tc: String?
    let rmk_en: String?
    let rmk_sc: String?
    let data_timestamp: String
    
    var id: String {
        // Include eta_seq to ensure uniqueness when multiple buses arrive at same stop
        let etaSeq = eta_seq ?? "0"
        return "\(route)-\(dir)-\(service_type)-\(stop ?? "unknown")-\(seq)-\(etaSeq)"
    }
    
    // Custom decoding to handle both String and Int for service_type and seq
    enum CodingKeys: String, CodingKey {
        case co, route, dir, service_type, seq, stop
        case dest_tc, dest_en, dest_sc, eta_seq, eta
        case rmk_tc, rmk_en, rmk_sc, data_timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        co = try container.decodeIfPresent(String.self, forKey: .co)
        route = try container.decode(String.self, forKey: .route)
        dir = try container.decode(String.self, forKey: .dir)
        
        // Handle service_type as either String or Int
        if let intValue = try? container.decode(Int.self, forKey: .service_type) {
            service_type = String(intValue)
        } else {
            service_type = try container.decode(String.self, forKey: .service_type)
        }
        
        // Handle seq as either String or Int
        if let intValue = try? container.decode(Int.self, forKey: .seq) {
            seq = String(intValue)
        } else {
            seq = try container.decode(String.self, forKey: .seq)
        }
        
        stop = try container.decodeIfPresent(String.self, forKey: .stop)
        dest_tc = try container.decodeIfPresent(String.self, forKey: .dest_tc)
        dest_en = try container.decodeIfPresent(String.self, forKey: .dest_en)
        dest_sc = try container.decodeIfPresent(String.self, forKey: .dest_sc)
        
        // Handle eta_seq as either String or Int
        if let intValue = try? container.decode(Int.self, forKey: .eta_seq) {
            eta_seq = String(intValue)
        } else {
            eta_seq = try container.decodeIfPresent(String.self, forKey: .eta_seq)
        }
        
        eta = try container.decodeIfPresent(String.self, forKey: .eta)
        rmk_tc = try container.decodeIfPresent(String.self, forKey: .rmk_tc)
        rmk_en = try container.decodeIfPresent(String.self, forKey: .rmk_en)
        rmk_sc = try container.decodeIfPresent(String.self, forKey: .rmk_sc)
        data_timestamp = try container.decode(String.self, forKey: .data_timestamp)
    }
    
    func localizedDestination(languageManager: LanguageManager) -> String {
        switch languageManager.currentLanguage {
        case .english:
            return dest_en ?? ""
        case .traditionalChinese:
            return dest_tc ?? ""
        }
    }
    
    func localizedRemark(languageManager: LanguageManager) -> String {
        switch languageManager.currentLanguage {
        case .english:
            return rmk_en ?? ""
        case .traditionalChinese:
            return rmk_tc ?? ""
        }
    }
    
    var formattedETA: String {
        guard let eta = eta else { return "" }
        // ETA format: "2024-01-01T12:00:00+08:00"
        // Convert to relative time (e.g., "5 min")
        return formatETATime(eta)
    }
    
    private func formatETATime(_ etaString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let etaDate = formatter.date(from: etaString) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let etaDate = formatter.date(from: etaString) else {
                return etaString
            }
            return formatRelativeTime(from: etaDate)
        }
        
        return formatRelativeTime(from: etaDate)
    }
    
    private func formatRelativeTime(from date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return "已過"
        }
        
        let minutes = Int(timeInterval / 60)
        if minutes < 1 {
            return "即將到站"
        }
        
        return "\(minutes) 分鐘"
    }
}

/// Service for fetching KMB/LWB bus information
protocol KMBServiceProtocol {
    func fetchRouteList() async throws -> [KMBRoute]
    func fetchRouteDetail(route: String, direction: String, serviceType: String) async throws -> KMBRouteDetail?
    func fetchRouteStops(route: String, direction: String, serviceType: String) async throws -> [KMBStop]
    func fetchETA(stopId: String, route: String, serviceType: String) async throws -> [KMBETA]
    func searchRoutes(keyword: String) async throws -> [KMBRoute]
}

struct KMBService: KMBServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseEndpoint = "https://data.etabus.gov.hk/v1/transport/kmb"
    
    init(session: URLSession? = nil, decoder: JSONDecoder? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5.0 // Reduced from 10.0 for faster response
        configuration.timeoutIntervalForResource = 8.0 // Reduced from 15.0 for faster response
        configuration.waitsForConnectivity = false
        configuration.httpMaximumConnectionsPerHost = 10 // Allow more concurrent connections
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData // Always fetch fresh data
        
        self.session = session ?? URLSession(configuration: configuration)
        
        let jsonDecoder = decoder ?? JSONDecoder()
        self.decoder = jsonDecoder
    }
    
    /// Fetch all routes
    func fetchRouteList() async throws -> [KMBRoute] {
        guard let url = URL(string: "\(baseEndpoint)/route/") else {
            throw KMBServiceError.invalidURL
        }
        
        print("🌐 Fetching KMB route list from: \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw KMBServiceError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            print("❌ HTTP error: \(httpResponse.statusCode)")
            throw KMBServiceError.httpError(httpResponse.statusCode)
        }
        
        // Check if response is HTML (API error)
        if let responseString = String(data: data, encoding: .utf8),
           responseString.contains("<!DOCTYPE") || responseString.contains("<html") {
            print("❌ API returned HTML instead of JSON")
            throw KMBServiceError.invalidResponse
        }
        
        do {
            let decoded = try decoder.decode(KMBRouteListResponse.self, from: data)
            print("✅ Successfully decoded \(decoded.data.count) routes")
            return decoded.data
        } catch {
            print("❌ JSON decode error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Response preview: \(String(jsonString.prefix(500)))")
            }
            throw KMBServiceError.apiError("Failed to decode route list: \(error.localizedDescription)")
        }
    }
    
    /// Convert direction from "O"/"I" to "outbound"/"inbound"
    private func convertDirection(_ direction: String) -> String {
        if direction.uppercased() == "O" {
            return "outbound"
        } else if direction.uppercased() == "I" {
            return "inbound"
        } else {
            return direction // Use as-is if already in correct format
        }
    }
    
    /// Fetch route detail with stops
    func fetchRouteDetail(route: String, direction: String, serviceType: String) async throws -> KMBRouteDetail? {
        let apiDirection = convertDirection(direction)
        let urlString = "\(baseEndpoint)/route/\(route)/\(apiDirection)/\(serviceType)"
        print("🌐 Fetching route detail from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw KMBServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KMBServiceError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(errorData)")
            }
            throw KMBServiceError.httpError(httpResponse.statusCode)
        }
        
        // Check if response is HTML (API error)
        if let responseString = String(data: data, encoding: .utf8),
           responseString.contains("<!DOCTYPE") || responseString.contains("<html") {
            print("❌ API returned HTML instead of JSON")
            throw KMBServiceError.invalidResponse
        }
        
        do {
            let decoded = try decoder.decode(KMBRouteDetailResponse.self, from: data)
            var routeDetail = decoded.data
            
            // Fetch stops separately using route-stop endpoint
            if let stops = try? await fetchRouteStops(route: route, direction: direction, serviceType: serviceType) {
                // Note: KMBRouteDetail doesn't have a mutable stops property, so we need to create a new one
                // For now, we'll fetch stops separately in the view model
            }
            
            return routeDetail
        } catch {
            print("❌ JSON decode error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Response preview: \(String(jsonString.prefix(500)))")
            }
            throw KMBServiceError.apiError("Failed to decode route detail: \(error.localizedDescription)")
        }
    }
    
    /// Fetch route stops using route-stop endpoint
    func fetchRouteStops(route: String, direction: String, serviceType: String) async throws -> [KMBStop] {
        let apiDirection = convertDirection(direction)
        let urlString = "\(baseEndpoint)/route-stop/\(route)/\(apiDirection)/\(serviceType)"
        print("🌐 Fetching route stops from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw KMBServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KMBServiceError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(errorData)")
            }
            throw KMBServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse route-stop response
        struct RouteStopResponse: Codable {
            let type: String
            let version: String
            let generated_timestamp: String
            let data: [RouteStopItem]
        }
        
        struct RouteStopItem: Codable {
            let route: String
            let bound: String
            let service_type: String
            let seq: String
            let stop: String
        }
        
        let routeStopResponse = try decoder.decode(RouteStopResponse.self, from: data)
        
        // Fetch stop details for each stop ID
        var stops: [KMBStop] = []
        for stopItem in routeStopResponse.data {
            if let stopDetail = try? await fetchStopDetail(stopId: stopItem.stop) {
                stops.append(stopDetail)
            }
        }
        
        // Sort by sequence
        let sortedStops = stops.sorted { stop1, stop2 in
            if let seq1 = routeStopResponse.data.firstIndex(where: { $0.stop == stop1.stop }),
               let seq2 = routeStopResponse.data.firstIndex(where: { $0.stop == stop2.stop }) {
                return seq1 < seq2
            }
            return false
        }
        
        print("✅ Fetched \(sortedStops.count) stops for route \(route)")
        return sortedStops
    }
    
    /// Fetch stop detail by stop ID
    private func fetchStopDetail(stopId: String) async throws -> KMBStop {
        let urlString = "\(baseEndpoint)/stop/\(stopId)"
        guard let url = URL(string: urlString) else {
            throw KMBServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw KMBServiceError.invalidResponse
        }
        
        struct StopDetailResponse: Codable {
            let type: String
            let version: String
            let generated_timestamp: String
            let data: KMBStop
        }
        
        let stopResponse = try decoder.decode(StopDetailResponse.self, from: data)
        return stopResponse.data
    }
    
    /// Fetch ETA for a specific stop and route
    func fetchETA(stopId: String, route: String, serviceType: String) async throws -> [KMBETA] {
        let urlString = "\(baseEndpoint)/eta/\(stopId)/\(route)/\(serviceType)"
        print("🌐 Fetching ETA from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            throw KMBServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KMBServiceError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            if let errorData = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(errorData)")
            }
            throw KMBServiceError.httpError(httpResponse.statusCode)
        }
        
        // Check if response is HTML (API error)
        if let responseString = String(data: data, encoding: .utf8),
           responseString.contains("<!DOCTYPE") || responseString.contains("<html") {
            print("❌ API returned HTML instead of JSON")
            throw KMBServiceError.invalidResponse
        }
        
        do {
            // API doesn't return 'stop' field, so we need to add it manually
            if var jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               var dataArray = jsonObject["data"] as? [[String: Any]] {
                // Add stop ID to each ETA item
                for i in 0..<dataArray.count {
                    dataArray[i]["stop"] = stopId
                }
                jsonObject["data"] = dataArray
                let modifiedData = try JSONSerialization.data(withJSONObject: jsonObject)
                let decoded = try decoder.decode(KMBETAResponse.self, from: modifiedData)
                let etas = decoded.data ?? []
                print("✅ Successfully decoded \(etas.count) ETAs with stop ID \(stopId)")
                return etas
            } else {
                // Fallback: try decoding without stop field
                let decoded = try decoder.decode(KMBETAResponse.self, from: data)
                let etas = decoded.data ?? []
                print("✅ Successfully decoded \(etas.count) ETAs (no stop field)")
                return etas
            }
        } catch {
            print("❌ JSON decode error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Response preview: \(String(jsonString.prefix(500)))")
            }
            throw KMBServiceError.apiError("Failed to decode ETA: \(error.localizedDescription)")
        }
    }
    
    /// Search routes by keyword (route number or station name)
    func searchRoutes(keyword: String) async throws -> [KMBRoute] {
        print("🔍 Searching for routes with keyword: '\(keyword)'")
        let allRoutes = try await fetchRouteList()
        let lowerKeyword = keyword.lowercased().trimmingCharacters(in: .whitespaces)
        
        let results = allRoutes.filter { route in
            route.route.lowercased().contains(lowerKeyword) ||
            route.orig_tc.lowercased().contains(lowerKeyword) ||
            route.orig_en.lowercased().contains(lowerKeyword) ||
            route.dest_tc.lowercased().contains(lowerKeyword) ||
            route.dest_en.lowercased().contains(lowerKeyword)
        }
        
        print("✅ Found \(results.count) matching routes")
        return results
    }
}

enum KMBServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid KMB API URL"
        case .invalidResponse:
            return "Invalid response from KMB API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        }
    }
}

