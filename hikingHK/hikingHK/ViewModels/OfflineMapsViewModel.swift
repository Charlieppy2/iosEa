//
//  OfflineMapsViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class OfflineMapsViewModel: ObservableObject {
    @Published var regions: [OfflineMapRegion] = []
    @Published var downloadingRegion: OfflineMapRegion?
    @Published var error: String?
    
    private var offlineMapsStore: OfflineMapsStore?
    private let downloadService: OfflineMapsDownloadServiceProtocol
    private var downloadTask: Task<Void, Never>?
    
    init(
        downloadService: OfflineMapsDownloadServiceProtocol = OfflineMapsDownloadService()
    ) {
        self.downloadService = downloadService
    }
    
    func configureIfNeeded(context: ModelContext) async {
        // 如果已经配置过，只刷新区域列表
        if let existingStore = offlineMapsStore {
            do {
                regions = try existingStore.loadAllRegions()
                if regions.isEmpty {
                    // 如果列表为空，尝试重新初始化
                    try existingStore.seedDefaultsIfNeeded()
                    regions = try existingStore.loadAllRegions()
                }
            } catch {
                print("Offline maps refresh error: \(error)")
            }
            return
        }
        
        // 首次配置
        let store = OfflineMapsStore(context: context)
        offlineMapsStore = store
        
        do {
            try store.seedDefaultsIfNeeded()
            regions = try store.loadAllRegions()
            
            // 如果区域列表仍然为空，强制创建
            if regions.isEmpty {
                print("⚠️ OfflineMapsViewModel: Regions list is still empty after seeding, forcing creation...")
                try store.forceSeedRegions()
                regions = try store.loadAllRegions()
                print("✅ OfflineMapsViewModel: Force created \(regions.count) regions")
            } else {
                print("✅ OfflineMapsViewModel: Loaded \(regions.count) regions")
            }
        } catch {
            print("❌ Offline maps load error: \(error)")
            self.error = "Failed to load offline map regions: \(error.localizedDescription)"
        }
    }
    
    func downloadRegion(_ region: OfflineMapRegion) {
        guard region.downloadStatus != .downloading else { return }
        guard let store = offlineMapsStore else { return }
        
        // Cancel any existing download
        downloadTask?.cancel()
        
        region.downloadStatus = .downloading
        region.downloadProgress = 0
        region.totalSize = downloadService.getEstimatedSize(for: region.name)
        downloadingRegion = region
        
        do {
            try store.updateRegion(region)
        } catch {
            print("Update region error: \(error)")
        }
        
        downloadTask = Task {
            do {
                try await downloadService.downloadRegion(region) { progress, downloaded, total in
                    Task { @MainActor in
                        region.downloadProgress = progress
                        region.downloadedSize = downloaded
                        region.totalSize = total
                        try? store.updateRegion(region)
                    }
                }
                
                // Download completed
                if !Task.isCancelled {
                    region.downloadStatus = .downloaded
                    region.downloadProgress = 1.0
                    region.downloadedAt = Date()
                    region.downloadedSize = region.totalSize
                    downloadingRegion = nil
                    try? store.updateRegion(region)
                }
            } catch {
                if !Task.isCancelled {
                    region.downloadStatus = .failed
                    region.downloadProgress = 0
                    downloadingRegion = nil
                    self.error = "Download failed: \(error.localizedDescription)"
                    try? store.updateRegion(region)
                }
            }
        }
    }
    
    func cancelDownload(_ region: OfflineMapRegion) {
        downloadTask?.cancel()
        region.downloadStatus = .notDownloaded
        region.downloadProgress = 0
        downloadingRegion = nil
        
        if let store = offlineMapsStore {
            try? store.updateRegion(region)
        }
    }
    
    func deleteRegion(_ region: OfflineMapRegion) {
        guard let store = offlineMapsStore else { return }
        do {
            // 删除文件数据
            try downloadService.deleteRegionData(region)
            
            // 更新状态（不删除，只重置）
            region.downloadStatus = .notDownloaded
            region.downloadProgress = 0
            region.downloadedSize = 0
            region.downloadedAt = nil
            region.totalSize = 0
            
            // 更新数据库
            try store.updateRegion(region)
            
            // 刷新列表
            refreshRegions()
        } catch {
            print("Delete region error: \(error)")
            self.error = "Failed to delete region: \(error.localizedDescription)"
        }
    }
    
    func refreshRegions() {
        guard let store = offlineMapsStore else { return }
        do {
            regions = try store.loadAllRegions()
            
            // 检查每个区域的下载状态
            for region in regions {
                if downloadService.isRegionDownloaded(region) && region.downloadStatus != .downloaded {
                    // 文件存在但状态不对，更新状态
                    region.downloadStatus = .downloaded
                    region.downloadProgress = 1.0
                    try? store.updateRegion(region)
                } else if !downloadService.isRegionDownloaded(region) && region.downloadStatus == .downloaded {
                    // 状态显示已下载但文件不存在，重置状态
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

