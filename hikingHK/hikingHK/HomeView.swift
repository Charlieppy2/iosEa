//
//  HomeView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var isShowingSafetySheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    weatherCard
                    if let featured = viewModel.featuredTrail {
                        featuredTrailCard(featured)
                    }
                    quickActions
                    savedHikesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle("Hiking HK")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.refreshWeather() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingWeather)
                    .accessibilityLabel("Refresh weather")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingSafetySheet.toggle()
                    } label: {
                        Label("Safety", systemImage: "cross.case")
                    }
                }
            }
            .sheet(isPresented: $isShowingSafetySheet) {
                SafetyChecklistView()
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var weatherCard: some View {
        let snapshot = viewModel.weatherSnapshot
        return VStack(alignment: .leading, spacing: 12) {
            Label(snapshot.location, systemImage: "location")
                .font(.caption)
                .foregroundStyle(.secondary)
            if viewModel.isLoadingWeather {
                ProgressView()
                    .progressViewStyle(.circular)
            }
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(format: "%.1f", snapshot.temperature))°C")
                        .font(.system(size: 46, weight: .semibold))
                    Text("Feels good for ridge walks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    label(value: "\(snapshot.humidity)%", caption: "Humidity")
                    label(value: "\(snapshot.uvIndex)", caption: "UV Index")
                }
            }
            Divider()
            if let warning = snapshot.warningMessage {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            } else if let error = viewModel.weatherError {
                Label(error, systemImage: "wifi.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(snapshot.suggestion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func label(value: String, caption: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold))
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func featuredTrailCard(_ trail: Trail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Featured Trail")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(trail.name)
                        .font(.title2.bold())
                    Text(trail.district)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: trail.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(.pink)
                    .onTapGesture {
                        viewModel.markFavorite(trail)
                    }
            }
            HStack(spacing: 16) {
                statBadge(value: "\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km", caption: "Distance")
                statBadge(value: "\(trail.elevationGain) m", caption: "Elev gain")
                statBadge(value: "\(trail.estimatedDurationMinutes / 60) h", caption: "Duration")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(trail.highlights, id: \.self) { highlight in
                        Text(highlight)
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                }
            }
            NavigationLink {
                TrailDetailView(trail: trail)
            } label: {
                Label("View trail plan", systemImage: "arrow.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.18),
                            Color.blue.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 25, y: 10)
        )
    }

    private func statBadge(value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(.headline)
            HStack(spacing: 16) {
                quickAction(icon: "dot.radiowaves.left.and.right", title: "Trail Alerts", color: .orange.opacity(0.2))
                quickAction(icon: "arrow.down.circle.dotted", title: "Offline Maps", color: .green.opacity(0.2))
                quickAction(icon: "camera.viewfinder", title: "AR Identify", color: .purple.opacity(0.2))
            }
        }
    }

    private func quickAction(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .padding()
                .background(color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var savedHikesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Next plans")
                    .font(.headline)
                Spacer()
                Button("Add") {
                    if let first = viewModel.trails.first {
                        viewModel.addSavedHike(for: first, scheduledDate: Date().addingTimeInterval(60 * 60 * 24))
                    }
                }
                .font(.subheadline)
            }
            if viewModel.savedHikes.isEmpty {
                Text("No hikes scheduled. Tap Add to plan your first walk.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.savedHikes) { hike in
                    SavedHikeRow(hike: hike)
                }
            }
        }
    }
}

struct SavedHikeRow: View {
    let hike: SavedHike

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(hike.trail.name)
                    .font(.headline)
                Text(hike.scheduledDate, style: .date)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SafetyChecklistView: View {
    @Environment(\.dismiss) private var dismiss
    private let items = [
        ("location.fill", "Enable Live Location"),
        ("drop.fill", "Pack 2L of water"),
        ("bolt.heart", "Check heat stroke signal"),
        ("antenna.radiowaves.left.and.right", "Download offline map"),
        ("person.2.wave.2", "Share hike plan with buddies")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.0) { item in
                    Label(item.1, systemImage: item.0)
                }
            }
            .navigationTitle("Safety checklist")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppViewModel())
}

