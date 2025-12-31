//
//  ContentView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI
import UIKit


/// Root tab-based container shown after the user has signed in.
struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var languageManager: LanguageManager
    
    init() {
        // Customize the TabBar background to match the hiking theme instead of the default white.
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.hikingBackground)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
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
                .environment(\.locale, Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US"))
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


