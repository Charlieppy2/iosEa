//
//  HomeView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var isShowingSafetySheet = false
    @State private var isShowingTrailAlerts = false
    @State private var isShowingOfflineMaps = false
    @State private var isShowingARIdentify = false
    @State private var isShowingLocationSharing = false
    @State private var isShowingHikeTracking = false
    @State private var isShowingHikeRecords = false
    @State private var isShowingRecommendations = false
    @State private var isShowingSpeciesIdentification = false
    @State private var isShowingJournal = false
    @State private var selectedSavedHike: SavedHike?
    @State private var isShowingTrailPicker = false
    @StateObject private var locationManager = LocationManager()
    @State private var isShowingSOSConfirmation = false

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
            .background(
                ZStack {
                    Color.hikingBackgroundGradient
                    HikingPatternBackground()
                        .opacity(0.2)
                }
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingSOSConfirmation = true
                    } label: {
                        Label("SOS", systemImage: "sos")
                            .foregroundStyle(.red)
                            .fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.refreshWeather() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.hikingGreen)
                    }
                    .disabled(viewModel.isLoadingWeather)
                    .accessibilityLabel("Refresh weather")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingSafetySheet.toggle()
                    } label: {
                        Label("Safety", systemImage: "cross.case.fill")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
            }
            .alert("緊急求救", isPresented: $isShowingSOSConfirmation) {
                Button("取消", role: .cancel) { }
                Button("打開位置分享", role: .destructive) {
                    isShowingLocationSharing = true
                }
            } message: {
                Text("這將打開位置分享功能，您可以在那裡發送緊急求救。")
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
            .sheet(isPresented: $isShowingLocationSharing) {
                LocationSharingView(locationManager: locationManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingHikeTracking) {
                HikeTrackingView(locationManager: locationManager)
                    .environmentObject(viewModel)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingHikeRecords) {
                HikeRecordsListView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingRecommendations) {
                TrailRecommendationView(appViewModel: viewModel)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingSpeciesIdentification) {
                SpeciesIdentificationView(locationManager: locationManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingJournal) {
                JournalListView()
                    .presentationDetents([.large])
            }
            .sheet(item: $selectedSavedHike) { hike in
                SavedHikeDetailSheet(
                    hike: hike,
                    onUpdate: { date, note, isCompleted, completedAt in
                        viewModel.updateSavedHike(
                            hike,
                            scheduledDate: date,
                            note: note,
                            isCompleted: isCompleted,
                            completedAt: completedAt
                        )
                    },
                    onDelete: {
                        viewModel.removeSavedHike(hike)
                    }
                )
            }
            .sheet(isPresented: $isShowingTrailPicker) {
                QuickAddTrailPickerView(
                    onTrailSelected: { trail in
                        viewModel.addSavedHike(for: trail, scheduledDate: Date().addingTimeInterval(60 * 60 * 24))
                        isShowingTrailPicker = false
                    }
                )
                .environmentObject(viewModel)
            }
        }
    }

    private var weatherCard: some View {
        let snapshot = viewModel.weatherSnapshot
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(snapshot.location, systemImage: "location.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(Color.hikingBrown)
            }
            if viewModel.isLoadingWeather {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.hikingGreen)
            }
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(format: "%.1f", snapshot.temperature))°C")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(Color.hikingDarkGreen)
                    Text("Feels good for ridge walks")
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    label(value: "\(snapshot.humidity)%", caption: "Humidity")
                    label(value: "\(snapshot.uvIndex)", caption: "UV Index")
                }
            }
            Divider()
                .background(Color.hikingBrown.opacity(0.2))
            if let warning = snapshot.warningMessage {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            } else if let error = viewModel.weatherError {
                    Label(error, systemImage: "wifi.slash")
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingStone)
            } else {
                Text(snapshot.suggestion)
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingBrown)
            }
        }
        .padding()
        .hikingCard()
    }

    private func label(value: String, caption: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.hikingDarkGreen)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Color.hikingBrown)
        }
    }

    private func featuredTrailCard(_ trail: Trail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "mountain.2.fill")
                            .foregroundStyle(Color.hikingGreen)
                        Text("Featured Trail")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.hikingDarkGreen)
                    }
                    Text(trail.name)
                        .font(.title2.bold())
                        .foregroundStyle(Color.hikingDarkGreen)
                    Label(trail.district, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                }
                Spacer()
                Button {
                    viewModel.markFavorite(trail)
                } label: {
                    Image(systemName: trail.isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(trail.isFavorite ? .red : Color.hikingStone)
                }
            }
            HStack(spacing: 12) {
                statBadge(value: "\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km", caption: "Distance")
                statBadge(value: "\(trail.elevationGain) m", caption: "Elev gain")
                statBadge(value: "\(trail.estimatedDurationMinutes / 60) h", caption: "Duration")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(trail.highlights, id: \.self) { highlight in
                        Text(highlight)
                            .font(.caption.weight(.medium))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .hikingBadge(color: Color.hikingGreen)
                    }
                }
            }
            NavigationLink {
                TrailDetailView(trail: trail)
            } label: {
                HStack {
                    Text("View trail plan")
                        .font(.headline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                }
                .foregroundStyle(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.hikingGradient)
                        .shadow(color: Color.hikingGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.98, blue: 0.95),
                            Color(red: 0.94, green: 0.97, blue: 0.93)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.hikingGreen.opacity(0.3), Color.hikingDarkGreen.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.hikingDarkGreen.opacity(0.15), radius: 20, x: 0, y: 8)
        )
    }

    private func statBadge(value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.hikingDarkGreen)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Color.hikingBrown)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.hikingTan.opacity(0.3))
        )
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color.hikingGreen)
                Text("Quick actions")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            HStack(spacing: 12) {
                quickAction(icon: "exclamationmark.triangle.fill", title: "Trail Alerts", color: .orange) {
                    isShowingTrailAlerts = true
                }
                quickAction(icon: "map.fill", title: "Offline Maps", color: Color.hikingGreen) {
                    isShowingOfflineMaps = true
                }
                quickAction(icon: "camera.viewfinder", title: "AR Identify", color: Color.hikingSky) {
                    isShowingARIdentify = true
                }
                quickAction(icon: "location.fill", title: "Location Share", color: .red) {
                    isShowingLocationSharing = true
                }
            }
            
            // 行山記錄快捷操作
            HStack(spacing: 12) {
                quickAction(icon: "record.circle.fill", title: "開始追蹤", color: Color.hikingGreen) {
                    isShowingHikeTracking = true
                }
                quickAction(icon: "list.bullet.rectangle", title: "行山記錄", color: Color.hikingSky) {
                    isShowingHikeRecords = true
                }
            }
            
            // 智能推薦和物種識別
            HStack(spacing: 12) {
                quickAction(icon: "sparkles", title: "智能推薦", color: Color.hikingBrown) {
                    isShowingRecommendations = true
                }
                quickAction(icon: "camera.macro", title: "物種識別", color: Color.hikingTan) {
                    isShowingSpeciesIdentification = true
                }
            }
            
            // 日記快捷操作
            HStack(spacing: 12) {
                quickAction(icon: "book.fill", title: "Journal", color: Color.hikingBrown) {
                    isShowingJournal = true
                }
            }
        }
    }

    private func quickAction(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(color.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(color.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.hikingDarkGreen)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.hikingCardGradient)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var savedHikesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(Color.hikingGreen)
                    Text("Next plans")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.hikingDarkGreen)
                }
                Spacer()
                Button {
                    isShowingTrailPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.hikingGreen)
                }
            }
            if viewModel.savedHikes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mountain.2")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.hikingStone.opacity(0.5))
                    Text("No hikes scheduled")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.hikingBrown)
                    Text("Tap Add to plan your first walk")
                        .font(.caption)
                        .foregroundStyle(Color.hikingStone)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
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
        HStack(spacing: 12) {
            // Status indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(hike.isCompleted ? Color.hikingGreen : Color.hikingBrown)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(hike.trail.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.hikingDarkGreen)
                    Spacer()
                    if hike.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
                HStack(spacing: 8) {
                    Text(hike.scheduledDate, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                    if !hike.note.isEmpty {
                        Text("•")
                            .foregroundStyle(Color.hikingStone)
                        Text(hike.note)
                            .font(.caption)
                            .foregroundStyle(Color.hikingStone)
                            .lineLimit(1)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.hikingStone)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.hikingCardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.hikingGreen.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

struct SafetyChecklistView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SafetyChecklistViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                if !viewModel.items.isEmpty {
                    Section {
                        HStack {
                            Text("Progress")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(viewModel.completedCount) / \(viewModel.totalCount)")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    ForEach(viewModel.items) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.iconName)
                                .foregroundStyle(item.isCompleted ? .green : .secondary)
                                .frame(width: 24)
                            
                            Text(item.title)
                                .strikethrough(item.isCompleted)
                                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                            
                            Spacer()
                            
                            if item.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.toggleItem(item)
                        }
                    }
                } footer: {
                    if viewModel.isAllCompleted {
                        Text("Great! You're all set for a safe hike.")
                            .foregroundStyle(.green)
                    } else {
                        Text("Complete all items before heading out.")
                    }
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
            .task {
                viewModel.configureIfNeeded(context: modelContext)
            }
            .onAppear {
                viewModel.refreshItems()
            }
        }
    }
}

struct SavedHikeDetailSheet: View {
    let hike: SavedHike
    var onUpdate: (Date, String, Bool, Date?) -> Void
    var onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var plannedDate: Date
    @State private var note: String
    @State private var isCompleted: Bool
    @State private var completedDate: Date
    @State private var isShowingDeleteConfirmation = false

    init(
        hike: SavedHike,
        onUpdate: @escaping (Date, String, Bool, Date?) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.hike = hike
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _plannedDate = State(initialValue: hike.scheduledDate)
        _note = State(initialValue: hike.note)
        _isCompleted = State(initialValue: hike.isCompleted)
        _completedDate = State(initialValue: hike.completedAt ?? Date())
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
                Section("Status") {
                    Toggle("Mark as completed", isOn: $isCompleted.animation())
                    if isCompleted {
                        DatePicker("Completed on", selection: $completedDate, displayedComponents: .date)
                    }
                }
                Section {
                    Button("Update plan") {
                        onUpdate(plannedDate, note, isCompleted, isCompleted ? completedDate : nil)
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
            .onChange(of: isCompleted) { newValue in
                if newValue && hike.completedAt == nil {
                    completedDate = Date()
                }
            }
        }
    }
}

struct TrailAlertsView: View {
    @StateObject private var viewModel = TrailAlertsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.alerts.isEmpty {
                    ContentUnavailableView(
                        "No Active Alerts",
                        systemImage: "checkmark.shield.fill",
                        description: Text("All trails are clear. Enjoy your hike!")
                    )
                } else {
                    List {
                        if !viewModel.criticalAlerts.isEmpty {
                            Section {
                                ForEach(viewModel.criticalAlerts) { alert in
                                    alertRow(alert: alert)
                                }
                            } header: {
                                Text("Critical")
                            }
                        }
                        
                        Section {
                            ForEach(viewModel.alerts.filter { $0.severity != .critical }) { alert in
                                alertRow(alert: alert)
                            }
                        } header: {
                            Text("Active Alerts")
                        }
                    }
                }
            }
            .navigationTitle("Trail Alerts")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await viewModel.fetchAlerts()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.fetchAlerts()
            }
        }
    }
    
    private func alertRow(alert: TrailAlert) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: alert.category.icon)
                    .foregroundStyle(severityColor(for: alert.severity))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(alert.title)
                            .font(.headline)
                        Spacer()
                        severityBadge(alert.severity)
                    }
                    
                    Text(alert.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Label(alert.category.rawValue, systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(alert.timeAgo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func severityBadge(_ severity: TrailAlert.Severity) -> some View {
        HStack(spacing: 4) {
            Image(systemName: severity.icon)
                .font(.caption2)
            Text(severity.rawValue)
                .font(.caption2.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(severityColor(for: severity).opacity(0.2), in: Capsule())
        .foregroundStyle(severityColor(for: severity))
    }
    
    private func severityColor(for severity: TrailAlert.Severity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct OfflineMapsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = OfflineMapsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if viewModel.regions.isEmpty {
                        Text("No regions available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.regions) { region in
                            regionRow(region: region)
                        }
                    }
                } header: {
                    Text("Available Regions")
                } footer: {
                    if viewModel.hasDownloadedMaps {
                        Text("Total downloaded: \(formatSize(viewModel.totalDownloadedSize))")
                            .font(.caption)
                    }
                }
                
                if viewModel.hasDownloadedMaps {
                    Section {
                        Button(role: .destructive) {
                            // Delete all downloaded maps
                            for region in viewModel.regions.filter({ $0.downloadStatus == .downloaded }) {
                                viewModel.deleteRegion(region)
                            }
                        } label: {
                            Label("Clear All Downloads", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Offline Maps")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                viewModel.configureIfNeeded(context: modelContext)
            }
            .onAppear {
                viewModel.refreshRegions()
            }
            .alert("Download Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }
    
    private func regionRow(region: OfflineMapRegion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(region.name)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        statusBadge(region.downloadStatus)
                        if region.downloadStatus == .downloaded {
                            Text(region.formattedSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("~\(region.formattedTotalSize)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if region.downloadStatus == .downloading {
                    Button {
                        viewModel.cancelDownload(region)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                } else if region.downloadStatus == .downloaded {
                    Button(role: .destructive) {
                        viewModel.deleteRegion(region)
                    } label: {
                        Image(systemName: "trash")
                    }
                } else {
                    Button {
                        viewModel.downloadRegion(region)
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            if region.downloadStatus == .downloading {
                ProgressView(value: region.downloadProgress) {
                    HStack {
                        Text("Downloading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(region.downloadProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusBadge(_ status: OfflineMapRegion.DownloadStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon(for: status))
                .font(.caption2)
            Text(status.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(statusColor(for: status).opacity(0.2), in: Capsule())
        .foregroundStyle(statusColor(for: status))
    }
    
    private func statusIcon(for status: OfflineMapRegion.DownloadStatus) -> String {
        switch status {
        case .notDownloaded: return "arrow.down.circle"
        case .downloading: return "arrow.down.circle.fill"
        case .downloaded: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .updating: return "arrow.clockwise.circle.fill"
        }
    }
    
    private func statusColor(for status: OfflineMapRegion.DownloadStatus) -> Color {
        switch status {
        case .notDownloaded: return .gray
        case .downloading: return .blue
        case .downloaded: return .green
        case .failed: return .red
        case .updating: return .orange
        }
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
}

struct ARIdentifyView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var identifier: ARLandmarkIdentifier
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLandmark: ARLandmarkIdentifier.IdentifiedLandmark?
    
    init() {
        let locationManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _identifier = StateObject(wrappedValue: ARLandmarkIdentifier(locationManager: locationManager))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Camera preview area (simulated)
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            if identifier.isScanning {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Scanning skyline…")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    if let closest = identifier.closestLandmark {
                                        Text("Found: \(closest.landmark.name)")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text("Point your camera at a ridge to identify peaks")
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.white.opacity(0.9))
                                        .padding(.horizontal)
                                }
                            }
                        }
                    
                    // Compass overlay
                    if identifier.isScanning, let closest = identifier.closestLandmark {
                        VStack {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Image(systemName: "location.north.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                    Text("\(Int(closest.bearing))°")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: Circle())
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                if identifier.isScanning {
                    if identifier.identifiedLandmarks.isEmpty {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Searching for landmarks...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(identifier.identifiedLandmarks) { identified in
                                    landmarkCard(identified: identified)
                                        .onTapGesture {
                                            selectedLandmark = identified
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    if !identifier.identifiedLandmarks.isEmpty {
                        ScrollView {
                            VStack(spacing: 12) {
                                Text("Recent Identifications")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                ForEach(identifier.identifiedLandmarks.prefix(3)) { identified in
                                    landmarkCard(identified: identified)
                                        .onTapGesture {
                                            selectedLandmark = identified
                                        }
                                }
                            }
                            .padding(.vertical)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "mountain.2.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No landmarks identified yet")
                                .font(.headline)
                            Text("Start scanning to identify nearby peaks")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
                
                Button {
                    if identifier.isScanning {
                        identifier.stopScanning()
                    } else {
                        // Request location permission if needed
                        if locationManager.authorizationStatus == .notDetermined {
                            locationManager.requestPermission()
                        } else if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                            locationManager.startUpdates()
                            identifier.startScanning()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: identifier.isScanning ? "stop.circle.fill" : "play.circle.fill")
                        Text(identifier.isScanning ? "Stop Scan" : "Start Scan")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted)
            }
            .padding()
            .navigationTitle("AR Identify")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        identifier.stopScanning()
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedLandmark) { identified in
                LandmarkDetailView(identified: identified)
            }
        }
    }
    
    private func landmarkCard(identified: ARLandmarkIdentifier.IdentifiedLandmark) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(identified.landmark.name)
                        .font(.headline)
                    if !identified.landmark.description.isEmpty {
                        Text(identified.landmark.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.north.circle.fill")
                            .font(.caption)
                        Text("\(Int(identified.bearing))°")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.blue)
                }
            }
            
            HStack(spacing: 16) {
                Label("\(identified.landmark.elevation) m", systemImage: "ruler")
                Label("\(identified.distance.formatted(.number.precision(.fractionLength(1)))) km", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                Label("\(Int(identified.distance * 12)) min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct LandmarkDetailView: View {
    let identified: ARLandmarkIdentifier.IdentifiedLandmark
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(identified.landmark.name)
                            .font(.largeTitle.bold())
                        if !identified.landmark.description.isEmpty {
                            Text(identified.landmark.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        detailRow(icon: "ruler", title: "Elevation", value: "\(identified.landmark.elevation) m")
                        detailRow(icon: "point.topleft.down.curvedto.point.bottomright.up", title: "Distance", value: "\(identified.distance.formatted(.number.precision(.fractionLength(2)))) km")
                        detailRow(icon: "location.north.circle.fill", title: "Bearing", value: "\(Int(identified.bearing))°")
                        detailRow(icon: "clock", title: "Estimated time", value: "\(Int(identified.distance * 12)) minutes")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding()
            }
            .navigationTitle("Landmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}

struct QuickAddTrailPickerView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var onTrailSelected: (Trail) -> Void
    
    private var filteredTrails: [Trail] {
        guard !searchText.isEmpty else { return viewModel.trails }
        return viewModel.trails.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.district.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTrails) { trail in
                    Button {
                        onTrailSelected(trail)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trail.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(trail.district)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 12) {
                                    Label("\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km", systemImage: "ruler")
                                    Label("\(trail.estimatedDurationMinutes / 60)h", systemImage: "clock")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Label(trail.difficulty.rawValue, systemImage: trail.difficulty.icon)
                                .labelStyle(.iconOnly)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Choose Trail")
            .searchable(text: $searchText, prompt: "Search trails")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
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

