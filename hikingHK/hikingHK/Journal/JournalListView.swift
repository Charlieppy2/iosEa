//
//  JournalListView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel: JournalViewModel
    @State private var isShowingCreateJournal = false
    @State private var selectedJournal: HikeJournal?
    
    init() {
        _viewModel = StateObject(wrappedValue: JournalViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.journals.isEmpty {
                    emptyStateView
                } else {
                    timelineView
                }
            }
            .navigationTitle(languageManager.localizedString(for: "journal.list.title"))
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
                        isShowingCreateJournal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
            }
            .task {
                // Configure the view model when the view first appears
                viewModel.configureIfNeeded(context: modelContext)
            }
            .onAppear {
                // On every appearance, ensure configuration and then refresh data
                print("🔄 JournalListView: View appeared")
                viewModel.configureIfNeeded(context: modelContext, skipRefresh: true)
                // Delay refresh slightly to give the JSON store time to sync
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    print("🔄 JournalListView: Refreshing journals on appear...")
                    viewModel.refreshJournals()
                }
            }
            .onChange(of: isShowingCreateJournal) { oldValue, newValue in
                // When the create journal sheet is dismissed, delay-refresh to ensure data is saved
                if oldValue == true && newValue == false {
                    print("🔄 JournalListView: Create journal sheet closed")
                    // Do not refresh immediately because createJournal already inserted into the array.
                    // The delayed refresh is only to catch up persistence sync, without overwriting manual changes.
                    Task { @MainActor in
                        // Wait longer so any underlying store has time to sync
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        print("🔄 JournalListView: Refreshing journals after delay...")
                        // Only refresh if the array is empty to avoid overwriting manual additions
                        if viewModel.journals.isEmpty {
                            print("🔄 JournalListView: Array is empty, refreshing from database...")
                            viewModel.refreshJournals()
                        } else {
                            print("🔄 JournalListView: Array has \(viewModel.journals.count) items, skipping refresh to preserve manual additions")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateJournal) {
                CreateJournalView(viewModel: viewModel)
            }
            .sheet(item: $selectedJournal) { journal in
                JournalDetailView(journal: journal, viewModel: viewModel)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.hikingStone)
            
            Text(languageManager.localizedString(for: "journal.no.entries"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.hikingDarkGreen)
            
            Text(languageManager.localizedString(for: "journal.start.documenting"))
                .font(.subheadline)
                .foregroundStyle(Color.hikingBrown)
                .multilineTextAlignment(.center)
            
            Button {
                isShowingCreateJournal = true
            } label: {
                Label(languageManager.localizedString(for: "journal.create.first.entry"), systemImage: "plus.circle.fill")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.hikingGreen, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 100)
    }
    
    private var timelineView: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(viewModel.sortedMonths, id: \.self) { month in
                monthSection(month: month, journals: viewModel.journalsByMonth[month] ?? [])
            }
        }
        .padding()
    }
    
    private func monthSection(month: String, journals: [HikeJournal]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month header
            HStack {
                Text(month)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Journal entries for this month
            ForEach(journals) { journal in
                JournalRow(journal: journal) {
                    selectedJournal = journal
                }
            }
        }
    }
}

struct JournalRow: View {
    @EnvironmentObject private var languageManager: LanguageManager
    let journal: HikeJournal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Vertical timeline line and dot
                VStack {
                    Circle()
                        .fill(Color.hikingGreen)
                        .frame(width: 12, height: 12)
                    Rectangle()
                        .fill(Color.hikingStone.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: 20)
                
                // Main card content
                VStack(alignment: .leading, spacing: 8) {
                    // Title and date
                    HStack {
                        Text(journal.title)
                            .font(.headline)
                            .foregroundStyle(Color.hikingDarkGreen)
                        Spacer()
                        Text(journal.hikeDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(Color.hikingStone)
                    }
                    
                    // Trail name (if any)
                    if let trailName = journal.trailName {
                        HStack(spacing: 4) {
                            Image(systemName: "map.fill")
                                .font(.caption)
                                .foregroundStyle(Color.hikingGreen)
                            Text(trailName)
                                .font(.subheadline)
                                .foregroundStyle(Color.hikingBrown)
                        }
                    }
                    
                    // Content preview
                    Text(journal.content)
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                        .lineLimit(3)
                    
                    // Photos preview (count)
                    if !journal.photos.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.fill")
                                .font(.caption)
                                .foregroundStyle(Color.hikingGreen)
                            Text("\(journal.photos.count) photo\(journal.photos.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(Color.hikingStone)
                        }
                    }
                    
                    // Weather information (localized)
                    if let weather = journal.weatherCondition {
                        HStack(spacing: 4) {
                            Image(systemName: "cloud.sun.fill")
                                .font(.caption)
                                .foregroundStyle(Color.hikingSky)
                            Text(localizedWeatherSuggestion(weather))
                                .font(.caption)
                                .foregroundStyle(Color.hikingStone)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
            .hikingCard()
        }
        .buttonStyle(.plain)
    }
    
    /// Convert the saved English weather suggestion into the current app language.
    private func localizedWeatherSuggestion(_ suggestion: String) -> String {
        if suggestion.contains("Weather warning in force") {
            return languageManager.localizedString(for: "weather.suggestion.warning")
        }
        if suggestion.contains("Extreme UV") {
            return languageManager.localizedString(for: "weather.suggestion.extreme.uv")
        }
        if suggestion.contains("Humid conditions") {
            return languageManager.localizedString(for: "weather.suggestion.humid")
        }
        if suggestion.contains("Conditions look stable") || suggestion.contains("great time to tackle") {
            return languageManager.localizedString(for: "weather.suggestion.stable")
        }
        if suggestion.contains("Partly cloudy") || suggestion.contains("Great time to start") {
            return languageManager.localizedString(for: "weather.suggestion.good")
        }
        return suggestion
    }
}

#Preview {
    JournalListView()
        .modelContainer(for: [HikeJournal.self, JournalPhoto.self], inMemory: true)
        .environmentObject(LanguageManager.shared)
}

