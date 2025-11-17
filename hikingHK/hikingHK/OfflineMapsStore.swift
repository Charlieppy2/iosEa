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
        guard existing.isEmpty else { return }
        
        let defaultRegions = OfflineMapRegion.availableRegions.map { name in
            OfflineMapRegion(name: name)
        }
        
        defaultRegions.forEach { context.insert($0) }
        try context.save()
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
}

