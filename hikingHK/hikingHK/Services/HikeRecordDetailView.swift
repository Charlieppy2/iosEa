//
//  HikeRecordDetailView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData
import MapKit

/// Shows detailed metrics and visualizations for a recorded hike.
struct HikeRecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
        .navigationTitle(record.trailName ?? "Hike Record")
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
        .alert("Delete Record", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("Are you sure you want to delete this hike record? This action cannot be undone.")
        }
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Track")
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            if !record.routeCoordinates.isEmpty {
                let center = calculateCenter()
                let span = calculateSpan()
                
                Map(position: .constant(.region(MKCoordinateRegion(center: center, span: span)))) {
                    MapPolyline(coordinates: record.routeCoordinates)
                        .stroke(Color.hikingGreen, lineWidth: 4)
                    
                    // Start point
                    if let start = record.routeCoordinates.first {
                        Annotation("Start", coordinate: start) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                    
                    // End point
                    if let end = record.routeCoordinates.last {
                        Annotation("End", coordinate: end) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                }
                .frame(height: 300)
                .cornerRadius(16)
            } else {
                Text("No Track Data")
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
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
                    unit: "km",
                    label: "Distance",
                    color: Color.hikingGreen
                )
                StatCard(
                    icon: "clock.fill",
                    value: record.formattedDuration,
                    unit: "",
                    label: "Duration",
                    color: Color.hikingSky
                )
            }
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "speedometer",
                    value: String(format: "%.1f", record.averageSpeedKmh),
                    unit: "km/h",
                    label: "Avg Speed",
                    color: Color.hikingBrown
                )
                StatCard(
                    icon: "arrow.up.arrow.down",
                    value: String(format: "%.0f", record.elevationGain),
                    unit: "m",
                    label: "Elev Gain",
                    color: Color.hikingDarkGreen
                )
            }
        }
    }
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Statistics")
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            VStack(spacing: 12) {
                DetailRow(label: "Max Speed", value: String(format: "%.1f km/h", record.maxSpeedKmh))
                DetailRow(label: "Max Altitude", value: String(format: "%.0f m", record.maxAltitude))
                DetailRow(label: "Min Altitude", value: String(format: "%.0f m", record.minAltitude))
                DetailRow(label: "Elev Loss", value: String(format: "%.0f m", record.elevationLoss))
                DetailRow(label: "Track Points", value: "\(record.trackPoints.count)")
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private var elevationChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Elevation Profile")
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            if record.trackPoints.count > 1 {
                ElevationChart(points: record.trackPoints)
                    .frame(height: 200)
            } else {
                Text("Insufficient Data")
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
                    Text("3D Track Playback")
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
            return CLLocationCoordinate2D(latitude: 22.3, longitude: 114.2)
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
        HikeRecordDetailView(record: HikeRecord())
    }
    .modelContainer(for: [HikeRecord.self, HikeTrackPoint.self], inMemory: true)
}

