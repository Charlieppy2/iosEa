//
//  SafetyChecklistViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class SafetyChecklistViewModel: ObservableObject {
    @Published var items: [SafetyChecklistItem] = []
    @Published var isLoading = false
    
    private var safetyChecklistStore: SafetyChecklistStore?
    
    func configureIfNeeded(context: ModelContext) {
        guard safetyChecklistStore == nil else { return }
        let store = SafetyChecklistStore(context: context)
        safetyChecklistStore = store
        
        do {
            try store.seedDefaultsIfNeeded()
            items = try store.loadAllItems()
        } catch {
            print("Safety checklist load error: \(error)")
        }
    }
    
    func toggleItem(_ item: SafetyChecklistItem) {
        guard let store = safetyChecklistStore else { return }
        do {
            try store.toggleItem(id: item.id)
            // Refresh items to ensure UI is in sync with SwiftData
            refreshItems()
        } catch {
            print("Toggle safety item error: \(error)")
        }
    }
    
    func refreshItems() {
        guard let store = safetyChecklistStore else { return }
        do {
            items = try store.loadAllItems()
        } catch {
            print("Refresh safety items error: \(error)")
        }
    }
    
    var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        items.count
    }
    
    var isAllCompleted: Bool {
        !items.isEmpty && items.allSatisfy { $0.isCompleted }
    }
}

