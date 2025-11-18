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
            .onAppear {
                viewModel.configureIfNeeded(context: modelContext)
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
            // 月份標題
            HStack {
                Text(month)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // 日記條目
            ForEach(journals) { journal in
                JournalRow(journal: journal) {
                    selectedJournal = journal
                }
            }
        }
    }
}

struct JournalRow: View {
    let journal: HikeJournal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // 時間軸線
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
                
                // 內容
                VStack(alignment: .leading, spacing: 8) {
                    // 標題和日期
                    HStack {
                        Text(journal.title)
                            .font(.headline)
                            .foregroundStyle(Color.hikingDarkGreen)
                        Spacer()
                        Text(journal.hikeDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(Color.hikingStone)
                    }
                    
                    // 路線名稱
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
                    
                    // 內容預覽
                    Text(journal.content)
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                        .lineLimit(3)
                    
                    // 照片預覽
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
                    
                    // 天氣信息
                    if let weather = journal.weatherCondition {
                        HStack(spacing: 4) {
                            Image(systemName: "cloud.sun.fill")
                                .font(.caption)
                                .foregroundStyle(Color.hikingSky)
                            Text(weather)
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
}

#Preview {
    JournalListView()
        .modelContainer(for: [HikeJournal.self, JournalPhoto.self], inMemory: true)
}

