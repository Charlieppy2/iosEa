//
//  OfflineMapRegion.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@Model
final class OfflineMapRegion {
    var id: UUID
    var name: String
    var downloadStatus: DownloadStatus
    var downloadProgress: Double
    var downloadedSize: Int64
    var totalSize: Int64
    var downloadedAt: Date?
    var lastUpdated: Date
    
    enum DownloadStatus: String, Codable {
        case notDownloaded = "Not Downloaded"
        case downloading = "Downloading"
        case downloaded = "Downloaded"
        case failed = "Failed"
        case updating = "Updating"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        downloadStatus: DownloadStatus = .notDownloaded,
        downloadProgress: Double = 0,
        downloadedSize: Int64 = 0,
        totalSize: Int64 = 0,
        downloadedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.downloadStatus = downloadStatus
        self.downloadProgress = downloadProgress
        self.downloadedSize = downloadedSize
        self.totalSize = totalSize
        self.downloadedAt = downloadedAt
        self.lastUpdated = Date()
    }
}

extension OfflineMapRegion {
    static let availableRegions = [
        "Hong Kong Island",
        "Kowloon Ridge",
        "Sai Kung East",
        "Lantau North"
    ]
    
    var formattedSize: String {
        let mb = Double(downloadedSize) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
    
    var formattedTotalSize: String {
        let mb = Double(totalSize) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
}

