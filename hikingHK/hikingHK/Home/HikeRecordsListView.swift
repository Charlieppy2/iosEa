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
    @Query(sort: \HikeRecord.startTime, order: .reverse) private var records: [HikeRecord]
    @State private var selectedRecord: HikeRecord?
    
    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    ContentUnavailableView(
                        languageManager.localizedString(for: "hike.records.none"),
                        systemImage: "figure.hiking",
                        description: Text(languageManager.localizedString(for: "hike.records.start.tracking"))
                    )
                } else {
                    ForEach(records) { record in
                        NavigationLink {
                            HikeRecordDetailView(record: record)
                        } label: {
                            HikeRecordRow(record: record)
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
        }
    }
}

struct HikeRecordRow: View {
    let record: HikeRecord
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.trailName ?? languageManager.localizedString(for: "hike.records.unnamed.trail"))
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    Text(record.startTime, style: .date)
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
}

#Preview {
    HikeRecordsListView()
        .modelContainer(for: [HikeRecord.self, HikeTrackPoint.self], inMemory: true)
        .environmentObject(LanguageManager.shared)
}

