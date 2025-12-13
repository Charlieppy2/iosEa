//
//  TrailAlertsService.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

protocol TrailAlertsServiceProtocol {
    func fetchAlerts(language: String) async throws -> [TrailAlert]
}

struct TrailAlertsService: TrailAlertsServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let warningService: WeatherWarningServiceProtocol
    private let baseWeatherEndpoint = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang="
    
    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        warningService: WeatherWarningServiceProtocol = WeatherWarningService()
    ) {
        self.session = session
        self.decoder = decoder
        self.warningService = warningService
    }
    
    private func weatherEndpointURL(language: String) -> URL {
        let langCode = language == "zh-Hant" ? "tc" : "en"
        return URL(string: "\(baseWeatherEndpoint)\(langCode)")!
    }
    
    func fetchAlerts(language: String = "en") async throws -> [TrailAlert] {
        var alerts: [TrailAlert] = []
        
        // Fetch weather warnings from warnsum API
        do {
            let warnings = try await warningService.fetchWarnings(language: language)
            
            for warning in warnings where warning.isActive {
                let issueDate = parseDate(warning.issueTime) ?? Date()
                alerts.append(TrailAlert(
                    id: UUID(),
                    title: warning.name,
                    detail: "\(warning.name) (\(warning.code))",
                    category: .weather,
                    severity: warning.severity,
                    issuedAt: issueDate,
                    expiresAt: nil
                ))
            }
        } catch {
            print("Failed to fetch weather warnings: \(error)")
        }
        
        // Also fetch from rhrread API for additional warnings
        do {
            let endpoint = weatherEndpointURL(language: language)
            let (data, response) = try await session.data(from: endpoint)
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                throw TrailAlertsServiceError.invalidResponse
            }
            
            let payload = try decoder.decode(HKORealTimeWeather.self, from: data)
            
            // Convert weather warnings to trail alerts (if not already added from warnsum)
            if let warningMessages = payload.warningMessage, !warningMessages.isEmpty {
                for warning in warningMessages.filter({ !$0.isEmpty }) {
                    // Check if this warning is already in alerts
                    let alreadyExists = alerts.contains { $0.detail.contains(warning) }
                    if !alreadyExists {
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
            print("Failed to fetch weather alerts from rhrread: \(error)")
        }
        
        // Add static route maintenance alerts (could be replaced with actual data source)
        alerts.append(contentsOf: getStaticAlerts())
        
        return alerts
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: dateString)
        }()
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

