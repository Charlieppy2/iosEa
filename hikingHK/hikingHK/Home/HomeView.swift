//
//  HomeView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI
import SwiftData
import CoreLocation
import Combine

/// Main landing screen showing weather, featured trail, quick actions and upcoming hikes.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isShowingSafetySheet = false
    @State private var isShowingTrailAlerts = false
    @State private var isShowingOfflineMaps = false
    @State private var isShowingLocationSharing = false
    @State private var isShowingHikeTracking = false
    @State private var isShowingHikeRecords = false
    @State private var isShowingRecommendations = false
    @State private var isShowingJournal = false
    @State private var isShowingWeatherForecast = false
    @State private var isShowingBestHikingTime = false
    @State private var isShowingTransport = false
    @State private var selectedSavedHike: SavedHike?
    @State private var isShowingTrailPicker = false
    @StateObject private var locationManager = LocationManager()
    @State private var isShowingSOSConfirmation = false
    @State private var featuredIndex: Int = 0
    @State private var weatherIndex: Int = 0
    @State private var isShowingLocationPicker = false
    @State private var trailPendingPlan: Trail?
    @State private var isShowingAddPlanConfirmation = false
    private let featuredTimer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    /// Featured trails carousel data source – 当前简单使用所有 trails 作为精选候选。
    private var featuredTrails: [Trail] {
        viewModel.trails
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    weatherCard
                    
                    // 精选路线卡片轮播
                    if !featuredTrails.isEmpty {
                        TabView(selection: $featuredIndex) {
                            ForEach(Array(featuredTrails.enumerated()), id: \.offset) { index, trail in
                                featuredTrailCard(trail: trail)
                                    .tag(index)
                            }
                        }
                        .frame(height: 380)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: featuredIndex)
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
                        // 英文版：只顯示文字 "SOS"
                        // 中文版：顯示圖標 + "緊急求救"
                        if languageManager.currentLanguage == .english {
                            Text("SOS")
                                .foregroundStyle(.red)
                                .fontWeight(.bold)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "sos")
                                    .foregroundStyle(.red)
                                
                                    .foregroundStyle(.red)
                                    .fontWeight(.bold)
                                Text(languageManager.localizedString(for: "home.sos.button"))
                            .foregroundStyle(.red)
                            .fontWeight(.bold)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.refreshWeather(language: languageManager.currentLanguage.rawValue) }
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
            .onAppear {
                // Configure persistence if needed
                viewModel.configurePersistenceIfNeeded(context: modelContext)
                // Refresh weather using the currently selected language
                Task {
                    await viewModel.refreshWeather(language: languageManager.currentLanguage.rawValue)
                }
            }
            .onChange(of: languageManager.currentLanguage) { oldValue, newValue in
                // When language changes, refresh weather with the new language code
                Task {
                    await viewModel.refreshWeather(language: newValue.rawValue)
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
                    .environmentObject(viewModel)
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingRecommendations) {
                TrailRecommendationView(appViewModel: viewModel)
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingJournal) {
                JournalListView()
                    .environmentObject(viewModel)
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingWeatherForecast) {
                WeatherForecastView()
                    .environmentObject(viewModel)
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingBestHikingTime) {
                BestHikingTimeView()
                    .environmentObject(viewModel)
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingTransport) {
                TransportView()
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $isShowingLocationPicker) {
                WeatherLocationPickerView(
                    snapshots: viewModel.weatherSnapshots.isEmpty ? [viewModel.weatherSnapshot] : viewModel.weatherSnapshots,
                    selectedIndex: $weatherIndex
                )
                .environmentObject(languageManager)
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
            .alert(languageManager.localizedString(for: "home.featured.add.to.plan.confirm"), isPresented: $isShowingAddPlanConfirmation) {
                Button(languageManager.localizedString(for: "cancel"), role: .cancel) {
                    trailPendingPlan = nil
                }
                Button(languageManager.localizedString(for: "ok")) {
                    if let trail = trailPendingPlan {
                        let defaultDate = Date().addingTimeInterval(60 * 60 * 24)
                        viewModel.addSavedHike(for: trail, scheduledDate: defaultDate)
                        viewModel.markFavorite(trail)
                    }
                    trailPendingPlan = nil
                }
            } message: {
                Text(languageManager.localizedString(for: "home.featured.add.to.plan.message"))
            }
            .onReceive(featuredTimer) { _ in
                guard !featuredTrails.isEmpty else { return }
                // 自动每 3 秒轮播到下一个精选路线
                let maxIndex = featuredTrails.count - 1
                if featuredIndex >= maxIndex {
                    featuredIndex = 0
                } else {
                    featuredIndex += 1
                }
            }
        }
    }

    private var weatherCard: some View {
        let snapshots = viewModel.weatherSnapshots.isEmpty ? [viewModel.weatherSnapshot] : viewModel.weatherSnapshots
        
        return TabView(selection: $weatherIndex) {
            ForEach(Array(snapshots.enumerated()), id: \.offset) { index, snapshot in
                weatherCardContent(snapshot: snapshot)
                    .tag(index)
            }
        }
        .frame(height: 280) // 增加高度確保所有內容都能完整顯示
        .tabViewStyle(.page(indexDisplayMode: snapshots.count > 1 ? .automatic : .never))
        .onChange(of: viewModel.weatherSnapshots) { _, newSnapshots in
            // Update index when snapshots change, prefer Hong Kong Observatory
            if let hkoIndex = newSnapshots.firstIndex(where: { $0.location == "Hong Kong Observatory" }) {
                weatherIndex = hkoIndex
            } else if !newSnapshots.isEmpty {
                weatherIndex = 0
            }
        }
    }
    
    private func weatherCardContent(snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    isShowingLocationPicker = true
                } label: {
                    HStack(spacing: 6) {
                Label(localizedLocation(snapshot.location), systemImage: "location.fill")
                            .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.hikingDarkGreen)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Color.hikingDarkGreen)
                    }
                }
                Spacer()
                Image(systemName: "sun.max.fill")
                    .font(.title3)
                    .foregroundStyle(Color.hikingBrown)
            }
            if viewModel.isLoadingWeather {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.hikingGreen)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                    Text("\(String(format: "%.1f", snapshot.temperature))°C")
                            .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(Color.hikingDarkGreen)
                }
                Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                    label(value: "\(snapshot.humidity)%", caption: languageManager.localizedString(for: "weather.humidity"))
                    label(value: "\(snapshot.uvIndex)", caption: languageManager.localizedString(for: "weather.uv.index"))
                }
            }
            Divider()
                .background(Color.hikingBrown.opacity(0.2))
                    .padding(.vertical, 6)
                // 顯示警告或建議（不重複顯示）
            if let warning = snapshot.warningMessage, !warning.isEmpty {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.body.weight(.medium))
                    .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
            } else if let error = viewModel.weatherError {
                    Label(localizedWeatherError(error), systemImage: "wifi.slash")
                        .font(.body)
                    .foregroundStyle(Color.hikingStone)
                        .fixedSize(horizontal: false, vertical: true)
            } else if !snapshot.suggestion.isEmpty {
                Text(localizedWeatherSuggestion(snapshot.suggestion))
                        .font(.body)
                    .foregroundStyle(Color.hikingBrown)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // 查看九天天氣預報按鈕（只顯示圖標）
                Button {
                    isShowingWeatherForecast = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.hikingGreen)
                    }
                    .padding(.top, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .hikingCard()
    }
    
    private func localizedLocation(_ location: String) -> String {
        // Prefer Hong Kong Observatory label
        if location == "Hong Kong Observatory" {
            return languageManager.localizedString(for: "weather.location.hko")
        }
        // Localize other known locations
        let locationKey = "weather.location.\(location.lowercased().replacingOccurrences(of: " ", with: ".").replacingOccurrences(of: "'", with: ""))"
        let localized = languageManager.localizedString(for: locationKey)
        // If we found a real localized string (not the key itself), use it
        if localized != locationKey {
            return localized
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
        // Create a localization key based on trail ID and highlight text
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
        VStack(alignment: .trailing, spacing: 4) {
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.hikingDarkGreen)
            Text(caption)
                .font(.subheadline)
                .foregroundStyle(Color.hikingBrown)
        }
    }

    @ViewBuilder
    private func featuredTrailCard(trail: Trail) -> some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "mountain.2.fill")
                                .font(.title3)
                                .foregroundStyle(Color.hikingGreen)
                            Text(languageManager.localizedString(for: "home.featured.trail"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.hikingDarkGreen)
                        }
                        Text(trail.localizedName(languageManager: languageManager))
                            .font(.title2.bold())
                            .foregroundStyle(Color.hikingDarkGreen)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Label(trail.localizedDistrict(languageManager: languageManager), systemImage: "mappin.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown)
                    }
                    Spacer()
                    Button {
                        if trail.isFavorite {
                            // 已经是收藏，直接取消收藏，不弹窗
                        viewModel.markFavorite(trail)
                        } else {
                            // 首次点亮时先弹出确认对话框
                            trailPendingPlan = trail
                            isShowingAddPlanConfirmation = true
                        }
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
                
                if !trail.highlights.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(trail.highlights, id: \.self) { highlight in
                            Text(localizedHighlight(highlight, for: trail))
                                .font(.caption.weight(.medium))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .hikingBadge(color: Color.hikingGreen)
                        }
                    }
                        .padding(.horizontal, 4)
                }
                    .frame(height: 36)
                }
                
                NavigationLink {
                    TrailDetailView(trail: trail)
                } label: {
                    HStack {
                        Text(languageManager.localizedString(for: "home.view.trail.plan"))
                            .font(.headline.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.hikingGradient)
                            .shadow(color: Color.hikingGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                    )
                }
            }
            .padding(18)
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
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.hikingDarkGreen)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Color.hikingBrown)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
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
            
            // Row 1: 5 items
            HStack(spacing: 12) {
                quickAction(icon: "car.fill", title: languageManager.localizedString(for: "home.transport"), color: Color.hikingGreen) {
                    isShowingTransport = true
                }
                quickAction(icon: "exclamationmark.triangle.fill", title: languageManager.localizedString(for: "home.trail.alerts"), color: .orange) {
                    isShowingTrailAlerts = true
                }
                quickAction(icon: "map.fill", title: languageManager.localizedString(for: "home.offline.maps"), color: Color.hikingGreen) {
                    isShowingOfflineMaps = true
                }
                quickAction(icon: "location.fill", title: languageManager.localizedString(for: "home.location.share"), color: .red) {
                    isShowingLocationSharing = true
                }
                quickAction(icon: "record.circle.fill", title: languageManager.localizedString(for: "home.start.tracking"), color: Color.hikingGreen) {
                    isShowingHikeTracking = true
                }
            }
            
            // Row 2: 5 items
            HStack(spacing: 12) {
                quickAction(icon: "list.bullet.rectangle", title: languageManager.localizedString(for: "home.hike.records"), color: Color.hikingSky) {
                    isShowingHikeRecords = true
                }
                quickAction(icon: "sparkles", title: languageManager.localizedString(for: "home.recommendations"), color: Color.hikingBrown) {
                    isShowingRecommendations = true
                }
                quickAction(icon: "book.fill", title: languageManager.localizedString(for: "home.journal"), color: Color.hikingBrown) {
                    isShowingJournal = true
                }
                quickAction(icon: "cloud.sun.fill", title: languageManager.localizedString(for: "home.weather.forecast"), color: Color.hikingSky) {
                    isShowingWeatherForecast = true
                }
                quickAction(icon: "star.fill", title: languageManager.localizedString(for: "home.best.hiking.time"), color: Color.hikingGreen) {
                    isShowingBestHikingTime = true
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
                    .frame(height: 32, alignment: .top)
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
                    Text(formattedDate(hike.scheduledDate))
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
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct SafetyChecklistView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel = SafetyChecklistViewModel()
    @State private var isCreatingItems = false
    @State private var isShowingAddItem = false
    
    // Use items from the view model instead of @Query
    private var items: [SafetyChecklistItem] {
        viewModel.items
    }
    
    private var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    private var totalCount: Int {
        items.count
    }
    
    private var isAllCompleted: Bool {
        !items.isEmpty && items.allSatisfy { $0.isCompleted }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty && isCreatingItems {
                    // Loading state: creating default items
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(languageManager.localizedString(for: "safety.loading"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 16)
                        Spacer()
                    }
                } else {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(languageManager.localizedString(for: "safety.progress"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(completedCount) / \(totalCount)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(isAllCompleted ? .green : .primary)
                                }
                                
                                // 进度条
                                ProgressView(value: Double(completedCount), total: Double(totalCount))
                                    .tint(isAllCompleted ? .green : .blue)
                                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Section {
                            ForEach(viewModel.items) { item in
                                checklistItemRow(item)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            do {
                                                try viewModel.deleteItem(item, context: modelContext)
                                            } catch {
                                                print("❌ Failed to delete item: \(error)")
                                            }
                                        } label: {
                                            Label(languageManager.localizedString(for: "delete"), systemImage: "trash")
                                        }
                                    }
                            }
                            .onMove { source, destination in
                                viewModel.moveItem(from: source, to: destination, context: modelContext)
                            }
                            
                            // 添加新项目按钮
                            Button {
                                isShowingAddItem = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.hikingGreen)
                                    Text(languageManager.localizedString(for: "safety.add.item"))
                                        .foregroundStyle(Color.hikingGreen)
                                }
                            }
                        } footer: {
                            if isAllCompleted {
                                Text(languageManager.localizedString(for: "safety.all.complete"))
                                    .foregroundStyle(.green)
                            } else {
                                Text(languageManager.localizedString(for: "safety.complete.all"))
                            }
                        }
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
            .sheet(isPresented: $isShowingAddItem) {
                AddSafetyChecklistItemView(viewModel: viewModel, modelContext: modelContext)
            }
            .task {
                // Configure view model and seed defaults when needed
                isCreatingItems = true
                await viewModel.configureIfNeeded(context: modelContext)
                // If still empty after configuration, create default items explicitly
                if viewModel.items.isEmpty {
                    await viewModel.createDefaultItems(context: modelContext)
                }
                isCreatingItems = false
            }
            .onAppear {
                // Refresh items on each appearance to ensure latest state
                viewModel.refreshItems()
            }
        }
    }
    
    // Single checklist row view
    private func checklistItemRow(_ item: SafetyChecklistItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.toggleItem(item, context: modelContext)
            }
        } label: {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(item.isCompleted ? Color.green : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.green))
                    }
                }
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: item.isCompleted)
                
                // Icon
                Image(systemName: item.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(item.isCompleted ? Color.green.opacity(0.7) : Color.hikingGreen)
                    .frame(width: 28)
                
                // Text label
                Text(itemTitle(for: item))
                    .font(.body)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // Resolve display title for an item (supports localization and custom items)
    private func itemTitle(for item: SafetyChecklistItem) -> String {
        // If this is a custom item (ID prefixed with "custom_"), use the raw title
        if item.id.hasPrefix("custom_") {
            return item.title
        }
        
        // Otherwise, try to localize using the default key
        let localizedKey = "safety.item.\(item.id)"
        let localized = languageManager.localizedString(for: localizedKey)
        
        // If the localization key is missing, fall back to the stored title
        if localized == localizedKey {
            return item.title
        }
        
        return localized
    }
    
}

