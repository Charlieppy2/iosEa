//
//  HikeTrackingView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
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
    @StateObject private var viewModel: HikeTrackingViewModel
    @State private var selectedTrail: Trail?
    @State private var isShowingTrailPicker = false
    
    init(locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: HikeTrackingViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 地圖背景 - 始終顯示地圖
                Map(position: .constant(mapCameraPosition)) {
                    // 顯示已選路線（如果有）
                    if let trail = selectedTrail, let polyline = trail.mkPolyline {
                        MapPolyline(polyline)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 3)
                        
                        // 顯示路線起點
                        if let startCoordinate = trail.routeLocations.first {
                            Annotation(languageManager.localizedString(for: "map.start"), coordinate: startCoordinate) {
                                Image(systemName: "flag.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .shadow(radius: 3)
                            }
                        }
                    }
                    
                    // 顯示軌跡線
                    if viewModel.trackPoints.count > 1 {
                        MapPolyline(coordinates: viewModel.routeCoordinates)
                            .stroke(Color.hikingGreen, lineWidth: 4)
                    }
                    
                    // 顯示當前位置
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
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // 統計卡片
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
                            if let trail = selectedTrail {
                                viewModel.startTracking(trailId: trail.id, trailName: trail.name)
                            } else {
                                viewModel.startTracking()
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
        }
    }
    
    private var statsCard: some View {
        VStack(spacing: 16) {
            // 主要統計
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
            
            // 次要統計
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
            
            // 控制按鈕
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
    
    // 計算地圖相機位置
    private var mapCameraPosition: MapCameraPosition {
        // 如果有當前位置，使用當前位置
        if let location = viewModel.currentLocation {
            return .camera(MapCamera(
                centerCoordinate: location.coordinate,
                distance: 1000,
                heading: 0,
                pitch: 0
            ))
        }
        
        // 如果有已選路線，使用路線中心
        if let trail = selectedTrail {
            return .region(trail.mapRegion)
        }
        
        // 如果有軌跡點，使用軌跡中心
        if !viewModel.trackPoints.isEmpty {
            let coordinates = viewModel.trackPoints.map { $0.coordinate }
            let center = calculateCenter(coordinates: coordinates)
            let span = calculateSpan(coordinates: coordinates)
            return .region(MKCoordinateRegion(center: center, span: span))
        }
        
        // 默認：香港中心位置
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
        
        let latDelta = max(maxLat - minLat, 0.01) * 1.2 // 添加 20% 邊距
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
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(appViewModel.trails) { trail in
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

