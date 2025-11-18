//
//  TrailListView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI

struct TrailListView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
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
            .scrollContentBackground(.hidden)
            .background(
                ZStack {
                    Color.hikingBackgroundGradient
                    HikingPatternBackground()
                        .opacity(0.15)
                }
                .ignoresSafeArea()
            )
            .navigationTitle(languageManager.localizedString(for: "trails.title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(languageManager.localizedString(for: "trails.all.difficulties")) { selectedDifficulty = nil }
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
            .searchable(text: $searchText, prompt: languageManager.localizedString(for: "trails.search.prompt"))
        }
    }
}

struct TrailRow: View {
    let trail: Trail

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(trail.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
                Label(trail.difficulty.rawValue, systemImage: trail.difficulty.icon)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.hikingGreen)
                    .font(.title3)
            }
            Text(trail.summary)
                .font(.subheadline)
                .foregroundStyle(Color.hikingBrown)
                .lineLimit(2)
            HStack(spacing: 16) {
                metricLabel(icon: "ruler.fill", text: "\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km")
                metricLabel(icon: "arrow.up.right", text: "\(trail.elevationGain) m")
                metricLabel(icon: "clock.fill", text: "\(trail.estimatedDurationMinutes / 60)h")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.hikingStone)
        }
        .padding(.vertical, 6)
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

