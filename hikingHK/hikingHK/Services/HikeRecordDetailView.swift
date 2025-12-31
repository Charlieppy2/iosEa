//
//  HikeRecordDetailView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI
import SwiftData
import MapKit

/// Shows detailed metrics and visualizations for a recorded hike.
struct HikeRecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var viewModel: AppViewModel
    let record: HikeRecord
    @State private var isShowingPlayback = false
    @State private var isShowingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Map section
                mapSection
                
                // Main summary stats
                mainStatsSection
                
                // Detailed statistics
                detailedStatsSection
                
                // Elevation profile chart
                elevationChartSection
                
                // Action buttons (e.g. 3D playback)
                actionButtons
            }
            .padding()
        }
        .navigationTitle(localizedTrailName)
        .navigationBarTitleDisplayMode(.inline)
        .background(
            ZStack {
                Color.hikingBackgroundGradient
                HikingPatternBackground()
                    .opacity(0.15)
            }
            .ignoresSafeArea()
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $isShowingPlayback) {
            HikePlaybackView(record: record)
        }
        .alert(languageManager.localizedString(for: "records.delete"), isPresented: $isShowingDeleteConfirmation) {
            Button(languageManager.localizedString(for: "cancel"), role: .cancel) { }
            Button(languageManager.localizedString(for: "delete"), role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text(languageManager.localizedString(for: "records.delete.confirm"))
        }
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "records.route.track"))
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            if !record.routeCoordinates.isEmpty {
                let center = calculateCenter()
                let span = calculateSpan()
                let region = MKCoordinateRegion(center: center, span: span)
                
                Map(position: .constant(.region(region))) {
                    MapPolyline(coordinates: record.routeCoordinates)
                        .stroke(Color.hikingGreen, lineWidth: 4)
                    
                    // Start point
                    if let start = record.routeCoordinates.first {
                        Annotation(languageManager.localizedString(for: "records.start"), coordinate: start) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                    
                    // End point
                    if let end = record.routeCoordinates.last {
                        Annotation(languageManager.localizedString(for: "records.end"), coordinate: end) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapLanguage(languageManager)
                .frame(height: 300)
                .cornerRadius(16)
            } else {
                // 當沒有路線座標時，顯示香港中心地圖
                let hongKongCenter = CLLocationCoordinate2D(latitude: 22.2783, longitude: 114.1747)
                let hongKongRegion = MKCoordinateRegion(
                    center: hongKongCenter,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
                
                Map(position: .constant(.region(hongKongRegion))) {
                    // 顯示香港中心標記
                    Annotation(languageManager.localizedString(for: "records.no.track.data"), coordinate: hongKongCenter) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapLanguage(languageManager)
                .frame(height: 300)
                .cornerRadius(16)
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private var mainStatsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    icon: "ruler.fill",
                    value: String(format: "%.2f", record.distanceKm),
                    unit: languageManager.localizedString(for: "records.unit.km"),
                    label: languageManager.localizedString(for: "records.distance"),
                    color: Color.hikingGreen
                )
                StatCard(
                    icon: "clock.fill",
                    value: record.formattedDuration,
                    unit: "",
                    label: languageManager.localizedString(for: "records.duration"),
                    color: Color.hikingSky
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "speedometer",
                    value: String(format: "%.1f", record.averageSpeedKmh),
                    unit: languageManager.localizedString(for: "records.unit.kmh"),
                    label: languageManager.localizedString(for: "records.avg.speed"),
                    color: Color.hikingBrown
                )
                StatCard(
                    icon: "arrow.up.arrow.down",
                    value: String(format: "%.0f", record.elevationGain),
                    unit: languageManager.localizedString(for: "records.unit.m"),
                    label: languageManager.localizedString(for: "records.elev.gain"),
                    color: Color.hikingDarkGreen
                )
            }
        }
    }
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "records.detailed.stats"))
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            VStack(spacing: 12) {
                DetailRow(
                    label: languageManager.localizedString(for: "records.max.speed"),
                    value: String(format: "%.1f %@", record.maxSpeedKmh, languageManager.localizedString(for: "records.unit.kmh"))
                )
                DetailRow(
                    label: languageManager.localizedString(for: "records.max.altitude"),
                    value: String(format: "%.0f %@", record.maxAltitude, languageManager.localizedString(for: "records.unit.m"))
                )
                DetailRow(
                    label: languageManager.localizedString(for: "records.min.altitude"),
                    value: String(format: "%.0f %@", record.minAltitude, languageManager.localizedString(for: "records.unit.m"))
                )
                DetailRow(
                    label: languageManager.localizedString(for: "records.elev.loss"),
                    value: String(format: "%.0f %@", record.elevationLoss, languageManager.localizedString(for: "records.unit.m"))
                )
                DetailRow(
                    label: languageManager.localizedString(for: "records.track.points"),
                    value: "\(record.trackPoints.count)"
                )
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private var elevationChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "records.elevation.profile"))
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            if record.trackPoints.count > 1 {
                ElevationChart(points: record.trackPoints)
                    .frame(height: 200)
            } else {
                Text(languageManager.localizedString(for: "records.insufficient.data"))
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                isShowingPlayback = true
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text(languageManager.localizedString(for: "records.3d.playback"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.hikingGreen, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
        }
    }
    
    private func calculateCenter() -> CLLocationCoordinate2D {
        guard !record.routeCoordinates.isEmpty else {
            // 香港中心座標（中環）
            return CLLocationCoordinate2D(latitude: 22.2783, longitude: 114.1747)
        }
        
        let sumLat = record.routeCoordinates.reduce(0) { $0 + $1.latitude }
        let sumLon = record.routeCoordinates.reduce(0) { $0 + $1.longitude }
        let count = Double(record.routeCoordinates.count)
        
        return CLLocationCoordinate2D(
            latitude: sumLat / count,
            longitude: sumLon / count
        )
    }
    
    private func calculateSpan() -> MKCoordinateSpan {
        guard record.routeCoordinates.count > 1 else {
            return MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        }
        
        let lats = record.routeCoordinates.map { $0.latitude }
        let lons = record.routeCoordinates.map { $0.longitude }
        
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!
        
        return MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
    }
    
    /// 獲取本地化的路線名稱
    private var localizedTrailName: String {
        // 優先從 AppViewModel 中查找對應的 Trail 對象
        if let trailId = record.trailId,
           let trail = viewModel.trails.first(where: { $0.id == trailId }) {
            return trail.localizedName(languageManager: languageManager)
        }
        
        // 如果找不到 Trail 對象，嘗試從本地化字符串中獲取
        if let trailName = record.trailName {
            if let trailId = record.trailId {
                let trailNameKey = "trail.\(trailId.uuidString.lowercased()).name"
                let localizedName = languageManager.localizedString(for: trailNameKey)
                
                // 如果找到了本地化版本（不是原始 key），使用它
                if localizedName != trailNameKey {
                    return localizedName
                }
            }
            
            // 否則使用原始名稱
            return trailName
        }
        
        // 如果都沒有，返回默認標題
        return languageManager.localizedString(for: "records.detail")
    }
    
    private func deleteRecord() {
        let store = HikeRecordStore(context: modelContext)
        do {
            try store.deleteRecord(record)
            dismiss()
        } catch {
            print("Delete record error: \(error)")
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(Color.hikingDarkGreen)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Color.hikingBrown)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.hikingStone)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.hikingBrown)
            Spacer()
            Text(value)
                .foregroundStyle(Color.hikingDarkGreen)
                .fontWeight(.medium)
        }
    }
}

