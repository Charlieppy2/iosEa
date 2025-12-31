//
//  TrailRecommendationViewModel.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData
import Combine

/// View model for generating personalized trail recommendations
/// based on user preferences, weather, time availability, and hike history.
@MainActor
final class TrailRecommendationViewModel: ObservableObject {
    @Published var recommendations: [TrailRecommendation] = []
    @Published var userPreference: UserPreference?
    @Published var isLoading: Bool = false
    @Published var error: String?
    /// Available time for hiking in seconds (used to filter and score recommendations).
    @Published var availableTime: TimeInterval?
    
    private var store: RecommendationStore?
    private var modelContext: ModelContext?
    private let recommendationService: TrailRecommendationServiceProtocol
    private let appViewModel: AppViewModel
    
    /// Creates a new recommendation view model with the shared `AppViewModel`
    /// and an injectable recommendation service (useful for testing).
    init(
        appViewModel: AppViewModel,
        recommendationService: TrailRecommendationServiceProtocol = TrailRecommendationService()
    ) {
        self.appViewModel = appViewModel
        self.recommendationService = recommendationService
    }
    
    /// Lazily configures the underlying `RecommendationStore`
    /// and loads or creates the user's preference model.
    /// - Parameters:
    ///   - context: The SwiftData model context.
    ///   - accountId: The user account ID to load preferences for.
    func configureIfNeeded(context: ModelContext, accountId: UUID) {
        guard store == nil else { return }
        self.modelContext = context
        store = RecommendationStore(context: context)
        
        // Load existing user preferences; create a default one if missing.
        do {
            userPreference = try store?.loadUserPreference(accountId: accountId)
            if userPreference == nil {
                // Create a default preference if none exists yet.
                userPreference = UserPreference(accountId: accountId)
            }
        } catch {
            self.error = "Failed to load user preferences: \(error.localizedDescription)"
        }
    }
    
    /// Generates trail recommendations for the current user context.
    /// - Parameters:
    ///   - availableTime: Optional time budget in seconds for the hike.
    ///   - accountId: The user account ID to load history for.
    func generateRecommendations(availableTime: TimeInterval? = nil, accountId: UUID) async {
        guard let store = store else { return }
        
        isLoading = true
        error = nil
        self.availableTime = availableTime
        
        defer { isLoading = false }
        
        // Load the user's hike history if a SwiftData context is available.
        let history: [HikeRecord]
        if let context = modelContext {
            do {
                let recordStore = HikeRecordStore(context: context)
                history = try recordStore.loadAllRecords(accountId: accountId)
            } catch {
                history = []
            }
        } else {
            history = []
        }
        
        // Load recommendation history for machine learning
        let recommendationHistory: [RecommendationRecord]?
        do {
            recommendationHistory = try store.loadRecommendationHistory(accountId: accountId)
        } catch {
            recommendationHistory = nil
        }
        
        // Ask the recommendation service to produce a ranked list of trails.
        // Pass recommendation history for machine learning weight adjustment
        let newRecommendations = recommendationService.recommendTrails(
            from: appViewModel.trails,
            userPreference: userPreference,
            weatherSnapshot: appViewModel.weatherSnapshot,
            currentTime: Date(),
            availableTime: availableTime,
            userHistory: history,
            recommendationHistory: recommendationHistory
        )
        
        recommendations = newRecommendations
        
        // Persist the top recommendations as history records (limit to first 10).
        for recommendation in newRecommendations.prefix(10) {
            let record = RecommendationRecord(
                accountId: accountId,
                trailId: recommendation.trail.id,
                recommendationScore: recommendation.score,
                reason: recommendation.reasons.joined(separator: "；")
            )
            do {
                try store.saveRecommendation(record)
            } catch {
                print("Failed to save recommendation record: \(error)")
            }
        }
    }
    
    /// Updates and persists the user's trail preference profile.
    func updateUserPreference(_ preference: UserPreference) {
        guard let store = store else { return }
        userPreference = preference
        preference.lastUpdated = Date()
        
        do {
            try store.saveUserPreference(preference)
        } catch {
            self.error = "Failed to save user preferences: \(error.localizedDescription)"
        }
    }
    
    /// Records what the user did with a recommendation (e.g. opened, accepted),
    /// so future suggestions can be improved.
    /// - Parameters:
    ///   - recommendation: The recommendation that was acted upon.
    ///   - action: The action taken by the user.
    ///   - accountId: The user account ID to filter history for.
    func recordUserAction(for recommendation: TrailRecommendation, action: RecommendationRecord.UserAction, accountId: UUID) {
        guard let store = store else { return }
        
        do {
            let history = try store.loadRecommendationHistory(accountId: accountId, trailId: recommendation.trail.id)
            if let record = history.first(where: { $0.trailId == recommendation.trail.id && $0.recommendedAt > Date().addingTimeInterval(-3600) }) {
                try store.updateRecommendationAction(record, action: action)
            }
        } catch {
            print("Failed to record user action: \(error)")
        }
    }
}

