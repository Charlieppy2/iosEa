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
            predicate: #Predicate { $0.hikeId == hikeId }
        )
        let items = try context.fetch(descriptor)
        // Manual sorting since SortDescriptor has limitations with enum types
        return items.sorted { item1, item2 in
            if item1.category.rawValue != item2.category.rawValue {
                return item1.category.rawValue < item2.category.rawValue
            }
            return item1.name < item2.name
        }
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

