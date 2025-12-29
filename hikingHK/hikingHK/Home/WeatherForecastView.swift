//
//  WeatherForecastView.swift
//  hikingHK
//
//  Created for weather forecast functionality
//

import SwiftUI

struct WeatherForecastView: View {
    @StateObject private var viewModel = WeatherForecastViewModel()
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTrail: Trail?
    @State private var isShowingLocationSearch = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let trail = selectedTrail ?? defaultTrail {
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
                        }
                        .padding(.horizontal)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if let forecast = viewModel.forecast {
                        // Best Hiking Times Section
                        if !forecast.bestHikingDays.isEmpty {
                            bestHikingTimesSection(forecast.bestHikingDays)
                        }
                        
                        // 7-Day Forecast
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingLocationSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            if let trail = selectedTrail ?? defaultTrail {
                                await viewModel.loadForecast(for: trail)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.hikingGreen)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                // 初次加载时优先使用「即將計劃」中的第一條路線
                if selectedTrail == nil {
                    selectedTrail = upcomingTrails.first ?? defaultTrail
                }
                if let trail = selectedTrail {
                    await viewModel.loadForecast(for: trail)
                }
            }
            .onChange(of: selectedTrail) { _, newValue in
                guard let trail = newValue else { return }
                Task { await viewModel.loadForecast(for: trail) }
            }
            .sheet(isPresented: $isShowingLocationSearch) {
                WeatherLocationSearchView { trail in
                    selectedTrail = trail
                }
                .environmentObject(appViewModel)
                .environmentObject(languageManager)
            }
        }
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
    
    private func forecastSection(_ forecasts: [DailyForecast]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.hikingGreen)
                Text(languageManager.localizedString(for: "weather.forecast.9day"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            
            ForEach(forecasts) { forecast in
                dailyForecastCard(forecast)
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
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
                    if let trail = selectedTrail ?? defaultTrail {
                        await viewModel.loadForecast(for: trail)
                    }
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

