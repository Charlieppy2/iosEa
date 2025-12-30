//
//  TrailDetailView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI

/// Detailed trail page showing map, checkpoints, facilities, highlights and transportation info.
struct TrailDetailView: View {
    let trail: Trail
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var mtrViewModel = MTRScheduleViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                trailImage
                header
                TrailMapView(trail: trail)
                timelineSection
                facilitiesSection
                highlightsSection
                transportationSection
                // MTR real-time schedule - always show, even if no schedule found
                mtrScheduleSection
                if !trail.supplyPoints.isEmpty {
                    supplyPointsSection
                }
                if !trail.exitRoutes.isEmpty {
                    exitRoutesSection
                }
                if let notes = trail.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(20)
        }
        .task {
            await mtrViewModel.loadSchedule(for: trail, languageManager: languageManager)
        }
        .background(
            ZStack {
                Color.hikingBackgroundGradient
                HikingPatternBackground()
                    .opacity(0.15)
            }
            .ignoresSafeArea()
        )
        .navigationTitle(trail.localizedName(languageManager: languageManager))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Trail hero image displayed at the top of the detail view.
    /// Supports both local asset names and remote URLs.
    private var trailImage: some View {
        Group {
            if trail.imageName.hasPrefix("http://") || trail.imageName.hasPrefix("https://") {
                // Remote URL image
                AsyncImage(url: URL(string: trail.imageName)) { phase in
                    switch phase {
                    case .empty:
                        // Placeholder while loading
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.hikingStone.opacity(0.2))
                            .frame(height: 200)
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        // Fallback placeholder if URL fails
                        fallbackImage
                    @unknown default:
                        fallbackImage
                    }
                }
            } else {
                // Local asset image
                Image(trail.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    /// Fallback image when remote image fails to load.
    private var fallbackImage: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [Color.hikingGreen.opacity(0.3), Color.hikingDarkGreen.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 200)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.hikingGreen.opacity(0.6))
                    Text(languageManager.localizedString(for: "trail.image.unavailable"))
                        .font(.caption)
                        .foregroundStyle(Color.hikingBrown.opacity(0.7))
                }
            }
    }

    /// Top summary header with district, distance, elevation and duration.
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(trail.localizedDistrict(languageManager: languageManager), systemImage: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        statBlock(title: languageManager.localizedString(for: "trails.distance"), value: "\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) \(languageManager.localizedString(for: "unit.km"))")
                        statBlock(title: languageManager.localizedString(for: "trails.elevation"), value: "\(trail.elevationGain) \(languageManager.localizedString(for: "unit.m"))")
                        statBlock(title: languageManager.localizedString(for: "trails.duration"), value: "\(trail.estimatedDurationMinutes / 60) \(languageManager.localizedString(for: "unit.h"))")
                    }
                }
                Spacer()
                Image(systemName: trail.difficulty.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
            }
            Text(trail.localizedSummary(languageManager: languageManager))
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    /// Timeline-style list of checkpoints along the trail.
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "trail.checkpoints"))
                .font(.headline)
            VStack(alignment: .leading, spacing: 16) {
                ForEach(trail.checkpoints) { checkpoint in
                    HStack(alignment: .top, spacing: 12) {
                        VStack {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundStyle(Color.accentColor)
                            Rectangle()
                                .frame(width: 2, height: 30)
                                .foregroundStyle(Color.accentColor.opacity(0.3))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localizedCheckpointTitle(checkpoint.title))
                                .font(.subheadline.weight(.semibold))
                            Text(localizedCheckpointSubtitle(checkpoint.subtitle))
                                .foregroundStyle(.secondary)
                            HStack(spacing: 12) {
                                Label {
                                    Text("\(checkpoint.distanceKm.formatted(.number.precision(.fractionLength(1)))) \(languageManager.localizedString(for: "unit.km"))")
                                } icon: {
                                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                }
                                Label {
                                    Text("\(checkpoint.altitude) \(languageManager.localizedString(for: "unit.m"))")
                                } icon: {
                                    Image(systemName: "altimeter")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    /// Horizontal list of trail facilities (toilets, shelters, kiosks, etc.).
    private var facilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "trail.facilities"))
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(trail.facilities, id: \.self) { facility in
                        VStack(spacing: 8) {
                            Image(systemName: facility.systemImage)
                                .font(.title2)
                            Text(localizedFacilityName(facility.name))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 120, height: 100)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    /// Section listing key highlights of the trail.
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "trail.highlights"))
                .font(.headline)
            ForEach(trail.highlights, id: \.self) { highlight in
                Label(localizedHighlight(highlight), systemImage: "sparkles")
                    .padding(.vertical, 6)
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
    
    /// Returns a localized version of a highlight, falling back to the original text.
    private func localizedHighlight(_ highlight: String) -> String {
        // Create a key based on trail ID and normalized highlight text.
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

    /// Section describing how to reach the trailhead and return from the finish.
    private var transportationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "trail.transportation"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // 起點交通
                if let startTransport = trail.startPointTransport, !startTransport.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(languageManager.localizedString(for: "trail.start.point"), systemImage: "location.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.hikingGreen)
                        Text(localizedStartTransport)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 終點交通
                if let endTransport = trail.endPointTransport, !endTransport.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(languageManager.localizedString(for: "trail.end.point"), systemImage: "flag.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.hikingGreen)
                        Text(localizedEndTransport)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 如果沒有分開的起終點，使用舊的 transportation
                if trail.startPointTransport == nil && trail.endPointTransport == nil {
            Text(localizedTransportation)
                        .font(.subheadline)
                .foregroundStyle(.secondary)
                }
            }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
    
    /// Section listing supply points along the trail.
    private var supplyPointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "trail.supply.points"))
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(trail.supplyPoints, id: \.self) { supply in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(Color.hikingGreen)
                            .font(.caption)
                        Text(localizedSupplyPoint(supply))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
    
    /// Section listing exit routes from the trail.
    private var exitRoutesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "trail.exit.routes"))
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(trail.exitRoutes, id: \.self) { exit in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.turn.up.right")
                            .foregroundStyle(Color.orange)
                            .font(.caption)
                        Text(localizedExitRoute(exit))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
    
    /// Section displaying important notes and warnings.
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "trail.notes"))
                .font(.headline)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.orange)
                Text(localizedNotes(notes))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var localizedTransportation: String {
        let key = "trail.\(trail.id.uuidString.lowercased()).transportation"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : trail.transportation
    }
    
    private var localizedStartTransport: String {
        guard let startTransport = trail.startPointTransport else { return "" }
        let key = "trail.\(trail.id.uuidString.lowercased()).start.transport"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : startTransport
    }
    
    private var localizedEndTransport: String {
        guard let endTransport = trail.endPointTransport else { return "" }
        let key = "trail.\(trail.id.uuidString.lowercased()).end.transport"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : endTransport
    }
    
    private func localizedSupplyPoint(_ supply: String) -> String {
        let key = "trail.\(trail.id.uuidString.lowercased()).supply.\(supply.lowercased().replacingOccurrences(of: " ", with: "."))"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : supply
    }
    
    private func localizedExitRoute(_ exit: String) -> String {
        let key = "trail.\(trail.id.uuidString.lowercased()).exit.\(exit.lowercased().replacingOccurrences(of: " ", with: "."))"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : exit
    }
    
    private func localizedNotes(_ notes: String) -> String {
        let key = "trail.\(trail.id.uuidString.lowercased()).notes"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : notes
    }
    
    /// Section displaying MTR real-time train schedules
    private var mtrScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(languageManager.localizedString(for: "mtr.real.time.schedule"))
                    .font(.headline)
                Spacer()
                if mtrViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        Task {
                            await mtrViewModel.loadSchedule(for: trail, languageManager: languageManager)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
            }
            
            if let error = mtrViewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            if let schedule = mtrViewModel.schedule {
                VStack(alignment: .leading, spacing: 12) {
                    // UP direction trains
                    if let upTrains = schedule.UP, !upTrains.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(languageManager.localizedString(for: "mtr.direction.up"), systemImage: "arrow.up")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.hikingGreen)
                            
                            ForEach(Array(upTrains.prefix(4))) { train in
                                HStack {
                                    Text(train.dest)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(formatTrainTime(train.time))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.hikingGreen)
                                }
                            }
                        }
                    }
                    
                    // DOWN direction trains
                    if let downTrains = schedule.DOWN, !downTrains.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(languageManager.localizedString(for: "mtr.direction.down"), systemImage: "arrow.down")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.hikingGreen)
                            
                            ForEach(Array(downTrains.prefix(4))) { train in
                                HStack {
                                    Text(train.dest)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(formatTrainTime(train.time))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.hikingGreen)
                                }
                            }
                        }
                    }
                }
            } else if !mtrViewModel.isLoading && mtrViewModel.error == nil {
                // Show message when no station found but no error occurred
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text(languageManager.localizedString(for: "mtr.no.station.found"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    /// Format train time string (e.g., "1 min" or "Arriving")
    private func formatTrainTime(_ time: String) -> String {
        if time.lowercased().contains("arriving") || time == "Arr" {
            return languageManager.localizedString(for: "mtr.arriving")
        }
        if let minutes = Int(time.replacingOccurrences(of: "min", with: "").trimmingCharacters(in: .whitespaces)) {
            return "\(minutes) \(languageManager.localizedString(for: "mtr.minutes"))"
        }
        return time
    }

    private func localizedCheckpointTitle(_ title: String) -> String {
        // Normalize the title key
        let normalizedTitle = title.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "-", with: ".")
        let key = "checkpoint.\(normalizedTitle)"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : title
    }
    
    private func localizedCheckpointSubtitle(_ subtitle: String) -> String {
        // Normalize the subtitle key
        let normalizedSubtitle = subtitle.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "'", with: "")
        let key = "checkpoint.\(normalizedSubtitle)"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : subtitle
    }
    
    private func localizedFacilityName(_ name: String) -> String {
        let normalizedName = name.lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .replacingOccurrences(of: "'", with: "")
        let key = "facility.\(normalizedName)"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : name
    }
    
    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        TrailDetailView(trail: Trail.sampleData[0])
            .environmentObject(LanguageManager.shared)
    }
}

