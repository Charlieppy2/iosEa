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
    @EnvironmentObject private var languageManager: LanguageManager
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
    @State private var isShowingWeatherForecast = false
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
            .navigationTitle(languageManager.localizedString(for: "app.name"))
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
                        Label(languageManager.localizedString(for: "home.sos.button"), systemImage: "sos")
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
                    .accessibilityLabel(languageManager.localizedString(for: "home.refresh.weather"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingSafetySheet.toggle()
                    } label: {
                        Label(languageManager.localizedString(for: "home.safety"), systemImage: "cross.case.fill")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
            }
            .alert(languageManager.localizedString(for: "home.sos"), isPresented: $isShowingSOSConfirmation) {
                Button(languageManager.localizedString(for: "cancel"), role: .cancel) { }
                Button(languageManager.localizedString(for: "home.sos.open.sharing"), role: .destructive) {
                    isShowingLocationSharing = true
                }
            } message: {
                Text(languageManager.localizedString(for: "home.sos.confirm"))
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
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingHikeTracking) {
                HikeTrackingView(locationManager: locationManager)
                    .environmentObject(viewModel)
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingHikeRecords) {
                HikeRecordsListView()
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingRecommendations) {
                TrailRecommendationView(appViewModel: viewModel)
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingSpeciesIdentification) {
                SpeciesIdentificationView(locationManager: locationManager)
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingJournal) {
                JournalListView()
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingWeatherForecast) {
                WeatherForecastView()
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
                Label(localizedLocation(snapshot.location), systemImage: "location.fill")
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
                    if !snapshot.suggestion.isEmpty {
                        Text(localizedWeatherSuggestion(snapshot.suggestion))
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    label(value: "\(snapshot.humidity)%", caption: languageManager.localizedString(for: "weather.humidity"))
                    label(value: "\(snapshot.uvIndex)", caption: languageManager.localizedString(for: "weather.uv.index"))
                }
            }
            Divider()
                .background(Color.hikingBrown.opacity(0.2))
            if let warning = snapshot.warningMessage {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            } else if let error = viewModel.weatherError {
                    Label(localizedWeatherError(error), systemImage: "wifi.slash")
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingStone)
            } else if !snapshot.suggestion.isEmpty {
                Text(localizedWeatherSuggestion(snapshot.suggestion))
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingBrown)
            }
        }
        .padding()
        .hikingCard()
    }
    
    private func localizedLocation(_ location: String) -> String {
        if location == "Hong Kong Observatory" {
            return languageManager.localizedString(for: "weather.location.hko")
        }
        return location
    }
    
    private func localizedWeatherError(_ error: String) -> String {
        if error == "Unable to load latest weather. Showing cached data." {
            return languageManager.localizedString(for: "weather.error.cached")
        }
        return error
    }
    
    private func localizedWeatherSuggestion(_ suggestion: String) -> String {
        // Map common weather suggestions to localized keys
        if suggestion.contains("Weather warning in force") {
            return languageManager.localizedString(for: "weather.suggestion.warning")
        }
        if suggestion.contains("Extreme UV") {
            return languageManager.localizedString(for: "weather.suggestion.extreme.uv")
        }
        if suggestion.contains("Humid conditions") {
            return languageManager.localizedString(for: "weather.suggestion.humid")
        }
        if suggestion.contains("Conditions look stable") || suggestion.contains("great time to tackle") {
            return languageManager.localizedString(for: "weather.suggestion.stable")
        }
        if suggestion.contains("Partly cloudy") || suggestion.contains("Great time to start") {
            return languageManager.localizedString(for: "weather.suggestion.good")
        }
        // If no match, return original
        return suggestion
    }
    
    private func localizedHighlight(_ highlight: String, for trail: Trail) -> String {
        // Create a key based on trail ID and highlight text
        let highlightKey = highlight.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        let key = "trail.\(trail.id.uuidString.lowercased()).highlight.\(highlightKey)"
        let localized = languageManager.localizedString(for: key)
        // If no localization found, return original highlight
        return localized != key ? localized : highlight
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
                        Text(languageManager.localizedString(for: "home.featured.trail"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.hikingDarkGreen)
                    }
                    Text(trail.localizedName(languageManager: languageManager))
                        .font(.title2.bold())
                        .foregroundStyle(Color.hikingDarkGreen)
                    Label(trail.localizedDistrict(languageManager: languageManager), systemImage: "mappin.circle.fill")
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
                statBadge(value: "\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km", caption: languageManager.localizedString(for: "trails.distance"))
                statBadge(value: "\(trail.elevationGain) m", caption: languageManager.localizedString(for: "home.elev.gain"))
                statBadge(value: "\(trail.estimatedDurationMinutes / 60) h", caption: languageManager.localizedString(for: "trails.duration"))
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
                    Text(languageManager.localizedString(for: "home.view.trail.plan"))
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
                Text(languageManager.localizedString(for: "home.quick.actions"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            
            // Row 1: Safety & Navigation (4 items)
            HStack(spacing: 12) {
                quickAction(icon: "exclamationmark.triangle.fill", title: languageManager.localizedString(for: "home.trail.alerts"), color: .orange) {
                    isShowingTrailAlerts = true
                }
                quickAction(icon: "map.fill", title: languageManager.localizedString(for: "home.offline.maps"), color: Color.hikingGreen) {
                    isShowingOfflineMaps = true
                }
                quickAction(icon: "camera.viewfinder", title: languageManager.localizedString(for: "home.ar.identify"), color: Color.hikingSky) {
                    isShowingARIdentify = true
                }
                quickAction(icon: "location.fill", title: languageManager.localizedString(for: "home.location.share"), color: .red) {
                    isShowingLocationSharing = true
                }
            }
            
            // Row 2: Tracking & Records (4 items)
            HStack(spacing: 12) {
                quickAction(icon: "record.circle.fill", title: languageManager.localizedString(for: "home.start.tracking"), color: Color.hikingGreen) {
                    isShowingHikeTracking = true
                }
                quickAction(icon: "list.bullet.rectangle", title: languageManager.localizedString(for: "home.hike.records"), color: Color.hikingSky) {
                    isShowingHikeRecords = true
                }
                quickAction(icon: "sparkles", title: languageManager.localizedString(for: "home.recommendations"), color: Color.hikingBrown) {
                    isShowingRecommendations = true
                }
                quickAction(icon: "camera.macro", title: languageManager.localizedString(for: "home.species.id"), color: Color.hikingTan) {
                    isShowingSpeciesIdentification = true
                }
            }
            
            // Row 3: Journal & Weather (2 items, left-aligned)
            HStack(spacing: 12) {
                quickAction(icon: "book.fill", title: languageManager.localizedString(for: "home.journal"), color: Color.hikingBrown) {
                    isShowingJournal = true
                }
                quickAction(icon: "cloud.sun.fill", title: languageManager.localizedString(for: "home.weather.forecast"), color: Color.hikingSky) {
                    isShowingWeatherForecast = true
                }
                Spacer()
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
                    Text(languageManager.localizedString(for: "home.next.plans"))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.hikingDarkGreen)
                }
                Spacer()
                Button {
                    isShowingTrailPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text(languageManager.localizedString(for: "home.add"))
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
                    Text(languageManager.localizedString(for: "home.no.hikes.scheduled"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.hikingBrown)
                    Text(languageManager.localizedString(for: "home.tap.add.to.plan"))
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
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(hike.isCompleted ? Color.hikingGreen : Color.hikingBrown)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(hike.trail.localizedName(languageManager: languageManager))
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
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel = SafetyChecklistViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                if !viewModel.items.isEmpty {
                    Section {
                        HStack {
                            Text(languageManager.localizedString(for: "safety.progress"))
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
                        Text(languageManager.localizedString(for: "safety.all.complete"))
                            .foregroundStyle(.green)
                    } else {
                        Text(languageManager.localizedString(for: "safety.complete.all"))
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "safety.checklist.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "done")) {
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
    @EnvironmentObject private var languageManager: LanguageManager
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
                Section(languageManager.localizedString(for: "trails.title")) {
                    Text(hike.trail.localizedName(languageManager: languageManager))
                        .font(.headline)
                    Label(hike.trail.localizedDistrict(languageManager: languageManager), systemImage: "mappin.and.ellipse")
                    Label {
                        Text("\(hike.trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km • \(hike.trail.estimatedDurationMinutes / 60) h")
                    } icon: {
                        Image(systemName: "clock")
                    }
                }
                Section(languageManager.localizedString(for: "planner.schedule")) {
                    DatePicker(languageManager.localizedString(for: "planner.date"), selection: $plannedDate, displayedComponents: .date)
                    TextField(languageManager.localizedString(for: "planner.note"), text: $note)
                }
                Section(languageManager.localizedString(for: "hike.plan.status")) {
                    Toggle(languageManager.localizedString(for: "hike.plan.mark.completed"), isOn: $isCompleted.animation())
                    if isCompleted {
                        DatePicker(languageManager.localizedString(for: "hike.plan.completed.on"), selection: $completedDate, displayedComponents: .date)
                    }
                }
                Section {
                    NavigationLink {
                        GearChecklistView(
                            trail: hike.trail,
                            weather: WeatherSnapshot.hongKongMorning, // TODO: Get actual weather
                            scheduledDate: plannedDate
                        )
                    } label: {
                        HStack {
                            Image(systemName: "backpack.fill")
                                .foregroundStyle(Color.hikingGreen)
                            Text(languageManager.localizedString(for: "gear.view.checklist"))
                                .foregroundStyle(Color.hikingDarkGreen)
                        }
                    }
                }
                Section {
                    Button(languageManager.localizedString(for: "hike.plan.update")) {
                        onUpdate(plannedDate, note, isCompleted, isCompleted ? completedDate : nil)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Section {
                    Button(languageManager.localizedString(for: "hike.plan.delete"), role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "hike.plan.title"))
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(languageManager.localizedString(for: "hike.plan.delete"), isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                Button(languageManager.localizedString(for: "delete"), role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button(languageManager.localizedString(for: "cancel"), role: .cancel) { }
            } message: {
                Text(languageManager.localizedString(for: "hike.plan.delete.message"))
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
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.alerts.isEmpty {
                    ContentUnavailableView(
                        languageManager.localizedString(for: "alerts.no.active"),
                        systemImage: "checkmark.shield.fill",
                        description: Text(languageManager.localizedString(for: "alerts.all.clear"))
                    )
                } else {
                    List {
                        if !viewModel.criticalAlerts.isEmpty {
                            Section {
                                ForEach(viewModel.criticalAlerts) { alert in
                                    alertRow(alert: alert)
                                }
                            } header: {
                                Text(languageManager.localizedString(for: "alerts.critical"))
                            }
                        }
                        
                        Section {
                            ForEach(viewModel.alerts.filter { $0.severity != .critical }) { alert in
                                alertRow(alert: alert)
                            }
                        } header: {
                            Text(languageManager.localizedString(for: "alerts.active"))
                        }
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "home.trail.alerts"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "done")) {
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
                        Text(localizedAlertTitle(alert.title))
                            .font(.headline)
                        Spacer()
                        severityBadge(alert.severity)
                    }
                    
                    Text(localizedAlertDetail(alert.detail))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Label(alert.category.localizedRawValue(languageManager: languageManager), systemImage: "tag.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(alert.timeAgo(languageManager: languageManager))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func localizedAlertTitle(_ title: String) -> String {
        // Map common alert titles to localized keys
        if title.contains("Route Maintenance") {
            return languageManager.localizedString(for: "alert.title.route.maintenance")
        }
        if title.contains("Weather") {
            return languageManager.localizedString(for: "alert.title.weather")
        }
        if title.contains("Safety") {
            return languageManager.localizedString(for: "alert.title.safety")
        }
        if title.contains("Closure") {
            return languageManager.localizedString(for: "alert.title.closure")
        }
        return title
    }
    
    private func localizedAlertDetail(_ detail: String) -> String {
        // Map common alert details to localized keys
        if detail.contains("Section 2 of MacLehose Trail is partially closed near Long Ke due to slope works") {
            return languageManager.localizedString(for: "alert.detail.maclehose.section2.maintenance")
        }
        // Add more mappings as needed
        return detail
    }
    
    private func severityBadge(_ severity: TrailAlert.Severity) -> some View {
        HStack(spacing: 4) {
            Image(systemName: severity.icon)
                .font(.caption2)
            Text(severity.localizedRawValue(languageManager: languageManager))
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
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if viewModel.regions.isEmpty {
                        Text(languageManager.localizedString(for: "offline.maps.no.regions"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.regions) { region in
                            regionRow(region: region)
                        }
                    }
                } header: {
                    Text(languageManager.localizedString(for: "offline.maps.available.regions"))
                } footer: {
                    if viewModel.hasDownloadedMaps {
                        Text("\(languageManager.localizedString(for: "offline.maps.total.downloaded")): \(formatSize(viewModel.totalDownloadedSize))")
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
                            Label(languageManager.localizedString(for: "offline.maps.clear.all"), systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "home.offline.maps"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "done")) {
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
            .alert(languageManager.localizedString(for: "offline.maps.download.error"), isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button(languageManager.localizedString(for: "ok")) {
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
                        Text(languageManager.localizedString(for: "offline.maps.downloading"))
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
    @EnvironmentObject private var languageManager: LanguageManager
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
                                    Text(languageManager.localizedString(for: "ar.scanning.skyline"))
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    if let closest = identifier.closestLandmark {
                                        Text("\(languageManager.localizedString(for: "ar.found")): \(closest.landmark.name)")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text(languageManager.localizedString(for: "ar.point.camera"))
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
                            Text(languageManager.localizedString(for: "ar.searching.landmarks"))
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
                                Text(languageManager.localizedString(for: "ar.recent.identifications"))
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
                            Text(languageManager.localizedString(for: "ar.no.landmarks"))
                                .font(.headline)
                            Text(languageManager.localizedString(for: "ar.start.scanning"))
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
                        Text(identifier.isScanning ? languageManager.localizedString(for: "ar.stop.scan") : languageManager.localizedString(for: "ar.start.scan"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted)
            }
            .padding()
            .navigationTitle(languageManager.localizedString(for: "home.ar.identify"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "done")) {
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

