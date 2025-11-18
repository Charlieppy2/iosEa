//
//  JournalViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import Combine
import CoreLocation

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var journals: [HikeJournal] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private var store: JournalStore?
    private var modelContext: ModelContext?
    
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        self.modelContext = context
        store = JournalStore(context: context)
        refreshJournals()
    }
    
    func refreshJournals() {
        guard let store = store else { return }
        do {
            journals = try store.loadAllJournals()
        } catch {
            self.error = "Failed to load journals: \(error.localizedDescription)"
        }
    }
    
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
        guard let store = store else { return }
        
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
        
        // 添加照片
        for (index, photoData) in photos.enumerated() {
            let photo = JournalPhoto(
                imageData: photoData,
                order: index
            )
            journal.photos.append(photo)
        }
        
        try store.saveJournal(journal)
        refreshJournals()
    }
    
    func updateJournal(
        _ journal: HikeJournal,
        title: String,
        content: String,
        hikeDate: Date,
        photos: [Data] = []
    ) throws {
        guard let store = store else { return }
        
        journal.title = title
        journal.content = content
        journal.hikeDate = hikeDate
        
        // 更新照片
        if !photos.isEmpty {
            // 刪除舊照片
            journal.photos.removeAll()
            
            // 添加新照片
            for (index, photoData) in photos.enumerated() {
                let photo = JournalPhoto(
                    imageData: photoData,
                    order: index
                )
                journal.photos.append(photo)
            }
        }
        
        try store.updateJournal(journal)
        refreshJournals()
    }
    
    func deleteJournal(_ journal: HikeJournal) throws {
        guard let store = store else { return }
        try store.deleteJournal(journal)
        refreshJournals()
    }
    
    func toggleShare(_ journal: HikeJournal) throws {
        guard let store = store else { return }
        journal.isShared.toggle()
        try store.updateJournal(journal)
        refreshJournals()
    }
    
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
        
        return journalsByMonth.keys.sorted { month1, month2 in
            guard let date1 = formatter.date(from: month1),
                  let date2 = formatter.date(from: month2) else {
                return false
            }
            return date1 > date2
        }
    }
}

