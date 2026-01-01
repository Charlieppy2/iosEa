//
//  OfflineMapsViewModel.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData
import Combine

/// View model for managing offline map regions, downloads, and local JSON persistence.
@MainActor
final class OfflineMapsViewModel: ObservableObject {
    @Published var regions: [OfflineMapRegion] = []
    @Published var downloadingRegion: OfflineMapRegion?
    @Published var error: String?
    
    private var offlineMapsStore: OfflineMapsStore?
    private let downloadService: OfflineMapsDownloadServiceProtocol
    private let fileStore = OfflineMapsFileStore()
    private var downloadTask: Task<Void, Never>?
    
    /// Creates a new offline maps view model with an injectable download service (useful for testing).
    init(
        downloadService: OfflineMapsDownloadServiceProtocol = OfflineMapsDownloadService()
    ) {
        self.downloadService = downloadService
    }
    
    /// Lazily configures the underlying `OfflineMapsStore` and loads all regions.
    /// Uses JSON as the primary source when available, and falls back to SwiftData seeding.
    /// - Parameters:
    ///   - context: The SwiftData model context.
    ///   - accountId: The user account ID to load regions for.
    func configureIfNeeded(context: ModelContext, accountId: UUID) async {
        // If already configured, refresh the region list and check for missing regions.
        if let existingStore = offlineMapsStore {
            do {
                // Always call seedDefaultsIfNeeded to ensure all available regions are present
                // This will add any missing regions without affecting existing ones
                let seededRegions = try existingStore.seedDefaultsIfNeeded(accountId: accountId)
                regions = seededRegions
                
                // Reconcile download status with file system
                for region in regions {
                    if region.totalSize == 0 {
                        region.totalSize = downloadService.getEstimatedSize(for: region.name)
                        try? existingStore.updateRegion(region)
                    }
                    
                    if downloadService.isRegionDownloaded(region) && region.downloadStatus != .downloaded {
                        region.downloadStatus = .downloaded
                        region.downloadProgress = 1.0
                        try? existingStore.updateRegion(region)
                    } else if !downloadService.isRegionDownloaded(region) && region.downloadStatus == .downloaded {
                        region.downloadStatus = .notDownloaded
                        region.downloadProgress = 0
                        region.downloadedSize = 0
                        try? existingStore.updateRegion(region)
                    }
                }
                
                // Persist updated regions to JSON
                try? fileStore.saveRegions(regions)
            } catch {
                print("Offline maps refresh error: \(error)")
            }
            return
        }
        
        // First-time configuration of the backing store.
        let store = OfflineMapsStore(context: context)
        offlineMapsStore = store
        
        do {
            // 1️⃣ Prefer loading from JSON if we have previously persisted regions.
            // BaseFileStore will automatically recover from corrupted files by returning empty array
            let persisted = try fileStore.loadAllRegions()
            // Filter by accountId to ensure data isolation
            let filteredPersisted = persisted.filter { $0.accountId == accountId }
            if !filteredPersisted.isEmpty {
                regions = filteredPersisted
                print("✅ OfflineMapsViewModel: Loaded \(regions.count) regions from JSON store (filtered by accountId: \(accountId))")
                
                // Check if there are missing regions and add them
                let seededRegions = try store.seedDefaultsIfNeeded(accountId: accountId)
                if seededRegions.count > regions.count {
                    print("✅ OfflineMapsViewModel: Added \(seededRegions.count - regions.count) missing regions")
                    regions = seededRegions
                    // Persist updated regions to JSON
                    try? fileStore.saveRegions(regions)
                }
                return
            }
            
            // 2️⃣ If JSON is empty (or was corrupted and recovered), use SwiftData to create/load default regions, then persist to JSON.
            let seededRegions = try store.seedDefaultsIfNeeded(accountId: accountId)
            // Use the returned regions directly instead of querying again.
            regions = seededRegions
            
            // If the region list is still empty, force-create default regions.
            if regions.isEmpty {
                print("⚠️ OfflineMapsViewModel: Regions list is still empty after seeding, forcing creation...")
                let forceSeededRegions = try store.forceSeedRegions(accountId: accountId)
                regions = forceSeededRegions
                print("✅ OfflineMapsViewModel: Force created \(regions.count) regions")
            } else {
                print("✅ OfflineMapsViewModel: Loaded \(regions.count) regions")
            }
            
            // Persist the initialized regions to JSON as the primary source for future loads.
            try? fileStore.saveRegions(regions)
        } catch {
            // If loading from JSON failed (e.g., corrupted file), BaseFileStore should have recovered automatically
            // But if SwiftData operations fail, we should still try to continue with empty regions
            print("⚠️ Offline maps load error: \(error)")
            print("   Attempting to recover by creating default regions...")
            
            // Try to recover by creating default regions
            do {
                let forceSeededRegions = try store.forceSeedRegions(accountId: accountId)
                regions = forceSeededRegions
                print("✅ OfflineMapsViewModel: Recovered by creating \(regions.count) default regions")
                // Persist the recovered regions
                try? fileStore.saveRegions(regions)
            } catch {
                // If even recovery fails, just log the error but don't show it to the user
                print("❌ OfflineMapsViewModel: Recovery failed: \(error)")
                // Set regions to empty array so the UI can still function
                regions = []
            }
        }
    }
    
