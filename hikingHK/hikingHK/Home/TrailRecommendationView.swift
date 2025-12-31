//
//  TrailRecommendationView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI
import SwiftData

struct TrailRecommendationView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var viewModel: TrailRecommendationViewModel
    @State private var availableHours: Double = 4.0
    @State private var isExpandingPreferences = false
    
    init(appViewModel: AppViewModel) {
        _viewModel = StateObject(wrappedValue: TrailRecommendationViewModel(appViewModel: appViewModel))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Recommendation settings card
                    recommendationSettingsCard
                    
                    // Recommendation results
                    if viewModel.isLoading {
                        ProgressView(languageManager.localizedString(for: "recommendations.generating"))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if viewModel.recommendations.isEmpty {
                        emptyStateView
                    } else {
                        recommendationsList
                    }
                }
                .padding()
            }
            .navigationTitle(languageManager.localizedString(for: "home.recommendations"))
            .background(
                ZStack {
                    Color.hikingBackgroundGradient
                    HikingPatternBackground()
                        .opacity(0.15)
                }
                .ignoresSafeArea()
            )
            .onAppear {
                guard let accountId = sessionManager.currentUser?.id else { return }
                viewModel.configureIfNeeded(context: modelContext, accountId: accountId)
                Task {
                    await viewModel.generateRecommendations(availableTime: availableHours * 3600, accountId: accountId)
                }
            }
        }
    }
    
    private var recommendationSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.localizedString(for: "recommendations.settings"))
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("\(languageManager.localizedString(for: "recommendations.available.time")): \(formatAvailableTime(availableHours))")
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingBrown)
                
                Slider(value: $availableHours, in: 1...8, step: 0.5) { editing in
                    if !editing {
                        guard let accountId = sessionManager.currentUser?.id else { return }
                        Task {
                            await viewModel.generateRecommendations(availableTime: availableHours * 3600, accountId: accountId)
                        }
                    }
                }
                .tint(Color.hikingGreen)
            }
            
            // Preference settings section
            if let preference = viewModel.userPreference {
                Divider()
                
                Button {
                    withAnimation {
                        isExpandingPreferences.toggle()
                    }
                } label: {
                    HStack {
                        Text(languageManager.localizedString(for: "preferences.title"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.hikingDarkGreen)
                        Spacer()
                        Image(systemName: isExpandingPreferences ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
                .buttonStyle(.plain)
                
                if isExpandingPreferences {
                    preferenceSettingsContent(preference: preference)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            Button {
                guard let accountId = sessionManager.currentUser?.id else { return }
                Task {
                    await viewModel.generateRecommendations(availableTime: availableHours * 3600, accountId: accountId)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(languageManager.localizedString(for: "recommendations.regenerate"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.hikingGreen, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    @ViewBuilder
    private func preferenceSettingsContent(preference: UserPreference) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Fitness Level
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.localizedString(for: "preferences.fitness.level"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: Binding(
                    get: { preference.fitnessLevel },
                    set: { newValue in
                        preference.fitnessLevel = newValue
                        viewModel.updateUserPreference(preference)
                        guard let accountId = sessionManager.currentUser?.id else { return }
                        Task {
                            await viewModel.generateRecommendations(availableTime: availableHours * 3600, accountId: accountId)
                        }
                    }
                )) {
                    ForEach(UserPreference.FitnessLevel.allCases, id: \.self) { level in
                        Text(level.localizedRawValue(languageManager: languageManager)).tag(level)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Scenery Preferences
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.localizedString(for: "preferences.scenery"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(UserPreference.SceneryType.allCases, id: \.self) { scenery in
                        Toggle(isOn: Binding(
                            get: { preference.preferredScenery.contains(scenery) },
                            set: { isOn in
                                if isOn {
                                    if !preference.preferredScenery.contains(scenery) {
                                        preference.preferredScenery.append(scenery)
                                    }
                                } else {
                                    preference.preferredScenery.removeAll { $0 == scenery }
                                }
                                viewModel.updateUserPreference(preference)
                                guard let accountId = sessionManager.currentUser?.id else { return }
                                Task {
                                    await viewModel.generateRecommendations(availableTime: availableHours * 3600, accountId: accountId)
                                }
                            }
                        )) {
                            Label(scenery.localizedRawValue(languageManager: languageManager), systemImage: scenery.icon)
                                .font(.caption)
                        }
                        .toggleStyle(.button)
                    }
                }
            }
            
            // Difficulty Preference
            VStack(alignment: .leading, spacing: 8) {
                Text(languageManager.localizedString(for: "preferences.difficulty"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: Binding(
                    get: { preference.preferredDifficulty },
                    set: { newValue in
                        preference.preferredDifficulty = newValue
                        viewModel.updateUserPreference(preference)
                        guard let accountId = sessionManager.currentUser?.id else { return }
                        Task {
                            await viewModel.generateRecommendations(availableTime: availableHours * 3600, accountId: accountId)
                        }
                    }
                )) {
                    Text(languageManager.localizedString(for: "preferences.no.preference")).tag(Trail.Difficulty?.none)
                    ForEach(Trail.Difficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.localizedRawValue(languageManager: languageManager)).tag(Trail.Difficulty?.some(difficulty))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(.top, 8)
    }
    
    private func formatAvailableTime(_ hours: Double) -> String {
        let wholeHours = Int(hours)
        let hasHalfHour = abs(hours.truncatingRemainder(dividingBy: 1.0) - 0.5) < 0.01
        
        if hasHalfHour {
            if wholeHours == 0 {
                return languageManager.localizedString(for: "recommendations.half.hour")
            } else {
                // Format: "1.5 hours" with localized suffix
                return "\(wholeHours)\(languageManager.localizedString(for: "recommendations.hour.and.half"))"
            }
        } else {
            return "\(wholeHours)\(languageManager.localizedString(for: "recommendations.hours"))"
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(Color.hikingGreen)
            Text(languageManager.localizedString(for: "recommendations.none"))
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            Text(languageManager.localizedString(for: "recommendations.adjust.preferences"))
                .font(.subheadline)
                .foregroundStyle(Color.hikingBrown)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var recommendationsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.localizedString(for: "recommendations.for.you"))
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            ForEach(viewModel.recommendations.prefix(10)) { recommendation in
                RecommendationCard(recommendation: recommendation) { action in
                    guard let accountId = sessionManager.currentUser?.id else { return }
                    viewModel.recordUserAction(for: recommendation, action: action, accountId: accountId)
                }
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: TrailRecommendation
    let onAction: (RecommendationRecord.UserAction) -> Void
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var isShowingDetail = false
    @State private var isShowingPlanner = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and match percentage
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.trail.localizedName(languageManager: languageManager))
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    Text(recommendation.trail.localizedDistrict(languageManager: languageManager))
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(recommendation.matchPercentage)%")
                        .font(.title2.bold())
                        .foregroundStyle(Color.hikingGreen)
                    Text(languageManager.localizedString(for: "recommendations.match"))
                        .font(.caption)
                        .foregroundStyle(Color.hikingStone)
                }
            }
            
            // Match progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.hikingStone.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.hikingGreen, Color.hikingDarkGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(recommendation.score), height: 8)
                }
            }
            .frame(height: 8)
            
            // Recommendation reasons
            VStack(alignment: .leading, spacing: 6) {
                ForEach(recommendation.reasons.prefix(3), id: \.self) { reason in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.hikingGreen)
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(Color.hikingBrown)
                    }
                }
            }
            
            // Basic trail information
            HStack(spacing: 16) {
                Label("\(recommendation.trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) \(languageManager.localizedString(for: "unit.km"))", systemImage: "ruler")
                    .foregroundStyle(Color.hikingStone)
                Label("\(recommendation.trail.estimatedDurationMinutes / 60)\(languageManager.localizedString(for: "unit.h"))", systemImage: "clock")
                    .foregroundStyle(Color.hikingStone)
                Label(recommendation.trail.difficulty.localizedRawValue(languageManager: languageManager), systemImage: recommendation.trail.difficulty.icon)
                    .foregroundStyle(difficultyColor(for: recommendation.trail.difficulty))
            }
            .font(.caption)
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    isShowingDetail = true
                    onAction(.viewed)
                } label: {
                    Text(languageManager.localizedString(for: "recommendations.view.details"))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.hikingGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.hikingGreen)
                }
                
                Button {
                    // Record the action
                    onAction(.planned)
                    // Open planner with the recommended trail pre-selected
                    isShowingPlanner = true
                } label: {
                    Image(systemName: "calendar.badge.plus")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.hikingSky.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.hikingSky)
                }
            }
        }
        .padding()
        .background(difficultyBackgroundColor(for: recommendation.trail.difficulty), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(difficultyAccentColor(for: recommendation.trail.difficulty).opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .sheet(isPresented: $isShowingDetail) {
            NavigationStack {
                TrailDetailView(trail: recommendation.trail)
            }
        }
        .sheet(isPresented: $isShowingPlanner) {
            NavigationStack {
                PlannerViewWithTrail(trail: recommendation.trail)
                    .environmentObject(appViewModel)
                    .environmentObject(languageManager)
                    .environmentObject(sessionManager)
            }
        }
    }
    
    /// Returns the background color for the trail difficulty, matching TrailListView
    private func difficultyBackgroundColor(for difficulty: Trail.Difficulty) -> Color {
        switch difficulty {
        case .easy:
            return Color.hikingDifficultyEasyBackground
        case .moderate:
            return Color.hikingDifficultyModerateBackground
        case .challenging:
            return Color.hikingDifficultyChallengingBackground
        }
    }
    
    /// Returns the accent color for the trail difficulty, matching TrailListView
    private func difficultyAccentColor(for difficulty: Trail.Difficulty) -> Color {
        switch difficulty {
        case .easy:
            return Color.hikingGreen
        case .moderate:
            return Color.orange
        case .challenging:
            return Color.red
        }
    }
    
    /// Returns the accent color for the trail difficulty (for text), matching TrailListView
    private func difficultyColor(for difficulty: Trail.Difficulty) -> Color {
        return difficultyAccentColor(for: difficulty)
    }
}

struct PreferenceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @Bindable var preference: UserPreference
    let onSave: (UserPreference) -> Void
    
    @State private var minDistance: Double
    @State private var maxDistance: Double
    
    init(preference: UserPreference, onSave: @escaping (UserPreference) -> Void) {
        self.preference = preference
        self.onSave = onSave
        _minDistance = State(initialValue: preference.preferredDistance?.minKm ?? 0)
        _maxDistance = State(initialValue: preference.preferredDistance?.maxKm ?? 20)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(languageManager.localizedString(for: "preferences.fitness.level")) {
                    Picker(languageManager.localizedString(for: "preferences.fitness.level"), selection: $preference.fitnessLevel) {
                        ForEach(UserPreference.FitnessLevel.allCases, id: \.self) { level in
                            Text(level.localizedRawValue(languageManager: languageManager)).tag(level)
                        }
                    }
                }
                
                Section(languageManager.localizedString(for: "preferences.scenery")) {
                    ForEach(UserPreference.SceneryType.allCases, id: \.self) { scenery in
                        Toggle(isOn: Binding(
                            get: { preference.preferredScenery.contains(scenery) },
                            set: { isOn in
                                if isOn {
                                    if !preference.preferredScenery.contains(scenery) {
                                        preference.preferredScenery.append(scenery)
                                    }
                                } else {
                                    preference.preferredScenery.removeAll { $0 == scenery }
                                }
                            }
                        )) {
                            Label(scenery.localizedRawValue(languageManager: languageManager), systemImage: scenery.icon)
                        }
                    }
                }
                
                Section(languageManager.localizedString(for: "preferences.difficulty")) {
                    Picker(languageManager.localizedString(for: "preferences.difficulty"), selection: Binding(
                        get: { preference.preferredDifficulty },
                        set: { newValue in
                            preference.preferredDifficulty = newValue
                        }
                    )) {
                        Text(languageManager.localizedString(for: "preferences.no.preference")).tag(Trail.Difficulty?.none)
                        ForEach(Trail.Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.localizedRawValue(languageManager: languageManager)).tag(Trail.Difficulty?.some(difficulty))
                        }
                    }
                }
                
                Section(languageManager.localizedString(for: "preferences.distance")) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("\(languageManager.localizedString(for: "preferences.min")): \(Int(minDistance)) km")
                            Spacer()
                            Text("\(languageManager.localizedString(for: "preferences.max")): \(Int(maxDistance)) km")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(languageManager.localizedString(for: "preferences.min"))
                                .font(.subheadline)
                            Slider(value: $minDistance, in: 0...maxDistance, step: 0.5)
                                .tint(Color.hikingGreen)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(languageManager.localizedString(for: "preferences.max"))
                                .font(.subheadline)
                            Slider(value: $maxDistance, in: minDistance...50, step: 0.5)
                                .tint(Color.hikingGreen)
                        }
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "preferences.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "save")) {
                        // Update distance range before saving
                        preference.preferredDistance = UserPreference.DistanceRange(
                            minKm: minDistance,
                            maxKm: maxDistance
                        )
                        onSave(preference)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TrailRecommendationView(appViewModel: AppViewModel())
        .modelContainer(for: [UserPreference.self, RecommendationRecord.self], inMemory: true)
        .environmentObject(LanguageManager.shared)
}

