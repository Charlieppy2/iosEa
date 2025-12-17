//
//  OfflineMapsFileStore.swift
//  hikingHK
//
//  使用 FileManager + JSON 持久化離線地圖區域狀態，避開 SwiftData 的同步問題
//

import Foundation

/// 用於 JSON 持久化的離線地圖區域 DTO
private struct PersistedOfflineRegion: Codable {
    var id: UUID
    var name: String
    var downloadStatus: OfflineMapRegion.DownloadStatus
    var downloadProgress: Double
    var downloadedSize: Int64
    var totalSize: Int64
    var downloadedAt: Date?
    var lastUpdated: Date
}

/// 使用檔案系統儲存與載入離線地圖區域
final class OfflineMapsFileStore {
    private let fileURL: URL
    
    init(fileName: String = "offline_maps.json") {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = directory.appendingPathComponent(fileName)
    }
    
    // MARK: - Public API
    
    func loadAllRegions() throws -> [OfflineMapRegion] {
        let persisted = try loadPersistedRegions()
        return persisted
            .map { $0.toModel() }
            .sorted { $0.name < $1.name }
    }
    
    func saveRegions(_ regions: [OfflineMapRegion]) throws {
        let persisted = regions.map { PersistedOfflineRegion(from: $0) }
        try persist(regions: persisted)
    }
    
    // MARK: - Private helpers
    
    private func loadPersistedRegions() throws -> [PersistedOfflineRegion] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        if data.isEmpty {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PersistedOfflineRegion].self, from: data)
    }
    
    private func persist(regions: [PersistedOfflineRegion]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(regions)
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - DTO <-> Model 轉換

private extension PersistedOfflineRegion {
    init(from model: OfflineMapRegion) {
        self.id = model.id
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


