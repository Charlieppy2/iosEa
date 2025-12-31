//
//  JournalFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist hiking journals, avoiding SwiftData synchronization issues.
//  Refactored to use the unified BaseFileStore architecture.
//

import Foundation
import CoreLocation

/// DTO for JSON persistence of a journal entry.
struct PersistedJournal: FileStoreDTO {
    struct PersistedPhoto: Codable {
        var id: UUID
        var imageData: Data
        var caption: String?
        var takenAt: Date
        var order: Int
    }

    var id: UUID
    var accountId: UUID // User account ID
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
}

/// Manages saving and loading journal entries using the file system.
/// Refactored to use the unified BaseFileStore architecture.
@MainActor
final class JournalFileStore: BaseFileStore<HikeJournal, PersistedJournal> {
    
    init() {
        super.init(fileName: "journals.json")
    }
    
    // MARK: - Custom Loading (with sorting)
    
    /// Loads all journals sorted by hike date (most recent first).
    override func loadAll() throws -> [HikeJournal] {
        let all = try super.loadAll()
        return all.sorted { $0.hikeDate > $1.hikeDate }
    }
    
    // MARK: - Convenience Methods (backward compatibility)
    
    /// Convenience method for backward compatibility.
    func loadAllJournals() throws -> [HikeJournal] {
        return try loadAll()
    }
    
    /// Convenience method for backward compatibility.
    func saveOrUpdateJournal(_ journal: HikeJournal) throws {
        try saveOrUpdate(journal)
    }
    
    /// Convenience method for backward compatibility.
    func deleteJournal(_ journal: HikeJournal) throws {
        try delete(journal)
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedJournal {
    init(from model: HikeJournal) {
        self.id = model.id
        self.accountId = model.accountId
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
            accountId: accountId,
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
        
        // Restore photos and link them back to the journal.
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


