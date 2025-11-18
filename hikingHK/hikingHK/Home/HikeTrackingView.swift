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
                // 地圖背景
                if let location = viewModel.currentLocation {
                    Map(position: .constant(.camera(MapCamera(
                        centerCoordinate: location.coordinate,
                        distance: 500,
                        heading: 0,
                        pitch: 0
                    )))) {
                        // 顯示軌跡線
                        if viewModel.trackPoints.count > 1 {
                            MapPolyline(coordinates: viewModel.routeCoordinates)
                                .stroke(Color.hikingGreen, lineWidth: 4)
                        }
                        
                        // 顯示當前位置
                        Annotation(languageManager.localizedString(for: "hike.tracking.current.location"), coordinate: location.coordinate) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .ignoresSafeArea()
                } else {
                    Color.hikingBackgroundGradient
                        .ignoresSafeArea()
                }
                
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
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @EnvironmentObject private var languageManager: LanguageManager
    
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
                                Text(trail.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(trail.district)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Label(trail.difficulty.rawValue, systemImage: trail.difficulty.icon)
                                .labelStyle(.iconOnly)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Trail")
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

extension HikeTrackingViewModel {
    var routeCoordinates: [CLLocationCoordinate2D] {
        trackPoints.map { $0.coordinate }
    }
}

#Preview {
    HikeTrackingView(locationManager: LocationManager())
        .modelContainer(for: [HikeRecord.self, HikeTrackPoint.self], inMemory: true)
}

