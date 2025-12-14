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
    
    func seedDefaultsIfNeeded() throws {
        let descriptor = FetchDescriptor<OfflineMapRegion>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            print("OfflineMapsStore: Found \(existing.count) existing regions, skipping seed")
            return
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
    }
    
    func loadAllRegions() throws -> [OfflineMapRegion] {
        let descriptor = FetchDescriptor<OfflineMapRegion>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
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
    
    func forceSeedRegions() throws {
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
    }
}

