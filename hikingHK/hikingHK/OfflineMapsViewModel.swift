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
            try store.deleteRegion(region)
            regions.removeAll { $0.id == region.id }
        } catch {
            print("Delete region error: \(error)")
        }
    }
    
    func refreshRegions() {
        guard let store = offlineMapsStore else { return }
        do {
            regions = try store.loadAllRegions()
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

