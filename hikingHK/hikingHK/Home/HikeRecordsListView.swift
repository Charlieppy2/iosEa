//
//  HikeRecordsListView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData

struct HikeRecordsListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var viewModel: AppViewModel
    @Query(sort: \HikeRecord.startTime, order: .reverse) private var records: [HikeRecord]
    @State private var selectedRecord: HikeRecord?
    @State private var isShowingHikeTracking = false
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    Section {
                        VStack(spacing: 20) {
                            Image(systemName: "figure.hiking")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.hikingGreen.opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text(languageManager.localizedString(for: "hike.records.none"))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(languageManager.localizedString(for: "hike.records.start.tracking"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Feature descriptions
                            VStack(alignment: .leading, spacing: 12) {
                                FeatureRow(
                                    icon: "list.bullet",
                                    title: languageManager.localizedString(for: "hike.records.feature.list"),
                                    description: languageManager.localizedString(for: "hike.records.feature.list.desc")
                                )
                                FeatureRow(
                                    icon: "info.circle",
                                    title: languageManager.localizedString(for: "hike.records.feature.detail"),
                                    description: languageManager.localizedString(for: "hike.records.feature.detail.desc")
                                )
                                FeatureRow(
                                    icon: "play.circle.fill",
                                    title: languageManager.localizedString(for: "hike.records.feature.playback"),
                                    description: languageManager.localizedString(for: "hike.records.feature.playback.desc")
                                )
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                            
                            // Start tracking button
                            Button {
                                isShowingHikeTracking = true
                            } label: {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text(languageManager.localizedString(for: "hike.tracking.start"))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.hikingGreen, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                } else {
                    ForEach(records) { record in
                        NavigationLink {
                            HikeRecordDetailView(record: record)
                                .environmentObject(viewModel)
                        } label: {
                            HikeRecordRow(record: record)
                                .environmentObject(viewModel)
                        }
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "home.hike.records"))
            .background(
                ZStack {
                    Color.hikingBackgroundGradient
                    HikingPatternBackground()
                        .opacity(0.15)
                }
                .ignoresSafeArea()
            )
            .sheet(isPresented: $isShowingHikeTracking) {
                HikeTrackingView(locationManager: locationManager)
                    .environmentObject(languageManager)
                    .presentationDetents([.large])
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.hikingGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct HikeRecordRow: View {
    let record: HikeRecord
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var viewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedTrailName)
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                }
                Spacer()
                if record.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.hikingGreen)
                }
            }
            
            HStack(spacing: 16) {
                Label(String(format: "%.2f km", record.distanceKm), systemImage: "ruler")
                    .font(.caption)
                    .foregroundStyle(Color.hikingStone)
                Label(record.formattedDuration, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(Color.hikingStone)
                Label(String(format: "%.1f km/h", record.averageSpeedKmh), systemImage: "speedometer")
                    .font(.caption)
                    .foregroundStyle(Color.hikingStone)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var localizedTrailName: String {
        // 如果有 trailId，嘗試從 viewModel 獲取本地化的路線名稱
        if let trailId = record.trailId,
           let trail = viewModel.trails.first(where: { $0.id == trailId }) {
            return trail.localizedName(languageManager: languageManager)
        }
        // 否則使用保存的路線名稱或默認文本
        return record.trailName ?? languageManager.localizedString(for: "hike.records.unnamed.trail")
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: record.startTime)
    }
}

#Preview {
    HikeRecordsListView()
        .modelContainer(for: [HikeRecord.self, HikeTrackPoint.self], inMemory: true)
        .environmentObject(LanguageManager.shared)
}

