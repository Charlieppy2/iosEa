//
//  hikingHKApp.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI
import SwiftData

@main
struct hikingHKApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(
            for: [
                UserCredential.self,
                SavedHikeRecord.self,
                FavoriteTrailRecord.self,
                SafetyChecklistItem.self,
                OfflineMapRegion.self,
                EmergencyContact.self,
                LocationShareSession.self,
                HikeRecord.self,
                HikeTrackPoint.self,
                UserPreference.self,
                RecommendationRecord.self,
                Achievement.self,
                HikeJournal.self,
                JournalPhoto.self,
                GearItem.self
            ]
        )
    }
}
