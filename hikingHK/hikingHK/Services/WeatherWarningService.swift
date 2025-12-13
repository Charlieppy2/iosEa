//
//  WeatherWarningService.swift
//  hikingHK
//
//  Created for weather warning API integration
//

import Foundation

protocol WeatherWarningServiceProtocol {
    func fetchWarnings(language: String) async throws -> [WeatherWarning]
}

struct WeatherWarningService: WeatherWarningServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private let baseEndpoint = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warnsum&lang="
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    private func endpointURL(language: String) -> URL {
        // Map language codes: en -> en, zh-Hant -> tc
        let langCode = language == "zh-Hant" ? "tc" : "en"
        return URL(string: "\(baseEndpoint)\(langCode)")!
    }
    
    func fetchWarnings(language: String = "en") async throws -> [WeatherWarning] {
        let endpoint = endpointURL(language: language)
        let (data, response) = try await session.data(from: endpoint)
        
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw WeatherWarningServiceError.invalidResponse
        }
        
        let payload = try decoder.decode(HKOWarningSummary.self, from: data)
        
        // Convert to WeatherWarning array
        return payload.warnings.map { warning in
            WeatherWarning(
                code: warning.code,
                name: warning.name,
                actionCode: warning.actionCode,
                issueTime: warning.issueTime,
                updateTime: warning.updateTime
            )
        }
    }
}

enum WeatherWarningServiceError: Error {
    case invalidResponse
    case decodingError
}

// MARK: - Data Models

struct WeatherWarning: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let actionCode: String
    let issueTime: String
    let updateTime: String
    
    var isActive: Bool {
        actionCode == "ISSUE" || actionCode == "EXTEND"
    }
    
    var severity: TrailAlert.Severity {
        // Map warning codes to severity
        if code.contains("8") || code.contains("9") || code.contains("10") {
            return .critical
        } else if code.contains("3") || code.contains("7") {
            return .high
        } else if code.contains("AMBER") || code.contains("YELLOW") {
            return .medium
        }
        return .medium
    }
}

// MARK: - DTOs

struct HKOWarningSummary: Decodable {
    // The API returns a dictionary where keys are warning codes
    // We need to decode this dynamically
    private struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init?(intValue: Int) {
            return nil
        }
    }
    
    let warnings: [HKOWarning]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var warnings: [HKOWarning] = []
        
        for key in container.allKeys {
            if let warning = try? container.decode(HKOWarning.self, forKey: key) {
                warnings.append(warning)
            }
        }
        
        self.warnings = warnings
    }
}

struct HKOWarning: Decodable {
    let name: String
    let code: String
    let actionCode: String
    let issueTime: String
    let updateTime: String
}

