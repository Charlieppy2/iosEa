//
//  OfflineMapRegion.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import MapKit

/// Metadata about an offline map region and its download status/progress.
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
        
        func localizedDescription(languageManager: LanguageManager) -> String {
            switch self {
            case .notDownloaded:
                return languageManager.localizedString(for: "offline.maps.status.not.downloaded")
            case .downloading:
                return languageManager.localizedString(for: "offline.maps.status.downloading")
            case .downloaded:
                return languageManager.localizedString(for: "offline.maps.status.downloaded")
            case .failed:
                return languageManager.localizedString(for: "offline.maps.status.failed")
            case .updating:
                return languageManager.localizedString(for: "offline.maps.status.updating")
            }
        }
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
    
    // Get the localized display name for this region
    func localizedName(languageManager: LanguageManager) -> String {
        switch name {
        case "Hong Kong Island":
            return languageManager.localizedString(for: "offline.maps.region.hong.kong.island")
        case "Kowloon Ridge":
            return languageManager.localizedString(for: "offline.maps.region.kowloon.ridge")
        case "Sai Kung East":
            return languageManager.localizedString(for: "offline.maps.region.sai.kung.east")
        case "Lantau North":
            return languageManager.localizedString(for: "offline.maps.region.lantau.north")
        default:
            return name
        }
    }
    
    // Coordinate bounds for each predefined region name
    var coordinateRegion: MKCoordinateRegion {
        switch name {
        case "Hong Kong Island":
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 22.267, longitude: 114.188),
                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            )
        case "Kowloon Ridge":
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 22.350, longitude: 114.183),
                span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
            )
        case "Sai Kung East":
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 22.383, longitude: 114.350),
                span: MKCoordinateSpan(latitudeDelta: 0.20, longitudeDelta: 0.20)
            )
        case "Lantau North":
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 22.267, longitude: 113.950),
                span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
            )
        default:
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 22.319, longitude: 114.169),
                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            )
        }
    }
    
    var formattedSize: String {
        let mb = Double(downloadedSize) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
    
    var formattedTotalSize: String {
        let mb = Double(totalSize) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
}

