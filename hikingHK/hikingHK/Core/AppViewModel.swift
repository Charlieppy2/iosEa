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
    /// All available trails currently loaded into the app.
    @Published private(set) var trails: [Trail]
    /// Trail highlighted on the home screen.
    @Published var featuredTrail: Trail?
    @Published var highlightedDistrict: String = "Sai Kung"
    /// Latest snapshot of real-time weather used across the app.
    @Published var weatherSnapshot: WeatherSnapshot
    @Published var weatherError: String?
    @Published var isLoadingWeather = false
    /// Planned or completed hikes saved by the user.
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

        // Initial weather fetch will use saved language preference or default to "en"
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        Task { await refreshWeather(language: savedLanguage) }
    }

    /// Lazily sets up the backing `TrailDataStore` and loads any user-specific data.
    func configurePersistenceIfNeeded(context: ModelContext) {
        guard trailDataStore == nil else { return }
        let store = TrailDataStore(context: context)
        trailDataStore = store
        reloadUserData()
    }
    
    /// Reloads favorites and saved hikes from persistent storage.
    func reloadUserData() {
        guard let store = trailDataStore else {
            print("⚠️ AppViewModel: TrailDataStore not configured, cannot reload data")
            return
        }
        
        print("🔄 AppViewModel: Reloading user data...")
        do {
            try applyFavorites(ids: store.loadFavoriteTrailIds())
            savedHikes = try store.loadSavedHikes(trails: trails)
            sortSavedHikes()
            objectWillChange.send()
            print("✅ AppViewModel: User data reloaded successfully")
        } catch {
            print("❌ AppViewModel: Trail data load error: \(error)")
        }
    }

    /// Toggles the favorite state for a given trail and persists the change.
    func markFavorite(_ trail: Trail) {
        guard let index = trails.firstIndex(of: trail) else {
            print("⚠️ AppViewModel: Trail not found in array")
            return
        }
        
        // Trail is a struct (value type), so we need to create a new instance
        var updatedTrail = trails[index]
        updatedTrail.isFavorite.toggle()
        trails[index] = updatedTrail
        
        // If this is also the featured trail, keep the featured copy in sync
        if featuredTrail?.id == trail.id {
            featuredTrail = updatedTrail
        }
        
        print("✅ AppViewModel: Toggled favorite for trail \(trail.name), isFavorite: \(updatedTrail.isFavorite)")
        
        do {
            try trailDataStore?.setFavorite(updatedTrail.isFavorite, trailId: trail.id)
            print("✅ AppViewModel: Favorite status saved to database")
        } catch {
            print("❌ Favorite persistence error: \(error)")
        }
    }

    /// Adds a new planned hike for the given trail and date.
    func addSavedHike(for trail: Trail, scheduledDate: Date, note: String = "") {
        let newHike = SavedHike(trail: trail, scheduledDate: scheduledDate, note: note)
        savedHikes.insert(newHike, at: 0)
        sortSavedHikes()
        do {
            try trailDataStore?.save(newHike)
            objectWillChange.send()
            print("✅ AppViewModel: Saved hike '\(trail.name)' scheduled for \(scheduledDate.formatted(date: .abbreviated, time: .omitted))")
        } catch {
            print("❌ AppViewModel: Save hike persistence error: \(error)")
            // Remove from array if save failed
            savedHikes.removeAll { $0.id == newHike.id }
        }
    }

    /// Updates an existing saved hike and re-sorts the list.
    func updateSavedHike(
        _ hike: SavedHike,
        scheduledDate: Date,
        note: String,
        isCompleted: Bool,
        completedAt: Date?
    ) {
        guard let index = savedHikes.firstIndex(where: { $0.id == hike.id }) else { return }
        savedHikes[index].scheduledDate = scheduledDate
        savedHikes[index].note = note
        savedHikes[index].isCompleted = isCompleted
        savedHikes[index].completedAt = isCompleted ? (completedAt ?? savedHikes[index].completedAt ?? Date()) : nil
        sortSavedHikes()
        objectWillChange.send() // Ensure UI updates
        do {
            try trailDataStore?.save(savedHikes[index])
            print("✅ AppViewModel: Updated saved hike '\(savedHikes[index].trail.name)' (ID: \(savedHikes[index].id)), isCompleted: \(isCompleted)")
        } catch {
            print("❌ AppViewModel: Update hike persistence error: \(error)")
        }
    }

    /// Removes a saved hike from both memory and persistent storage.
    func removeSavedHike(_ hike: SavedHike) {
        savedHikes.removeAll { $0.id == hike.id }
        do {
            try trailDataStore?.delete(hike)
        } catch {
            print("Delete hike persistence error: \(error)")
        }
    }

    /// Returns trails filtered by difficulty, or all trails when `difficulty` is nil.
    func trails(for difficulty: Trail.Difficulty?) -> [Trail] {
        guard let difficulty else { return trails }
        return trails.filter { $0.difficulty == difficulty }
    }

    /// Refreshes the real-time weather snapshot for the given language code.
    /// Keeps the last successful snapshot as a cache if loading fails.
    func refreshWeather(language: String = "en") async {
        isLoadingWeather = true
        defer { isLoadingWeather = false }
        
        print("🌤️ AppViewModel: Refreshing weather (language: \(language))")
        
        do {
            let snapshot = try await weatherService.fetchSnapshot(language: language)
            weatherSnapshot = snapshot
            weatherError = nil
            print("✅ AppViewModel: Weather refreshed successfully")
        } catch let error as WeatherServiceError {
            // Provide more detailed information based on the specific error type
            let errorMessage: String
            switch error {
            case .networkError(let urlError):
                errorMessage = "Network error: \(urlError.localizedDescription)"
                print("❌ AppViewModel: Network error - \(urlError.localizedDescription)")
            case .decodingError(let decodingError):
                errorMessage = "Data parsing error: \(decodingError.localizedDescription)"
                print("❌ AppViewModel: Decoding error - \(decodingError.localizedDescription)")
            case .invalidResponse:
                errorMessage = "Invalid response from weather API"
                print("❌ AppViewModel: Invalid response")
            case .missingKeyFields:
                errorMessage = "Missing required weather data"
                print("❌ AppViewModel: Missing key fields")
            }
            
            // Keep the cached snapshot but surface an error message to the user
            weatherError = "Unable to load latest weather. Showing cached data."
            print("⚠️ AppViewModel: Using cached weather data due to error: \(errorMessage)")
        } catch {
            // Any other unknown error
            weatherError = "Unable to load latest weather. Showing cached data."
            print("❌ AppViewModel: Unknown error - \(error.localizedDescription)")
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

    private func sortSavedHikes() {
        savedHikes.sort { lhs, rhs in
            if lhs.isCompleted == rhs.isCompleted {
                return lhs.scheduledDate < rhs.scheduledDate
            }
            return !lhs.isCompleted && rhs.isCompleted
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

