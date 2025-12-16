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

        // Initial weather fetch will use saved language preference or default to "en"
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        Task { await refreshWeather(language: savedLanguage) }
    }

    func configurePersistenceIfNeeded(context: ModelContext) {
        guard trailDataStore == nil else { return }
        let store = TrailDataStore(context: context)
        trailDataStore = store
        reloadUserData()
    }
    
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

    func markFavorite(_ trail: Trail) {
        guard let index = trails.firstIndex(of: trail) else {
            print("⚠️ AppViewModel: Trail not found in array")
            return
        }
        
        // 因为 Trail 是 struct（值类型），需要创建新的实例
        var updatedTrail = trails[index]
        updatedTrail.isFavorite.toggle()
        trails[index] = updatedTrail
        
        // 如果这是 featured trail，也需要更新
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

    func addSavedHike(for trail: Trail, scheduledDate: Date, note: String = "") {
        let newHike = SavedHike(trail: trail, scheduledDate: scheduledDate, note: note)
        savedHikes.insert(newHike, at: 0)
        sortSavedHikes()
        do {
            try trailDataStore?.save(newHike)
        } catch {
            print("Save hike persistence error: \(error)")
        }
    }

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
            // 根据错误类型提供更详细的信息
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
            
            // 保留缓存数据，但显示错误信息
            weatherError = "Unable to load latest weather. Showing cached data."
            print("⚠️ AppViewModel: Using cached weather data due to error: \(errorMessage)")
        } catch {
            // 其他未知错误
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

