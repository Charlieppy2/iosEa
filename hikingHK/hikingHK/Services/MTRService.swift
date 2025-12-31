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
        
        // Check for error response first
        if let errorResponse = try? decoder.decode(MTRErrorResponse.self, from: data) {
            if errorResponse.resultCode == 0 && errorResponse.status == 0 {
                // API returned an error (e.g., line disabled in CMS)
                let errorMsg = errorResponse.error?.errorMsg ?? errorResponse.message ?? "Line or station not available"
                throw MTRServiceError.apiError(errorMsg)
            }
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

/// Error response structure from MTR API
struct MTRErrorResponse: Codable {
    let resultCode: Int
    let timestamp: String?
    let error: MTRAPIError?
    let status: Int
    let message: String?
}

struct MTRAPIError: Codable {
    let errorCode: String?
    let errorMsg: String?
}

enum MTRServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case lineDisabled(String) // Specific error for disabled lines
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid MTR API URL"
        case .invalidResponse:
            return "Invalid response from MTR API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            // Check if it's a line disabled error
            if message.contains("disabled in CMS") || message.contains("NT-205") {
                return "此路線暫時不提供實時列車資訊"
            }
            return message
        case .lineDisabled(let line):
            return "\(line) 路線暫時不提供實時列車資訊"
        }
    }
}

/// Helper to map station names to MTR line and station codes
struct MTRStationMapper {
    /// Lines that are known to be disabled in MTR API CMS
    /// These lines will return error "line is disabled in CMS"
    static let disabledLines: Set<String> = ["TKO", "DIS"]
    
    /// Check if a line is known to be disabled
    static func isLineDisabled(_ line: String) -> Bool {
        return disabledLines.contains(line)
    }
    
