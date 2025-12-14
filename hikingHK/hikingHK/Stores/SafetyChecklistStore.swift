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
        // 先检查是否已存在数据
        var descriptor = FetchDescriptor<SafetyChecklistItem>()
        descriptor.fetchLimit = 1
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            print("SafetyChecklistStore: Found \(existing.count) existing items, skipping seed")
            return
        }
        
        print("SafetyChecklistStore: Seeding default safety checklist items...")
        
        // 创建默认项目
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
    }
    
    func loadAllItems() throws -> [SafetyChecklistItem] {
        // 先尝试不使用排序的简单查询
        let simpleDescriptor = FetchDescriptor<SafetyChecklistItem>()
        let allItems = try context.fetch(simpleDescriptor)
        print("SafetyChecklistStore: loadAllItems() fetched \(allItems.count) items (no sort)")
        
        // 手动排序
        return allItems.sorted { $0.id < $1.id }
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

