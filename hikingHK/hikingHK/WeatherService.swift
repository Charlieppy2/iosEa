//
//  WeatherService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

protocol WeatherServiceProtocol {
    func fetchSnapshot() async throws -> WeatherSnapshot
}

struct WeatherService: WeatherServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let endpoint = URL(string: "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang=en")!

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func fetchSnapshot() async throws -> WeatherSnapshot {
        let (data, response) = try await session.data(from: endpoint)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw WeatherServiceError.invalidResponse
        }
        let payload = try decoder.decode(HKORealTimeWeather.self, from: data)
        guard let temperatureEntry = payload.temperature.data.first,
              let temperature = temperatureEntry.value,
              let humidityEntry = payload.humidity.data.first,
              let humidityValue = humidityEntry.value
        else {
            throw WeatherServiceError.missingKeyFields
        }

        let uvIndex = payload.uvindex?.data?.compactMap { Int($0.value ?? "") }.first ?? 0
        let warningMessage = payload.warningMessage?.filter { !$0.isEmpty }.joined(separator: "\n")
        let suggestion = WeatherSuggestionBuilder.suggestion(
            uvIndex: uvIndex,
            humidity: Int(humidityValue),
            hasWarning: warningMessage != nil
        )

        return WeatherSnapshot(
            location: temperatureEntry.place,
            temperature: temperature,
            humidity: Int(humidityValue),
            uvIndex: uvIndex,
            warningMessage: warningMessage,
            suggestion: suggestion,
            updatedAt: Date()
        )
    }
}

enum WeatherServiceError: Error {
    case invalidResponse
    case missingKeyFields
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
}

struct WeatherDataset: Decodable {
    let data: [WeatherEntry]
}

struct WeatherEntry: Decodable {
    let place: String
    let value: Double?
    let unit: String?
    let recordTime: String?
}

struct UVIndexDataset: Decodable {
    let data: [UVIndexEntry]?
}

struct UVIndexEntry: Decodable {
    let place: String?
    let value: String?
    let recordTime: String?
}

