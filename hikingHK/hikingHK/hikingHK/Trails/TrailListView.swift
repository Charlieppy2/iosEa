//
//  TrailListView.swift
//  hikingHK
//
//  路線列表頁（已優化 UI：難度卡片底色、難度標籤、地區列等）
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
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.district.localizedCaseInsensitiveContains(searchText)
        }
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
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
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
                        Button(languageManager.localizedString(for: "trails.all.difficulties")) {
                            selectedDifficulty = nil
                        }
                        Divider()
                        ForEach(Trail.Difficulty.allCases) { difficulty in
                            Button {
                                selectedDifficulty = difficulty
                            } label: {
                                Label(
                                    difficulty.localizedRawValue(languageManager: languageManager),
                                    systemImage: difficulty.icon
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(
                text: $searchText,
                prompt: languageManager.localizedString(for: "trails.search.prompt")
            )
        }
    }
}

struct TrailRow: View {
    let trail: Trail
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題 + 難度標籤
            HStack {
                Text(trail.localizedName(languageManager: languageManager))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: trail.difficulty.icon)
                    Text(trail.difficulty.localizedRawValue(languageManager: languageManager))
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(difficultyAccentColor.opacity(0.12))
                )
                .foregroundStyle(difficultyAccentColor)
            }
            
            // 簡介
            Text(trail.localizedSummary(languageManager: languageManager))
                .font(.subheadline)
                .foregroundStyle(Color.hikingBrown)
                .lineLimit(2)
            
            // 地區列
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption2)
                    .foregroundStyle(Color.hikingGreen)
                Text(trail.localizedDistrict(languageManager: languageManager))
                    .font(.caption)
                    .foregroundStyle(Color.hikingBrown.opacity(0.9))
                Spacer()
            }
            
            // 指標列
            HStack(spacing: 16) {
                metricLabel(
                    icon: "ruler.fill",
                    text: "\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) \(languageManager.localizedString(for: "unit.km"))"
                )
                metricLabel(
                    icon: "arrow.up.right",
                    text: "\(trail.elevationGain) \(languageManager.localizedString(for: "unit.m"))"
                )
                metricLabel(
                    icon: "clock.fill",
                    text: "\(trail.estimatedDurationMinutes / 60)\(languageManager.localizedString(for: "unit.h"))"
                )
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.hikingStone)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(difficultyBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.vertical, 4)
    }
    
    private func metricLabel(icon: String, text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
        }
    }
    
    /// 根據路線難度，使用 3 種不同的卡片底色做區分
    private var difficultyBackgroundColor: Color {
        switch trail.difficulty {
        case .easy:
            return Color.hikingDifficultyEasyBackground
        case .moderate:
            return Color.hikingDifficultyModerateBackground
        case .challenging:
            return Color.hikingDifficultyChallengingBackground
        }
    }
    
    /// 難度標籤用的主色
    private var difficultyAccentColor: Color {
        switch trail.difficulty {
        case .easy:
            return Color.hikingGreen
        case .moderate:
            return Color.orange
        case .challenging:
            return Color.red
        }
    }
}

#Preview {
    TrailListView()
        .environmentObject(AppViewModel())
        .environmentObject(LanguageManager.shared)
}


