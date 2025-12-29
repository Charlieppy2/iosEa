//
//  APIConnectionChecker.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import Combine

/// Centralized helper that checks connectivity for all external APIs used by the app.
@MainActor
class APIConnectionChecker: ObservableObject {
    @Published var weatherAPIStatus: ConnectionStatus = .checking
    @Published var weatherWarningAPIStatus: ConnectionStatus = .checking
    @Published var mapboxAPIStatus: ConnectionStatus = .notConfigured
    @Published var lastCheckTime: Date?
    
    /// Possible connection states for an external service.
    enum ConnectionStatus {
        case checking
        case connected
        case disconnected
        case notConfigured
        case error(String)
        
        /// Simple English description for debugging and logs.
        var description: String {
            switch self {
            case .checking: return "Checking..."
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .notConfigured: return "Not Configured"
            case .error(let message): return "Error: \(message)"
            }
        }
        
        /// Localized human-readable description for displaying in the UI.
        func localizedDescription(languageManager: LanguageManager) -> String {
            switch self {
            case .checking: return languageManager.localizedString(for: "api.status.checking")
            case .connected: return languageManager.localizedString(for: "api.status.connected")
            case .disconnected: return languageManager.localizedString(for: "api.status.disconnected")
            case .notConfigured: return languageManager.localizedString(for: "api.status.not.configured")
            case .error(let message): return "\(languageManager.localizedString(for: "api.status.error")): \(message)"
            }
        }
        
        /// SF Symbol name representing the connection state.
        var icon: String {
            switch self {
            case .checking: return "hourglass"
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "xmark.circle.fill"
            case .notConfigured: return "exclamationmark.triangle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
        
        /// Basic color keyword that can be mapped to UI colors.
        var color: String {
            switch self {
            case .checking: return "orange"
            case .connected: return "green"
            case .disconnected: return "red"
            case .notConfigured: return "gray"
            case .error: return "red"
            }
        }
    }
    
    /// Checks all configured APIs and records the time of the last check.
    func checkAllAPIs() async {
        await checkWeatherAPI()
        await checkWeatherWarningAPI()
        checkMapboxAPI()
        lastCheckTime = Date()
    }
    
    /// Checks the HK Observatory real-time weather API.
    func checkWeatherAPI() async {
        weatherAPIStatus = .checking
        
        let endpoint = URL(string: "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang=en")!
        
        do {
            let (_, response) = try await URLSession.shared.data(from: endpoint)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200..<300).contains(httpResponse.statusCode) {
                    weatherAPIStatus = .connected
                } else {
                    weatherAPIStatus = .error("HTTP \(httpResponse.statusCode)")
                }
            } else {
                weatherAPIStatus = .disconnected
            }
        } catch {
            weatherAPIStatus = .error(error.localizedDescription)
        }
    }
    
    /// Checks the HK Observatory weather warning summary API.
    func checkWeatherWarningAPI() async {
        weatherWarningAPIStatus = .checking
        
        let endpoint = URL(string: "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warnsum&lang=en")!
        
        do {
            let (_, response) = try await URLSession.shared.data(from: endpoint)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200..<300).contains(httpResponse.statusCode) {
                    weatherWarningAPIStatus = .connected
                } else {
                    weatherWarningAPIStatus = .error("HTTP \(httpResponse.statusCode)")
                }
            } else {
                weatherWarningAPIStatus = .disconnected
            }
        } catch {
            weatherWarningAPIStatus = .error(error.localizedDescription)
        }
    }
    
    
    /// Validates whether the Mapbox access token is present (but does not perform a live request).
    func checkMapboxAPI() {
        let accessToken = ProcessInfo.processInfo.environment["MAPBOX_ACCESS_TOKEN"] ?? ""
        if accessToken.isEmpty {
            mapboxAPIStatus = .notConfigured
        } else {
            // Mapbox is configured, but we don't test the connection here
            // as it requires actual coordinates
            mapboxAPIStatus = .connected
        }
    }
}

