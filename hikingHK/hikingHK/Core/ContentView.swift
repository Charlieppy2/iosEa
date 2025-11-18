//
//  ContentView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//


import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(languageManager.localizedString(for: "home.title"), systemImage: "house.fill")
                }
            TrailListView()
                .tabItem {
                    Label(languageManager.localizedString(for: "trails.title"), systemImage: "map.fill")
                }
            PlannerView()
                .tabItem {
                    Label(languageManager.localizedString(for: "planner.title"), systemImage: "calendar.badge.plus")
                }
            ProfileView()
                .tabItem {
                    Label(languageManager.localizedString(for: "profile.title"), systemImage: "person.circle.fill")
                }
        }
        .tint(Color.hikingGreen)
        .hikingBackgroundWithPattern()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
        .environmentObject(SessionManager.previewSignedIn())
        .environmentObject(LanguageManager.shared)
}
