//
//  GearChecklistViewModel.swift
//  hikingHK
//
//  Created for gear checklist view model
//

import Foundation
import SwiftData
import Combine

/// View model for generating, loading and updating the smart gear checklist.
@MainActor
final class GearChecklistViewModel: ObservableObject {
    @Published var gearItems: [GearItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var store: GearChecklistStore?
    private let gearItemFileStore = GearItemFileStore()
    private var gearService: SmartGearServiceProtocol?
    private var languageManager: LanguageManager?
    private var currentHikeId: UUID?
    
    /// Allows injecting a custom gear service for testing; defaults to `SmartGearService`.
    nonisolated init(gearService: SmartGearServiceProtocol? = nil) {
        self.gearService = gearService
    }
    
    /// Returns the active gear service, lazily creating a default implementation if needed.
    private func getGearService() -> SmartGearServiceProtocol {
        if let service = gearService {
            return service
        }
        return SmartGearService()
    }
    
    /// Lazily configures the underlying `GearChecklistStore` with the given context.
    func configureIfNeeded(context: ModelContext, languageManager: LanguageManager? = nil) {
        guard store == nil else { return }
        store = GearChecklistStore(context: context)
        self.languageManager = languageManager
    }
    
    /// Generates a recommended gear list for the given trail, weather and scheduled date.
    func generateGearList(
        for trail: Trail,
        weather: WeatherSnapshot,
        scheduledDate: Date
    ) {
        isLoading = true
        error = nil
        
        let season = Season.from(date: scheduledDate)
        let duration = trail.estimatedDurationMinutes / 60
        
        // Create localization function if languageManager is available
        let localize: ((String) -> String)? = languageManager.map { lm in
            { key in lm.localizedString(for: key) }
        }
        
        let items = getGearService().generateGearList(
            difficulty: trail.difficulty,
            weather: weather,
            season: season,
            duration: duration,
            localize: localize
        )
        
        // Set `hikeId` for all items so they can be queried per hike.
        for item in items {
            item.hikeId = trail.id
        }
        
        currentHikeId = trail.id
        gearItems = items
        isLoading = false
        
        // Auto-save generated items to JSON file store
        saveGearItems()
    }
    
    /// Loads stored gear items for a specific hike from the JSON file store (like journals).
    func loadGearItems(for hikeId: UUID) {
        currentHikeId = hikeId
        do {
            // Load all items from FileStore and filter by hikeId
            let allItems = try gearItemFileStore.loadAll()
            gearItems = allItems.filter { $0.hikeId == hikeId }
            print("✅ GearChecklistViewModel: Loaded \(gearItems.count) gear items for hike \(hikeId.uuidString) from JSON store")
        } catch {
            self.error = "Failed to load gear items: \(error.localizedDescription)"
            print("❌ GearChecklistViewModel: Failed to load gear items: \(error)")
        }
    }
    
    /// Persists the current in-memory gear items to the JSON file store (like journals).
    func saveGearItems() {
        guard let hikeId = currentHikeId else {
            print("⚠️ GearChecklistViewModel: No hikeId set, cannot save gear items")
            return
        }
        do {
            // Load all existing items
            var allItems = try gearItemFileStore.loadAll()
            
            // Remove old items for this hike
            allItems.removeAll { $0.hikeId == hikeId }
            
            // Add current items
            allItems.append(contentsOf: gearItems)
            
            // Save all items
            try gearItemFileStore.saveAll(allItems)
            print("✅ GearChecklistViewModel: Saved \(gearItems.count) gear items for hike \(hikeId.uuidString) to JSON store")
        } catch {
            self.error = "Failed to save gear items: \(error.localizedDescription)"
            print("❌ GearChecklistViewModel: Failed to save gear items: \(error)")
        }
    }
    
    /// Toggles completion state for a single gear item and saves the change to JSON file store.
    func toggleItem(_ item: GearItem) {
        // Update the item directly (GearItem is a class, so this modifies the reference)
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        
        // Save to FileStore
        do {
            try gearItemFileStore.saveOrUpdate(item)
            objectWillChange.send()
            print("✅ GearChecklistViewModel: Toggled item '\(item.name)' completion to \(item.isCompleted)")
        } catch {
            // Revert the change if save failed
            item.isCompleted.toggle()
            self.error = "Failed to update gear item: \(error.localizedDescription)"
            print("❌ GearChecklistViewModel: Failed to toggle item: \(error)")
        }
    }
    
    /// Refreshes gear items from the JSON file store.
    func refreshGearItems() {
        guard let hikeId = currentHikeId else { return }
        loadGearItems(for: hikeId)
    }
    
    /// Number of gear items that are marked as completed.
    var completedCount: Int {
        gearItems.filter { $0.isCompleted }.count
    }
    
    /// Total number of gear items.
    var totalCount: Int {
        gearItems.count
    }
    
    /// Number of required gear items that are completed.
    var requiredCompletedCount: Int {
        gearItems.filter { $0.isRequired && $0.isCompleted }.count
    }
    
    /// Total number of required gear items.
    var requiredTotalCount: Int {
        gearItems.filter { $0.isRequired }.count
    }
    
    /// Indicates whether all required gear items have been completed.
    var isAllRequiredCompleted: Bool {
        requiredCompletedCount == requiredTotalCount && requiredTotalCount > 0
    }
    
    /// Groups gear items by their category for easier sectioned display.
    var itemsByCategory: [GearItem.GearCategory: [GearItem]] {
        Dictionary(grouping: gearItems) { $0.category }
    }
}