/// Sheet used to add a new custom safety checklist item.
struct AddSafetyChecklistItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    let viewModel: SafetyChecklistViewModel
    let modelContext: ModelContext
    
    @State private var itemTitle: String = ""
    @State private var selectedIcon: String = "checkmark.circle"
    @State private var errorMessage: String?
    
    // 可用的图标选项
    private let iconOptions = [
        "checkmark.circle", "exclamationmark.triangle", "heart.fill",
        "star.fill", "bell.fill", "shield.fill", "bolt.fill",
        "flame.fill", "drop.fill", "sun.max.fill", "moon.fill",
        "cloud.fill", "location.fill", "map.fill", "camera.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        languageManager.localizedString(for: "safety.item.title.placeholder"),
                        text: $itemTitle
                    )
                } header: {
                    Text(languageManager.localizedString(for: "safety.item.title"))
                }
                
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(selectedIcon == icon ? .white : Color.hikingGreen)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(selectedIcon == icon ? Color.hikingGreen : Color.gray.opacity(0.1))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } header: {
                    Text(languageManager.localizedString(for: "safety.item.icon"))
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "safety.add.item"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "save")) {
                        saveItem()
                    }
                    .disabled(itemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        let trimmedTitle = itemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            errorMessage = languageManager.localizedString(for: "safety.item.title.required")
            return
        }
        
        do {
            try viewModel.addItem(title: trimmedTitle, iconName: selectedIcon, context: modelContext)
            dismiss()
        } catch {
            errorMessage = languageManager.localizedString(for: "safety.item.save.error")
            print("❌ Failed to add item: \(error)")
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
                // Auto-save when toggle is switched (like gear checklist)
                onUpdate(plannedDate, note, isCompleted, isCompleted ? completedDate : nil)
            }
            .onChange(of: completedDate) { newValue in
                // Auto-save when completed date changes
                if isCompleted {
                    onUpdate(plannedDate, note, isCompleted, newValue)
                }
            }
        }
    }
}

