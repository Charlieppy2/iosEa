//
//  AchievementView.swift
//  hikingHK
//
//  Profile achievements & badges screen with progress summary and filters.
//

import SwiftUI
import SwiftData

/// Displays the user's unlocked and locked achievements with filtering by badge type.
struct AchievementView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel: AchievementViewModel
    @State private var selectedType: Achievement.BadgeType?
    
    init() {
        _viewModel = StateObject(wrappedValue: AchievementViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary statistics card (unlocked vs total achievements)
                    statsCard
                    
                    // Badge type filter chips
                    typeFilter
                    
                    // Achievements list
                    achievementsList
                }
                .padding()
            }
            .navigationTitle(languageManager.localizedString(for: "profile.achievements.badges"))
            .background(
                ZStack {
                    Color.hikingBackgroundGradient
                    HikingPatternBackground()
                        .opacity(0.15)
                }
                .ignoresSafeArea()
            )
            .onAppear {
                // Ensure default achievements exist in the database before loading
                AchievementSeeder.ensureDefaults(in: modelContext)
                viewModel.configureIfNeeded(context: modelContext)
                
                // Load hike records and refresh achievement progress
                Task {
                    await refreshAchievementProgress()
                }
            }
            .alert(languageManager.localizedString(for: "achievement.new.unlocked"), isPresented: .constant(!viewModel.newlyUnlockedAchievements.isEmpty)) {
                Button(languageManager.localizedString(for: "achievement.view")) {
                    // Can scroll to newly unlocked achievement
                }
                Button(languageManager.localizedString(for: "ok"), role: .cancel) {
                    viewModel.newlyUnlockedAchievements = []
                }
            } message: {
                if let first = viewModel.newlyUnlockedAchievements.first {
                    Text(languageManager.localizedString(for: "achievement.congratulations").replacingOccurrences(of: "{title}", with: first.title))
                }
            }
        }
    }
    
    /// Loads hike records and refreshes achievement progress
    private func refreshAchievementProgress() async {
        do {
            let recordStore = HikeRecordStore(context: modelContext)
            let hikeRecords = try recordStore.loadAllRecords()
            viewModel.refreshAchievements(from: hikeRecords)
        } catch {
            print("⚠️ AchievementView: Failed to load hike records: \(error)")
            // Continue with existing achievement data even if hike records fail to load
        }
    }
    
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.unlockedCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color.hikingGreen)
                    Text(languageManager.localizedString(for: "achievement.unlocked"))
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.totalCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color.hikingDarkGreen)
                    Text(languageManager.localizedString(for: "achievement.total"))
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                }
            }
            
            // Overall unlocked progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.hikingStone.opacity(0.2))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.hikingGreen, Color.hikingDarkGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(viewModel.unlockedCount) / CGFloat(max(viewModel.totalCount, 1)), height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterButton(
                    title: languageManager.localizedString(for: "achievement.filter.all"),
                    icon: "star.fill",
                    isSelected: selectedType == nil
                ) {
                    selectedType = nil
                }
                
                ForEach(Achievement.BadgeType.allCases, id: \.self) { type in
                    FilterButton(
                        title: type.localizedRawValue(languageManager: languageManager),
                        icon: type.icon,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var achievementsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            let filteredAchievements = selectedType == nil
                ? viewModel.achievements
                : viewModel.achievements.filter { $0.badgeType == selectedType }
            
            ForEach(filteredAchievements) { achievement in
                AchievementRow(achievement: achievement)
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.hikingGreen : Color.hikingStone.opacity(0.2),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : Color.hikingDarkGreen)
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? LinearGradient(
                                colors: [Color.hikingGreen, Color.hikingDarkGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.hikingStone.opacity(0.3), Color.hikingStone.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(achievement.isUnlocked ? .white : Color.hikingStone)
            }
            
            // Achievement title, description and progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(achievement.localizedTitle(languageManager: languageManager))
                        .font(.headline)
                        .foregroundStyle(achievement.isUnlocked ? Color.hikingDarkGreen : Color.hikingStone)
                    
                    Spacer()
                    
                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
                
                Text(achievement.localizedDescription(languageManager: languageManager))
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingBrown)
                
                // Per-achievement progress bar
                if !achievement.isUnlocked {
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.hikingStone.opacity(0.2))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.hikingGreen)
                                    .frame(width: geometry.size.width * CGFloat(achievement.progress), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        Text("\(formatValue(achievement.currentValue)) / \(formatValue(achievement.targetValue))")
                            .font(.caption)
                            .foregroundStyle(Color.hikingStone)
                    }
                } else if let unlockedAt = achievement.unlockedAt {
                    Text("\(languageManager.localizedString(for: "achievement.unlocked.on")) \(unlockedAt, style: .date)")
                        .font(.caption)
                        .foregroundStyle(Color.hikingGreen)
                }
            }
        }
        .padding()
        .background(
            achievement.isUnlocked
                ? AnyShapeStyle(Color.hikingCardGradient)
                : AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.98, blue: 0.95).opacity(0.5),
                            Color(red: 0.92, green: 0.95, blue: 0.92).opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .hikingCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked ? Color.hikingGreen.opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
    }
    
    private func formatValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0f", value)
        } else if value >= 1 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

#Preview {
    AchievementView()
        .modelContainer(for: [Achievement.self], inMemory: true)
        .environmentObject(LanguageManager.shared)
}

