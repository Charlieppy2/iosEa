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
    
    func seedDefaultsIfNeeded() throws -> [SafetyChecklistItem] {
        // 先检查是否已存在数据
        var descriptor = FetchDescriptor<SafetyChecklistItem>()
        descriptor.fetchLimit = 1
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            print("SafetyChecklistStore: Found \(existing.count) existing items, skipping seed")
            // 返回所有现有项目
            return try loadAllItems()
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
        
        // 立即返回已插入的项目，而不是查询
        print("SafetyChecklistStore: Returning \(defaultItems.count) inserted items directly")
        return defaultItems.sorted { $0.id < $1.id }
    }
    
    func loadAllItems() throws -> [SafetyChecklistItem] {
        // 使用简单的查询，不使用排序
        let descriptor = FetchDescriptor<SafetyChecklistItem>()
        // 不设置 fetchLimit，获取所有项目
        let allItems = try context.fetch(descriptor)
        print("SafetyChecklistStore: loadAllItems() fetched \(allItems.count) items")
        
        // 如果查询结果为空，尝试强制刷新 context
        if allItems.isEmpty {
            print("⚠️ SafetyChecklistStore: Query returned 0 items, trying to refresh context...")
            // 手动排序并返回（即使为空）
            return []
        }
        
        // 手动排序
        let sorted = allItems.sorted { $0.id < $1.id }
        print("SafetyChecklistStore: Returning \(sorted.count) sorted items")
        return sorted
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
    
    func createItem(id: String, iconName: String, title: String) throws -> SafetyChecklistItem {
        let newItem = SafetyChecklistItem(id: id, iconName: iconName, title: title)
        context.insert(newItem)
        try context.save()
        print("SafetyChecklistStore: Created new item with id: \(id), title: \(title)")
        return newItem
    }
    
    func deleteItem(_ item: SafetyChecklistItem) throws {
        context.delete(item)
        try context.save()
        print("SafetyChecklistStore: Deleted item with id: \(item.id)")
    }
}