    /// Starts downloading tiles for a specific offline map region and tracks progress.
    func downloadRegion(_ region: OfflineMapRegion) {
        guard region.downloadStatus != .downloading else { return }
        
        // Cancel any existing download task before starting a new one.
        downloadTask?.cancel()
        
        region.downloadStatus = .downloading
        region.downloadProgress = 0
        region.totalSize = downloadService.getEstimatedSize(for: region.name)
        downloadingRegion = region
        
        // Persist the state before starting the download (e.g. show "downloading" immediately).
        try? fileStore.saveRegions(regions)
        
        downloadTask = Task {
            do {
                try await downloadService.downloadRegion(region) { progress, downloaded, total in
                    Task { @MainActor in
                        region.downloadProgress = progress
                        region.downloadedSize = downloaded
                        region.totalSize = total
                        
                        // If progress reaches 100%, immediately mark as downloaded
                        if progress >= 1.0 {
                            region.downloadStatus = .downloaded
                            region.downloadProgress = 1.0
                            region.downloadedAt = Date()
                            region.downloadedSize = total
                            self.downloadingRegion = nil
                        }
                        
                        try? self.fileStore.saveRegions(self.regions)
                    }
                }
                
                // Download completed successfully - ensure final state is set
                if !Task.isCancelled {
                    region.downloadStatus = .downloaded
                    region.downloadProgress = 1.0
                    region.downloadedAt = Date()
                    region.downloadedSize = region.totalSize
                    downloadingRegion = nil
                    try? self.fileStore.saveRegions(self.regions)
                }
            } catch {
                if !Task.isCancelled {
                    region.downloadStatus = .failed
                    region.downloadProgress = 0
                    downloadingRegion = nil
                    self.error = "Download failed: \(error.localizedDescription)"
                    try? self.fileStore.saveRegions(self.regions)
                }
            }
        }
    }
    
    /// Cancels the current download and resets the region's download state.
    func cancelDownload(_ region: OfflineMapRegion) {
        downloadTask?.cancel()
        region.downloadStatus = .notDownloaded
        region.downloadProgress = 0
        downloadingRegion = nil
        try? fileStore.saveRegions(regions)
    }
    
