import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "sparkle")
                }
            TrailListView()
                .tabItem {
                    Label("Trails", systemImage: "map")
                }
            PlannerView()
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
        .environmentObject(SessionManager.previewSignedIn())
}
//
//  ContentView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

