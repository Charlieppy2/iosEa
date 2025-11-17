//
//  AppViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import Combine
import SwiftData

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
    private var trailDataStore: TrailDataStore?

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

    func configurePersistenceIfNeeded(context: ModelContext) {
        guard trailDataStore == nil else { return }
        let store = TrailDataStore(context: context)
        trailDataStore = store
        do {
            try applyFavorites(ids: store.loadFavoriteTrailIds())
            savedHikes = try store.loadSavedHikes(trails: trails)
        } catch {
            print("Trail data load error: \(error)")
        }
    }

    func markFavorite(_ trail: Trail) {
        guard let index = trails.firstIndex(of: trail) else { return }
        trails[index].isFavorite.toggle()
        do {
            try trailDataStore?.setFavorite(trails[index].isFavorite, trailId: trail.id)
        } catch {
            print("Favorite persistence error: \(error)")
        }
    }

    func addSavedHike(for trail: Trail, scheduledDate: Date, note: String = "") {
        let newHike = SavedHike(trail: trail, scheduledDate: scheduledDate, note: note)
        savedHikes.insert(newHike, at: 0)
        do {
            try trailDataStore?.save(newHike)
        } catch {
            print("Save hike persistence error: \(error)")
        }
    }

    func updateSavedHike(_ hike: SavedHike, scheduledDate: Date, note: String) {
        guard let index = savedHikes.firstIndex(where: { $0.id == hike.id }) else { return }
        savedHikes[index].scheduledDate = scheduledDate
        savedHikes[index].note = note
        do {
            try trailDataStore?.save(savedHikes[index])
        } catch {
            print("Update hike persistence error: \(error)")
        }
    }

    func removeSavedHike(_ hike: SavedHike) {
        savedHikes.removeAll { $0.id == hike.id }
        do {
            try trailDataStore?.delete(hike)
        } catch {
            print("Delete hike persistence error: \(error)")
        }
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

    private func applyFavorites(ids: Set<UUID>) throws {
        guard !ids.isEmpty else { return }
        trails = trails.map { trail in
            var mutableTrail = trail
            mutableTrail.isFavorite = ids.contains(trail.id)
            return mutableTrail
        }
        featuredTrail = trails.first
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

