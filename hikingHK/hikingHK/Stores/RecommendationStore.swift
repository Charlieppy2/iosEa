//
//  RecommendationStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
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
    
    /// Loads the single stored `UserPreference`, if any.
    func loadUserPreference() throws -> UserPreference? {
        var descriptor = FetchDescriptor<UserPreference>()
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    /// Replaces any existing user preference with the given one and saves it.
    func saveUserPreference(_ preference: UserPreference) throws {
        // Delete any existing preference so there is at most one record.
        if let existing = try loadUserPreference() {
            context.delete(existing)
        }
        context.insert(preference)
        try context.save()
    }
    
    /// Loads recommendation history, optionally filtered by a specific trail.
    /// Results are sorted by recommendation time (newest first).
    func loadRecommendationHistory(trailId: UUID? = nil) throws -> [RecommendationRecord] {
        var descriptor = FetchDescriptor<RecommendationRecord>(
            sortBy: [SortDescriptor(\.recommendedAt, order: .reverse)]
        )
        
        if let trailId = trailId {
            descriptor.predicate = #Predicate { $0.trailId == trailId }
        }
        
        return try context.fetch(descriptor)
    }
    
    /// Saves a new recommendation record to the store.
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

