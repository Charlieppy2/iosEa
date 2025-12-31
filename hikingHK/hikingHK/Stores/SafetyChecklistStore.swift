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
    
    /// Inserts the default safety checklist items if none exist for a specific user, and returns all items.
    /// - Parameter accountId: The user account ID to create items for.
    func seedDefaultsIfNeeded(accountId: UUID) throws -> [SafetyChecklistItem] {
        // First check whether any data already exists for this user.
        var descriptor = FetchDescriptor<SafetyChecklistItem>(
            predicate: #Predicate { $0.accountId == accountId }
        )
        descriptor.fetchLimit = 1
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            print("SafetyChecklistStore: Found \(existing.count) existing items, skipping seed")
            // Return all existing items if seeding is not needed.
            return try loadAllItems(accountId: accountId)
        }
        
        print("SafetyChecklistStore: Seeding default safety checklist items for account: \(accountId)...")
        
        // Create the default checklist items.
        let locationItem = SafetyChecklistItem(id: "location", accountId: accountId, iconName: "location.fill", title: "Enable Live Location")
        let waterItem = SafetyChecklistItem(id: "water", accountId: accountId, iconName: "drop.fill", title: "Pack 2L of water")
        let heatItem = SafetyChecklistItem(id: "heat", accountId: accountId, iconName: "bolt.heart", title: "Check heat stroke signal")
        let offlineItem = SafetyChecklistItem(id: "offline", accountId: accountId, iconName: "antenna.radiowaves.left.and.right", title: "Download offline map")
        let shareItem = SafetyChecklistItem(id: "share", accountId: accountId, iconName: "person.2.wave.2", title: "Share hike plan with buddies")
        
        let defaultItems = [locationItem, waterItem, heatItem, offlineItem, shareItem]
        
        print("SafetyChecklistStore: Inserting \(defaultItems.count) items into context...")
        for item in defaultItems {
            context.insert(item)
            print("SafetyChecklistStore: Inserted item with id: \(item.id), title: \(item.title)")
        }
        
        print("SafetyChecklistStore: Saving context...")
        do {
            try context.save()
            print("SafetyChecklistStore: Context saved successfully")
        } catch {
            print("❌ SafetyChecklistStore: Failed to save context: \(error)")
            context.processPendingChanges()
            try context.save()
            print("✅ SafetyChecklistStore: Successfully saved after processing pending changes")
        }
        
        // Return the inserted items directly instead of querying again.
        print("SafetyChecklistStore: Returning \(defaultItems.count) inserted items directly")
        return defaultItems.sorted { $0.id < $1.id }
    }
    
    /// Loads all safety checklist items for a specific user, sorted by their identifier.
    /// - Parameter accountId: The user account ID to filter items for.
    func loadAllItems(accountId: UUID) throws -> [SafetyChecklistItem] {
        do {
            // Perform a simple unsorted fetch from SwiftData.
            let descriptor = FetchDescriptor<SafetyChecklistItem>(
                predicate: #Predicate { $0.accountId == accountId }
            )
            // Do not set a fetchLimit; load all items.
            let allItems = try context.fetch(descriptor)
            print("SafetyChecklistStore: loadAllItems() fetched \(allItems.count) items")
            
            // If the query is empty, log and return an empty sorted array.
            if allItems.isEmpty {
                print("⚠️ SafetyChecklistStore: Query returned 0 items")
                return []
            }
            
            // Manually sort by ID to get a stable order.
            let sorted = allItems.sorted { $0.id < $1.id }
            print("SafetyChecklistStore: Returning \(sorted.count) sorted items")
            return sorted
        } catch {
            print("❌ SafetyChecklistStore: Failed to load items: \(error)")
            // If fetch fails, try to process pending changes and retry once
            do {
                context.processPendingChanges()
                let descriptor = FetchDescriptor<SafetyChecklistItem>(
                    predicate: #Predicate { $0.accountId == accountId }
                )
                let allItems = try context.fetch(descriptor)
                print("✅ SafetyChecklistStore: Successfully loaded \(allItems.count) items after processing pending changes")
                return allItems.sorted { $0.id < $1.id }
            } catch {
                print("❌ SafetyChecklistStore: Retry also failed: \(error)")
                throw error
            }
        }
    }
    
    /// Toggles completion for the checklist item with the given identifier for a specific user.
    /// - Parameters:
    ///   - id: The item identifier.
    ///   - accountId: The user account ID to ensure only the owner can toggle.
    func toggleItem(id: String, accountId: UUID) throws {
        var descriptor = FetchDescriptor<SafetyChecklistItem>(
            predicate: #Predicate { $0.id == id && $0.accountId == accountId }
        )
        descriptor.fetchLimit = 1
        guard let item = try context.fetch(descriptor).first else { return }
        
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        context.processPendingChanges()
        do {
            try context.save()
            // Save again to ensure synchronization in edge cases.
            try context.save()
        } catch {
            print("❌ SafetyChecklistStore: Failed to save toggle: \(error)")
            context.processPendingChanges()
            try context.save()
        }
    }
    
    /// Explicitly sets completion state for the checklist item with the given identifier for a specific user.
    /// - Parameters:
    ///   - id: The item identifier.
    ///   - isCompleted: The completion state to set.
    ///   - accountId: The user account ID to ensure only the owner can update.
    func setItemCompleted(id: String, isCompleted: Bool, accountId: UUID) throws {
        var descriptor = FetchDescriptor<SafetyChecklistItem>(
            predicate: #Predicate { $0.id == id && $0.accountId == accountId }
        )
        descriptor.fetchLimit = 1
        guard let item = try context.fetch(descriptor).first else { return }
        
        item.isCompleted = isCompleted
        item.lastUpdated = Date()
        context.processPendingChanges()
        do {
            try context.save()
            // Save again to ensure synchronization in edge cases.
            try context.save()
        } catch {
            print("❌ SafetyChecklistStore: Failed to save completion state: \(error)")
            context.processPendingChanges()
            try context.save()
        }
    }
    
    /// Creates and persists a new safety checklist item for a specific user.
    /// - Parameters:
    ///   - id: The item identifier.
    ///   - iconName: The icon name.
    ///   - title: The item title.
    ///   - accountId: The user account ID to associate this item with.
    func createItem(id: String, iconName: String, title: String, accountId: UUID) throws -> SafetyChecklistItem {
        let newItem = SafetyChecklistItem(id: id, accountId: accountId, iconName: iconName, title: title)
        context.insert(newItem)
        do {
            try context.save()
            print("SafetyChecklistStore: Created new item with id: \(id), title: \(title)")
        } catch {
            print("❌ SafetyChecklistStore: Failed to save new item: \(error)")
            context.processPendingChanges()
            try context.save()
            print("✅ SafetyChecklistStore: Successfully saved after processing pending changes")
        }
        return newItem
    }
    
    /// Deletes a safety checklist item from the store.
    func deleteItem(_ item: SafetyChecklistItem) throws {
        context.delete(item)
        do {
            try context.save()
            print("SafetyChecklistStore: Deleted item with id: \(item.id)")
        } catch {
            print("❌ SafetyChecklistStore: Failed to delete item: \(error)")
            context.processPendingChanges()
            try context.save()
            print("✅ SafetyChecklistStore: Successfully deleted after processing pending changes")
        }
    }
}

