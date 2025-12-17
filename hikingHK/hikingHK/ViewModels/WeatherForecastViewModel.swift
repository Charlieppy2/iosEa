//
//  WeatherForecastViewModel.swift
//  hikingHK
//
//  Created for weather forecast functionality
//

import Foundation
import Combine

/// View model responsible for loading and exposing the weather forecast
/// for display in the UI.
@MainActor
final class WeatherForecastViewModel: ObservableObject {
    @Published var forecast: WeatherForecast?
    @Published var isLoading = false
    @Published var error: String?
    
    private let forecastService: WeatherForecastServiceProtocol
    
    /// Creates a new weather forecast view model with an injectable service (useful for testing).
    init(forecastService: WeatherForecastServiceProtocol = WeatherForecastService()) {
        self.forecastService = forecastService
    }
    
    /// Loads the latest weather forecast from the backend service.
    func loadForecast() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            forecast = try await forecastService.fetchForecast()
        } catch {
            self.error = "Failed to load weather forecast. Please try again later."
            print("Weather forecast error: \(error)")
        }
    }
}