    /// Map a station name (in Chinese or English) to MTR line and station codes
    /// Returns (line, station) tuple if found, nil otherwise
    static func mapStation(_ stationName: String) -> (line: String, station: String)? {
        let normalizedName = stationName.lowercased()
            .replacingOccurrences(of: "站", with: "")
            .replacingOccurrences(of: "station", with: "")
            .replacingOccurrences(of: " ", with: "") // Remove all spaces
            .trimmingCharacters(in: .whitespaces)
        
        // Complete MTR station mapping
        let stationMap: [String: (line: String, station: String)] = [
            // Island Line (ISL)
            "central": ("ISL", "CEN"),
            "中環": ("ISL", "CEN"),
            "admiralty": ("ISL", "ADM"),
            "金鐘": ("ISL", "ADM"),
            "wanchai": ("ISL", "WAC"),
            "灣仔": ("ISL", "WAC"),
            "causewaybay": ("ISL", "CAB"),
            "銅鑼灣": ("ISL", "CAB"),
            "tinhau": ("ISL", "TIH"),
            "天后": ("ISL", "TIH"),
            "fortresshill": ("ISL", "FOH"),
            "炮台山": ("ISL", "FOH"),
            "northpoint": ("ISL", "NOP"),
            "北角": ("ISL", "NOP"),
            "quarrybay": ("ISL", "QUB"),
            "鰂魚涌": ("ISL", "QUB"),
            "taikoo": ("ISL", "TAK"),
            "太古城": ("ISL", "TAK"),
            "saiwanho": ("ISL", "SWH"),
            "西灣河": ("ISL", "SWH"),
            "shaukeiwan": ("ISL", "SKW"),
            "筲箕灣": ("ISL", "SKW"),
            "hengfachuen": ("ISL", "HFC"),
            "杏花邨": ("ISL", "HFC"),
            "chaiwan": ("ISL", "CHW"),
            "柴灣": ("ISL", "CHW"),
            "kennedytown": ("ISL", "KET"),
            "堅尼地城": ("ISL", "KET"),
            
            // Tsuen Wan Line (TWL)
            "tsuenwan": ("TWL", "TSW"),
            "荃灣": ("TWL", "TSW"),
            "tsuenwansouth": ("TWL", "TWS"),
            "荃灣西": ("TWL", "TWS"),
            "taiwohau": ("TWL", "TWW"),
            "大窩口": ("TWL", "TWW"),
            "kwaihing": ("TWL", "KWF"),
            "葵興": ("TWL", "KWF"),
            "kwaifong": ("TWL", "KWH"),
            "葵芳": ("TWL", "KWH"),
            "laiking": ("TWL", "LAK"),
            "荔景": ("TWL", "LAK"),
            "meifoo": ("TWL", "MEF"),
            "美孚": ("TWL", "MEF"),
            "laichikok": ("TWL", "PRE"),
            "荔枝角": ("TWL", "PRE"),
            "cheungshawan": ("TWL", "CSW"),
            "長沙灣": ("TWL", "CSW"),
            "shamshuipo": ("TWL", "SHM"),
            "深水埗": ("TWL", "SHM"),
            "mongkok": ("TWL", "MOK"),
            "旺角": ("TWL", "MOK"),
            "yaumatei": ("TWL", "YMT"),
            "油麻地": ("TWL", "YMT"),
            "jordan": ("TWL", "JOR"),
            "佐敦": ("TWL", "JOR"),
            "tsimshatsui": ("TWL", "TST"),
            "尖沙咀": ("TWL", "TST"),
            
            // Kwun Tong Line (KTL)
            "wongtaisin": ("KTL", "WHC"),
            "黃大仙": ("KTL", "WHC"),
            "diamondhill": ("KTL", "DIH"),
            "鑽石山": ("KTL", "DIH"),
            "choihung": ("KTL", "CHH"),
            "彩虹": ("KTL", "CHH"),
            "kowloonbay": ("KTL", "KOB"),
            "九龍灣": ("KTL", "KOB"),
            "ngautaukok": ("KTL", "NTK"),
            "牛頭角": ("KTL", "NTK"),
            "kwuntong": ("KTL", "KWT"),
            "觀塘": ("KTL", "KWT"),
            "lamtin": ("KTL", "LAT"),
            "藍田": ("KTL", "LAT"),
            "yautong": ("KTL", "YAT"),
            "油塘": ("KTL", "YAT"),
            "tiukengleng": ("KTL", "TIK"),
            "調景嶺": ("KTL", "TIK"),
            
            // Tseung Kwan O Line (TKO)
            "tseungkwan": ("TKO", "TKO"),
            "將軍澳": ("TKO", "TKO"),
            "hanghau": ("TKO", "HAH"),
            "坑口": ("TKO", "HAH"),
            "polam": ("TKO", "POA"),
            "寶琳": ("TKO", "POA"),
            "lohaspark": ("TKO", "LHP"),
            "康城": ("TKO", "LHP"),
            
            // Tung Chung Line (TCL)
            "tungchung": ("TCL", "TUC"),
            "東涌": ("TCL", "TUC"),
            "sunnybay": ("TCL", "SUN"),
            "欣澳": ("TCL", "SUN"),
            "tsingyi": ("TCL", "TSY"),
            "青衣": ("TCL", "TSY"),
            "airport": ("TCL", "AWE"),
            "機場": ("TCL", "AWE"),
            "asiaworldexpo": ("TCL", "AEL"),
            "博覽館": ("TCL", "AEL"),
            
            // East Rail Line (EAL)
            "hunghom": ("EAL", "HUH"),
            "紅磡": ("EAL", "HUH"),
            "easttsimshatsui": ("EAL", "ETS"),
            "尖東": ("EAL", "ETS"),
            "mongkokeast": ("EAL", "MKK"),
            "旺角東": ("EAL", "MKK"),
            "kowloontong": ("EAL", "KOT"),
            "九龍塘": ("EAL", "KOT"),
            "taiwai": ("EAL", "TAW"),
            "大圍": ("EAL", "TAW"),
            "shatin": ("EAL", "SHT"),
            "沙田": ("EAL", "SHT"),
            "fotan": ("EAL", "FOT"),
            "火炭": ("EAL", "FOT"),
            "racecourse": ("EAL", "RAC"),
            "馬場": ("EAL", "RAC"),
            "university": ("EAL", "UNI"),
            "大學": ("EAL", "UNI"),
            "taipomarket": ("EAL", "TAP"),
            "大埔墟": ("EAL", "TAP"),
            "taiwo": ("EAL", "TWO"),
            "太和": ("EAL", "TWO"),
            "fanling": ("EAL", "FAN"),
            "粉嶺": ("EAL", "FAN"),
            "sheungshui": ("EAL", "SHS"),
            "上水": ("EAL", "SHS"),
            "lowu": ("EAL", "LOW"),
            "羅湖": ("EAL", "LOW"),
            "lokmachau": ("EAL", "LMC"),
            "落馬洲": ("EAL", "LMC"),
            
            // Tuen Ma Line (TML)
            "tuennun": ("TML", "TUM"),
            "屯門": ("TML", "TUM"),
            "siuhong": ("TML", "SIH"),
            "兆康": ("TML", "SIH"),
            "tinshuiwai": ("TML", "TIS"),
            "天水圍": ("TML", "TIS"),
            "yuenlong": ("TML", "YUL"),
            "元朗": ("TML", "YUL"),
            "kamsheungroad": ("TML", "KSR"),
            "錦上路": ("TML", "KSR"),
            "longping": ("TML", "LOP"),
            "朗屏": ("TML", "LOP"),
            "wukaisha": ("TML", "WKS"),
            "烏溪沙": ("TML", "WKS"),
            "maonshan": ("TML", "MOS"),
            "馬鞍山": ("TML", "MOS"),
            "hengon": ("TML", "HEO"),
            "恆安": ("TML", "HEO"),
            "taishuihang": ("TML", "AFC"),
            "大水坑": ("TML", "AFC"),
            "shatinwai": ("TML", "WHA"),
            "沙田圍": ("TML", "WHA"),
            "chekungtemple": ("TML", "CIO"),
            "車公廟": ("TML", "CIO"),
            "shekmun": ("TML", "STW"),
            "石門": ("TML", "STW"),
            "cityone": ("TML", "FIR"),
            "第一城": ("TML", "FIR"),
            "hinkeng": ("TML", "HIK"),
            "顯徑": ("TML", "HIK"),
            "homan": ("TML", "HOM"),
            "何文田": ("TML", "HOM"),
            "hongkong": ("TML", "HOK"),
            "香港": ("TML", "HOK"),
            "kowloon": ("TML", "KOW"),
            "九龍": ("TML", "KOW"),
            "austin": ("TML", "AUS"),
            "柯士甸": ("TML", "AUS"),
            "exhibitioncentre": ("TML", "EXC"),
            "會展": ("TML", "EXC"),
            "namcheong": ("TML", "NAC"),
            "南昌": ("TML", "NAC"),
            
            // South Island Line (SIL)
            "oceanpark": ("SIL", "OCP"),
            "海洋公園": ("SIL", "OCP"),
            "wongchukhang": ("SIL", "WCH"),
            "黃竹坑": ("SIL", "WCH"),
            "leitung": ("SIL", "LET"),
            "利東": ("SIL", "LET"),
            "southhorizons": ("SIL", "SOH"),
            "海怡半島": ("SIL", "SOH"),
            
            // Disneyland Resort Line (DIS)
            "disneyland": ("DIS", "DIS"),
            "disneylandresort": ("DIS", "DIS"),
            "迪士尼": ("DIS", "DIS"),
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

