//
//  WeatherWarningHistoryView.swift
//  hikingHK
//
//  Created for weather warning history display
//

import SwiftUI

struct WeatherWarningHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    private let historyService = WeatherWarningHistoryService.shared
    @State private var history: [WeatherWarningHistory] = []
    @State private var selectedFilter: FilterType = .all
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case cancelled = "Cancelled"
        
        var localizedName: String {
            switch self {
            case .all:
                return "alert.history.filter.all"
            case .active:
                return "alert.history.filter.active"
            case .cancelled:
                return "alert.history.filter.cancelled"
            }
        }
    }
    
    var filteredHistory: [WeatherWarningHistory] {
        switch selectedFilter {
        case .all:
            return history
        case .active:
            return history.filter { $0.cancelledAt == nil }
        case .cancelled:
            return history.filter { $0.cancelledAt != nil }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    ContentUnavailableView(
                        languageManager.localizedString(for: "alert.history.empty"),
                        systemImage: "clock.badge.questionmark",
                        description: Text(languageManager.localizedString(for: "alert.history.description"))
                    )
                } else {
                    VStack(spacing: 0) {
                        // Filter Picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(FilterType.allCases, id: \.self) { filter in
                                Text(languageManager.localizedString(for: filter.localizedName)).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        // History List
                        List {
                            ForEach(filteredHistory) { warning in
                                historyRow(warning: warning)
                            }
                        }
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "alert.history.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "done")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHistory()
            }
        }
    }
    
    private func loadHistory() {
        history = historyService.loadHistory()
    }
    
    private func historyRow(warning: WeatherWarningHistory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(warning.cancelledAt == nil ? .orange : .gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(warning.name)
                            .font(.headline)
                        Spacer()
                        if warning.cancelledAt != nil {
                            Text(languageManager.localizedString(for: "alert.cancelled"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2), in: Capsule())
                        }
                    }
                    
                    Text("\(warning.name) (\(warning.code))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(formatDate(warning.issueTime))
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        
                        if let updateTime = warning.updateTime {
                            Text("•")
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption2)
                                Text(formatDate(updateTime))
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        if let cancelledAt = warning.cancelledAt {
                            Text("•")
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                Text(formatDate(cancelledAt))
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .english ? "en_US" : "zh_Hant_HK")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