    /// Deletes the downloaded data for a region and resets its metadata.
    func deleteRegion(_ region: OfflineMapRegion) {
        do {
            // Delete the on-disk map data.
            try downloadService.deleteRegionData(region)
            
            // Keep the region record but reset all download-related fields.
            region.downloadStatus = .notDownloaded
            region.downloadProgress = 0
            region.downloadedSize = 0
            region.downloadedAt = nil
            region.totalSize = 0
            
            // Persist the updated region list back to JSON.
            try? fileStore.saveRegions(regions)
            
            // Refresh the list so UI and store stay in sync with the file system.
            // Use the region's accountId to refresh from the store.
            refreshRegions(accountId: region.accountId)
        } catch {
            print("Delete region error: \(error)")
            self.error = "Failed to delete region: \(error.localizedDescription)"
        }
    }
    
    /// Ensures a default set of offline regions exists.
    /// If none exist, they will be created through the store and assigned to `regions`.
    /// Creates default regions for a specific user.
    /// - Parameters:
    ///   - context: The SwiftData model context.
    ///   - accountId: The user account ID to create regions for.
    func createDefaultRegions(context: ModelContext, accountId: UUID) async {
        print("🔧 OfflineMapsViewModel: Creating default regions...")
        
        // If we already have regions, do not create them again.
        if !regions.isEmpty {
            print("⚠️ OfflineMapsViewModel: Regions already exist (\(regions.count) regions), skipping creation")
            return
        }
        
        // Use the store to create regions if it already exists.
        guard let store = offlineMapsStore else {
            print("⚠️ OfflineMapsViewModel: Store is nil, creating store...")
            let newStore = OfflineMapsStore(context: context)
            offlineMapsStore = newStore
            do {
                let seededRegions = try newStore.seedDefaultsIfNeeded(accountId: accountId)
                regions = seededRegions
                print("✅ OfflineMapsViewModel: Created store and seeded \(seededRegions.count) regions")
            } catch {
                print("❌ OfflineMapsViewModel: Failed to seed regions: \(error)")
            }
            return
        }
        
        do {
            // Use the store's `seedDefaultsIfNeeded` to get the regions directly.
            let createdRegions = try store.seedDefaultsIfNeeded(accountId: accountId)
            print("✅ OfflineMapsViewModel: Created \(createdRegions.count) regions")
            // Set `regions` directly instead of querying again.
            regions = createdRegions
            print("✅ OfflineMapsViewModel: Set regions directly, count: \(regions.count)")
        } catch {
            print("❌ OfflineMapsViewModel: Failed to create regions: \(error)")
            // If creation fails, try to refresh from the store.
            refreshRegions(accountId: accountId)
        }
    }
    
    /// Reloads regions from the store and reconciles download status with on-disk files.
    /// - Parameter accountId: The user account ID to load regions for.
    func refreshRegions(accountId: UUID) {
        guard let store = offlineMapsStore else { return }
        do {
            regions = try store.loadAllRegions(accountId: accountId)
            
            // Reconcile each region's download status with the actual file system.
            for region in regions {
                // Ensure totalSize is set if it's 0 (for regions created before this update)
                if region.totalSize == 0 {
                    region.totalSize = downloadService.getEstimatedSize(for: region.name)
                    try? store.updateRegion(region)
                }
                
                if downloadService.isRegionDownloaded(region) && region.downloadStatus != .downloaded {
                    // File exists but state is wrong → mark as downloaded.
                    region.downloadStatus = .downloaded
                    region.downloadProgress = 1.0
                    try? store.updateRegion(region)
                } else if !downloadService.isRegionDownloaded(region) && region.downloadStatus == .downloaded {
                    // Marked as downloaded but file missing → reset state.
                    region.downloadStatus = .notDownloaded
                    region.downloadProgress = 0
                    region.downloadedSize = 0
                    try? store.updateRegion(region)
                }
            }
        } catch {
            print("Refresh regions error: \(error)")
        }
    }
    
    var hasDownloadedMaps: Bool {
        regions.contains { $0.downloadStatus == .downloaded }
    }
    
    var totalDownloadedSize: Int64 {
        regions
            .filter { $0.downloadStatus == .downloaded }
            .reduce(0) { $0 + $1.downloadedSize }
    }
}

