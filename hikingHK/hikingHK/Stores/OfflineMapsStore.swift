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
    
    /// Inserts the default offline regions if none exist for a specific user, and returns all regions.
    /// Also adds any missing regions from the available regions list.
    /// - Parameter accountId: The user account ID to create regions for.
    func seedDefaultsIfNeeded(accountId: UUID) throws -> [OfflineMapRegion] {
        let descriptor = FetchDescriptor<OfflineMapRegion>(
            predicate: #Predicate { $0.accountId == accountId }
        )
        let existing = try context.fetch(descriptor)
        
        // Get all available region names
        let availableRegionNames = Set(OfflineMapRegion.availableRegions)
        let existingRegionNames = Set(existing.map { $0.name })
        
        // Find missing regions
        let missingRegionNames = availableRegionNames.subtracting(existingRegionNames)
        
        if existing.isEmpty {
            print("OfflineMapsStore: No existing regions, seeding all default regions for account: \(accountId)...")
            let downloadService = OfflineMapsDownloadService()
            let defaultRegions = OfflineMapRegion.availableRegions.map { name in
                let estimatedSize = downloadService.getEstimatedSize(for: name)
                return OfflineMapRegion(accountId: accountId, name: name, totalSize: estimatedSize)
            }
            
            for region in defaultRegions {
                context.insert(region)
            }
            
            do {
                try context.save()
                print("OfflineMapsStore: Successfully seeded \(defaultRegions.count) regions")
            } catch {
                print("❌ OfflineMapsStore: Failed to save seeded regions: \(error)")
                context.processPendingChanges()
                try context.save()
                print("✅ OfflineMapsStore: Successfully saved after processing pending changes")
            }
            
            return defaultRegions.sorted { $0.name < $1.name }
        } else if !missingRegionNames.isEmpty {
            // Add missing regions
            print("OfflineMapsStore: Found \(existing.count) existing regions, adding \(missingRegionNames.count) missing regions...")
            let downloadService = OfflineMapsDownloadService()
            let newRegions = missingRegionNames.map { name in
                let estimatedSize = downloadService.getEstimatedSize(for: name)
                return OfflineMapRegion(accountId: accountId, name: name, totalSize: estimatedSize)
            }
            
            for region in newRegions {
                context.insert(region)
            }
            
            do {
                try context.save()
                print("OfflineMapsStore: Successfully added \(newRegions.count) missing regions")
            } catch {
                print("❌ OfflineMapsStore: Failed to save new regions: \(error)")
                context.processPendingChanges()
                try context.save()
                print("✅ OfflineMapsStore: Successfully saved after processing pending changes")
            }
            
            // Return all regions (existing + new)
            return try loadAllRegions(accountId: accountId)
        } else {
            print("OfflineMapsStore: Found \(existing.count) existing regions, all regions present")
            // Return all existing regions if all are present.
            return try loadAllRegions(accountId: accountId)
        }
    }
    
    /// Loads all offline map regions for a specific user, sorted by name.
    /// - Parameter accountId: The user account ID to filter regions for.
    func loadAllRegions(accountId: UUID) throws -> [OfflineMapRegion] {
        do {
            // First perform an unsorted fetch from SwiftData.
            let simpleDescriptor = FetchDescriptor<OfflineMapRegion>(
                predicate: #Predicate { $0.accountId == accountId }
            )
            let allRegions = try context.fetch(simpleDescriptor)
            print("OfflineMapsStore: loadAllRegions() fetched \(allRegions.count) regions for account: \(accountId) (no sort)")
            
            // Manually sort by name to avoid SortDescriptor limitations with @Model.
            return allRegions.sorted { $0.name < $1.name }
        } catch {
            print("❌ OfflineMapsStore: Failed to load regions: \(error)")
            // If fetch fails, try to process pending changes and retry once
            do {
                context.processPendingChanges()
                let simpleDescriptor = FetchDescriptor<OfflineMapRegion>(
                    predicate: #Predicate { $0.accountId == accountId }
                )
                let allRegions = try context.fetch(simpleDescriptor)
                print("✅ OfflineMapsStore: Successfully loaded \(allRegions.count) regions after processing pending changes")
                return allRegions.sorted { $0.name < $1.name }
            } catch {
                print("❌ OfflineMapsStore: Retry also failed: \(error)")
                throw error
            }
        }
    }
    
    /// Fetches a single region by its display name for a specific user.
    /// - Parameters:
    ///   - name: The region name.
    ///   - accountId: The user account ID to filter regions for.
    func getRegion(named name: String, accountId: UUID) throws -> OfflineMapRegion? {
        var descriptor = FetchDescriptor<OfflineMapRegion>(
            predicate: #Predicate { $0.name == name && $0.accountId == accountId }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    /// Updates the `lastUpdated` timestamp and saves a region.
    func updateRegion(_ region: OfflineMapRegion) throws {
        region.lastUpdated = Date()
        do {
            try context.save()
        } catch {
            print("❌ OfflineMapsStore: Failed to update region: \(error)")
            context.processPendingChanges()
            try context.save()
        }
    }
    
    /// Deletes a region from the SwiftData context.
    func deleteRegion(_ region: OfflineMapRegion) throws {
        context.delete(region)
        do {
            try context.save()
        } catch {
            print("❌ OfflineMapsStore: Failed to delete region: \(error)")
            context.processPendingChanges()
            try context.save()
        }
    }
    
    /// Force-creates all default regions even if they already exist.
    /// Primarily useful for debugging or testing seeding behaviour.
    /// - Parameter accountId: The user account ID to create regions for.
    func forceSeedRegions(accountId: UUID) throws -> [OfflineMapRegion] {
        print("OfflineMapsStore: Force seeding regions for account: \(accountId)...")
        let downloadService = OfflineMapsDownloadService()
        let defaultRegions = OfflineMapRegion.availableRegions.map { name in
            let estimatedSize = downloadService.getEstimatedSize(for: name)
            return OfflineMapRegion(accountId: accountId, name: name, totalSize: estimatedSize)
        }
        
        for region in defaultRegions {
            context.insert(region)
        }
        
        do {
            try context.save()
            print("OfflineMapsStore: Force seeded \(defaultRegions.count) regions")
        } catch {
            print("❌ OfflineMapsStore: Failed to save force-seeded regions: \(error)")
            context.processPendingChanges()
            try context.save()
            print("✅ OfflineMapsStore: Successfully saved after processing pending changes")
        }
        
        // Return the inserted regions directly instead of querying again.
        print("OfflineMapsStore: Returning \(defaultRegions.count) inserted regions directly")
        return defaultRegions.sorted { $0.name < $1.name }
    }
}

