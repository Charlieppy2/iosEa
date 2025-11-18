//
//  GearChecklistStore.swift
//  hikingHK
//
//  Created for gear checklist persistence
//

import Foundation
import SwiftData

@MainActor
final class GearChecklistStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func saveGearItems(_ items: [GearItem]) throws {
        for item in items {
            context.insert(item)
        }
        try context.save()
    }
    
    func loadGearItems(for hikeId: UUID) throws -> [GearItem] {
        let descriptor = FetchDescriptor<GearItem>(
            predicate: #Predicate { $0.hikeId == hikeId },
            sortBy: [SortDescriptor(\.category), SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }
    
    func toggleItem(_ item: GearItem) throws {
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        try context.save()
    }
    
    func deleteGearItems(for hikeId: UUID) throws {
        let items = try loadGearItems(for: hikeId)
        for item in items {
            context.delete(item)
        }
        try context.save()
    }
    
    func deleteAllGearItems() throws {
        let descriptor = FetchDescriptor<GearItem>()
        let items = try context.fetch(descriptor)
        for item in items {
            context.delete(item)
        }
        try context.save()
    }
}

