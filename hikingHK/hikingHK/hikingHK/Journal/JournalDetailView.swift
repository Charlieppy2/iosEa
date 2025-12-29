//
//  JournalDetailView.swift
//  hikingHK
//
//  Hiking journal detail screen with localized weather hints and photos.
//

import SwiftUI
import SwiftData
import CoreLocation

/// Displays the detailed view of a hiking journal entry, including trail info, weather, content, and photos.
struct JournalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var appViewModel: AppViewModel
    
    let journal: HikeJournal
    @ObservedObject var viewModel: JournalViewModel
    
    @State private var isShowingEdit = false
    @State private var isShowingShareSheet = false
    @State private var isShowingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title and date
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizedTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.hikingDarkGreen)
                        
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingStone)
                    }
                    
                    // Trail information
                    if let trailName = localizedTrailName {
                        infoRow(
                            icon: "map.fill",
                            title: languageManager.localizedString(for: "journal.trail"),
                            value: trailName,
                            color: .hikingGreen
                        )
                    }
                    
                    // Location information
                    if let locationName = localizedLocationName {
                        infoRow(
                            icon: "location.fill",
                            title: languageManager.localizedString(for: "journal.location"),
                            value: locationName,
                            color: .hikingSky
                        )
                    }
                    
                    // Weather information (localized)
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
                    
                    // Main journal content
                    Text(journal.content)
                        .font(.body)
                        .foregroundStyle(Color.hikingDarkGreen)
                        .lineSpacing(4)
                    
                    // Attached photos section
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
                        // Optionally handle delete error (e.g. show an alert) if needed
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
    
    /// 本地化標題：將 "Day 1", "Day 2" 等轉換為本地化版本
    private var localizedTitle: String {
        let title = journal.title
        
        // 檢查是否是 "Day X" 格式
        if title.lowercased().hasPrefix("day ") {
            let dayNumber = title.replacingOccurrences(of: "day ", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            
            if let dayInt = Int(dayNumber) {
                if languageManager.currentLanguage == .traditionalChinese {
                    return "第 \(dayInt) 天"
                } else {
                    return "Day \(dayInt)"
                }
            }
        }
        
        // 如果不是 "Day X" 格式，返回原始標題
        return title
    }
    
    /// 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageManager.currentLanguage == .traditionalChinese ? "zh_Hant_HK" : "en_US")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: journal.hikeDate)
    }
    
    /// 獲取本地化的路線名稱
    private var localizedTrailName: String? {
        // 優先從 AppViewModel 中查找對應的 Trail 對象
        if let trailId = journal.trailId,
           let trail = appViewModel.trails.first(where: { $0.id == trailId }) {
            return trail.localizedName(languageManager: languageManager)
        }
        
        // 如果找不到 Trail 對象，嘗試從本地化字符串中獲取
        if let trailName = journal.trailName {
            if let trailId = journal.trailId {
                let trailNameKey = "trail.\(trailId.uuidString.lowercased()).name"
                let localizedName = languageManager.localizedString(for: trailNameKey)
                
                // 如果找到了本地化版本（不是原始 key），使用它
                if localizedName != trailNameKey {
                    return localizedName
                }
            }
            
            // 否則使用原始名稱
            return trailName
        }
        
        return nil
    }
    
    /// 獲取本地化的位置名稱
    private var localizedLocationName: String? {
        guard let locationName = journal.locationName else { return nil }
        
        // 嘗試從本地化字符串中獲取位置名稱
        // 常見位置名稱的本地化
        let locationKey = "trail.district.\(locationName.lowercased().replacingOccurrences(of: " ", with: "."))"
        let localizedName = languageManager.localizedString(for: locationKey)
        
        // 如果找到了本地化版本（不是原始 key），使用它
        if localizedName != locationKey {
            return localizedName
        }
        
        // 否則使用原始名稱
        return locationName
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
        var content = "\(localizedTitle)\n\n"
        content += "\(languageManager.localizedString(for: "journal.share.date")): \(formattedDate)\n\n"
        
        if let trailName = localizedTrailName {
            content += "\(languageManager.localizedString(for: "journal.share.trail")): \(trailName)\n"
        }
        
        if let weather = journal.weatherCondition {
            content += "\(languageManager.localizedString(for: "journal.share.weather")): \(localizedWeatherSuggestion(weather))\n"
        }
        
        content += "\n\(journal.content)\n\n"
        content += languageManager.localizedString(for: "journal.share.shared.from")
        
        return content
    }
    
    /// Convert the English weather suggestion into the current localized text (logic consistent with HomeView).
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


