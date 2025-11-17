//
//  TrailListView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI

struct TrailListView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var selectedDifficulty: Trail.Difficulty?
    @State private var searchText = ""

    private var filteredTrails: [Trail] {
        let base = viewModel.trails(for: selectedDifficulty)
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.district.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTrails) { trail in
                    NavigationLink {
                        TrailDetailView(trail: trail)
                    } label: {
                        TrailRow(trail: trail)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Trails")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All difficulties") { selectedDifficulty = nil }
                        Divider()
                        ForEach(Trail.Difficulty.allCases) { difficulty in
                            Button {
                                selectedDifficulty = difficulty
                            } label: {
                                Label(difficulty.rawValue, systemImage: difficulty.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Name or district")
        }
    }
}

struct TrailRow: View {
    let trail: Trail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trail.name)
                    .font(.headline)
                Spacer()
                Label(trail.difficulty.rawValue, systemImage: trail.difficulty.icon)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
            }
            Text(trail.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 16) {
                metricLabel(icon: "ruler", text: "\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km")
                metricLabel(icon: "arrow.up.right", text: "\(trail.elevationGain) m")
                metricLabel(icon: "clock", text: "\(trail.estimatedDurationMinutes / 60)h")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func metricLabel(icon: String, text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
        }
    }
}

#Preview {
    TrailListView()
        .environmentObject(AppViewModel())
}

