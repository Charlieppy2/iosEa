//
//  HikeRecordStore.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

/// Store responsible for persisting and querying `HikeRecord` models.
@MainActor
final class HikeRecordStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// Inserts or updates a single hike record in the store.
    func saveRecord(_ record: HikeRecord) throws {
        context.insert(record)
        try context.save()
    }
    
    /// Loads all hike records for a specific user, sorted by start time descending (newest first).
    /// - Parameter accountId: The user account ID to filter records for.
    func loadAllRecords(accountId: UUID) throws -> [HikeRecord] {
        let descriptor = FetchDescriptor<HikeRecord>(
            predicate: #Predicate { $0.accountId == accountId },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// Loads a single hike record by its identifier for a specific user.
    /// - Parameters:
    ///   - id: The record ID.
    ///   - accountId: The user account ID to ensure only the owner can access.
    func loadRecord(id: UUID, accountId: UUID) throws -> HikeRecord? {
        var descriptor = FetchDescriptor<HikeRecord>(
            predicate: #Predicate { $0.id == id && $0.accountId == accountId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    /// Deletes a hike record and all of its associated track points.
    func deleteRecord(_ record: HikeRecord) throws {
        // Delete all associated track points before removing the record itself.
        for point in record.trackPoints {
            context.delete(point)
        }
        context.delete(record)
        try context.save()
    }
    
    /// Loads all hike records associated with a specific trail for a specific user, sorted by start time descending.
    /// - Parameters:
    ///   - trailId: The trail ID.
    ///   - accountId: The user account ID to filter records for.
    func loadRecordsForTrail(trailId: UUID, accountId: UUID) throws -> [HikeRecord] {
        let descriptor = FetchDescriptor<HikeRecord>(
            predicate: #Predicate { $0.trailId == trailId && $0.accountId == accountId },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}

