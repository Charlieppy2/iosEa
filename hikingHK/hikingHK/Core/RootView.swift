//
//  RootView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var languageManager = LanguageManager.shared
    @State private var didConfigure = false

    var body: some View {
        Group {
            if sessionManager.currentUser != nil {
                ContentView()
                    .environmentObject(appViewModel)
                    .environmentObject(sessionManager)
                    .environmentObject(languageManager)
                    .id("logged_in_\(sessionManager.currentUser?.id.uuidString ?? "")") // 强制在用户变化时刷新
            } else {
                AuthView()
                    .environmentObject(sessionManager)
                    .environmentObject(languageManager)
                    .id("logged_out") // 确保登出视图有唯一 ID
            }
        }
        .onChange(of: sessionManager.currentUser) { oldValue, newValue in
            print("🔄 RootView: currentUser changed from \(oldValue?.email ?? "nil") to \(newValue?.email ?? "nil")")
        }
        .task {
            guard !didConfigure else { return }
            await sessionManager.configureIfNeeded(context: modelContext)
            appViewModel.configurePersistenceIfNeeded(context: modelContext)
            didConfigure = true
        }
    }
}

#Preview {
    RootView()
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
                SpeciesIdentificationRecord.self,
                Achievement.self,
                HikeJournal.self,
                JournalPhoto.self
            ],
            inMemory: true
        )
}

