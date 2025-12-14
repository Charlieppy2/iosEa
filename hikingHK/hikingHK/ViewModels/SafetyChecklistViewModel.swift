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
    private var safetyChecklistStore: SafetyChecklistStore?
    private var hasSeeded = false
    
    func configureIfNeeded(context: ModelContext) async {
        // 防止重复初始化
        guard safetyChecklistStore == nil else {
            print("🔧 SafetyChecklistViewModel: Already configured")
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
        } catch {
            print("❌ Safety checklist seeding error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func toggleItem(_ item: SafetyChecklistItem, context: ModelContext) {
        // 直接使用 context 更新，@Query 会自动刷新
        item.isCompleted.toggle()
        item.lastUpdated = Date()
        do {
            try context.save()
        } catch {
            print("❌ Toggle safety item error: \(error)")
        }
    }
}

