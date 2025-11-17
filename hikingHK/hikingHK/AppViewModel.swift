//
//  AppViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var trails: [Trail]
    @Published var featuredTrail: Trail?
    @Published var highlightedDistrict: String = "Sai Kung"
    @Published var weatherSnapshot: WeatherSnapshot
    @Published var weatherError: String?
    @Published var isLoadingWeather = false
    @Published var savedHikes: [SavedHike]

    private let weatherService: WeatherServiceProtocol

    init(
        trails: [Trail],
        weatherSnapshot: WeatherSnapshot,
        savedHikes: [SavedHike],
        weatherService: WeatherServiceProtocol
    ) {
        self.trails = trails
        self.weatherSnapshot = weatherSnapshot
        self.savedHikes = savedHikes
        self.featuredTrail = trails.first
        self.weatherService = weatherService

        Task { await refreshWeather() }
    }

    func markFavorite(_ trail: Trail) {
        guard let index = trails.firstIndex(of: trail) else { return }
        trails[index].isFavorite.toggle()
    }

    func addSavedHike(for trail: Trail, scheduledDate: Date) {
        let newHike = SavedHike(trail: trail, scheduledDate: scheduledDate)
        savedHikes.insert(newHike, at: 0)
    }

    func trails(for difficulty: Trail.Difficulty?) -> [Trail] {
        guard let difficulty else { return trails }
        return trails.filter { $0.difficulty == difficulty }
    }

    func refreshWeather() async {
        isLoadingWeather = true
        defer { isLoadingWeather = false }
        do {
            let snapshot = try await weatherService.fetchSnapshot()
            weatherSnapshot = snapshot
            weatherError = nil
        } catch {
            weatherError = "Unable to load latest weather. Showing cached data."
            print("Weather fetch error: \(error)")
        }
    }
}

extension AppViewModel {
    convenience init(weatherService: WeatherServiceProtocol = WeatherService()) {
        self.init(
            trails: Trail.sampleData,
            weatherSnapshot: .hongKongMorning,
            savedHikes: SavedHike.sampleData,
            weatherService: weatherService
        )
    }
}

