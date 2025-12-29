//
//  OfflineMapsStore.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

/// Store responsible for seeding, loading and updating `OfflineMapRegion` records via SwiftData.
@MainActor
final class OfflineMapsStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// Inserts the default offline regions if none exist, and returns all regions.
    func seedDefaultsIfNeeded() throws -> [OfflineMapRegion] {
        let descriptor = FetchDescriptor<OfflineMapRegion>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            print("OfflineMapsStore: Found \(existing.count) existing regions, skipping seed")
            // Return all existing regions if seeding is not needed.
            return try loadAllRegions()
        }
        
        print("OfflineMapsStore: Seeding default regions...")
        let downloadService = OfflineMapsDownloadService()
        let defaultRegions = OfflineMapRegion.availableRegions.map { name in
            let estimatedSize = downloadService.getEstimatedSize(for: name)
            return OfflineMapRegion(name: name, totalSize: estimatedSize)
        }
        
        for region in defaultRegions {
            context.insert(region)
        }
        
        try context.save()
        print("OfflineMapsStore: Successfully seeded \(defaultRegions.count) regions")
        
        // Return the inserted regions directly instead of querying again.
        print("OfflineMapsStore: Returning \(defaultRegions.count) inserted regions directly")
        return defaultRegions.sorted { $0.name < $1.name }
    }
    
    /// Loads all offline map regions, sorted by name.
    func loadAllRegions() throws -> [OfflineMapRegion] {
        // First perform an unsorted fetch from SwiftData.
        let simpleDescriptor = FetchDescriptor<OfflineMapRegion>()
        let allRegions = try context.fetch(simpleDescriptor)
        print("OfflineMapsStore: loadAllRegions() fetched \(allRegions.count) regions (no sort)")
        
        // Manually sort by name to avoid SortDescriptor limitations with @Model.
        return allRegions.sorted { $0.name < $1.name }
    }
    
    /// Fetches a single region by its display name.
    func getRegion(named name: String) throws -> OfflineMapRegion? {
        var descriptor = FetchDescriptor<OfflineMapRegion>(
            predicate: #Predicate { $0.name == name }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    /// Updates the `lastUpdated` timestamp and saves a region.
    func updateRegion(_ region: OfflineMapRegion) throws {
        region.lastUpdated = Date()
        try context.save()
    }
    
    /// Deletes a region from the SwiftData context.
    func deleteRegion(_ region: OfflineMapRegion) throws {
        context.delete(region)
        try context.save()
    }
    
    /// Force-creates all default regions even if they already exist.
    /// Primarily useful for debugging or testing seeding behaviour.
    func forceSeedRegions() throws -> [OfflineMapRegion] {
        print("OfflineMapsStore: Force seeding regions...")
        let downloadService = OfflineMapsDownloadService()
        let defaultRegions = OfflineMapRegion.availableRegions.map { name in
            let estimatedSize = downloadService.getEstimatedSize(for: name)
            return OfflineMapRegion(name: name, totalSize: estimatedSize)
        }
        
        for region in defaultRegions {
            context.insert(region)
        }
        
        try context.save()
        print("OfflineMapsStore: Force seeded \(defaultRegions.count) regions")
        
        // Return the inserted regions directly instead of querying again.
        print("OfflineMapsStore: Returning \(defaultRegions.count) inserted regions directly")
        return defaultRegions.sorted { $0.name < $1.name }
    }
}

