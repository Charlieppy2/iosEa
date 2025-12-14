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
    private var safetyChecklistStore: SafetyChecklistStore?
    private var hasSeeded = false
    
    func configureIfNeeded(context: ModelContext) async {
        // 如果已经配置过，只刷新项目列表
        if let existingStore = safetyChecklistStore {
            refreshItems()
            return
        }
        
        print("🔧 SafetyChecklistViewModel: configureIfNeeded called")
        
        let store = SafetyChecklistStore(context: context)
        safetyChecklistStore = store
        
        do {
            print("🔧 SafetyChecklistViewModel: Seeding default items...")
            try store.seedDefaultsIfNeeded()
            hasSeeded = true
            print("✅ SafetyChecklistViewModel: Seeding completed")
            // 刷新项目列表
            refreshItems()
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
                try newStore.seedDefaultsIfNeeded()
                refreshItems()
            } catch {
                print("❌ SafetyChecklistViewModel: Failed to seed items: \(error)")
            }
            return
        }
        
        do {
            // 使用 Store 的 seedDefaultsIfNeeded 方法
            try store.seedDefaultsIfNeeded()
            // 等待一小段时间
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            // 刷新项目列表
            refreshItems()
            print("✅ SafetyChecklistViewModel: Created and refreshed items")
        } catch {
            print("❌ SafetyChecklistViewModel: Failed to create items: \(error)")
        }
    }
    
    func toggleItem(_ item: SafetyChecklistItem, context: ModelContext) {
        // 直接使用 context 更新
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        do {
            try context.save()
            // 刷新项目列表
            refreshItems()
        } catch {
            print("❌ Toggle safety item error: \(error)")
        }
    }
}

