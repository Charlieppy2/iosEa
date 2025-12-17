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
    private var gearService: SmartGearServiceProtocol?
    
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
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        store = GearChecklistStore(context: context)
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
        
        let items = getGearService().generateGearList(
            difficulty: trail.difficulty,
            weather: weather,
            season: season,
            duration: duration
        )
        
        // Set `hikeId` for all items so they can be queried per hike.
        for item in items {
            item.hikeId = trail.id
        }
        
        gearItems = items
        isLoading = false
    }
    
    /// Loads stored gear items for a specific hike from the store.
    func loadGearItems(for hikeId: UUID) {
        guard let store = store else { return }
        do {
            gearItems = try store.loadGearItems(for: hikeId)
        } catch {
            self.error = "Failed to load gear items: \(error.localizedDescription)"
        }
    }
    
    /// Persists the current in-memory gear items to the store.
    func saveGearItems() {
        guard let store = store else { return }
        do {
            try store.saveGearItems(gearItems)
        } catch {
            self.error = "Failed to save gear items: \(error.localizedDescription)"
        }
    }
    
    /// Toggles completion state for a single gear item and saves the change.
    func toggleItem(_ item: GearItem) {
        guard let store = store else { return }
        do {
            try store.toggleItem(item)
        } catch {
            self.error = "Failed to update gear item: \(error.localizedDescription)"
        }
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

