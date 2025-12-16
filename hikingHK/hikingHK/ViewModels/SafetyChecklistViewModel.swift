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
    @Published var itemOrder: [String] = [] // 保存 item 的顯示順序
    private var safetyChecklistStore: SafetyChecklistStore?
    private var hasSeeded = false
    
    /// 使用 UserDefaults 額外保存完成狀態，避免 SwiftData 同步問題
    private let completionDefaultsKey = "safetyChecklist.completionStates"
    /// 使用 UserDefaults 備份自定義項目內容（標題、圖示），確保重新開啓後仍然存在
    private let customItemsDefaultsKey = "safetyChecklist.customItems"
    /// 使用 UserDefaults 保存 item 的顯示順序
    private let itemOrderDefaultsKey = "safetyChecklist.itemOrder"
    
    /// 自定義 checklist item 的簡單 DTO，方便寫入 UserDefaults
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
    
    /// 將 UserDefaults 中的完成狀態套用到當前 items
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
    
    /// 根據保存的順序重新排列 items，如果沒有保存的順序則使用默認順序（按 ID 排序）
    private func applyItemOrder() {
        let savedOrder = loadItemOrder()
        
        if savedOrder.isEmpty {
            // 如果沒有保存的順序，使用默認順序（按 ID 排序）
            itemOrder = items.map { $0.id }.sorted { $0 < $1 }
        } else {
            // 使用保存的順序，但確保所有現有 items 都在順序中
            var order = savedOrder.filter { id in items.contains(where: { $0.id == id }) }
            // 添加任何不在順序中的新 items（按 ID 排序）
            let missingIds = items.map { $0.id }.filter { !order.contains($0) }.sorted { $0 < $1 }
            order.append(contentsOf: missingIds)
            itemOrder = order
        }
        
        // 根據順序重新排列 items
        let reorderedItems = itemOrder.compactMap { id in
            items.first(where: { $0.id == id })
        }
        
        // 只有在順序改變時才更新
        if reorderedItems.map({ $0.id }) != items.map({ $0.id }) {
            items = reorderedItems
            objectWillChange.send()
        }
    }
    
    /// 移動 item 到新位置
    func moveItem(from source: IndexSet, to destination: Int, context: ModelContext) {
        // 手動實現移動邏輯（處理單個或多個 item 的移動）
        var reorderedItems = items
        var itemsToMove: [SafetyChecklistItem] = []
        
        // 按降序移除，避免索引變化問題
        for index in source.sorted(by: >) {
            itemsToMove.insert(reorderedItems.remove(at: index), at: 0)
        }
        
        // 計算正確的插入位置
        let insertIndex = min(destination, reorderedItems.count)
        
        // 在目標位置插入
        for (offset, item) in itemsToMove.enumerated() {
            reorderedItems.insert(item, at: insertIndex + offset)
        }
        
        items = reorderedItems
        
        // 更新順序
        itemOrder = items.map { $0.id }
        // 保存順序
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
    
    /// 如果 SwiftData 讀出來的 items 缺少某些自定義項目，根據備份重新建立，同時套用完成狀態
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
    
    func configureIfNeeded(context: ModelContext) async {
        // 如果已经配置过，只刷新项目列表
        if let existingStore = safetyChecklistStore {
            // 如果 items 已经有数据，不需要刷新
            if !items.isEmpty {
                print("✅ SafetyChecklistViewModel: Already configured with \(items.count) items")
                return
            }
            // 只有在 items 为空时才刷新
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
            // 直接使用返回的项目，而不是查询
            items = seededItems
            print("✅ SafetyChecklistViewModel: Set items directly, count: \(items.count)")
            // 套用已保存的完成狀態並還原自定義項目
            applyCompletionStatesFromDefaults()
            restoreCustomItemsIfNeeded()
            // 應用保存的順序
            applyItemOrder()
        } catch {
            print("❌ Safety checklist seeding error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func refreshItems() {
        guard let store = safetyChecklistStore else {
            print("⚠️ SafetyChecklistViewModel: Store is nil, cannot refresh")
            return
        }
        do {
            let loadedItems = try store.loadAllItems()
            items = loadedItems
            print("✅ SafetyChecklistViewModel: Refreshed \(loadedItems.count) items")
            // 套用已保存的完成狀態並還原自定義項目
            applyCompletionStatesFromDefaults()
            restoreCustomItemsIfNeeded()
            // 應用保存的順序
            applyItemOrder()
        } catch {
            print("❌ Refresh safety items error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func createDefaultItems(context: ModelContext) async {
        print("🔧 SafetyChecklistViewModel: Creating default items...")
        
        // 检查是否已有项目
        if !items.isEmpty {
            print("⚠️ SafetyChecklistViewModel: Items already exist (\(items.count) items), skipping creation")
            return
        }
        
        // 使用 Store 来创建项目
        guard let store = safetyChecklistStore else {
            print("⚠️ SafetyChecklistViewModel: Store is nil, creating store...")
            let newStore = SafetyChecklistStore(context: context)
            safetyChecklistStore = newStore
            do {
                let seededItems = try newStore.seedDefaultsIfNeeded()
                items = seededItems
                print("✅ SafetyChecklistViewModel: Created store and seeded \(seededItems.count) items")
                applyCompletionStatesFromDefaults()
                restoreCustomItemsIfNeeded()
                applyItemOrder()
            } catch {
                print("❌ SafetyChecklistViewModel: Failed to seed items: \(error)")
            }
            return
        }
        
        do {
            // 使用 Store 的 seedDefaultsIfNeeded 方法，直接获取返回的项目
            let createdItems = try store.seedDefaultsIfNeeded()
            print("✅ SafetyChecklistViewModel: Created \(createdItems.count) items")
            // 直接设置 items，而不是查询
            items = createdItems
            print("✅ SafetyChecklistViewModel: Set items directly, count: \(items.count)")
            applyCompletionStatesFromDefaults()
            restoreCustomItemsIfNeeded()
            applyItemOrder()
        } catch {
            print("❌ SafetyChecklistViewModel: Failed to create items: \(error)")
            // 如果失败，尝试刷新
            refreshItems()
        }
    }
    
    func toggleItem(_ item: SafetyChecklistItem, context: ModelContext) {
        // 直接更新 item 状态
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        
        // 手动触发 @Published 更新，因为修改引用类型对象不会自动触发
        objectWillChange.send()
        
        // 更新本地完成狀態緩存（UserDefaults）
        var states = loadCompletionStates()
        states[item.id] = item.isCompleted
        saveCompletionStates(states)
        
        do {
            // 強制處理待處理的更改，然後保存到 SwiftData
            context.processPendingChanges()
            try context.save()
            
            let completedCount = items.filter { $0.isCompleted }.count
            print("✅ SafetyChecklistViewModel: Toggled item \(item.id), isCompleted: \(item.isCompleted), progress: \(completedCount)/\(items.count)")
        } catch {
            print("❌ Toggle safety item error: \(error)")
            // 如果保存失败，恢复状态
            item.isCompleted.toggle()
            // 回滾 UserDefaults 狀態
            states[item.id] = item.isCompleted
            saveCompletionStates(states)
            objectWillChange.send() // 触发更新以恢复 UI
        }
    }
    
    func addItem(title: String, iconName: String = "checkmark.circle", context: ModelContext) throws {
        guard let store = safetyChecklistStore else {
            throw NSError(domain: "SafetyChecklistViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Store not configured"])
        }
        
        // 生成唯一的 ID
        let newId = "custom_\(UUID().uuidString)"
        let newItem = try store.createItem(id: newId, iconName: iconName, title: title)
        
        // 添加到 items 数组的最頂部
        items.insert(newItem, at: 0)
        
        // 更新順序：新 item 添加到最頂部（索引 0）
        itemOrder.insert(newItem.id, at: 0)
        saveItemOrder(itemOrder)
        
        // 將新 item 的狀態（默認為 false）保存到 UserDefaults
        var states = loadCompletionStates()
        states[newItem.id] = newItem.isCompleted
        saveCompletionStates(states)
        
        // 保存自定義項目備份（title 和 iconName）
        var backups = loadCustomItemsBackup()
        let dto = CustomItemDTO(id: newItem.id, title: newItem.title, iconName: newItem.iconName)
        backups.append(dto)
        saveCustomItemsBackup(backups)
        
        // 觸發 UI 更新
        objectWillChange.send()
        
        print("✅ SafetyChecklistViewModel: Added new item at top, total: \(items.count), saved to UserDefaults and backup")
    }
    
    func deleteItem(_ item: SafetyChecklistItem, context: ModelContext) throws {
        guard let store = safetyChecklistStore else {
            throw NSError(domain: "SafetyChecklistViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Store not configured"])
        }
        
        try store.deleteItem(item)
        
        // 从 items 数组中移除
        items.removeAll { $0.id == item.id }
        
        // 從順序中移除
        itemOrder.removeAll { $0 == item.id }
        saveItemOrder(itemOrder)
        
        // 從 UserDefaults 中移除對應的狀態
        var states = loadCompletionStates()
        states.removeValue(forKey: item.id)
        saveCompletionStates(states)
        
        // 從備份中移除自定義項目（如果是自定義項目的話）
        if item.id.hasPrefix("custom_") {
            var backups = loadCustomItemsBackup()
            backups.removeAll { $0.id == item.id }
            saveCustomItemsBackup(backups)
        }
        
        print("✅ SafetyChecklistViewModel: Deleted item, total: \(items.count), removed from UserDefaults and backup")
    }
}

