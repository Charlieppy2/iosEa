//
//  SafetyChecklistStore.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

/// Store responsible for seeding, loading, and updating `SafetyChecklistItem` entries.
@MainActor
final class SafetyChecklistStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// Inserts the default safety checklist items if none exist, and returns all items.
    func seedDefaultsIfNeeded() throws -> [SafetyChecklistItem] {
        // First check whether any data already exists.
        var descriptor = FetchDescriptor<SafetyChecklistItem>()
        descriptor.fetchLimit = 1
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            print("SafetyChecklistStore: Found \(existing.count) existing items, skipping seed")
            // Return all existing items if seeding is not needed.
            return try loadAllItems()
        }
        
        print("SafetyChecklistStore: Seeding default safety checklist items...")
        
        // Create the default checklist items.
        let locationItem = SafetyChecklistItem(id: "location", iconName: "location.fill", title: "Enable Live Location")
        let waterItem = SafetyChecklistItem(id: "water", iconName: "drop.fill", title: "Pack 2L of water")
        let heatItem = SafetyChecklistItem(id: "heat", iconName: "bolt.heart", title: "Check heat stroke signal")
        let offlineItem = SafetyChecklistItem(id: "offline", iconName: "antenna.radiowaves.left.and.right", title: "Download offline map")
        let shareItem = SafetyChecklistItem(id: "share", iconName: "person.2.wave.2", title: "Share hike plan with buddies")
        
        let defaultItems = [locationItem, waterItem, heatItem, offlineItem, shareItem]
        
        print("SafetyChecklistStore: Inserting \(defaultItems.count) items into context...")
        for item in defaultItems {
            context.insert(item)
            print("SafetyChecklistStore: Inserted item with id: \(item.id), title: \(item.title)")
        }
        
        print("SafetyChecklistStore: Saving context...")
        try context.save()
        print("SafetyChecklistStore: Context saved successfully")
        
        // Return the inserted items directly instead of querying again.
        print("SafetyChecklistStore: Returning \(defaultItems.count) inserted items directly")
        return defaultItems.sorted { $0.id < $1.id }
    }
    
    /// Loads all safety checklist items, sorted by their identifier.
    func loadAllItems() throws -> [SafetyChecklistItem] {
        // Perform a simple unsorted fetch from SwiftData.
        let descriptor = FetchDescriptor<SafetyChecklistItem>()
        // Do not set a fetchLimit; load all items.
        let allItems = try context.fetch(descriptor)
        print("SafetyChecklistStore: loadAllItems() fetched \(allItems.count) items")
        
        // If the query is empty, log and return an empty sorted array.
        if allItems.isEmpty {
            print("⚠️ SafetyChecklistStore: Query returned 0 items, trying to refresh context...")
            return []
        }
        
        // Manually sort by ID to get a stable order.
        let sorted = allItems.sorted { $0.id < $1.id }
        print("SafetyChecklistStore: Returning \(sorted.count) sorted items")
        return sorted
    }
    
    /// Toggles completion for the checklist item with the given identifier.
    func toggleItem(id: String) throws {
        var descriptor = FetchDescriptor<SafetyChecklistItem>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let item = try context.fetch(descriptor).first else { return }
        
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        context.processPendingChanges()
        try context.save()
        // Save again to ensure synchronization in edge cases.
        try context.save()
    }
    
    /// Explicitly sets completion state for the checklist item with the given identifier.
    func setItemCompleted(id: String, isCompleted: Bool) throws {
        var descriptor = FetchDescriptor<SafetyChecklistItem>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let item = try context.fetch(descriptor).first else { return }
        
        item.isCompleted = isCompleted
        item.lastUpdated = Date()
        context.processPendingChanges()
        try context.save()
        // Save again to ensure synchronization in edge cases.
        try context.save()
    }
    
    /// Creates and persists a new safety checklist item.
    func createItem(id: String, iconName: String, title: String) throws -> SafetyChecklistItem {
        let newItem = SafetyChecklistItem(id: id, iconName: iconName, title: title)
        context.insert(newItem)
        try context.save()
        print("SafetyChecklistStore: Created new item with id: \(id), title: \(title)")
        return newItem
    }
    
    /// Deletes a safety checklist item from the store.
    func deleteItem(_ item: SafetyChecklistItem) throws {
        context.delete(item)
        try context.save()
        print("SafetyChecklistStore: Deleted item with id: \(item.id)")
    }
}

