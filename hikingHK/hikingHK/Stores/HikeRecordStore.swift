//
//  HikeRecordStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class HikeRecordStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func saveRecord(_ record: HikeRecord) throws {
        context.insert(record)
        try context.save()
    }
    
    func loadAllRecords() throws -> [HikeRecord] {
        let descriptor = FetchDescriptor<HikeRecord>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func loadRecord(id: UUID) throws -> HikeRecord? {
        var descriptor = FetchDescriptor<HikeRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    func deleteRecord(_ record: HikeRecord) throws {
        // 刪除所有關聯的軌跡點
        for point in record.trackPoints {
            context.delete(point)
        }
        context.delete(record)
        try context.save()
    }
    
    func loadRecordsForTrail(trailId: UUID) throws -> [HikeRecord] {
        let descriptor = FetchDescriptor<HikeRecord>(
            predicate: #Predicate { $0.trailId == trailId },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}

