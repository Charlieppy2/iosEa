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
    let stop: String
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
        "\(route)-\(dir)-\(service_type)-\(stop)-\(seq)"
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
    func fetchETA(stopId: String, route: String, serviceType: String) async throws -> [KMBETA]
    func searchRoutes(keyword: String) async throws -> [KMBRoute]
}

struct KMBService: KMBServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseEndpoint = "https://data.etabus.gov.hk/v1/transport/kmb"
    
    init(session: URLSession? = nil, decoder: JSONDecoder? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0
        configuration.timeoutIntervalForResource = 15.0
        configuration.waitsForConnectivity = true
        
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
    
    /// Fetch route detail with stops
    func fetchRouteDetail(route: String, direction: String, serviceType: String) async throws -> KMBRouteDetail? {
        guard let url = URL(string: "\(baseEndpoint)/route/\(route)/\(direction)/\(serviceType)") else {
            throw KMBServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KMBServiceError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw KMBServiceError.httpError(httpResponse.statusCode)
        }
        
        let decoded = try decoder.decode(KMBRouteDetailResponse.self, from: data)
        return decoded.data
    }
    
    /// Fetch ETA for a specific stop and route
    func fetchETA(stopId: String, route: String, serviceType: String) async throws -> [KMBETA] {
        guard let url = URL(string: "\(baseEndpoint)/eta/\(stopId)/\(route)/\(serviceType)") else {
            throw KMBServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KMBServiceError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw KMBServiceError.httpError(httpResponse.statusCode)
        }
        
        let decoded = try decoder.decode(KMBETAResponse.self, from: data)
        return decoded.data ?? []
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