struct ElevationChart: View {
    let points: [HikeTrackPoint]
    
    var body: some View {
        GeometryReader { geometry in
            let minAlt = points.map { $0.altitude }.min() ?? 0
            let maxAlt = points.map { $0.altitude }.max() ?? 0
            let altRange = max(maxAlt - minAlt, 1)
            
            Path { path in
                guard points.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                for (index, point) in points.enumerated() {
                    let x = CGFloat(index) / CGFloat(points.count - 1) * width
                    let normalizedAlt = (point.altitude - minAlt) / altRange
                    let y = height - (normalizedAlt * height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.hikingGreen, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .background(
                Path { path in
                    guard points.count > 1 else { return }
                    
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) / CGFloat(points.count - 1) * width
                        let normalizedAlt = (point.altitude - minAlt) / altRange
                        let y = height - (normalizedAlt * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    
                    // Close the path to create a filled area under the elevation line
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.hikingGreen.opacity(0.3), Color.hikingGreen.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
        }
    }
}

#Preview {
    NavigationStack {
        HikeRecordDetailView(record: HikeRecord(accountId: UUID(), trailId: nil, trailName: nil, startTime: Date(), isCompleted: false))
            .environmentObject(LanguageManager.shared)
    }
    .modelContainer(for: [HikeRecord.self, HikeTrackPoint.self], inMemory: true)
}

