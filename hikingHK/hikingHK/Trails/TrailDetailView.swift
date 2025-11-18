//
//  TrailDetailView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI

struct TrailDetailView: View {
    let trail: Trail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                TrailMapView(trail: trail)
                timelineSection
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
        .navigationTitle(trail.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(trail.district, systemImage: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        statBlock(title: "Distance", value: "\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km")
                        statBlock(title: "Elevation", value: "\(trail.elevationGain) m")
                        statBlock(title: "Duration", value: "\(trail.estimatedDurationMinutes / 60) h")
                    }
                }
                Spacer()
                Image(systemName: trail.difficulty.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
            }
            Text(trail.summary)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route checkpoints")
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
                            Text(checkpoint.title)
                                .font(.subheadline.weight(.semibold))
                            Text(checkpoint.subtitle)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 12) {
                                Label {
                                    Text("\(checkpoint.distanceKm.formatted(.number.precision(.fractionLength(1)))) km")
                                } icon: {
                                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                }
                                Label {
                                    Text("\(checkpoint.altitude) m")
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

    private var facilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Facilities & services")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(trail.facilities, id: \.self) { facility in
                        VStack(spacing: 8) {
                            Image(systemName: facility.systemImage)
                                .font(.title2)
                            Text(facility.name)
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

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)
            ForEach(trail.highlights, id: \.self) { highlight in
                Label(highlight, systemImage: "sparkles")
                    .padding(.vertical, 6)
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var transportationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transport tips")
                .font(.headline)
            Text(trail.transportation)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
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
    }
}

