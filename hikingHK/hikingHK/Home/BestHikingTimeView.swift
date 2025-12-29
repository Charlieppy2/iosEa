//
//  BestHikingTimeView.swift
//  hikingHK
//
//  Created for best hiking time recommendations
//

import SwiftUI

struct BestHikingTimeView: View {
    @StateObject private var viewModel = WeatherForecastViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLocationIndex: Int = 0
    @State private var isShowingLocationPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Location selector using weather API locations
                    let snapshots = appViewModel.weatherSnapshots.isEmpty ? [appViewModel.weatherSnapshot] : appViewModel.weatherSnapshots
                    let currentSnapshot = snapshots[selectedLocationIndex]
                    
                    Button {
                        isShowingLocationPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(Color.hikingGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localizedLocation(currentSnapshot.location))
                                    .font(.headline)
                                    .foregroundStyle(Color.hikingDarkGreen)
                                Text("\(String(format: "%.1f", currentSnapshot.temperature))°C • \(currentSnapshot.humidity)%")
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
                            await loadForecastForCurrentLocation()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.hikingGreen)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await loadForecastForCurrentLocation()
            }
            .onChange(of: selectedLocationIndex) { _, _ in
                Task { await loadForecastForCurrentLocation() }
            }
            .onChange(of: appViewModel.weatherSnapshots) { _, _ in
                Task { await loadForecastForCurrentLocation() }
            }
            .sheet(isPresented: $isShowingLocationPicker) {
                WeatherLocationPickerView(
                    snapshots: appViewModel.weatherSnapshots.isEmpty ? [appViewModel.weatherSnapshot] : appViewModel.weatherSnapshots,
                    selectedIndex: $selectedLocationIndex
                )
                .environmentObject(languageManager)
                .presentationDetents([.large])
            }
        }
    }
    
    /// 根據當前選擇的地區加載天氣預報
    private func loadForecastForCurrentLocation() async {
        let snapshots = appViewModel.weatherSnapshots.isEmpty ? [appViewModel.weatherSnapshot] : appViewModel.weatherSnapshots
        guard selectedLocationIndex < snapshots.count else { return }
        
        let selectedSnapshot = snapshots[selectedLocationIndex]
        let locationName = selectedSnapshot.location
        
        // 嘗試找到對應的路線（用於獲取座標等信息）
        // 如果找不到，使用默認路線
        let trail = findTrailForLocation(locationName) ?? appViewModel.trails.first
        
        if let trail = trail {
            await viewModel.loadForecast(for: trail)
        }
    }
    
    /// 根據地區名稱查找對應的路線
    private func findTrailForLocation(_ locationName: String) -> Trail? {
        // 嘗試根據地區名稱匹配路線
        // 例如："Sai Kung" -> 查找西貢的路線
        let locationKey = locationName.lowercased()
        
        // 簡單匹配邏輯：根據地區名稱關鍵字匹配
        for trail in appViewModel.trails {
            let district = trail.district.lowercased()
            if district.contains(locationKey) || locationKey.contains(district) {
                return trail
            }
        }
        
        // 如果找不到，返回 nil，使用默認路線
        return nil
    }
    
    /// 本地化地區名稱
    private func localizedLocation(_ location: String) -> String {
        // Prefer Hong Kong Observatory label
        if location == "Hong Kong Observatory" {
            return languageManager.localizedString(for: "weather.location.hko")
        }
        // Localize other known locations
        let locationKey = "weather.location.\(location.lowercased().replacingOccurrences(of: " ", with: ".").replacingOccurrences(of: "'", with: ""))"
        let localized = languageManager.localizedString(for: locationKey)
        return localized != locationKey ? localized : location
    }
    
    private func bestHikingTimesSection(_ bestTimes: [BestHikingTime]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.hikingGreen)
                Text(languageManager.localizedString(for: "weather.forecast.best.times"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            
            ForEach(bestTimes) { bestTime in
                bestTimeCard(bestTime)
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private func bestTimeCard(_ bestTime: BestHikingTime) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(bestTime.date))
                    .font(.headline)
                    .foregroundStyle(Color.hikingDarkGreen)
                Text(bestTime.timeSlot.displayTime)
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingBrown)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(Int(bestTime.comfortIndex))")
                        .font(.title2.bold())
                        .foregroundStyle(comfortIndexColor(bestTime.comfortIndex))
                    Text("/100")
                        .font(.caption)
                        .foregroundStyle(Color.hikingStone)
                }
                Text(languageManager.localizedString(for: "weather.forecast.comfort.index"))
                    .font(.caption2)
                    .foregroundStyle(Color.hikingStone)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
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
                    await loadForecastForCurrentLocation()
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

