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
    @State private var isShowingTrailAlerts = false
    @State private var isShowingOfflineMaps = false
    @State private var isShowingARIdentify = false
    @State private var selectedSavedHike: SavedHike?

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
            .sheet(isPresented: $isShowingTrailAlerts) {
                TrailAlertsView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isShowingOfflineMaps) {
                OfflineMapsView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $isShowingARIdentify) {
                ARIdentifyView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedSavedHike) { hike in
                SavedHikeDetailSheet(
                    hike: hike,
                    onUpdate: { date, note in
                        viewModel.updateSavedHike(hike, scheduledDate: date, note: note)
                    },
                    onDelete: {
                        viewModel.removeSavedHike(hike)
                    }
                )
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
                quickAction(icon: "dot.radiowaves.left.and.right", title: "Trail Alerts", color: .orange.opacity(0.2)) {
                    isShowingTrailAlerts = true
                }
                quickAction(icon: "arrow.down.circle.dotted", title: "Offline Maps", color: .green.opacity(0.2)) {
                    isShowingOfflineMaps = true
                }
                quickAction(icon: "camera.viewfinder", title: "AR Identify", color: .purple.opacity(0.2)) {
                    isShowingARIdentify = true
                }
            }
        }
    }

    private func quickAction(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSavedHike = hike
                        }
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
                if !hike.note.isEmpty {
                    Text(hike.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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

struct SavedHikeDetailSheet: View {
    let hike: SavedHike
    var onUpdate: (Date, String) -> Void
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var plannedDate: Date
    @State private var note: String
    @State private var isShowingDeleteConfirmation = false

    init(hike: SavedHike, onUpdate: @escaping (Date, String) -> Void, onDelete: @escaping () -> Void) {
        self.hike = hike
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _plannedDate = State(initialValue: hike.scheduledDate)
        _note = State(initialValue: hike.note)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trail") {
                    Text(hike.trail.name)
                        .font(.headline)
                    Label(hike.trail.district, systemImage: "mappin.and.ellipse")
                    Label {
                        Text("\(hike.trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km • \(hike.trail.estimatedDurationMinutes / 60) h")
                    } icon: {
                        Image(systemName: "clock")
                    }
                }
                Section("Schedule") {
                    DatePicker("Date", selection: $plannedDate, displayedComponents: .date)
                    TextField("Note", text: $note)
                }
                Section {
                    Button("Update plan") {
                        onUpdate(plannedDate, note)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Section {
                    Button("Delete plan", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("Hike plan")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Delete plan", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This hike will be removed from your planner.")
            }
        }
    }
}

struct TrailAlertsView: View {
    private let alerts: [TrailAlert] = [
        TrailAlert(title: "Strong Monsoon Signal", detail: "Gale force northeasterlies along Sai Kung coast. Avoid exposed ridge lines."),
        TrailAlert(title: "Heat Advisory", detail: "High humidity expected after 2pm. Pack extra fluids for long distance hikes."),
        TrailAlert(title: "Route Maintenance", detail: "Section 2 of MacLehose is partially closed near Long Ke due to slope works.")
    ]

    var body: some View {
        NavigationStack {
            List(alerts) { alert in
                VStack(alignment: .leading, spacing: 6) {
                    Text(alert.title)
                        .font(.headline)
                    Text(alert.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Trail Alerts")
        }
    }
}

private struct TrailAlert: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

struct OfflineMapsView: View {
    @State private var selectedRegion = "Hong Kong Island"
    private let regions = ["Hong Kong Island", "Kowloon Ridge", "Sai Kung East", "Lantau North"]

    var body: some View {
        NavigationStack {
            Form {
                Picker("Region", selection: $selectedRegion) {
                    ForEach(regions, id: \.self) { region in
                        Text(region)
                    }
                }
                Section("Download status") {
                    Label("Topographic tiles", systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                    Label("Trail overlays", systemImage: "arrow.down.circle")
                        .foregroundStyle(.yellow)
                    Label("3D terrain", systemImage: "clock.arrow.circlepath")
                        .foregroundStyle(.orange)
                }
                Section {
                    Button {
                        // Placeholder action
                    } label: {
                        Label("Download latest package", systemImage: "tray.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Offline Maps")
        }
    }
}

struct ARIdentifyView: View {
    @State private var isScanning = false
    @State private var selectedLandmark = "Lion Rock"
    private let landmarks = ["Lion Rock", "Sharp Peak", "Skyline Ridge", "Tai Mo Shan"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.1))
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: isScanning ? "camera.metering.center.weighted" : "camera.viewfinder")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text(isScanning ? "Scanning skyline…" : "Point your camera at a ridge to identify peaks.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                    .frame(height: 250)

                Picker("Latest identification", selection: $selectedLandmark) {
                    ForEach(landmarks, id: \.self) { landmark in
                        Text(landmark).tag(landmark)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Lion Rock")
                        .font(.title3.bold())
                    Label("Height 495m", systemImage: "ruler")
                    Label("Distance 2.4 km", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    Label("Time to reach 40 min", systemImage: "clock")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    isScanning.toggle()
                } label: {
                    Text(isScanning ? "Stop Scan" : "Start Scan")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("AR Identify")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppViewModel())
}

