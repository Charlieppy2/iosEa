//
//  TrailDataStore.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

/// Store responsible for bridging SwiftData records to in-memory `SavedHike`
/// models and managing favorite trail IDs.
@MainActor
final class TrailDataStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Loads all saved hikes and joins them with the provided `Trail` list.
    /// - Parameters:
    ///   - trails: The full list of trails to resolve IDs into full models.
    ///   - accountId: The user account ID to filter records for the current user.
    /// - Returns: An array of `SavedHike` sorted with incomplete hikes first, then by date.
    func loadSavedHikes(trails: [Trail], accountId: UUID) throws -> [SavedHike] {
        let descriptor = FetchDescriptor<SavedHikeRecord>(
            predicate: #Predicate { $0.accountId == accountId }
        )
        let records = try context.fetch(descriptor)
        let trailMap = Dictionary(uniqueKeysWithValues: trails.map { ($0.id, $0) })

        return records.compactMap { record in
            guard let trail = trailMap[record.trailId] else { return nil }
            return SavedHike(
                id: record.id,
                trail: trail,
                scheduledDate: record.scheduledDate,
                note: record.note,
                isCompleted: record.isCompleted,
                completedAt: record.completedAt
            )
        }
        .sorted { lhs, rhs in
            if lhs.isCompleted == rhs.isCompleted {
                return lhs.scheduledDate < rhs.scheduledDate
            }
            return !lhs.isCompleted && rhs.isCompleted
        }
    }

    /// Loads the set of trail IDs that are currently marked as favorites.
    /// - Parameter accountId: The user account ID to filter records for the current user.
    func loadFavoriteTrailIds(accountId: UUID) throws -> Set<UUID> {
        do {
            let descriptor = FetchDescriptor<FavoriteTrailRecord>(
                predicate: #Predicate { $0.accountId == accountId }
            )
            let favorites = try context.fetch(descriptor)
            return Set(favorites.map(\.trailId))
        } catch {
            print("❌ TrailDataStore: Failed to load favorite trail IDs: \(error)")
            // If fetch fails, try to process pending changes and retry once
            do {
                context.processPendingChanges()
                let descriptor = FetchDescriptor<FavoriteTrailRecord>(
                    predicate: #Predicate { $0.accountId == accountId }
                )
                let favorites = try context.fetch(descriptor)
                print("✅ TrailDataStore: Successfully loaded \(favorites.count) favorites after processing pending changes")
                return Set(favorites.map(\.trailId))
            } catch {
                print("❌ TrailDataStore: Retry also failed: \(error)")
                // Return empty set instead of throwing to allow app to continue
                return []
            }
        }
    }

    /// Inserts or updates a saved hike record based on its identifier.
    /// - Parameters:
    ///   - hike: The saved hike to save.
    ///   - accountId: The user account ID to associate this record with.
    func save(_ hike: SavedHike, accountId: UUID) throws {
        if let record = try savedHikeRecord(for: hike.id, accountId: accountId) {
            record.scheduledDate = hike.scheduledDate
            record.note = hike.note
            record.isCompleted = hike.isCompleted
            record.completedAt = hike.completedAt
        } else {
            let record = SavedHikeRecord(
                id: hike.id,
                accountId: accountId,
                trailId: hike.trail.id,
                scheduledDate: hike.scheduledDate,
                note: hike.note,
                isCompleted: hike.isCompleted,
                completedAt: hike.completedAt
            )
            context.insert(record)
        }
        
        // Try to save with retry mechanism
        do {
            try context.save()
        } catch {
            print("❌ TrailDataStore: Failed to save hike: \(error)")
            // Process pending changes and retry once
            context.processPendingChanges()
            do {
                try context.save()
                print("✅ TrailDataStore: Successfully saved after processing pending changes")
            } catch {
                print("❌ TrailDataStore: Retry also failed: \(error)")
                throw error
            }
        }
    }

    /// Deletes a saved hike record corresponding to the given `SavedHike`.
    /// - Parameters:
    ///   - hike: The saved hike to delete.
    ///   - accountId: The user account ID to ensure only the owner can delete.
    func delete(_ hike: SavedHike, accountId: UUID) throws {
        guard let record = try savedHikeRecord(for: hike.id, accountId: accountId) else { return }
        context.delete(record)
        try context.save()
    }

    /// Toggles the favorite status for a given trail ID by inserting or removing a `FavoriteTrailRecord`.
    /// - Parameters:
    ///   - isFavorite: Whether the trail should be marked as favorite.
    ///   - trailId: The trail ID to toggle favorite status for.
    ///   - accountId: The user account ID to associate this record with.
    func setFavorite(_ isFavorite: Bool, trailId: UUID, accountId: UUID) throws {
        if isFavorite {
            guard try favoriteRecord(for: trailId, accountId: accountId) == nil else { return }
            context.insert(FavoriteTrailRecord(accountId: accountId, trailId: trailId))
        } else if let record = try favoriteRecord(for: trailId, accountId: accountId) {
            context.delete(record)
        }
        try context.save()
    }

    // MARK: - Helpers

    /// Fetches the underlying `SavedHikeRecord` for a given ID, if it exists.
    private func savedHikeRecord(for id: UUID, accountId: UUID) throws -> SavedHikeRecord? {
        var descriptor = FetchDescriptor<SavedHikeRecord>(
            predicate: #Predicate { $0.id == id && $0.accountId == accountId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Fetches the `FavoriteTrailRecord` for a given trail ID, if it exists.
    private func favoriteRecord(for trailId: UUID, accountId: UUID) throws -> FavoriteTrailRecord? {
        var descriptor = FetchDescriptor<FavoriteTrailRecord>(
            predicate: #Predicate { $0.trailId == trailId && $0.accountId == accountId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

