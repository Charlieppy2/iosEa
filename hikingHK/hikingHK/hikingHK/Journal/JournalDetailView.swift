//
//  JournalDetailView.swift
//  hikingHK
//
//  行山日記詳情（支援中英文、本地化天氣提示）
//

import SwiftUI
import SwiftData
import CoreLocation

struct JournalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
    let journal: HikeJournal
    @ObservedObject var viewModel: JournalViewModel
    
    @State private var isShowingEdit = false
    @State private var isShowingShareSheet = false
    @State private var isShowingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 標題和日期
                    VStack(alignment: .leading, spacing: 8) {
                        Text(journal.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.hikingDarkGreen)
                        
                        Text(journal.hikeDate, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingStone)
                    }
                    
                    // 路線信息
                    if let trailName = journal.trailName {
                        infoRow(
                            icon: "map.fill",
                            title: languageManager.localizedString(for: "journal.trail"),
                            value: trailName,
                            color: .hikingGreen
                        )
                    }
                    
                    // 位置信息
                    if let locationName = journal.locationName {
                        infoRow(
                            icon: "location.fill",
                            title: languageManager.localizedString(for: "journal.location"),
                            value: locationName,
                            color: .hikingSky
                        )
                    }
                    
                    // 天氣信息（本地化）
                    if let weather = journal.weatherCondition {
                        HStack {
                            Image(systemName: "cloud.sun.fill")
                                .foregroundStyle(Color.hikingSky)
                            Text(localizedWeatherSuggestion(weather))
                                .foregroundStyle(Color.hikingBrown)
                            if let temp = journal.temperature {
                                Text("• \(Int(temp))°C")
                                    .foregroundStyle(Color.hikingStone)
                            }
                        }
                        .font(.subheadline)
                    }
                    
                    Divider()
                    
                    // 內容
                    Text(journal.content)
                        .font(.body)
                        .foregroundStyle(Color.hikingDarkGreen)
                        .lineSpacing(4)
                    
                    // 照片
                    if !journal.photos.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(languageManager.localizedString(for: "journal.photos"))
                                .font(.headline)
                                .foregroundStyle(Color.hikingDarkGreen)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(journal.photos.sorted(by: { $0.order < $1.order })) { photo in
                                        if let uiImage = UIImage(data: photo.imageData) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 200, height: 200)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                
                                                if let caption = photo.caption, !caption.isEmpty {
                                                    Text(caption)
                                                        .font(.caption)
                                                        .foregroundStyle(Color.hikingBrown)
                                                        .lineLimit(2)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(languageManager.localizedString(for: "journal.detail"))
            .navigationBarTitleDisplayMode(.inline)
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
                    Button(languageManager.localizedString(for: "close")) {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        isShowingShareSheet = true
                    } label: {
                        Image(systemName: journal.isShared ? "square.and.arrow.up.fill" : "square.and.arrow.up")
                            .foregroundStyle(Color.hikingGreen)
                    }
                    
                    Menu {
                        Button {
                            isShowingEdit = true
                        } label: {
                            Label(languageManager.localizedString(for: "edit"), systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            Label(languageManager.localizedString(for: "delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
            }
            .sheet(isPresented: $isShowingEdit) {
                EditJournalView(journal: journal, viewModel: viewModel)
            }
            .confirmationDialog(
                languageManager.localizedString(for: "journal.delete.confirm"),
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(languageManager.localizedString(for: "delete"), role: .destructive) {
                    do {
                        try viewModel.deleteJournal(journal)
                        dismiss()
                    } catch {
                        // 可以根據需要加入錯誤提示
                    }
                }
                Button(languageManager.localizedString(for: "cancel"), role: .cancel) {}
            } message: {
                Text(languageManager.localizedString(for: "journal.delete.message"))
            }
            .sheet(isPresented: $isShowingShareSheet) {
                ShareSheet(items: [generateShareContent()])
            }
        }
    }
    
    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(title + ":")
                .font(.subheadline)
                .foregroundStyle(Color.hikingBrown)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.hikingDarkGreen)
        }
    }
    
    private func generateShareContent() -> String {
        var content = "\(journal.title)\n\n"
        content += "Date: \(journal.hikeDate.formatted(date: .abbreviated, time: .omitted))\n\n"
        
        if let trailName = journal.trailName {
            content += "Trail: \(trailName)\n"
        }
        
        if let weather = journal.weatherCondition {
            content += "Weather: \(localizedWeatherSuggestion(weather))\n"
        }
        
        content += "\n\(journal.content)\n\n"
        content += "Shared from Hiking HK"
        
        return content
    }
    
    /// 將英文 weather suggestion 轉成本地化文字（邏輯與首頁一致）
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let journal = HikeJournal(
        title: "Amazing Hike",
        content: "Today I had an amazing hike...",
        trailName: "Lion Rock"
    )
    return JournalDetailView(journal: journal, viewModel: JournalViewModel())
        .modelContainer(for: [HikeJournal.self, JournalPhoto.self], inMemory: true)
        .environmentObject(LanguageManager.shared)
}


