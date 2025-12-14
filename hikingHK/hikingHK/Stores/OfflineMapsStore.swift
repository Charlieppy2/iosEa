//
//  OfflineMapsStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class OfflineMapsStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func seedDefaultsIfNeeded() throws -> [OfflineMapRegion] {
        let descriptor = FetchDescriptor<OfflineMapRegion>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            print("OfflineMapsStore: Found \(existing.count) existing regions, skipping seed")
            // 返回所有现有区域
            return try loadAllRegions()
        }
        
        print("OfflineMapsStore: Seeding default regions...")
        let defaultRegions = OfflineMapRegion.availableRegions.map { name in
            OfflineMapRegion(name: name)
        }
        
        for region in defaultRegions {
            context.insert(region)
        }
        
        try context.save()
        print("OfflineMapsStore: Successfully seeded \(defaultRegions.count) regions")
        
        // 立即返回已插入的区域，而不是查询
        print("OfflineMapsStore: Returning \(defaultRegions.count) inserted regions directly")
        return defaultRegions.sorted { $0.name < $1.name }
    }
    
    func loadAllRegions() throws -> [OfflineMapRegion] {
        // 先尝试不使用排序的简单查询
        let simpleDescriptor = FetchDescriptor<OfflineMapRegion>()
        let allRegions = try context.fetch(simpleDescriptor)
        print("OfflineMapsStore: loadAllRegions() fetched \(allRegions.count) regions (no sort)")
        
        // 手动排序
        return allRegions.sorted { $0.name < $1.name }
    }
    
    func getRegion(named name: String) throws -> OfflineMapRegion? {
        var descriptor = FetchDescriptor<OfflineMapRegion>(
            predicate: #Predicate { $0.name == name }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    func updateRegion(_ region: OfflineMapRegion) throws {
        region.lastUpdated = Date()
        try context.save()
    }
    
    func deleteRegion(_ region: OfflineMapRegion) throws {
        context.delete(region)
        try context.save()
    }
    
    func forceSeedRegions() throws -> [OfflineMapRegion] {
        // 强制创建所有默认区域，即使已存在
        print("OfflineMapsStore: Force seeding regions...")
        let defaultRegions = OfflineMapRegion.availableRegions.map { name in
            OfflineMapRegion(name: name)
        }
        
        for region in defaultRegions {
            context.insert(region)
        }
        
        try context.save()
        print("OfflineMapsStore: Force seeded \(defaultRegions.count) regions")
        
        // 立即返回已插入的区域，而不是查询
        print("OfflineMapsStore: Returning \(defaultRegions.count) inserted regions directly")
        return defaultRegions.sorted { $0.name < $1.name }
    }
}

