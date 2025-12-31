//
//  AppViewModel.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
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
    /// All available weather snapshots for different locations.
    @Published var weatherSnapshots: [WeatherSnapshot] = []
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
        self.weatherSnapshots = [weatherSnapshot] // Initialize with single snapshot
        self.savedHikes = savedHikes
        self.featuredTrail = trails.first
        self.weatherService = weatherService

        // Initial weather fetch will use saved language preference or default to "en"
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        Task { await refreshWeather(language: savedLanguage) }
    }

    /// Lazily sets up the backing `TrailDataStore`.
    /// Note: After calling this, you should call `reloadUserData(accountId:)` separately with the user's accountId.
    func configurePersistenceIfNeeded(context: ModelContext) {
        guard trailDataStore == nil else { return }
        let store = TrailDataStore(context: context)
        trailDataStore = store
    }
    
    /// Reloads favorites and saved hikes from persistent storage.
    /// - Parameter accountId: The user account ID to filter data for the current user.
    func reloadUserData(accountId: UUID) {
        guard let store = trailDataStore else {
            print("⚠️ AppViewModel: TrailDataStore not configured, cannot reload data")
            return
        }
        
        print("🔄 AppViewModel: Reloading user data for account: \(accountId)...")
        do {
            try applyFavorites(ids: store.loadFavoriteTrailIds(accountId: accountId))
            savedHikes = try store.loadSavedHikes(trails: trails, accountId: accountId)
            sortSavedHikes()
            objectWillChange.send()
            print("✅ AppViewModel: User data reloaded successfully")
        } catch {
            print("❌ AppViewModel: Trail data load error: \(error)")
        }
    }

    /// Toggles the favorite state for a given trail and persists the change.
    /// - Parameters:
    ///   - trail: The trail to toggle favorite status for.
    ///   - accountId: The user account ID to associate this favorite with.
    func markFavorite(_ trail: Trail, accountId: UUID) {
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
            try trailDataStore?.setFavorite(updatedTrail.isFavorite, trailId: trail.id, accountId: accountId)
            print("✅ AppViewModel: Favorite status saved to database")
        } catch {
            print("❌ Favorite persistence error: \(error)")
        }
    }

    /// Adds a new planned hike for the given trail and date.
    /// - Parameters:
    ///   - trail: The trail to plan a hike for.
    ///   - scheduledDate: The scheduled date for the hike.
    ///   - note: Optional note for the hike.
    ///   - accountId: The user account ID to associate this hike with.
    func addSavedHike(for trail: Trail, scheduledDate: Date, note: String = "", accountId: UUID) {
        let newHike = SavedHike(trail: trail, scheduledDate: scheduledDate, note: note)
        // Insert at the beginning to show newest first (before sorting)
        savedHikes.insert(newHike, at: 0)
        
        do {
            try trailDataStore?.save(newHike, accountId: accountId)
            // After saving, sort to ensure completed hikes are at bottom, but keep newest incomplete at top
            sortSavedHikesWithNewestFirst()
            objectWillChange.send()
            print("✅ AppViewModel: Saved hike '\(trail.name)' scheduled for \(scheduledDate.formatted(date: .abbreviated, time: .omitted))")
        } catch {
            print("❌ AppViewModel: Save hike persistence error: \(error)")
            // Remove from array if save failed
            savedHikes.removeAll { $0.id == newHike.id }
        }
    }

    /// Updates an existing saved hike and re-sorts the list.
    /// - Parameters:
    ///   - hike: The hike to update.
    ///   - scheduledDate: The new scheduled date.
    ///   - note: The new note.
    ///   - isCompleted: Whether the hike is completed.
    ///   - completedAt: The completion date.
    ///   - accountId: The user account ID to ensure only the owner can update.
    func updateSavedHike(
        _ hike: SavedHike,
        scheduledDate: Date,
        note: String,
        isCompleted: Bool,
        completedAt: Date?,
        accountId: UUID
    ) {
        guard let index = savedHikes.firstIndex(where: { $0.id == hike.id }) else { return }
        savedHikes[index].scheduledDate = scheduledDate
        savedHikes[index].note = note
        savedHikes[index].isCompleted = isCompleted
        savedHikes[index].completedAt = isCompleted ? (completedAt ?? savedHikes[index].completedAt ?? Date()) : nil
        sortSavedHikes()
        objectWillChange.send() // Ensure UI updates
        do {
            try trailDataStore?.save(savedHikes[index], accountId: accountId)
            print("✅ AppViewModel: Updated saved hike '\(savedHikes[index].trail.name)' (ID: \(savedHikes[index].id)), isCompleted: \(isCompleted)")
        } catch {
            print("❌ AppViewModel: Update hike persistence error: \(error)")
        }
    }

    /// Removes a saved hike from both memory and persistent storage.
    /// - Parameters:
    ///   - hike: The hike to remove.
    ///   - accountId: The user account ID to ensure only the owner can delete.
    func removeSavedHike(_ hike: SavedHike, accountId: UUID) {
        let trailId = hike.trail.id
        
        // 1. 先从「即將計劃」中移除這條計劃
        savedHikes.removeAll { $0.id == hike.id }
        
        // 2. 如果這條路線已經沒有任何計劃了，同步取消收藏狀態
        let stillHasPlansForTrail = savedHikes.contains { $0.trail.id == trailId }
        if !stillHasPlansForTrail {
            if let index = trails.firstIndex(where: { $0.id == trailId }) {
                var updatedTrail = trails[index]
                if updatedTrail.isFavorite {
                    updatedTrail.isFavorite = false
                    trails[index] = updatedTrail
                    
                    // 如果這也是精選路線，保持 featuredTrail 一致
                    if featuredTrail?.id == trailId {
                        featuredTrail = updatedTrail
                    }
                    
                    do {
                        try trailDataStore?.setFavorite(false, trailId: trailId, accountId: accountId)
                        print("✅ AppViewModel: Unfavorited trail '\(updatedTrail.name)' after deleting its last plan")
                    } catch {
                        print("❌ AppViewModel: Failed to unfavorite trail after deleting plan: \(error)")
                    }
                }
            }
        }
        
        do {
            try trailDataStore?.delete(hike, accountId: accountId)
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
            // Fetch all locations for swipeable weather cards
            let snapshots = try await weatherService.fetchSnapshotsForAllLocations(language: language)
            if !snapshots.isEmpty {
                weatherSnapshots = snapshots
                // Set the first snapshot as the default (or prefer Hong Kong Observatory)
                if let hkoIndex = snapshots.firstIndex(where: { $0.location == "Hong Kong Observatory" }) {
                    weatherSnapshot = snapshots[hkoIndex]
                } else {
                    weatherSnapshot = snapshots.first ?? weatherSnapshot
                }
            } else {
                // Fallback to single snapshot if multi-location fetch fails
                let snapshot = try await weatherService.fetchSnapshot(language: language)
                weatherSnapshot = snapshot
                weatherSnapshots = [snapshot]
            }
            weatherError = nil
            print("✅ AppViewModel: Weather refreshed successfully for \(weatherSnapshots.count) locations")
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
        // Always update all trails' favorite status, even if ids is empty
        // This ensures that trails that were previously favorited but are now unfavorited
        // will have their isFavorite set to false
        trails = trails.map { trail in
            var mutableTrail = trail
            mutableTrail.isFavorite = ids.contains(trail.id)
            return mutableTrail
        }
        
        // Update featuredTrail to match the updated trail in the trails array
        if let featuredId = featuredTrail?.id,
           let updatedTrail = trails.first(where: { $0.id == featuredId }) {
            featuredTrail = updatedTrail
        } else if featuredTrail == nil {
            // If featuredTrail is nil, set it to the first trail
            featuredTrail = trails.first
        }
    }

    private func sortSavedHikes() {
        savedHikes.sort { lhs, rhs in
            if lhs.isCompleted == rhs.isCompleted {
                return lhs.scheduledDate < rhs.scheduledDate
            }
            return !lhs.isCompleted && rhs.isCompleted
        }
    }
    
    /// Sorts saved hikes with newest incomplete hikes at the top
    /// This ensures newly added plans appear first
    private func sortSavedHikesWithNewestFirst() {
        // Separate completed and incomplete hikes
        var incomplete = savedHikes.filter { !$0.isCompleted }
        let completed = savedHikes.filter { $0.isCompleted }
        
        // For incomplete hikes, maintain insertion order (newest first)
        // Since we insert at index 0, the array is already in reverse insertion order
        // So we reverse it to get newest first
        incomplete.reverse()
        
        // Sort completed hikes by completion date (newest first)
        let sortedCompleted = completed.sorted { lhs, rhs in
            let lhsDate = lhs.completedAt ?? lhs.scheduledDate
            let rhsDate = rhs.completedAt ?? rhs.scheduledDate
            return lhsDate > rhsDate
        }
        
        // Combine: incomplete first (newest at top), then completed
        savedHikes = incomplete + sortedCompleted
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

