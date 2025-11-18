//
//  GearChecklistViewModel.swift
//  hikingHK
//
//  Created for gear checklist view model
//

import Foundation
import SwiftData
import Combine

@MainActor
final class GearChecklistViewModel: ObservableObject {
    @Published var gearItems: [GearItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var store: GearChecklistStore?
    private var gearService: SmartGearServiceProtocol?
    
    nonisolated init(gearService: SmartGearServiceProtocol? = nil) {
        self.gearService = gearService
    }
    
    private func getGearService() -> SmartGearServiceProtocol {
        if let service = gearService {
            return service
        }
        return SmartGearService()
    }
    
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        store = GearChecklistStore(context: context)
    }
    
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
        
        // Set hikeId for all items
        for item in items {
            item.hikeId = trail.id
        }
        
        gearItems = items
        isLoading = false
    }
    
    func loadGearItems(for hikeId: UUID) {
        guard let store = store else { return }
        do {
            gearItems = try store.loadGearItems(for: hikeId)
        } catch {
            self.error = "Failed to load gear items: \(error.localizedDescription)"
        }
    }
    
    func saveGearItems() {
        guard let store = store else { return }
        do {
            try store.saveGearItems(gearItems)
        } catch {
            self.error = "Failed to save gear items: \(error.localizedDescription)"
        }
    }
    
    func toggleItem(_ item: GearItem) {
        guard let store = store else { return }
        do {
            try store.toggleItem(item)
        } catch {
            self.error = "Failed to update gear item: \(error.localizedDescription)"
        }
    }
    
    var completedCount: Int {
        gearItems.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        gearItems.count
    }
    
    var requiredCompletedCount: Int {
        gearItems.filter { $0.isRequired && $0.isCompleted }.count
    }
    
    var requiredTotalCount: Int {
        gearItems.filter { $0.isRequired }.count
    }
    
    var isAllRequiredCompleted: Bool {
        requiredCompletedCount == requiredTotalCount && requiredTotalCount > 0
    }
    
    var itemsByCategory: [GearItem.GearCategory: [GearItem]] {
        Dictionary(grouping: gearItems) { $0.category }
    }
}

