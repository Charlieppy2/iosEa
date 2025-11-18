//
//  JournalStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class JournalStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func loadAllJournals() throws -> [HikeJournal] {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.sortBy = [SortDescriptor(\.hikeDate, order: .reverse)]
        return try context.fetch(descriptor)
    }
    
    func loadJournal(by id: UUID) throws -> HikeJournal? {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.predicate = #Predicate { $0.id == id }
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    func saveJournal(_ journal: HikeJournal) throws {
        journal.updatedAt = Date()
        journal.updateShareToken()
        context.insert(journal)
        try context.save()
    }
    
    func updateJournal(_ journal: HikeJournal) throws {
        journal.updatedAt = Date()
        journal.updateShareToken()
        try context.save()
    }
    
    func deleteJournal(_ journal: HikeJournal) throws {
        context.delete(journal)
        try context.save()
    }
    
    func loadJournalsByTrail(trailId: UUID) throws -> [HikeJournal] {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.predicate = #Predicate { $0.trailId == trailId }
        descriptor.sortBy = [SortDescriptor(\.hikeDate, order: .reverse)]
        return try context.fetch(descriptor)
    }
    
    func loadSharedJournals() throws -> [HikeJournal] {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.predicate = #Predicate { $0.isShared == true }
        descriptor.sortBy = [SortDescriptor(\.hikeDate, order: .reverse)]
        return try context.fetch(descriptor)
    }
}

