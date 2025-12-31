//
//  RecommendationStore.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

/// Store responsible for persisting user preferences and recommendation history.
@MainActor
final class RecommendationStore {
    private let context: ModelContext
    
    /// Creates a new store bound to the provided SwiftData context.
    init(context: ModelContext) {
        self.context = context
    }
    
    /// Loads the single stored `UserPreference` for a specific user, if any.
    /// - Parameter accountId: The user account ID to load preferences for.
    func loadUserPreference(accountId: UUID) throws -> UserPreference? {
        var descriptor = FetchDescriptor<UserPreference>(
            predicate: #Predicate { $0.accountId == accountId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    /// Replaces any existing user preference with the given one and saves it.
    /// - Parameter preference: The preference to save (must have accountId set).
    func saveUserPreference(_ preference: UserPreference) throws {
        // Delete any existing preference for this user so there is at most one record per user.
        if let existing = try loadUserPreference(accountId: preference.accountId) {
            context.delete(existing)
        }
        context.insert(preference)
        try context.save()
    }
    
    /// Loads recommendation history for a specific user, optionally filtered by a specific trail.
    /// - Parameters:
    ///   - accountId: The user account ID to load history for.
    ///   - trailId: Optional trail ID to filter by.
    /// - Returns: Results sorted by recommendation time (newest first).
    func loadRecommendationHistory(accountId: UUID, trailId: UUID? = nil) throws -> [RecommendationRecord] {
        var descriptor: FetchDescriptor<RecommendationRecord>
        
        if let trailId = trailId {
            descriptor = FetchDescriptor<RecommendationRecord>(
                predicate: #Predicate { $0.accountId == accountId && $0.trailId == trailId },
                sortBy: [SortDescriptor(\.recommendedAt, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<RecommendationRecord>(
                predicate: #Predicate { $0.accountId == accountId },
                sortBy: [SortDescriptor(\.recommendedAt, order: .reverse)]
            )
        }
        
        return try context.fetch(descriptor)
    }
    
    /// Saves a new recommendation record to the store.
    /// - Parameter recommendation: The recommendation record to save (must have accountId set).
    func saveRecommendation(_ recommendation: RecommendationRecord) throws {
        context.insert(recommendation)
        try context.save()
    }
    
    /// Updates the user action taken on a recommendation (e.g. opened, dismissed).
    func updateRecommendationAction(_ record: RecommendationRecord, action: RecommendationRecord.UserAction) throws {
        record.userAction = action
        try context.save()
    }
}

