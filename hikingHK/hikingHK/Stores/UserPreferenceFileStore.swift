//
//  UserPreferenceFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist user preferences, avoiding SwiftData synchronization issues.
//  Uses the unified BaseFileStore architecture.
//

import Foundation

/// DTO for JSON persistence of user preferences.
struct PersistedUserPreference: FileStoreDTO {
    var id: UUID
    var preferredScenery: [UserPreference.SceneryType]
    var preferredDifficultyRawValue: String?
    var preferredDuration: UserPreference.TimeRange?
    var preferredDistance: UserPreference.DistanceRange?
    var preferredTimeOfDay: [UserPreference.TimeOfDay]
    var fitnessLevel: UserPreference.FitnessLevel
    var lastUpdated: Date
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns the ID of the user preference for identification.
    var modelId: UUID { id }
}

/// Manages saving and loading user preferences using the file system.
/// Uses the unified BaseFileStore architecture.
@MainActor
final class UserPreferenceFileStore: BaseFileStore<UserPreference, PersistedUserPreference> {
    
    init() {
        super.init(fileName: "user_preferences.json")
    }
    
    // MARK: - Convenience Methods
    
    /// Gets the current user preference (there should typically be only one).
    func getCurrentPreference() throws -> UserPreference? {
        let all = try loadAll()
        return all.first
    }
    
    /// Saves or updates the current user preference.
    /// If multiple preferences exist, this will update the most recent one.
    func saveCurrentPreference(_ preference: UserPreference) throws {
        var updated = preference
        updated.lastUpdated = Date()
        try saveOrUpdate(updated)
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedUserPreference {
    init(from model: UserPreference) {
        self.id = model.id
        self.preferredScenery = model.preferredScenery
        self.preferredDifficultyRawValue = model.preferredDifficultyRawValue
        self.preferredDuration = model.preferredDuration
        self.preferredDistance = model.preferredDistance
        self.preferredTimeOfDay = model.preferredTimeOfDay
        self.fitnessLevel = model.fitnessLevel
        self.lastUpdated = model.lastUpdated
    }
    
    func toModel() -> UserPreference {
        UserPreference(
            id: id,
            preferredScenery: preferredScenery,
            preferredDifficulty: preferredDifficultyRawValue.flatMap { Trail.Difficulty(rawValue: $0) },
            preferredDuration: preferredDuration,
            preferredDistance: preferredDistance,
            preferredTimeOfDay: preferredTimeOfDay,
            fitnessLevel: fitnessLevel,
            lastUpdated: lastUpdated
        )
    }
}

