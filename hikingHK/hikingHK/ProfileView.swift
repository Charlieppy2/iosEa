import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    private var completedCount: Int {
        viewModel.savedHikes.count
    }

    var body: some View {
        NavigationStack {
            List {
                accountSection
                statsSection
                Section("Goals") {
                    Label("Complete 4 Ridge Lines", systemImage: "flag.2.crossed")
                    Label("Log 50 km this month", systemImage: "chart.line.uptrend.xyaxis")
                }
                Section("Data & services") {
                    Label("Connected: HK Weather API", systemImage: "cloud.sun")
                    Label("GPS tracking enabled", systemImage: "location")
                    Label("Offline tiles ready", systemImage: "arrow.down.circle")
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var accountSection: some View {
        Section("Account") {
            if let user = sessionManager.currentUser {
                HStack(spacing: 16) {
                    Image(systemName: user.avatarSymbol)
                        .font(.title3)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Button("Sign out", role: .destructive) {
                sessionManager.signOut()
            }
        }
    }

    private var statsSection: some View {
        Section("Journey") {
            HStack {
                stat(value: "\(completedCount)", label: "planned")
                stat(value: "\(viewModel.trails.filter { $0.isFavorite }.count)", label: "favorites")
                stat(value: "\(totalDistance().formatted(.number.precision(.fractionLength(1)))) km", label: "logged")
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack {
            Text(value)
                .font(.title3.weight(.bold))
            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func totalDistance() -> Double {
        viewModel.savedHikes
            .map(\.trail.lengthKm)
            .reduce(0, +)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
        .environmentObject(SessionManager.previewSignedIn())
}
//
//  ProfileView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//


