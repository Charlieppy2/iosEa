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
    @State private var didConfigure = false

    var body: some View {
        Group {
            if sessionManager.currentUser != nil {
                ContentView()
                    .environmentObject(appViewModel)
                    .environmentObject(sessionManager)
            } else {
                AuthView()
                    .environmentObject(sessionManager)
            }
        }
        .task {
            guard !didConfigure else { return }
            await sessionManager.configureIfNeeded(context: modelContext)
            didConfigure = true
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: UserCredential.self, inMemory: true)
}

