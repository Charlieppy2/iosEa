//
//  JournalViewModel.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist hiking journals instead of SwiftData.
//

import Foundation
import Combine
import CoreLocation
import SwiftData // Only for configureIfNeeded(context:), no longer used for persistence.

@MainActor
/// ViewModel for managing hiking journal entries.
/// Uses FileManager + JSON for persistence, avoiding SwiftData synchronization issues.
final class JournalViewModel: ObservableObject {
    @Published var journals: [HikeJournal] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let fileStore = JournalFileStore()
    private var isConfigured = false

    /// For backward compatibility: context is now only used to trigger the first refresh.
    /// Actual persistence is handled by JSON.
    /// - Parameters:
    ///   - context: The SwiftData context (for compatibility).
    ///   - skipRefresh: Whether to skip the initial refresh.
    ///   - accountId: The user account ID to filter journals for.
    func configureIfNeeded(context: ModelContext, skipRefresh: Bool = false, accountId: UUID? = nil) {
        guard !isConfigured else { return }
        isConfigured = true
        print("📋 JournalViewModel: Configured (file-based)")
        if !skipRefresh {
            refreshJournals(accountId: accountId)
        }
    }

    /// Loads all journal entries from the JSON file store for a specific user.
    /// - Parameter accountId: Optional user account ID to filter journals for. If nil, loads all journals.
    func refreshJournals(accountId: UUID? = nil) {
        do {
            let loaded = try fileStore.loadAllJournals()
            // Filter by accountId if provided
            let filtered = accountId != nil ? loaded.filter { $0.accountId == accountId } : loaded
            journals = filtered
            print("✅ JournalViewModel: Refreshed \(filtered.count) journals from JSON store (accountId: \(accountId?.uuidString ?? "all"))")
        } catch let err {
            self.error = "Failed to load journals: \(err.localizedDescription)"
            print("❌ JournalViewModel: Failed to refresh journals: \(err)")
        }
    }

    /// Creates a new journal entry and saves it to the JSON file store.
    /// - Parameter accountId: The user account ID to associate this journal with.
    func createJournal(
        accountId: UUID,
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
            accountId: accountId,
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

        // Add photos to the journal
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

    /// Compatibility overload: the version with ModelContext directly calls the context-less implementation.
    /// - Parameter accountId: The user account ID to associate this journal with.
    func createJournal(
        accountId: UUID,
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
            accountId: accountId,
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

    /// Updates an existing journal entry and saves it to the JSON file store.
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

    /// Deletes a journal entry from the JSON file store.
    func deleteJournal(_ journal: HikeJournal) throws {
        try fileStore.deleteJournal(journal)
        journals.removeAll { $0.id == journal.id }
        objectWillChange.send()
    }

    /// Toggles the share status of a journal entry.
    func toggleShare(_ journal: HikeJournal) throws {
        journal.isShared.toggle()
        try fileStore.saveOrUpdateJournal(journal)
        objectWillChange.send()
    }

    // MARK: - Monthly Grouping / Sorting

    /// Groups journal entries by month and year.

    var journalsByMonth: [String: [HikeJournal]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        // 使用當前語言設置
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        formatter.locale = Locale(identifier: savedLanguage == "zh-Hant" ? "zh_Hant_HK" : "en_US")

        return Dictionary(grouping: journals) { journal in
            formatter.string(from: journal.hikeDate)
        }
    }
    /// Returns a sorted list of month strings (most recent first).
    var sortedMonths: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        // 使用當前語言設置
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        formatter.locale = Locale(identifier: savedLanguage == "zh-Hant" ? "zh_Hant_HK" : "en_US")

        return journalsByMonth.keys.sorted { m1, m2 in
            guard let d1 = formatter.date(from: m1),
                  let d2 = formatter.date(from: m2) else { return false }
            return d1 > d2
        }
    }
}


