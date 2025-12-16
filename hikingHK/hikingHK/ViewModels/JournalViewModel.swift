//
//  JournalViewModel.swift
//  hikingHK
//
//  用 FileManager + JSON 持久化行山日記，完全不用 SwiftData 讀寫
//

import Foundation
import Combine
import CoreLocation
import SwiftData // 只為了兼容 configureIfNeeded(context:)，不再用來持久化

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var journals: [HikeJournal] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let fileStore = JournalFileStore()
    private var isConfigured = false

    /// 為兼容舊代碼：context 現在只用來觸發第一次 refresh，實際持久化用 JSON
    func configureIfNeeded(context: ModelContext, skipRefresh: Bool = false) {
        guard !isConfigured else { return }
        isConfigured = true
        print("📋 JournalViewModel: Configured (file-based)")
        if !skipRefresh {
            refreshJournals()
        }
    }

    /// 從 JSON 讀取所有日記
    func refreshJournals() {
        do {
            let loaded = try fileStore.loadAllJournals()
            journals = loaded
            print("✅ JournalViewModel: Refreshed \(loaded.count) journals from JSON store")
        } catch let err {
            self.error = "Failed to load journals: \(err.localizedDescription)"
            print("❌ JournalViewModel: Failed to refresh journals: \(err)")
        }
    }

    /// 新增日記
    func createJournal(
        title: String,
        content: String,
        hikeDate: Date,
        trailId: UUID? = nil,
        trailName: String? = nil,
        weatherCondition: String? = nil,
        temperature: Double? = nil,
        humidity: Double? = nil,
        location: CLLocationCoordinate2D? = nil,
        locationName: String? = nil,
        hikeRecordId: UUID? = nil,
        photos: [Data] = []
    ) throws {
        print("💾 JournalViewModel: Creating journal (file-based)")

        let journal = HikeJournal(
            title: title,
            content: content,
            hikeDate: hikeDate,
            trailId: trailId,
            trailName: trailName,
            weatherCondition: weatherCondition,
            temperature: temperature,
            humidity: humidity,
            locationLatitude: location?.latitude,
            locationLongitude: location?.longitude,
            locationName: locationName,
            hikeRecordId: hikeRecordId
        )

        // 照片
        for (index, data) in photos.enumerated() {
            let photo = JournalPhoto(imageData: data, caption: nil, takenAt: Date(), order: index)
            photo.journal = journal
            journal.photos.append(photo)
        }

        try fileStore.saveOrUpdateJournal(journal)
        print("✅ JournalViewModel: Saved journal '\(title)' (ID: \(journal.id)) to JSON store")

        journals.insert(journal, at: 0)
        journals.sort { $0.hikeDate > $1.hikeDate }
        objectWillChange.send()
    }

    /// 兼容舊簽名：帶 context 版本會直接調用不帶 context 的實作
    func createJournal(
        title: String,
        content: String,
        hikeDate: Date,
        trailId: UUID? = nil,
        trailName: String? = nil,
        weatherCondition: String? = nil,
        temperature: Double? = nil,
        humidity: Double? = nil,
        location: CLLocationCoordinate2D? = nil,
        locationName: String? = nil,
        hikeRecordId: UUID? = nil,
        photos: [Data] = [],
        context: ModelContext
    ) throws {
        try createJournal(
            title: title,
            content: content,
            hikeDate: hikeDate,
            trailId: trailId,
            trailName: trailName,
            weatherCondition: weatherCondition,
            temperature: temperature,
            humidity: humidity,
            location: location,
            locationName: locationName,
            hikeRecordId: hikeRecordId,
            photos: photos
        )
    }

    /// 更新日記
    func updateJournal(
        _ journal: HikeJournal,
        title: String,
        content: String,
        hikeDate: Date,
        photos: [Data] = []
    ) throws {
        journal.title = title
        journal.content = content
        journal.hikeDate = hikeDate

        if !photos.isEmpty {
            journal.photos.removeAll()
            for (index, data) in photos.enumerated() {
                let photo = JournalPhoto(imageData: data, caption: nil, takenAt: Date(), order: index)
                photo.journal = journal
                journal.photos.append(photo)
            }
        }

        try fileStore.saveOrUpdateJournal(journal)
        journals.sort { $0.hikeDate > $1.hikeDate }
        objectWillChange.send()
    }

    /// 刪除日記
    func deleteJournal(_ journal: HikeJournal) throws {
        try fileStore.deleteJournal(journal)
        journals.removeAll { $0.id == journal.id }
        objectWillChange.send()
    }

    /// 切換分享狀態
    func toggleShare(_ journal: HikeJournal) throws {
        journal.isShared.toggle()
        try fileStore.saveOrUpdateJournal(journal)
        objectWillChange.send()
    }

    // MARK: - 月份分組 / 排序

    var journalsByMonth: [String: [HikeJournal]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        return Dictionary(grouping: journals) { journal in
            formatter.string(from: journal.hikeDate)
        }
    }

    var sortedMonths: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        return journalsByMonth.keys.sorted { m1, m2 in
            guard let d1 = formatter.date(from: m1),
                  let d2 = formatter.date(from: m2) else { return false }
            return d1 > d2
        }
    }
}


