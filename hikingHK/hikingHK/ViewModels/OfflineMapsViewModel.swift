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
    func configureIfNeeded(context: ModelContext) async {
        // If already configured, just refresh the region list.
        if let existingStore = offlineMapsStore {
            do {
                regions = try existingStore.loadAllRegions()
                if regions.isEmpty {
                    // If the list is empty, try to re-seed the default regions.
                    let seededRegions = try existingStore.seedDefaultsIfNeeded()
                    regions = seededRegions
                }
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
            let persisted = try fileStore.loadAllRegions()
            if !persisted.isEmpty {
                regions = persisted
                print("✅ OfflineMapsViewModel: Loaded \(regions.count) regions from JSON store")
                return
            }
            
            // 2️⃣ If JSON is empty, use SwiftData to create/load default regions, then persist to JSON.
            let seededRegions = try store.seedDefaultsIfNeeded()
            // Use the returned regions directly instead of querying again.
            regions = seededRegions
            
            // If the region list is still empty, force-create default regions.
            if regions.isEmpty {
                print("⚠️ OfflineMapsViewModel: Regions list is still empty after seeding, forcing creation...")
                let forceSeededRegions = try store.forceSeedRegions()
                regions = forceSeededRegions
                print("✅ OfflineMapsViewModel: Force created \(regions.count) regions")
            } else {
                print("✅ OfflineMapsViewModel: Loaded \(regions.count) regions")
            }
            
            // Persist the initialized regions to JSON as the primary source for future loads.
            try? fileStore.saveRegions(regions)
        } catch {
            print("❌ Offline maps load error: \(error)")
            self.error = "Failed to load offline map regions: \(error.localizedDescription)"
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
            refreshRegions()
        } catch {
            print("Delete region error: \(error)")
            self.error = "Failed to delete region: \(error.localizedDescription)"
        }
    }
    
    /// Ensures a default set of offline regions exists.
    /// If none exist, they will be created through the store and assigned to `regions`.
    func createDefaultRegions(context: ModelContext) async {
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
                let seededRegions = try newStore.seedDefaultsIfNeeded()
                regions = seededRegions
                print("✅ OfflineMapsViewModel: Created store and seeded \(seededRegions.count) regions")
            } catch {
                print("❌ OfflineMapsViewModel: Failed to seed regions: \(error)")
            }
            return
        }
        
        do {
            // Use the store's `seedDefaultsIfNeeded` to get the regions directly.
            let createdRegions = try store.seedDefaultsIfNeeded()
            print("✅ OfflineMapsViewModel: Created \(createdRegions.count) regions")
            // Set `regions` directly instead of querying again.
            regions = createdRegions
            print("✅ OfflineMapsViewModel: Set regions directly, count: \(regions.count)")
        } catch {
            print("❌ OfflineMapsViewModel: Failed to create regions: \(error)")
            // If creation fails, try to refresh from the store.
            refreshRegions()
        }
    }
    
    /// Reloads regions from the store and reconciles download status with on-disk files.
    func refreshRegions() {
        guard let store = offlineMapsStore else { return }
        do {
            regions = try store.loadAllRegions()
            
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

