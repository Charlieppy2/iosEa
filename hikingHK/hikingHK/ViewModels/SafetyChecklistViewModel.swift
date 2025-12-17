//
//  SafetyChecklistViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import Combine

/// View model for the safety checklist on the Home screen.
/// Handles loading, ordering, completion state, and persistence via SwiftData + UserDefaults.
@MainActor
final class SafetyChecklistViewModel: ObservableObject {
    @Published var items: [SafetyChecklistItem] = []
    @Published var itemOrder: [String] = [] // Stores the display order of items
    private var safetyChecklistStore: SafetyChecklistStore?
    private var hasSeeded = false
    
    /// Stores completion states in UserDefaults to avoid SwiftData synchronization issues.
    private let completionDefaultsKey = "safetyChecklist.completionStates"
    /// Stores custom item content (title, icon) in UserDefaults so they persist between launches.
    private let customItemsDefaultsKey = "safetyChecklist.customItems"
    /// Stores the item display order in UserDefaults.
    private let itemOrderDefaultsKey = "safetyChecklist.itemOrder"
    /// Stores deleted default item IDs in UserDefaults to prevent them from being recreated.
    private let deletedDefaultItemsKey = "safetyChecklist.deletedDefaultItems"
    
    /// Simple DTO for custom checklist items, used for encoding/decoding to UserDefaults.
    private struct CustomItemDTO: Codable {
        let id: String
        let title: String
        let iconName: String
    }
    
    // MARK: - Completion State Persistence (UserDefaults)
    
    private func loadCompletionStates() -> [String: Bool] {
        let dict = UserDefaults.standard.dictionary(forKey: completionDefaultsKey) as? [String: Bool]
        return dict ?? [:]
    }
    
    private func saveCompletionStates(_ states: [String: Bool]) {
        UserDefaults.standard.set(states, forKey: completionDefaultsKey)
    }
    
    /// Applies completion states from UserDefaults to the current in-memory items.
    private func applyCompletionStatesFromDefaults() {
        let states = loadCompletionStates()
        guard !states.isEmpty else { return }
        
        for item in items {
            if let saved = states[item.id] {
                item.isCompleted = saved
            }
        }
        objectWillChange.send()
    }
    
    // MARK: - Item Order Persistence (UserDefaults)
    
    private func loadItemOrder() -> [String] {
        return UserDefaults.standard.stringArray(forKey: itemOrderDefaultsKey) ?? []
    }
    
    private func saveItemOrder(_ order: [String]) {
        UserDefaults.standard.set(order, forKey: itemOrderDefaultsKey)
    }
    
    // MARK: - Deleted Default Items Tracking (UserDefaults)
    
    /// IDs of the built-in default checklist items.
    private let defaultItemIds = ["location", "water", "heat", "offline", "share"]
    
