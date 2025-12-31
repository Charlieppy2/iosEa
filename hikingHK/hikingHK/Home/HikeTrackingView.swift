//
//  HikeTrackingView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct HikeTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var viewModel: HikeTrackingViewModel
    @StateObject private var weatherAlertManager = WeatherAlertManager()
    @State private var selectedTrail: Trail?
    @State private var isShowingTrailPicker = false
    @State private var latestWeather: WeatherSnapshot?
    @State private var isShowingWeatherUpdate = false
    
    init(locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: HikeTrackingViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map background – always visible behind stats and controls
                Map(position: .constant(mapCameraPosition)) {
                    // Show selected trail polyline (if any)
                    if let trail = selectedTrail, let polyline = trail.mkPolyline {
                        MapPolyline(polyline)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 3)
                        
                        // Show trail start point
                        if let startCoordinate = trail.routeLocations.first {
                            Annotation(languageManager.localizedString(for: "map.start"), coordinate: startCoordinate) {
                                Image(systemName: "flag.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .shadow(radius: 3)
                            }
                        }
                    }
                    
                    // Show live tracking polyline
                    if viewModel.trackPoints.count > 1 {
                        MapPolyline(coordinates: viewModel.routeCoordinates)
                            .stroke(Color.hikingGreen, lineWidth: 4)
                    }
                    
                    // Show current user location
                    if let location = viewModel.currentLocation {
                        Annotation(languageManager.localizedString(for: "hike.tracking.current.location"), coordinate: location.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 16, height: 16)
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapLanguage(languageManager)
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Statistics card over the map
                    statsCard
                        .padding()
                }
            }
            .navigationTitle(languageManager.localizedString(for: "hike.tracking.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.localizedString(for: "cancel")) {
                        if viewModel.isTracking {
                            viewModel.pauseTracking()
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isTracking {
                        Button(languageManager.localizedString(for: "stop")) {
                            viewModel.stopTracking()
                            dismiss()
                        }
                        .foregroundStyle(.red)
                    } else {
                        Button(languageManager.localizedString(for: "start")) {
                            guard let accountId = sessionManager.currentUser?.id else { return }
                            if let trail = selectedTrail {
                                viewModel.startTracking(trailId: trail.id, trailName: trail.name, accountId: accountId)
                            } else {
                                viewModel.startTracking(accountId: accountId)
                            }
                        }
                        .foregroundStyle(Color.hikingGreen)
                    }
                }
            }
            .sheet(isPresented: $isShowingTrailPicker) {
                TrailPickerForTracking { trail in
                    selectedTrail = trail
                    isShowingTrailPicker = false
                }
                .environmentObject(appViewModel)
                .environmentObject(languageManager)
            }
            .onAppear {
                viewModel.configureIfNeeded(context: modelContext)
                if selectedTrail == nil {
                    isShowingTrailPicker = true
                }
            }
            .onChange(of: viewModel.isTracking) { oldValue, newValue in
                if newValue {
                    // Start weather monitoring when tracking starts
                    Task {
                        let hasPermission = await weatherAlertManager.requestNotificationPermission()
                        if hasPermission {
                            weatherAlertManager.startHikeMonitoring(language: languageManager.currentLanguage.rawValue)
                            await updateWeather()
                        }
                    }
                } else {
                    // Stop weather monitoring when tracking stops
                    weatherAlertManager.stopMonitoring()
                }
            }
        }
    }
    
    /// Updates the latest weather snapshot
    private func updateWeather() async {
        let language = languageManager.currentLanguage.rawValue
        latestWeather = await weatherAlertManager.getLatestWeather(language: language)
    }
    
    private var statsCard: some View {
        VStack(spacing: 16) {
            // Primary statistics
            HStack(spacing: 24) {
                StatItem(
                    icon: "clock.fill",
                    value: viewModel.formattedElapsedTime,
                    label: languageManager.localizedString(for: "hike.tracking.time"),
                    color: Color.hikingGreen
                )
                StatItem(
                    icon: "ruler.fill",
                    value: viewModel.formattedDistance,
                    label: languageManager.localizedString(for: "hike.tracking.distance"),
                    color: Color.hikingSky
                )
                StatItem(
                    icon: "speedometer",
                    value: String(format: "%.1f km/h", viewModel.currentSpeedKmh),
                    label: languageManager.localizedString(for: "hike.tracking.speed"),
                    color: Color.hikingBrown
                )
            }
            
            Divider()
            
            // Secondary statistics
            HStack(spacing: 24) {
                StatItem(
                    icon: "mountain.2.fill",
                    value: String(format: "%.0f m", viewModel.currentAltitude),
                    label: languageManager.localizedString(for: "hike.tracking.altitude"),
                    color: Color.hikingDarkGreen
                )
                StatItem(
                    icon: "arrow.up.circle.fill",
                    value: "\(viewModel.trackPoints.count)",
                    label: languageManager.localizedString(for: "hike.tracking.track.points"),
                    color: Color.hikingTan
                )
            }
            
            // Real-time weather update section (only shown during active tracking)
            if viewModel.isTracking {
                Divider()
                
                // Weather update card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundStyle(Color.hikingGreen)
                        Text(languageManager.localizedString(for: "weather.alert.real.time.update"))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.hikingDarkGreen)
                        Spacer()
                        if let weather = latestWeather {
                            Button {
                                Task {
                                    await updateWeather()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundStyle(Color.hikingGreen)
                            }
                        }
                    }
                    
                    if let weather = latestWeather {
                        HStack(spacing: 16) {
                            Label("\(Int(weather.temperature))°C", systemImage: "thermometer")
                                .font(.caption)
                            Label("\(weather.humidity)%", systemImage: "humidity")
                                .font(.caption)
                            if weather.uvIndex >= 0 {
                                Label("UV \(weather.uvIndex)", systemImage: "sun.max.fill")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(.secondary)
                        
                        if let warning = weather.warningMessage, !warning.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .padding(.top, 4)
                        }
                    } else {
                        Button {
                            Task {
                                await updateWeather()
                            }
                        } label: {
                            Text(languageManager.localizedString(for: "weather.alert.check.now"))
                                .font(.caption)
                                .foregroundStyle(Color.hikingGreen)
                        }
                    }
                    
                    if weatherAlertManager.isMonitoring {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text(languageManager.localizedString(for: "weather.alert.monitoring"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                weatherAlertManager.stopMonitoring()
                            } label: {
                                Text(languageManager.localizedString(for: "weather.alert.stop.monitoring"))
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        Button {
                            Task {
                                let hasPermission = await weatherAlertManager.requestNotificationPermission()
                                if hasPermission {
                                    weatherAlertManager.startHikeMonitoring(language: languageManager.currentLanguage.rawValue)
                                    await updateWeather()
                                }
                            }
                        } label: {
                            Text(languageManager.localizedString(for: "weather.alert.start.monitoring"))
                                .font(.caption2)
                                .foregroundStyle(Color.hikingGreen)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Tracking control buttons
            if viewModel.isTracking {
                HStack(spacing: 12) {
                    Button {
                        viewModel.pauseTracking()
                    } label: {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text(languageManager.localizedString(for: "pause"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.orange)
                    }
                    
                    Button {
                        weatherAlertManager.stopMonitoring()
                        viewModel.stopTracking()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text(languageManager.localizedString(for: "stop"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.red)
                    }
                }
            } else if viewModel.currentRecord != nil {
                Button {
                    viewModel.resumeTracking()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(languageManager.localizedString(for: "resume"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.hikingGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color.hikingGreen)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
    
    private var routeCoordinates: [CLLocationCoordinate2D] {
        viewModel.trackPoints.map { $0.coordinate }
    }
    
    // Compute the camera position for the map based on current data
    private var mapCameraPosition: MapCameraPosition {
        // If we have a current location, center on it
        if let location = viewModel.currentLocation {
            return .camera(MapCamera(
                centerCoordinate: location.coordinate,
                distance: 1000,
                heading: 0,
                pitch: 0
            ))
        }
        
        // If a trail is selected, use its map region
        if let trail = selectedTrail {
            return .region(trail.mapRegion)
        }
        
        // If there are recorded track points, fit the route
        if !viewModel.trackPoints.isEmpty {
            let coordinates = viewModel.trackPoints.map { $0.coordinate }
            let center = calculateCenter(coordinates: coordinates)
            let span = calculateSpan(coordinates: coordinates)
            return .region(MKCoordinateRegion(center: center, span: span))
        }
        
        // Default: center on Hong Kong
        return .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 22.319, longitude: 114.169),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
    
    private func calculateCenter(coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        guard !coordinates.isEmpty else {
            return CLLocationCoordinate2D(latitude: 22.319, longitude: 114.169)
        }
        
        let sumLat = coordinates.reduce(0) { $0 + $1.latitude }
        let sumLon = coordinates.reduce(0) { $0 + $1.longitude }
        
        return CLLocationCoordinate2D(
            latitude: sumLat / Double(coordinates.count),
            longitude: sumLon / Double(coordinates.count)
        )
    }
    
    private func calculateSpan(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateSpan {
        guard !coordinates.isEmpty else {
            return MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let latDelta = max(maxLat - minLat, 0.01) * 1.2 // Add 20% padding
        let lonDelta = max(maxLon - minLon, 0.01) * 1.2
        
        return MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TrailPickerForTracking: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    let onTrailSelected: (Trail) -> Void
    
    enum SortOption: String, CaseIterable {
        case name = "name"
        case district = "district"
        case difficulty = "difficulty"
        case length = "length"
        
        func localizedName(_ languageManager: LanguageManager) -> String {
            switch self {
            case .name:
                return languageManager.localizedString(for: "trails.sort.name")
            case .district:
                return languageManager.localizedString(for: "trails.sort.district")
            case .difficulty:
                return languageManager.localizedString(for: "trails.sort.difficulty")
            case .length:
                return languageManager.localizedString(for: "trails.sort.length")
            }
        }
    }
    
    @State private var sortOption: SortOption = .name
    @State private var isAscending: Bool = true
    
    private var sortedTrails: [Trail] {
        let sorted = appViewModel.trails.sorted { lhs, rhs in
            let comparison: Bool
            switch sortOption {
            case .name:
                comparison = lhs.localizedName(languageManager: languageManager) < rhs.localizedName(languageManager: languageManager)
            case .district:
                comparison = lhs.localizedDistrict(languageManager: languageManager) < rhs.localizedDistrict(languageManager: languageManager)
            case .difficulty:
                comparison = lhs.difficulty.rawValue < rhs.difficulty.rawValue
            case .length:
                comparison = lhs.lengthKm < rhs.lengthKm
            }
            return isAscending ? comparison : !comparison
        }
        return sorted
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedTrails) { trail in
                    Button {
                        onTrailSelected(trail)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trail.localizedName(languageManager: languageManager))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(trail.localizedDistrict(languageManager: languageManager))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Label(trail.difficulty.localizedRawValue(languageManager: languageManager), systemImage: trail.difficulty.icon)
                                .labelStyle(.iconOnly)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "hike.tracking.select.trail"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker(languageManager.localizedString(for: "trails.sort.by"), selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.localizedName(languageManager)).tag(option)
                            }
                        }
                        Button {
                            isAscending.toggle()
                        } label: {
                            HStack {
                                Text(isAscending ? languageManager.localizedString(for: "trails.sort.ascending") : languageManager.localizedString(for: "trails.sort.descending"))
                                Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }
}

extension HikeTrackingViewModel {
    var routeCoordinates: [CLLocationCoordinate2D] {
        trackPoints.map { $0.coordinate }
    }
}

#Preview {
    HikeTrackingView(locationManager: LocationManager())
        .modelContainer(for: [HikeRecord.self, HikeTrackPoint.self], inMemory: true)
        .environmentObject(AppViewModel())
        .environmentObject(LanguageManager.shared)
}

