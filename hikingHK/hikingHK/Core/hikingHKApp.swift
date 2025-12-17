//
//  hikingHKApp.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI
import SwiftData

/// Main application entry point. Configures the SwiftData model container and shows `RootView`.
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
            ],
            isAutosaveEnabled: true,
            isUndoEnabled: false
        )
    }
}