    private func loadDeletedDefaultItems() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: deletedDefaultItemsKey) ?? []
        return Set(array)
    }
    
    private func saveDeletedDefaultItems(_ deletedIds: Set<String>) {
        UserDefaults.standard.set(Array(deletedIds), forKey: deletedDefaultItemsKey)
    }
    
    /// Filters out default items that have been deleted by the user.
    private func filterDeletedDefaultItems(_ items: [SafetyChecklistItem]) -> [SafetyChecklistItem] {
        let deletedIds = loadDeletedDefaultItems()
        guard !deletedIds.isEmpty else { return items }
        
        let filtered = items.filter { item in
            // If this is a default item and it was deleted, filter it out.
            if defaultItemIds.contains(item.id) && deletedIds.contains(item.id) {
                return false
            }
            return true
        }
        
        if filtered.count != items.count {
            print("🔍 SafetyChecklistViewModel: Filtered out \(items.count - filtered.count) deleted default items")
        }
        
        return filtered
    }
    
    /// Reorders items based on the saved order; falls back to default (sorted by ID) if no order is stored.
    private func applyItemOrder() {
        let savedOrder = loadItemOrder()
        
        if savedOrder.isEmpty {
            // If there is no saved order, use the default order (sorted by ID).
            itemOrder = items.map { $0.id }.sorted { $0 < $1 }
        } else {
            // Use the saved order, but ensure all existing items are present.
            var order = savedOrder.filter { id in items.contains(where: { $0.id == id }) }
            // Add any missing items (sorted by ID) that were not in the saved order.
            let missingIds = items.map { $0.id }.filter { !order.contains($0) }.sorted { $0 < $1 }
            order.append(contentsOf: missingIds)
            itemOrder = order
        }
        
        // Reorder items according to the resolved order.
        let reorderedItems = itemOrder.compactMap { id in
            items.first(where: { $0.id == id })
        }
        
        // Only update if the order has actually changed.
        if reorderedItems.map({ $0.id }) != items.map({ $0.id }) {
            items = reorderedItems
            objectWillChange.send()
        }
    }
    
    /// Moves an item to a new position in the list and updates the stored order.
    func moveItem(from source: IndexSet, to destination: Int, context: ModelContext) {
        // Manually implement move logic to handle moving one or multiple items.
        var reorderedItems = items
        var itemsToMove: [SafetyChecklistItem] = []
        
        // Remove in descending order to avoid index shifting issues.
        for index in source.sorted(by: >) {
            itemsToMove.insert(reorderedItems.remove(at: index), at: 0)
        }
        
        // Calculate the correct insertion index.
        let insertIndex = min(destination, reorderedItems.count)
        
        // Insert moved items at the destination index.
        for (offset, item) in itemsToMove.enumerated() {
            reorderedItems.insert(item, at: insertIndex + offset)
        }
        
        items = reorderedItems
        
        // Update the stored order.
        itemOrder = items.map { $0.id }
        // Persist the new order to UserDefaults.
        saveItemOrder(itemOrder)
        objectWillChange.send()
        print("✅ SafetyChecklistViewModel: Moved item, new order: \(itemOrder)")
    }
    
    // MARK: - Custom Items Backup (UserDefaults)
    
    private func loadCustomItemsBackup() -> [CustomItemDTO] {
        guard let data = UserDefaults.standard.data(forKey: customItemsDefaultsKey) else {
            return []
        }
        do {
            let decoded = try JSONDecoder().decode([CustomItemDTO].self, from: data)
            return decoded
        } catch {
            print("⚠️ SafetyChecklistViewModel: Failed to decode custom items backup: \(error)")
            return []
        }
    }
    
    private func saveCustomItemsBackup(_ items: [CustomItemDTO]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: customItemsDefaultsKey)
        } catch {
            print("⚠️ SafetyChecklistViewModel: Failed to encode custom items backup: \(error)")
        }
    }
    
    /// Restores missing custom items from the UserDefaults backup and reapplies completion state.
    private func restoreCustomItemsIfNeeded() {
        guard let store = safetyChecklistStore else {
            print("⚠️ SafetyChecklistViewModel: Store is nil, cannot restore custom items")
            return
        }
        
        let backups = loadCustomItemsBackup()
        print("🔍 SafetyChecklistViewModel: Checking custom items backup, found \(backups.count) items")
        guard !backups.isEmpty else {
            print("ℹ️ SafetyChecklistViewModel: No custom items backup found")
            return
        }
        
        // 讀取已保存的完成狀態，確保恢復時一併套用（例如 QQQQ 已經剔選過）
        let states = loadCompletionStates()
        
        var changed = false
        
        for backup in backups {
            // 只處理自定義項（id 以 custom_ 開頭）
            guard backup.id.hasPrefix("custom_") else { continue }
            
            if items.first(where: { $0.id == backup.id }) == nil {
                do {
                    print("🔧 SafetyChecklistViewModel: Restoring custom item: \(backup.id) - \(backup.title)")
                    let newItem = try store.createItem(id: backup.id, iconName: backup.iconName, title: backup.title)
                    
                    // 套用之前保存的完成狀態（true / false）
                    if let savedCompleted = states[backup.id] {
                        newItem.isCompleted = savedCompleted
                    }
                    
                    items.append(newItem)
                    changed = true
                    print("✅ SafetyChecklistViewModel: Restored custom item from backup: \(backup.id) - \(backup.title), isCompleted: \(newItem.isCompleted)")
                } catch {
                    print("❌ SafetyChecklistViewModel: Failed to restore custom item \(backup.id): \(error)")
                }
            } else {
                print("ℹ️ SafetyChecklistViewModel: Custom item \(backup.id) already exists, skipping")
            }
        }
        
        if changed {
            // 應用順序（會自動排序）
            applyItemOrder()
            objectWillChange.send()
            print("✅ SafetyChecklistViewModel: Restored some custom items, total: \(items.count)")
        } else {
            print("ℹ️ SafetyChecklistViewModel: No custom items needed restoration")
        }
    }
    
    /// Lazily configures the underlying `SafetyChecklistStore` and seeds default items if needed.
    func configureIfNeeded(context: ModelContext) async {
        // If already configured, only refresh the list when items are empty.
        if let existingStore = safetyChecklistStore {
            // If items are already loaded, no need to refresh.
            if !items.isEmpty {
                print("✅ SafetyChecklistViewModel: Already configured with \(items.count) items")
                return
            }
            // Only refresh if the in-memory list is empty.
            refreshItems()
            return
        }
        
        print("🔧 SafetyChecklistViewModel: configureIfNeeded called")
        
        let store = SafetyChecklistStore(context: context)
        safetyChecklistStore = store
        
        do {
            print("🔧 SafetyChecklistViewModel: Seeding default items...")
            let seededItems = try store.seedDefaultsIfNeeded()
            hasSeeded = true
            print("✅ SafetyChecklistViewModel: Seeding completed, got \(seededItems.count) items")
            // Filter out default items that the user has deleted.
            let filteredItems = filterDeletedDefaultItems(seededItems)
            // Use the seeded items directly instead of querying again.
            items = filteredItems
            print("✅ SafetyChecklistViewModel: Set items directly, count: \(items.count) (after filtering deleted defaults)")
            // Apply saved completion states and restore any missing custom items.
            applyCompletionStatesFromDefaults()
            restoreCustomItemsIfNeeded()
            // Apply the saved display order.
            applyItemOrder()
        } catch {
            print("❌ Safety checklist seeding error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    /// Reloads checklist items from the store and reapplies completion, custom items, and order.
    func refreshItems() {
        guard let store = safetyChecklistStore else {
            print("⚠️ SafetyChecklistViewModel: Store is nil, cannot refresh")
            return
        }
        do {
            let loadedItems = try store.loadAllItems()
            // Filter out default items that have been deleted.
            let filteredItems = filterDeletedDefaultItems(loadedItems)
            items = filteredItems
            print("✅ SafetyChecklistViewModel: Refreshed \(filteredItems.count) items (after filtering deleted defaults)")
            // Apply saved completion states and restore custom items.
            applyCompletionStatesFromDefaults()
            restoreCustomItemsIfNeeded()
            // Apply the saved display order.
            applyItemOrder()
        } catch {
            print("❌ Refresh safety items error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    /// Ensures default checklist items exist, creating them if the list is currently empty.
    func createDefaultItems(context: ModelContext) async {
        print("🔧 SafetyChecklistViewModel: Creating default items...")
        
        // If we already have items, do not create them again.
        if !items.isEmpty {
            print("⚠️ SafetyChecklistViewModel: Items already exist (\(items.count) items), skipping creation")
            return
        }
        
        // Use the store to create items if it already exists.
        guard let store = safetyChecklistStore else {
            print("⚠️ SafetyChecklistViewModel: Store is nil, creating store...")
            let newStore = SafetyChecklistStore(context: context)
            safetyChecklistStore = newStore
            do {
                let seededItems = try newStore.seedDefaultsIfNeeded()
                // Filter out default items that the user has deleted.
                let filteredItems = filterDeletedDefaultItems(seededItems)
                items = filteredItems
                print("✅ SafetyChecklistViewModel: Created store and seeded \(filteredItems.count) items (after filtering deleted defaults)")
                applyCompletionStatesFromDefaults()
                restoreCustomItemsIfNeeded()
                applyItemOrder()
            } catch {
                print("❌ SafetyChecklistViewModel: Failed to seed items: \(error)")
            }
            return
        }
        
        do {
            // Use the store's `seedDefaultsIfNeeded` method to get created items directly.
            let createdItems = try store.seedDefaultsIfNeeded()
            // Filter out default items that the user has deleted.
            let filteredItems = filterDeletedDefaultItems(createdItems)
            print("✅ SafetyChecklistViewModel: Created \(filteredItems.count) items (after filtering deleted defaults)")
            // Set items directly instead of querying again.
            items = filteredItems
            print("✅ SafetyChecklistViewModel: Set items directly, count: \(items.count)")
            applyCompletionStatesFromDefaults()
            restoreCustomItemsIfNeeded()
            applyItemOrder()
        } catch {
            print("❌ SafetyChecklistViewModel: Failed to create items: \(error)")
            // If creation fails, fall back to refreshing from the store.
            refreshItems()
        }
    }
    
    /// Toggles the completion state of a checklist item and persists the change to SwiftData and UserDefaults.
    func toggleItem(_ item: SafetyChecklistItem, context: ModelContext) {
        // Directly update the item state.
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        
        // Manually trigger @Published update because mutating a reference type does not auto-publish.
        objectWillChange.send()
        
        // Update the cached completion state in UserDefaults.
        var states = loadCompletionStates()
        states[item.id] = item.isCompleted
        saveCompletionStates(states)
        
        do {
            // Process pending changes and save to SwiftData.
            context.processPendingChanges()
            try context.save()
            
            let completedCount = items.filter { $0.isCompleted }.count
            print("✅ SafetyChecklistViewModel: Toggled item \(item.id), isCompleted: \(item.isCompleted), progress: \(completedCount)/\(items.count)")
        } catch {
            print("❌ Toggle safety item error: \(error)")
            // If saving fails, roll back the in-memory state.
            item.isCompleted.toggle()
            // Roll back the state stored in UserDefaults.
            states[item.id] = item.isCompleted
            saveCompletionStates(states)
            objectWillChange.send() // Trigger UI update to reflect the rollback.
        }
    }
    
    /// Adds a new custom checklist item at the top of the list and persists its metadata.
    func addItem(title: String, iconName: String = "checkmark.circle", context: ModelContext) throws {
        guard let store = safetyChecklistStore else {
            throw NSError(domain: "SafetyChecklistViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Store not configured"])
        }
        
        // Generate a unique ID for the custom item.
        let newId = "custom_\(UUID().uuidString)"
        let newItem = try store.createItem(id: newId, iconName: iconName, title: title)
        
        // Insert the new item at the top of the in-memory list.
        items.insert(newItem, at: 0)
        
        // Update order: new item goes to the top (index 0).
        itemOrder.insert(newItem.id, at: 0)
        saveItemOrder(itemOrder)
        
        // Store the new item's completion state (default false) in UserDefaults.
        var states = loadCompletionStates()
        states[newItem.id] = newItem.isCompleted
        saveCompletionStates(states)
        
        // Save a backup entry for this custom item (title and iconName).
        var backups = loadCustomItemsBackup()
        let dto = CustomItemDTO(id: newItem.id, title: newItem.title, iconName: newItem.iconName)
        backups.append(dto)
        saveCustomItemsBackup(backups)
        
        // Trigger UI update.
        objectWillChange.send()
        
        print("✅ SafetyChecklistViewModel: Added new item at top, total: \(items.count), saved to UserDefaults and backup")
    }
    
    /// Deletes an item from the checklist, updates order and persistence, and records deleted defaults.
    func deleteItem(_ item: SafetyChecklistItem, context: ModelContext) throws {
        guard let store = safetyChecklistStore else {
            throw NSError(domain: "SafetyChecklistViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Store not configured"])
        }
        
        try store.deleteItem(item)
        
        // Remove from the in-memory items array.
        items.removeAll { $0.id == item.id }
        
        // Remove from the stored order.
        itemOrder.removeAll { $0 == item.id }
        saveItemOrder(itemOrder)
        
        // Remove the completion state from UserDefaults.
        var states = loadCompletionStates()
        states.removeValue(forKey: item.id)
        saveCompletionStates(states)
        
        // Remove from the custom items backup if this is a custom item.
        if item.id.hasPrefix("custom_") {
            var backups = loadCustomItemsBackup()
            backups.removeAll { $0.id == item.id }
            saveCustomItemsBackup(backups)
        }
        
        // If this is a default item, record it as deleted so it is not recreated later.
        if defaultItemIds.contains(item.id) {
            var deletedIds = loadDeletedDefaultItems()
            deletedIds.insert(item.id)
            saveDeletedDefaultItems(deletedIds)
            print("✅ SafetyChecklistViewModel: Marked default item '\(item.id)' as deleted, will not recreate")
        }
        
        // Trigger UI update.
        objectWillChange.send()
        
        print("✅ SafetyChecklistViewModel: Deleted item, total: \(items.count), removed from UserDefaults and backup")
    }
}