struct TrailAlertsView: View {
    @StateObject private var viewModel: TrailAlertsViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isShowingWarningHistory = false
    
    init() {
        _viewModel = StateObject(wrappedValue: TrailAlertsViewModel(languageManager: LanguageManager.shared))
    }
    
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
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await viewModel.fetchAlerts()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button {
                        isShowingWarningHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                }
                }
            }
            .sheet(isPresented: $isShowingWarningHistory) {
                WeatherWarningHistoryView()
                    .environmentObject(languageManager)
            }
            .task {
                viewModel.updateLanguageManager(languageManager)
                await viewModel.fetchAlerts()
                // 启动自动刷新
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                // 停止自动刷新以节省资源
                viewModel.stopAutoRefresh()
            }
            .onChange(of: languageManager.currentLanguage) { _, _ in
                viewModel.updateLanguageManager(languageManager)
                Task {
                    await viewModel.fetchAlerts()
                }
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
                        // 顯示發佈時間
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(formatIssueTime(alert.issuedAt, languageManager: languageManager))
                            .font(.caption)
                        }
                            .foregroundStyle(.secondary)
                        // 如果有更新時間，顯示更新時間
                        if let updatedAt = alert.updatedAt {
                            Text("•")
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption2)
                                Text(formatUpdateTime(updatedAt, languageManager: languageManager))
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
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
    
    /// 格式化發佈時間
    private func formatIssueTime(_ date: Date, languageManager: LanguageManager) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .english ? "en_US" : "zh_Hant_HK")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "\(languageManager.localizedString(for: "alert.issued.at")) \(formatter.string(from: date))"
    }
    
    /// 格式化更新時間
    private func formatUpdateTime(_ date: Date, languageManager: LanguageManager) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .english ? "en_US" : "zh_Hant_HK")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "\(languageManager.localizedString(for: "alert.updated.at")) \(formatter.string(from: date))"
    }
}

