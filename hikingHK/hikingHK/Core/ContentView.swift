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
                    Label("Home", systemImage: "house.fill")
                }
            TrailListView()
                .tabItem {
                    Label("Trails", systemImage: "map.fill")
                }
            PlannerView()
                .tabItem {
                    Label("Planner", systemImage: "calendar.badge.plus")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
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
