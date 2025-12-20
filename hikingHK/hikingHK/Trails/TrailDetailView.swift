//
//  TrailDetailView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI

/// Detailed trail page showing map, checkpoints, facilities, highlights and transportation info.
struct TrailDetailView: View {
    let trail: Trail
    @EnvironmentObject private var languageManager: LanguageManager
    private let distancePostService = DistancePostService()
    @State private var distancePosts: [DistancePost] = []
    @State private var isLoadingDistancePosts: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                TrailMapView(trail: trail)
                timelineSection
                distancePostsSection
                facilitiesSection
                highlightsSection
                transportationSection
            }
            .padding(20)
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
        .task {
            await loadDistancePosts()
        }
    }
    
    /// Loads distance posts for the current trail.
    private func loadDistancePosts() async {
        isLoadingDistancePosts = true
        defer { isLoadingDistancePosts = false }
        
        do {
            distancePosts = try await distancePostService.fetchDistancePosts(for: trail.id)
            print("✅ TrailDetailView: Loaded \(distancePosts.count) distance posts for trail \(trail.name)")
        } catch {
            print("⚠️ TrailDetailView: Failed to load distance posts: \(error)")
            distancePosts = []
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

    /// Section displaying distance posts along the trail.
    private var distancePostsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localizedString(for: "distance.posts.title"))
                .font(.headline)
            
            if isLoadingDistancePosts {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(languageManager.localizedString(for: "distance.posts.loading"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else if distancePosts.isEmpty {
                Text(languageManager.localizedString(for: "distance.posts.no.posts"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(distancePosts.sorted(by: { $0.distanceFromStart < $1.distanceFromStart })) { post in
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(Color.orange)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(languageManager.localizedString(for: "distance.posts.post.number")
                                    .replacingOccurrences(of: "{number}", with: post.postNumber))
                                    .font(.subheadline.weight(.semibold))
                                Text(languageManager.localizedString(for: "distance.posts.distance.from.start")
                                    .replacingOccurrences(of: "{distance}", with: String(format: "%.1f", post.distanceFromStart)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
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
            Text(localizedTransportation)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
    
    private var localizedTransportation: String {
        let key = "trail.\(trail.id.uuidString.lowercased()).transportation"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : trail.transportation
    }

    private func localizedCheckpointTitle(_ title: String) -> String {
        let key = "checkpoint.\(title.lowercased().replacingOccurrences(of: " ", with: ".").replacingOccurrences(of: "'", with: ""))"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : title
    }
    
    private func localizedCheckpointSubtitle(_ subtitle: String) -> String {
        let key = "checkpoint.\(subtitle.lowercased())"
        let localized = languageManager.localizedString(for: key)
        return localized != key ? localized : subtitle
    }
    
    private func localizedFacilityName(_ name: String) -> String {
        let key = "facility.\(name.lowercased().replacingOccurrences(of: " ", with: "."))"
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

