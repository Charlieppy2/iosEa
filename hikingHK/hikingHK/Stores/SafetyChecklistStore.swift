//
//  SafetyChecklistStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class SafetyChecklistStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func seedDefaultsIfNeeded() throws {
        let descriptor = FetchDescriptor<SafetyChecklistItem>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else { return }
        
        let defaultItems = [
            SafetyChecklistItem(id: "location", iconName: "location.fill", title: "Enable Live Location"),
            SafetyChecklistItem(id: "water", iconName: "drop.fill", title: "Pack 2L of water"),
            SafetyChecklistItem(id: "heat", iconName: "bolt.heart", title: "Check heat stroke signal"),
            SafetyChecklistItem(id: "offline", iconName: "antenna.radiowaves.left.and.right", title: "Download offline map"),
            SafetyChecklistItem(id: "share", iconName: "person.2.wave.2", title: "Share hike plan with buddies")
        ]
        
        defaultItems.forEach { context.insert($0) }
        try context.save()
    }
    
    func loadAllItems() throws -> [SafetyChecklistItem] {
        let descriptor = FetchDescriptor<SafetyChecklistItem>(
            sortBy: [SortDescriptor(\.id)]
        )
        return try context.fetch(descriptor)
    }
    
    func toggleItem(id: String) throws {
        var descriptor = FetchDescriptor<SafetyChecklistItem>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let item = try context.fetch(descriptor).first else { return }
        
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        try context.save()
    }
    
    func setItemCompleted(id: String, isCompleted: Bool) throws {
        var descriptor = FetchDescriptor<SafetyChecklistItem>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let item = try context.fetch(descriptor).first else { return }
        
        item.isCompleted = isCompleted
        item.lastUpdated = Date()
        try context.save()
    }
}