struct OfflineMapsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = OfflineMapsViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isCreatingRegions = false
    @State private var regionToDelete: OfflineMapRegion?
    
    // 使用 ViewModel 的 regions 而不是 @Query
    private var regions: [OfflineMapRegion] {
        viewModel.regions
    }
    
    private var hasDownloadedMaps: Bool {
        regions.contains { $0.downloadStatus == .downloaded }
    }
    
    private var totalDownloadedSize: Int64 {
        regions
            .filter { $0.downloadStatus == .downloaded }
            .reduce(0) { $0 + $1.downloadedSize }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if regions.isEmpty && isCreatingRegions {
                    // 加载状态：正在创建区域
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(languageManager.localizedString(for: "offline.maps.loading"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 16)
                        Spacer()
                    }
                } else {
                    Form {
                        Section {
                            ForEach(regions.sorted(by: { $0.name < $1.name })) { region in
                                regionRow(region: region)
                            }
                        } header: {
                            Text(languageManager.localizedString(for: "offline.maps.available.regions"))
                        } footer: {
                            if hasDownloadedMaps {
                                Text("\(languageManager.localizedString(for: "offline.maps.total.downloaded")): \(formatSize(totalDownloadedSize))")
                                    .font(.caption)
                            }
                        }
                        
                        if hasDownloadedMaps {
                            Section {
                                Button(role: .destructive) {
                                    // Delete all downloaded maps
                                    for region in regions.filter({ $0.downloadStatus == .downloaded }) {
                                        viewModel.deleteRegion(region)
                                    }
                                } label: {
                                    Label(languageManager.localizedString(for: "offline.maps.clear.all"), systemImage: "trash")
                                }
                            }
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
                // 在 task 中配置和初始化数据
                isCreatingRegions = true
                await viewModel.configureIfNeeded(context: modelContext)
                // configureIfNeeded 已经会自动创建区域，如果还是空的才手动创建
                if viewModel.regions.isEmpty {
                    await viewModel.createDefaultRegions(context: modelContext)
                }
                isCreatingRegions = false
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
            .confirmationDialog(
                languageManager.localizedString(for: "offline.maps.delete.confirm"),
                isPresented: Binding(
                    get: { regionToDelete != nil },
                    set: { if !$0 { regionToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(languageManager.localizedString(for: "delete"), role: .destructive) {
                    if let region = regionToDelete {
                        viewModel.deleteRegion(region)
                        regionToDelete = nil
                    }
                }
                Button(languageManager.localizedString(for: "cancel"), role: .cancel) {
                    regionToDelete = nil
                }
            } message: {
                Text(languageManager.localizedString(for: "offline.maps.delete.message"))
            }
        }
    }
    
    private func regionRow(region: OfflineMapRegion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(region.localizedName(languageManager: languageManager))
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
                        regionToDelete = region
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
            Text(status.localizedDescription(languageManager: languageManager))
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


struct QuickAddTrailPickerView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var onTrailSelected: (Trail) -> Void
    
    private var filteredTrails: [Trail] {
        guard !searchText.isEmpty else { return viewModel.trails }
        return viewModel.trails.filter { trail in
            let localizedName = trail.localizedName(languageManager: languageManager)
            let localizedDistrict = trail.localizedDistrict(languageManager: languageManager)
            return localizedName.localizedCaseInsensitiveContains(searchText) ||
                   localizedDistrict.localizedCaseInsensitiveContains(searchText) ||
                   trail.name.localizedCaseInsensitiveContains(searchText) ||
                   trail.district.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTrails) { trail in
                    Button {
                        onTrailSelected(trail)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trail.localizedName(languageManager: languageManager))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(trail.localizedDistrict(languageManager: languageManager))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 12) {
                                    Label("\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) \(languageManager.localizedString(for: "unit.km"))", systemImage: "ruler")
                                    Label("\(trail.estimatedDurationMinutes / 60)\(languageManager.localizedString(for: "unit.h"))", systemImage: "clock")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Label(trail.difficulty.localizedRawValue(languageManager: languageManager), systemImage: trail.difficulty.icon)
                                .labelStyle(.iconOnly)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "planner.choose.trail"))
            .searchable(text: $searchText, prompt: languageManager.localizedString(for: "trails.search.prompt"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.localizedString(for: "cancel")) {
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
        .environmentObject(LanguageManager.shared)
        .modelContainer(for: [SafetyChecklistItem.self, OfflineMapRegion.self, HikeJournal.self, FavoriteTrailRecord.self, UserCredential.self], inMemory: true)
}

