//
//  TrailDataStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class TrailDataStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

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
                note: record.note
            )
        }
        .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    func loadFavoriteTrailIds() throws -> Set<UUID> {
        let descriptor = FetchDescriptor<FavoriteTrailRecord>()
        let favorites = try context.fetch(descriptor)
        return Set(favorites.map(\.trailId))
    }

    func save(_ hike: SavedHike) throws {
        if let record = try savedHikeRecord(for: hike.id) {
            record.scheduledDate = hike.scheduledDate
            record.note = hike.note
        } else {
            let record = SavedHikeRecord(
                id: hike.id,
                trailId: hike.trail.id,
                scheduledDate: hike.scheduledDate,
                note: hike.note
            )
            context.insert(record)
        }
        try context.save()
    }

    func delete(_ hike: SavedHike) throws {
        guard let record = try savedHikeRecord(for: hike.id) else { return }
        context.delete(record)
        try context.save()
    }

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

    private func savedHikeRecord(for id: UUID) throws -> SavedHikeRecord? {
        var descriptor = FetchDescriptor<SavedHikeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func favoriteRecord(for trailId: UUID) throws -> FavoriteTrailRecord? {
        var descriptor = FetchDescriptor<FavoriteTrailRecord>(
            predicate: #Predicate { $0.trailId == trailId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

