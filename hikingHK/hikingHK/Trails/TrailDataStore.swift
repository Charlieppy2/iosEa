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
    /// - Parameter trails: The full list of trails to resolve IDs into full models.
    /// - Returns: An array of `SavedHike` sorted with incomplete hikes first, then by date.
    func loadSavedHikes(trails: [Trail]) throws -> [SavedHike] {
        let descriptor = FetchDescriptor<SavedHikeRecord>()
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
    func loadFavoriteTrailIds() throws -> Set<UUID> {
        let descriptor = FetchDescriptor<FavoriteTrailRecord>()
        let favorites = try context.fetch(descriptor)
        return Set(favorites.map(\.trailId))
    }

    /// Inserts or updates a saved hike record based on its identifier.
    func save(_ hike: SavedHike) throws {
        if let record = try savedHikeRecord(for: hike.id) {
            record.scheduledDate = hike.scheduledDate
            record.note = hike.note
            record.isCompleted = hike.isCompleted
            record.completedAt = hike.completedAt
        } else {
            let record = SavedHikeRecord(
                id: hike.id,
                trailId: hike.trail.id,
                scheduledDate: hike.scheduledDate,
                note: hike.note,
                isCompleted: hike.isCompleted,
                completedAt: hike.completedAt
            )
            context.insert(record)
        }
        try context.save()
    }

    /// Deletes a saved hike record corresponding to the given `SavedHike`.
    func delete(_ hike: SavedHike) throws {
        guard let record = try savedHikeRecord(for: hike.id) else { return }
        context.delete(record)
        try context.save()
    }

    /// Toggles the favorite status for a given trail ID by inserting or removing a `FavoriteTrailRecord`.
    func setFavorite(_ isFavorite: Bool, trailId: UUID) throws {
        if isFavorite {
            guard try favoriteRecord(for: trailId) == nil else { return }
            context.insert(FavoriteTrailRecord(trailId: trailId))
        } else if let record = try favoriteRecord(for: trailId) {
            context.delete(record)
        }
        try context.save()
    }

    // MARK: - Helpers

    /// Fetches the underlying `SavedHikeRecord` for a given ID, if it exists.
    private func savedHikeRecord(for id: UUID) throws -> SavedHikeRecord? {
        var descriptor = FetchDescriptor<SavedHikeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Fetches the `FavoriteTrailRecord` for a given trail ID, if it exists.
    private func favoriteRecord(for trailId: UUID) throws -> FavoriteTrailRecord? {
        var descriptor = FetchDescriptor<FavoriteTrailRecord>(
            predicate: #Predicate { $0.trailId == trailId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

