//
//  BestHikingTimeView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI

struct BestHikingTimeView: View {
    @StateObject private var viewModel = WeatherForecastViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTrail: Trail?
    @State private var isShowingTrailSearch = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Trail selector
                    let currentTrail = selectedTrail ?? defaultTrail
                    
                    if let trail = currentTrail {
                        Button {
                            isShowingTrailSearch = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(Color.hikingGreen)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trail.localizedName(languageManager: languageManager))
                                        .font(.headline)
                                        .foregroundStyle(Color.hikingDarkGreen)
                                    Text(trail.localizedDistrict(languageManager: languageManager))
                                        .font(.caption)
                                        .foregroundStyle(Color.hikingBrown)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(Color.hikingDarkGreen)
                            }
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if let forecast = viewModel.forecast {
                        if !forecast.bestHikingDays.isEmpty {
                            bestHikingTimesSection(forecast.bestHikingDays)
                        } else {
                            emptyStateView
                        }
                    } else if let error = viewModel.error {
                        errorView(error)
                    }
                }
                .padding()
            }
            .navigationTitle(languageManager.localizedString(for: "weather.forecast.best.times"))
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
                        Task {
                            await loadForecastForCurrentTrail()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.hikingGreen)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                if selectedTrail == nil {
                    selectedTrail = upcomingTrails.first ?? defaultTrail
                }
                await loadForecastForCurrentTrail()
            }
            .onChange(of: selectedTrail) { _, newValue in
                guard let trail = newValue else { return }
                Task { await loadForecastForTrail(trail) }
            }
            .sheet(isPresented: $isShowingTrailSearch) {
                WeatherLocationSearchView { trail in
                    selectedTrail = trail
                }
                .environmentObject(appViewModel)
                .environmentObject(languageManager)
            }
        }
    }
    
    /// 根據當前選擇的路線加載天氣預報
    private func loadForecastForCurrentTrail() async {
        if let trail = selectedTrail ?? defaultTrail {
            await loadForecastForTrail(trail)
        }
    }
    
    /// 為指定路線加載天氣預報
    private func loadForecastForTrail(_ trail: Trail) async {
        await viewModel.loadForecast(for: trail)
    }
    
    /// 當前「即將計劃」的路線（按日期排序後去重）
    private var upcomingTrails: [Trail] {
        let hikes = appViewModel.savedHikes.sorted { $0.scheduledDate < $1.scheduledDate }
        var seen: Set<UUID> = []
        var result: [Trail] = []
        for hike in hikes {
            if !seen.contains(hike.trail.id) {
                seen.insert(hike.trail.id)
                result.append(hike.trail)
            }
        }
        return result
    }
    
    /// 沒有即將計劃時的預設路線（取第一條已有路線）
    private var defaultTrail: Trail? {
        appViewModel.trails.first
    }
    
    private func bestHikingTimesSection(_ bestTimes: [BestHikingTime]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.hikingGreen)
                    .font(.title3)
                Text(languageManager.localizedString(for: "weather.forecast.best.times"))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                ForEach(bestTimes) { bestTime in
                    bestTimeCard(bestTime)
                }
            }
        }
        .padding(20)
        .hikingCard()
    }
    
    private func bestTimeCard(_ bestTime: BestHikingTime) -> some View {
        HStack(spacing: 16) {
            // Date and time section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.hikingGreen)
                    Text(formattedDate(bestTime.date))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.hikingDarkGreen)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(Color.hikingBrown)
                    Text(bestTime.timeSlot.displayTime)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.hikingBrown)
                }
            }
            
            Spacer()
            
            // Comfort index section with progress indicator
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 6) {
                    Text("\(Int(bestTime.comfortIndex))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(comfortIndexColor(bestTime.comfortIndex))
                    Text("/100")
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingStone)
                }
                
                // Comfort index progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.hikingStone.opacity(0.2))
                        .frame(width: 80, height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(comfortIndexColor(bestTime.comfortIndex))
                        .frame(width: 80 * CGFloat(bestTime.comfortIndex / 100), height: 6)
                }
                
                Text(languageManager.localizedString(for: "weather.forecast.comfort.index"))
                    .font(.caption2)
                    .foregroundStyle(Color.hikingStone)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(comfortIndexColor(bestTime.comfortIndex).opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.largeTitle)
                .foregroundStyle(Color.hikingStone)
            Text(languageManager.localizedString(for: "weather.forecast.no.best.times"))
                .font(.body)
                .foregroundStyle(Color.hikingBrown)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .font(.body)
                .foregroundStyle(Color.hikingBrown)
                .multilineTextAlignment(.center)
            Button {
                Task {
                    await loadForecastForCurrentTrail()
                }
            } label: {
                Text(languageManager.localizedString(for: "retry"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.hikingGreen, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    private func comfortIndexColor(_ index: Double) -> Color {
        if index >= 80 {
            return Color.hikingGreen
        } else if index >= 70 {
            return Color.hikingSky
        } else if index >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Localized date formatting
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    BestHikingTimeView()
        .environmentObject(AppViewModel())
        .environmentObject(LanguageManager.shared)
}

