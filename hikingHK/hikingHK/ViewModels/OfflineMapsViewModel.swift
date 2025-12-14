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
    
    func configureIfNeeded(context: ModelContext) {
        guard offlineMapsStore == nil else { return }
        let store = OfflineMapsStore(context: context)
        offlineMapsStore = store
        
        do {
            try store.seedDefaultsIfNeeded()
            regions = try store.loadAllRegions()
        } catch {
            print("Offline maps load error: \(error)")
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
            
            // 更新状态
            region.downloadStatus = .notDownloaded
            region.downloadProgress = 0
            region.downloadedSize = 0
            region.downloadedAt = nil
            
            // 从数据库删除
            try store.deleteRegion(region)
            regions.removeAll { $0.id == region.id }
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

