//
//  JournalFileStore.swift
//  hikingHK
//
//  使用 FileManager + JSON 持久化行山日記，避開 SwiftData 的同步問題
//

import Foundation
import CoreLocation

/// 用於 JSON 持久化的日記 DTO
private struct PersistedJournal: Codable {
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
}

/// 使用檔案系統儲存與載入日記
@MainActor
final class JournalFileStore {
    private let fileURL: URL

    init(fileName: String = "journals.json") {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = directory.appendingPathComponent(fileName)
    }

    // MARK: - Public API

    func loadAllJournals() throws -> [HikeJournal] {
        let persisted = try loadPersistedJournals()
        return persisted.map { $0.toModel() }.sorted { $0.hikeDate > $1.hikeDate }
    }

    func saveOrUpdateJournal(_ journal: HikeJournal) throws {
        var persisted = try loadPersistedJournals()
        let dto = PersistedJournal(from: journal)

        if let index = persisted.firstIndex(where: { $0.id == dto.id }) {
            persisted[index] = dto
        } else {
            persisted.append(dto)
        }

        try persist(journals: persisted)
    }

    func deleteJournal(_ journal: HikeJournal) throws {
        var persisted = try loadPersistedJournals()
        persisted.removeAll { $0.id == journal.id }
        try persist(journals: persisted)
    }

    // MARK: - Private helpers

    private func loadPersistedJournals() throws -> [PersistedJournal] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        if data.isEmpty {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PersistedJournal].self, from: data)
    }

    private func persist(journals: [PersistedJournal]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(journals)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - DTO <-> Model 轉換

private extension PersistedJournal {
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

        // 還原照片
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


