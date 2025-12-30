//
//  MTRService.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation

/// MTR real-time train schedule data models
struct MTRScheduleResponse: Codable {
    let status: Int
    let message: String
    let data: [String: MTRStationSchedule]?
    
    // Helper to convert to MTRScheduleData format
    // Merge all station schedules to get complete UP and DOWN data
    func toScheduleData() -> MTRScheduleData? {
        guard let data = data, !data.isEmpty else { return nil }
        
        // Merge UP and DOWN trains from all stations in the response
        var allUP: [MTRTrain] = []
        var allDOWN: [MTRTrain] = []
        
        for stationSchedule in data.values {
            if let up = stationSchedule.UP {
                allUP.append(contentsOf: up)
            }
            if let down = stationSchedule.DOWN {
                allDOWN.append(contentsOf: down)
            }
        }
        
        // Sort by time/sequence to show earliest trains first
        allUP.sort { train1, train2 in
            let time1 = Int(train1.formattedTime) ?? 999
            let time2 = Int(train2.formattedTime) ?? 999
            return time1 < time2
        }
        
        allDOWN.sort { train1, train2 in
            let time1 = Int(train1.formattedTime) ?? 999
            let time2 = Int(train2.formattedTime) ?? 999
            return time1 < time2
        }
        
        return MTRScheduleData(
            UP: allUP.isEmpty ? nil : allUP,
            DOWN: allDOWN.isEmpty ? nil : allDOWN
        )
    }
}

struct MTRStationSchedule: Codable {
    let curr_time: String?
    let sys_time: String?
    let UP: [MTRTrain]?
    let DOWN: [MTRTrain]?
}

struct MTRScheduleData: Codable {
    let UP: [MTRTrain]?
    let DOWN: [MTRTrain]?
}

struct MTRTrain: Codable, Identifiable, Hashable {
    let plat: String
    let time: String
    let dest: String
    let seq: String
    let ttnt: String?
    let valid: String?
    
    var id: String {
        "\(plat)-\(time)-\(dest)-\(seq)"
    }
    
    enum CodingKeys: String, CodingKey {
        case plat, time, dest, seq, ttnt, valid
    }
    
    // Computed property for formatted time (minutes until arrival)
    var formattedTime: String {
        if let ttnt = ttnt, let minutes = Int(ttnt) {
            if minutes <= 0 {
                return "Arr"
            }
            return "\(minutes)"
        }
        // Fallback: parse time string
        return time
    }
}

/// Service for fetching real-time MTR train schedules
protocol MTRServiceProtocol {
    func fetchSchedule(line: String, station: String) async throws -> MTRScheduleData
}

struct MTRService: MTRServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseEndpoint = "https://rt.data.gov.hk/v1/transport/mtr/getSchedule.php"
    
    init(session: URLSession? = nil, decoder: JSONDecoder? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5.0
        configuration.timeoutIntervalForResource = 10.0
        // Note: waitsForConnectivity may cause warnings in simulator, but doesn't affect functionality
        configuration.waitsForConnectivity = false
        
        self.session = session ?? URLSession(configuration: configuration)
        
        let jsonDecoder = decoder ?? JSONDecoder()
        self.decoder = jsonDecoder
    }
    
    /// Fetch real-time train schedule for a specific line and station
    /// - Parameters:
    ///   - line: MTR line code (e.g., "TWL" for Tsuen Wan Line, "ISL" for Island Line)
    ///   - station: Station code (e.g., "TIK" for Tsuen Wan)
    /// - Returns: MTRScheduleData containing UP and DOWN train schedules
    func fetchSchedule(line: String, station: String) async throws -> MTRScheduleData {
        var components = URLComponents(string: baseEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "line", value: line),
            URLQueryItem(name: "sta", value: station)
        ]
        
        guard let url = components.url else {
            throw MTRServiceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MTRServiceError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw MTRServiceError.httpError(httpResponse.statusCode)
        }
        
        // Check if response is HTML (API error)
        if let responseString = String(data: data, encoding: .utf8),
           responseString.contains("<!DOCTYPE") || responseString.contains("<html") {
            throw MTRServiceError.invalidResponse
        }
        
        let decoded = try decoder.decode(MTRScheduleResponse.self, from: data)
        
        guard decoded.status == 1 else {
            throw MTRServiceError.apiError(decoded.message)
        }
        
        guard let scheduleData = decoded.toScheduleData() else {
            throw MTRServiceError.apiError("No schedule data available")
        }
        
        return scheduleData
    }
}

enum MTRServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid MTR API URL"
        case .invalidResponse:
            return "Invalid response from MTR API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        }
    }
}

/// Helper to map station names to MTR line and station codes
struct MTRStationMapper {
    /// Map a station name (in Chinese or English) to MTR line and station codes
    /// Returns (line, station) tuple if found, nil otherwise
    static func mapStation(_ stationName: String) -> (line: String, station: String)? {
        let normalizedName = stationName.lowercased()
            .replacingOccurrences(of: "站", with: "")
            .replacingOccurrences(of: "station", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // Common MTR stations near hiking trails
        let stationMap: [String: (line: String, station: String)] = [
            // Tsuen Wan Line
            "tsuenwan": ("TWL", "TSW"),
            "tsuenwansouth": ("TWL", "TWS"),
            "荃灣": ("TWL", "TSW"),
            "荃灣西": ("TWL", "TWS"),
            
            // Island Line
            "chaiwan": ("ISL", "CHW"),
            "柴灣": ("ISL", "CHW"),
            "shaukeiwan": ("ISL", "SKW"),
            "筲箕灣": ("ISL", "SKW"),
            "quarrybay": ("ISL", "QUB"),
            "鰂魚涌": ("ISL", "QUB"),
            
            // Kwun Tong Line
            "kwuntong": ("KTL", "KWT"),
            "觀塘": ("KTL", "KWT"),
            
            // Tseung Kwan O Line
            "tseungkwan": ("TKO", "TKO"),
            "將軍澳": ("TKO", "TKO"),
            
            // East Rail Line
            "taipomarket": ("EAL", "TAP"),
            "大埔墟": ("EAL", "TAP"),
            "taiwo": ("EAL", "TWO"),
            "大窩": ("EAL", "TWO"),
            
            // Tung Chung Line
            "tungchung": ("TCL", "TUC"),
            "東涌": ("TCL", "TUC"),
            
            // South Island Line
            "oceanpark": ("SIL", "OCP"),
            "海洋公園": ("SIL", "OCP"),
            
            // West Rail Line / Tuen Ma Line
            "tuennun": ("TML", "TUM"),
            "屯門": ("TML", "TUM"),
            
            // Common stations
            "central": ("ISL", "CEN"),
            "中環": ("ISL", "CEN"),
            "admiralty": ("ISL", "ADM"),
            "金鐘": ("ISL", "ADM"),
            "wanchai": ("ISL", "WAC"),
            "灣仔": ("ISL", "WAC"),
        ]
        
        // Try exact match first
        if let codes = stationMap[normalizedName] {
            return codes
        }
        
        // Try partial match
        for (key, codes) in stationMap {
            if normalizedName.contains(key) || key.contains(normalizedName) {
                return codes
            }
        }
        
        return nil
    }
}

