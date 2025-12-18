//
//  FileStoreExample.swift
//  hikingHK
//
//  Example implementation showing how to use the unified FileManager + JSON architecture.
//  This file demonstrates how to refactor existing stores to use BaseFileStore.
//

import Foundation

// MARK: - Example: Refactored JournalFileStore

/// Example DTO for HikeJournal persistence.
struct PersistedJournalDTO: FileStoreDTO {
    struct PersistedPhoto: Codable {
        var id: UUID
        var imageData: Data
        var caption: String?
        var takenAt: Date
        var order: Int
    }

    var id: UUID
    var title: String
    var content: String
    var hikeDate: Date
    var createdAt: Date
    var updatedAt: Date
    var trailId: UUID?
    var trailName: String?
    var weatherCondition: String?
    var temperature: Double?
    var humidity: Double?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationName: String?
    var hikeRecordId: UUID?
    var isShared: Bool
    var shareToken: String?
    var photos: [PersistedPhoto]
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns the ID of the journal for identification.
    var modelId: UUID { id }
    
    init(from model: HikeJournal) {
        self.id = model.id
        self.title = model.title
        self.content = model.content
        self.hikeDate = model.hikeDate
        self.createdAt = model.createdAt
        self.updatedAt = model.updatedAt
        self.trailId = model.trailId
        self.trailName = model.trailName
        self.weatherCondition = model.weatherCondition
        self.temperature = model.temperature
        self.humidity = model.humidity
        self.locationLatitude = model.locationLatitude
        self.locationLongitude = model.locationLongitude
        self.locationName = model.locationName
        self.hikeRecordId = model.hikeRecordId
        self.isShared = model.isShared
        self.shareToken = model.shareToken
        self.photos = model.photos.map {
            PersistedPhoto(
                id: $0.id,
                imageData: $0.imageData,
                caption: $0.caption,
                takenAt: $0.takenAt,
                order: $0.order
            )
        }
    }
    
    func toModel() -> HikeJournal {
        let journal = HikeJournal(
            id: id,
            title: title,
            content: content,
            hikeDate: hikeDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            trailId: trailId,
            trailName: trailName,
            weatherCondition: weatherCondition,
            temperature: temperature,
            humidity: humidity,
            locationLatitude: locationLatitude,
            locationLongitude: locationLongitude,
            locationName: locationName,
            hikeRecordId: hikeRecordId,
            isShared: isShared,
            shareToken: shareToken
        )
        
        // Restore photos
        let restoredPhotos: [JournalPhoto] = photos.map {
            let photo = JournalPhoto(
                id: $0.id,
                imageData: $0.imageData,
                caption: $0.caption,
                takenAt: $0.takenAt,
                order: $0.order
            )
            photo.journal = journal
            return photo
        }
        journal.photos = restoredPhotos.sorted { $0.order < $1.order }
        
        return journal
    }
}

/// Example refactored JournalFileStore using BaseFileStore.
/// This replaces the original JournalFileStore with a cleaner implementation.
@MainActor
final class JournalFileStoreRefactored: BaseFileStore<HikeJournal, PersistedJournalDTO> {
    
    init() {
        super.init(fileName: "journals.json")
    }
    
    /// Loads all journals sorted by hike date (most recent first).
    override func loadAll() throws -> [HikeJournal] {
        let all = try super.loadAll()
        return all.sorted { $0.hikeDate > $1.hikeDate }
    }
}

// MARK: - Example: Simple Store (OfflineMapRegion)

/// Example DTO for OfflineMapRegion persistence.
struct PersistedOfflineRegionDTO: FileStoreDTO {
    var id: UUID
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

/// Example refactored OfflineMapsFileStore using BaseFileStore.
@MainActor
final class OfflineMapsFileStoreRefactored: BaseFileStore<OfflineMapRegion, PersistedOfflineRegionDTO> {
    
    init() {
        super.init(fileName: "offline_maps.json")
    }
    
    /// Loads all regions sorted by name.
    override func loadAll() throws -> [OfflineMapRegion] {
        let all = try super.loadAll()
        return all.sorted { $0.name < $1.name }
    }
}

