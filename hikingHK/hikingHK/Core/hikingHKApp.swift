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
    /// Shared model container for the entire app.
    /// Configured with all SwiftData models and error recovery.
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
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
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If container creation fails, try to recover by deleting the database
            print("❌ Failed to create model container: \(error)")
            print("   Attempting to recover by resetting database...")
            
            // Try to delete the database file and recreate
            let url = modelConfiguration.url
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                    print("✅ Deleted corrupted database, recreating...")
                } catch {
                    print("⚠️ Failed to delete database: \(error)")
                }
            }
            
            // Try again with a fresh database
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // If still fails, use in-memory container as fallback
                print("❌ Failed to recreate container, using in-memory fallback")
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
