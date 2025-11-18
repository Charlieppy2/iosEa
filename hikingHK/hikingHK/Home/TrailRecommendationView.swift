//
//  TrailRecommendationView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData

struct TrailRecommendationView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var viewModel: TrailRecommendationViewModel
    @State private var isShowingPreferenceSettings = false
    @State private var availableHours: Double = 4.0
    
    init(appViewModel: AppViewModel) {
        _viewModel = StateObject(wrappedValue: TrailRecommendationViewModel(appViewModel: appViewModel))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 推薦設置卡片
                    recommendationSettingsCard
                    
                    // 推薦結果
                    if viewModel.isLoading {
                        ProgressView("正在生成推薦...")
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
            .navigationTitle("Trail Recommendations")
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
                        isShowingPreferenceSettings = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.gearshape")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
            }
            .sheet(isPresented: $isShowingPreferenceSettings) {
                PreferenceSettingsView(preference: viewModel.userPreference ?? UserPreference()) { preference in
                    viewModel.updateUserPreference(preference)
                    Task {
                        await viewModel.generateRecommendations(availableTime: availableHours * 3600)
                    }
                }
            }
            .onAppear {
                viewModel.configureIfNeeded(context: modelContext)
                Task {
                    await viewModel.generateRecommendations(availableTime: availableHours * 3600)
                }
            }
        }
    }
    
    private var recommendationSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendation Settings")
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Time: \(Int(availableHours)) hours")
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingBrown)
                
                Slider(value: $availableHours, in: 1...8, step: 0.5) { editing in
                    if !editing {
                        Task {
                            await viewModel.generateRecommendations(availableTime: availableHours * 3600)
                        }
                    }
                }
                .tint(Color.hikingGreen)
            }
            
            Button {
                Task {
                    await viewModel.generateRecommendations(availableTime: availableHours * 3600)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Regenerate Recommendations")
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
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(Color.hikingGreen)
            Text("No Recommendations")
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            Text("Please adjust your preferences or available time")
                .font(.subheadline)
                .foregroundStyle(Color.hikingBrown)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var recommendationsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended for You")
                .font(.headline)
                .foregroundStyle(Color.hikingDarkGreen)
            
            ForEach(viewModel.recommendations.prefix(10)) { recommendation in
                RecommendationCard(recommendation: recommendation) { action in
                    viewModel.recordUserAction(for: recommendation, action: action)
                }
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: TrailRecommendation
    let onAction: (RecommendationRecord.UserAction) -> Void
    @State private var isShowingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題和匹配度
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.trail.name)
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    Text(recommendation.trail.district)
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(recommendation.matchPercentage)%")
                        .font(.title2.bold())
                        .foregroundStyle(Color.hikingGreen)
                    Text("Match")
                        .font(.caption)
                        .foregroundStyle(Color.hikingStone)
                }
            }
            
            // 進度條
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
            
            // 推薦理由
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
            
            // 路線信息
            HStack(spacing: 16) {
                Label("\(recommendation.trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km", systemImage: "ruler")
                Label("\(recommendation.trail.estimatedDurationMinutes / 60)h", systemImage: "clock")
                Label(recommendation.trail.difficulty.rawValue, systemImage: recommendation.trail.difficulty.icon)
            }
            .font(.caption)
            .foregroundStyle(Color.hikingStone)
            
            // 操作按鈕
            HStack(spacing: 12) {
                Button {
                    isShowingDetail = true
                    onAction(.viewed)
                } label: {
                    Text("View Details")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.hikingGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.hikingGreen)
                }
                
                Button {
                    onAction(.planned)
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
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
        .sheet(isPresented: $isShowingDetail) {
            NavigationStack {
                TrailDetailView(trail: recommendation.trail)
            }
        }
    }
}

struct PreferenceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State var preference: UserPreference
    let onSave: (UserPreference) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("體能水平") {
                    Picker("體能水平", selection: $preference.fitnessLevel) {
                        ForEach(UserPreference.FitnessLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }
                
                Section("偏好風景") {
                    ForEach(UserPreference.SceneryType.allCases, id: \.self) { scenery in
                        Toggle(isOn: Binding(
                            get: { preference.preferredScenery.contains(scenery) },
                            set: { isOn in
                                if isOn {
                                    preference.preferredScenery.append(scenery)
                                } else {
                                    preference.preferredScenery.removeAll { $0 == scenery }
                                }
                            }
                        )) {
                            Label(scenery.rawValue, systemImage: scenery.icon)
                        }
                    }
                }
                
                Section("Preferred Difficulty") {
                    Picker("Difficulty", selection: $preference.preferredDifficulty) {
                        Text("No Preference").tag(Trail.Difficulty?.none)
                        ForEach(Trail.Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(Trail.Difficulty?.some(difficulty))
                        }
                    }
                }
                
                Section("Preferred Distance") {
                    VStack {
                        HStack {
                            Text("Min: \(Int(preference.preferredDistance?.minKm ?? 0)) km")
                            Spacer()
                            Text("Max: \(Int(preference.preferredDistance?.maxKm ?? 20)) km")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        // 簡化版：使用滑塊設置距離範圍
                        // 實際應用中可以更精細地設置
                    }
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
}

