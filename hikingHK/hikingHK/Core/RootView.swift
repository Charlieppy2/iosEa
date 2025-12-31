//
//  RootView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI
import SwiftData

/// Entry view that decides whether to show authentication or the main content,
/// and wires up shared environment objects.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var languageManager = LanguageManager.shared
    @State private var didConfigure = false
    @State private var viewRefreshID = UUID()

    var body: some View {
        Group {
            if sessionManager.currentUser != nil {
                ContentView()
                    .environmentObject(appViewModel)
                    .environmentObject(sessionManager)
                    .environmentObject(languageManager)
                    .environment(\.locale, Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US"))
                    .id("logged_in_\(sessionManager.currentUser?.id.uuidString ?? "")") // Force refresh when the logged-in user changes
                    .transition(.opacity)
            } else {
                AuthView()
                    .environmentObject(sessionManager)
                    .environmentObject(languageManager)
                    .environment(\.locale, Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US"))
                    .id("logged_out_\(viewRefreshID.uuidString)") // Force refresh when logging out
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionManager.currentUser != nil)
        .onChange(of: sessionManager.currentUser) { oldValue, newValue in
            print("🔄 RootView: currentUser changed from \(oldValue?.email ?? "nil") to \(newValue?.email ?? "nil")")
            print("🔄 RootView: Will show \(newValue != nil ? "ContentView" : "AuthView")")
            
            // When the user logs in, reload user-scoped data
            if oldValue == nil && newValue != nil, let accountId = newValue?.id {
                print("🔄 RootView: User logged in, reloading data for account: \(accountId)...")
                appViewModel.configurePersistenceIfNeeded(context: modelContext)
                // Ensure data is loaded after configuration
                appViewModel.reloadUserData(accountId: accountId)
            }
            
            // When the user logs out, ensure the view refreshes
            if oldValue != nil && newValue == nil {
                print("🔄 RootView: User logged out, switching to AuthView...")
                viewRefreshID = UUID() // Force view refresh
            }
        }
        .onAppear {
            print("🔄 RootView: Appeared, currentUser: \(sessionManager.currentUser?.email ?? "nil")")
            print("🔄 RootView: Will show \(sessionManager.currentUser != nil ? "ContentView" : "AuthView")")
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
                Achievement.self,
                HikeJournal.self,
                JournalPhoto.self
            ],
            inMemory: true
        )
}

