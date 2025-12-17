//
//  GearChecklistStore.swift
//  hikingHK
//
//  Created for gear checklist persistence
//

import Foundation
import SwiftData

/// Store responsible for persisting and querying `GearItem` checklist entries.
@MainActor
final class GearChecklistStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// Saves a collection of gear items to the underlying context.
    func saveGearItems(_ items: [GearItem]) throws {
        for item in items {
            context.insert(item)
        }
        try context.save()
    }
    
    /// Loads all gear items associated with a given hike, sorted by category then name.
    func loadGearItems(for hikeId: UUID) throws -> [GearItem] {
        let descriptor = FetchDescriptor<GearItem>(
            predicate: #Predicate { $0.hikeId == hikeId }
        )
        let items = try context.fetch(descriptor)
        // Manual sorting since SortDescriptor has limitations with enum-backed categories.
        return items.sorted { item1, item2 in
            if item1.category.rawValue != item2.category.rawValue {
                return item1.category.rawValue < item2.category.rawValue
            }
            return item1.name < item2.name
        }
    }
    
    /// Toggles completion for a single gear item and updates its timestamp.
    func toggleItem(_ item: GearItem) throws {
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        try context.save()
    }
    
    /// Deletes all gear items associated with a specific hike.
    func deleteGearItems(for hikeId: UUID) throws {
        let items = try loadGearItems(for: hikeId)
        for item in items {
            context.delete(item)
        }
        try context.save()
    }
    
    /// Deletes all gear items from the store (used for resets / debugging).
    func deleteAllGearItems() throws {
        let descriptor = FetchDescriptor<GearItem>()
        let items = try context.fetch(descriptor)
        for item in items {
            context.delete(item)
        }
        try context.save()
    }
}

