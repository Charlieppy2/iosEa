//
//  OfflineMapsFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist offline map region status, avoiding SwiftData synchronization issues.
//  Refactored to use the unified BaseFileStore architecture.
//

import Foundation

/// DTO used for JSON persistence of an offline map region.
struct PersistedOfflineRegion: FileStoreDTO {
    var id: UUID
    var accountId: UUID // User account ID
    var name: String
    var downloadStatus: OfflineMapRegion.DownloadStatus
    var downloadProgress: Double
    var downloadedSize: Int64
    var totalSize: Int64
    var downloadedAt: Date?
    var lastUpdated: Date
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns the ID of the region for identification.
    var modelId: UUID { id }
}

/// Persists and loads offline map region metadata using the file system.
/// Refactored to use the unified BaseFileStore architecture.
@MainActor
final class OfflineMapsFileStore: BaseFileStore<OfflineMapRegion, PersistedOfflineRegion> {
    
    init() {
        super.init(fileName: "offline_maps.json")
    }
    
    // MARK: - Custom Loading (with sorting)
    
    /// Loads all regions sorted by name.
    override func loadAll() throws -> [OfflineMapRegion] {
        let all = try super.loadAll()
        return all.sorted { $0.name < $1.name }
    }
    
    // MARK: - Convenience Methods (backward compatibility)
    
    /// Convenience method for backward compatibility.
    func loadAllRegions() throws -> [OfflineMapRegion] {
        return try loadAll()
    }
    
    /// Convenience method for backward compatibility (batch save).
    /// This method merges the provided regions with existing regions from other users
    /// to ensure data isolation across different user accounts.
    func saveRegions(_ regions: [OfflineMapRegion]) throws {
        // If regions is empty, don't save anything (preserve existing data)
        guard !regions.isEmpty else {
            return
        }
        
        // Get the accountId from the first region (all regions should have the same accountId)
        let accountId = regions.first!.accountId
        
        // Load all existing regions from the file
        let allExisting = try loadPersistedDTOs()
        
        // Filter out regions belonging to the current user
        let otherUsersRegions = allExisting.filter { $0.accountId != accountId }
        
        // Convert new regions to DTOs
        let newDTOs = regions.map { PersistedOfflineRegion(from: $0) }
        
        // Merge: other users' regions + current user's new regions
        let mergedDTOs = otherUsersRegions + newDTOs
        
        // Save the merged data
        try persist(dtos: mergedDTOs)
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedOfflineRegion {
    init(from model: OfflineMapRegion) {
        self.id = model.id
        self.accountId = model.accountId
        self.name = model.name
        self.downloadStatus = model.downloadStatus
        self.downloadProgress = model.downloadProgress
        self.downloadedSize = model.downloadedSize
        self.totalSize = model.totalSize
        self.downloadedAt = model.downloadedAt
        self.lastUpdated = model.lastUpdated
    }
    
    func toModel() -> OfflineMapRegion {
        let region = OfflineMapRegion(
            id: id,
            accountId: accountId,
            name: name,
            downloadStatus: downloadStatus,
            downloadProgress: downloadProgress,
            downloadedSize: downloadedSize,
            totalSize: totalSize,
            downloadedAt: downloadedAt
        )
        region.lastUpdated = lastUpdated
        return region
    }
}


