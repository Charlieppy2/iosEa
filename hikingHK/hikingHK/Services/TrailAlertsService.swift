//
//  TrailAlertsService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

protocol TrailAlertsServiceProtocol {
    func fetchAlerts() async throws -> [TrailAlert]
}

struct TrailAlertsService: TrailAlertsServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let weatherEndpoint = URL(string: "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang=en")!
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    func fetchAlerts() async throws -> [TrailAlert] {
        var alerts: [TrailAlert] = []
        
        // Fetch weather warnings from HKO API
        do {
            let (data, response) = try await session.data(from: weatherEndpoint)
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                throw TrailAlertsServiceError.invalidResponse
            }
            
            let payload = try decoder.decode(HKORealTimeWeather.self, from: data)
            
            // Convert weather warnings to trail alerts
            if let warnings = payload.warningMessage, !warnings.isEmpty {
                for warning in warnings.filter({ !$0.isEmpty }) {
                    alerts.append(TrailAlert(
                        id: UUID(),
                        title: parseWarningTitle(warning),
                        detail: warning,
                        category: .weather,
                        severity: determineSeverity(warning),
                        issuedAt: Date(),
                        expiresAt: nil
                    ))
                }
            }
            
            // Add UV index alerts
            if let uvIndex = payload.uvindex?.data?.compactMap({ Int($0.value ?? "") }).first, uvIndex >= 8 {
                alerts.append(TrailAlert(
                    id: UUID(),
                    title: "High UV Index",
                    detail: "UV Index is \(uvIndex). Extreme UV levels detected. Start pre-dawn and bring SPF/umbrella.",
                    category: .weather,
                    severity: .high,
                    issuedAt: Date(),
                    expiresAt: nil
                ))
            }
            
        } catch {
            // If API fails, return empty array (don't throw to allow app to continue)
            print("Failed to fetch weather alerts: \(error)")
        }
        
        // Add static route maintenance alerts (could be replaced with actual data source)
        alerts.append(contentsOf: getStaticAlerts())
        
        return alerts
    }
    
    private func parseWarningTitle(_ warning: String) -> String {
        // Parse common warning types
        let lowercased = warning.lowercased()
        if lowercased.contains("typhoon") || lowercased.contains("tropical cyclone") {
            return "Typhoon Warning"
        } else if lowercased.contains("rain") || lowercased.contains("thunderstorm") {
            return "Rain Warning"
        } else if lowercased.contains("monsoon") {
            return "Monsoon Signal"
        } else if lowercased.contains("heat") {
            return "Heat Advisory"
        } else if lowercased.contains("cold") {
            return "Cold Weather Warning"
        } else if lowercased.contains("frost") {
            return "Frost Warning"
        } else if lowercased.contains("fire") {
            return "Fire Danger Warning"
        }
        return "Weather Warning"
    }
    
    private func determineSeverity(_ warning: String) -> TrailAlert.Severity {
        let lowercased = warning.lowercased()
        if lowercased.contains("signal no. 8") || lowercased.contains("signal no. 9") || lowercased.contains("signal no. 10") {
            return .critical
        } else if lowercased.contains("signal no. 3") || lowercased.contains("signal no. 7") {
            return .high
        } else if lowercased.contains("amber") || lowercased.contains("yellow") {
            return .medium
        }
        return .medium
    }
    
    private func getStaticAlerts() -> [TrailAlert] {
        // Static route maintenance alerts
        // In the future, this could come from a government API or user reports
        return [
            TrailAlert(
                id: UUID(),
                title: "Route Maintenance",
                detail: "Section 2 of MacLehose Trail is partially closed near Long Ke due to slope works. Alternative route available.",
                category: .maintenance,
                severity: .medium,
                issuedAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                expiresAt: Date().addingTimeInterval(86400 * 5) // 5 days from now
            )
        ]
    }
}

enum TrailAlertsServiceError: Error {
    case invalidResponse
    case decodingError
}

