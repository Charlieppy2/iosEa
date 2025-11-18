//
//  WeatherForecastViewModel.swift
//  hikingHK
//
//  Created for weather forecast functionality
//

import Foundation
import Combine

@MainActor
final class WeatherForecastViewModel: ObservableObject {
    @Published var forecast: WeatherForecast?
    @Published var isLoading = false
    @Published var error: String?
    
    private let forecastService: WeatherForecastServiceProtocol
    
    init(forecastService: WeatherForecastServiceProtocol = WeatherForecastService()) {
        self.forecastService = forecastService
    }
    
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

