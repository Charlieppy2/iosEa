//
//  APIConnectionChecker.swift
//  hikingHK
//
//  Created to check API connection status
//

import Foundation
import Combine

@MainActor
class APIConnectionChecker: ObservableObject {
    @Published var weatherAPIStatus: ConnectionStatus = .checking
    @Published var mapboxAPIStatus: ConnectionStatus = .notConfigured
    @Published var lastCheckTime: Date?
    
    enum ConnectionStatus {
        case checking
        case connected
        case disconnected
        case notConfigured
        case error(String)
        
        var description: String {
            switch self {
            case .checking: return "Checking..."
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .notConfigured: return "Not Configured"
            case .error(let message): return "Error: \(message)"
            }
        }
        
        var icon: String {
            switch self {
            case .checking: return "hourglass"
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "xmark.circle.fill"
            case .notConfigured: return "exclamationmark.triangle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
        
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
    
    func checkAllAPIs() async {
        await checkWeatherAPI()
        checkMapboxAPI()
        lastCheckTime = Date()
    }
    
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

