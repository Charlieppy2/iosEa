//
//  WeatherForecastView.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import SwiftUI

struct WeatherForecastView: View {
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
                        // 9-Day Forecast only
                        forecastSection(forecast.dailyForecasts)
                    } else if let error = viewModel.error {
                        errorView(error)
                    }
                }
                .padding()
            }
            .navigationTitle(languageManager.localizedString(for: "weather.forecast.title"))
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
    
    private func forecastSection(_ forecasts: [DailyForecast]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.hikingGreen)
                Text(languageManager.localizedString(for: "weather.forecast.9day"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            
            // Color legend
            colorLegend
            
            ForEach(forecasts) { forecast in
                dailyForecastCard(forecast)
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private var colorLegend: some View {
        HStack(spacing: 16) {
            // Good for hiking indicator
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.hikingGreen.opacity(0.1))
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.hikingGreen.opacity(0.3), lineWidth: 1)
                    )
                Text(languageManager.localizedString(for: "weather.forecast.good.for.hiking"))
                    .font(.caption)
                    .foregroundStyle(Color.hikingBrown)
            }
            
            // Other days indicator
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 20, height: 20)
                Text(languageManager.localizedString(for: "weather.forecast.other.days"))
                    .font(.caption)
                    .foregroundStyle(Color.hikingBrown)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func dailyForecastCard(_ forecast: DailyForecast) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate(forecast.date))
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    if forecast.date < Date().addingTimeInterval(86400) {
                        Text(languageManager.localizedString(for: "weather.forecast.today"))
                            .font(.caption)
                            .foregroundStyle(Color.hikingBrown)
                    }
                }
                
                Spacer()
                
                Image(systemName: forecast.condition.icon)
                    .font(.title2)
                    .foregroundStyle(Color.hikingGreen)
            }
            
            HStack(spacing: 16) {
                // Temperature
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(Int(forecast.highTemperature))°")
                            .font(.title3.bold())
                            .foregroundStyle(Color.hikingDarkGreen)
                        Text("/ \(Int(forecast.lowTemperature))°")
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingStone)
                    }
                    Text(languageManager.localizedString(for: "weather.temperature"))
                        .font(.caption2)
                        .foregroundStyle(Color.hikingStone)
                }
                
                Spacer()
                
                // Comfort Index
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(Int(forecast.comfortIndex))")
                            .font(.title3.bold())
                            .foregroundStyle(comfortIndexColor(forecast.comfortIndex))
                        Text("/100")
                            .font(.caption)
                            .foregroundStyle(Color.hikingStone)
                    }
                    Text(languageManager.localizedString(for: "weather.forecast.comfort.index"))
                        .font(.caption2)
                        .foregroundStyle(Color.hikingStone)
                }
            }
            
            // Weather details
            HStack(spacing: 16) {
                detailItem(
                    icon: "humidity",
                    value: "\(forecast.humidity)%",
                    label: languageManager.localizedString(for: "weather.humidity")
                )
                detailItem(
                    icon: "sun.max",
                    value: "\(forecast.uvIndex)",
                    label: languageManager.localizedString(for: "weather.uv.index")
                )
                detailItem(
                    icon: "cloud.rain",
                    value: "\(forecast.precipitationChance)%",
                    label: languageManager.localizedString(for: "weather.forecast.precipitation")
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(forecast.isGoodForHiking ? Color.hikingGreen.opacity(0.1) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(forecast.isGoodForHiking ? Color.hikingGreen.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func detailItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.hikingBrown)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(Color.hikingDarkGreen)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.hikingStone)
        }
        .frame(maxWidth: .infinity)
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
    
    // Localized date formatting for forecast labels
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    WeatherForecastView()
        .environmentObject(AppViewModel())
        .environmentObject(LanguageManager.shared)
}

