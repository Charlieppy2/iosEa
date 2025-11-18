//
//  JournalDetailView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData
import CoreLocation

struct JournalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
                        infoRow(icon: "map.fill", title: "Trail", value: trailName, color: .hikingGreen)
                    }
                    
                    // 位置信息
                    if let locationName = journal.locationName {
                        infoRow(icon: "location.fill", title: "Location", value: locationName, color: .hikingSky)
                    }
                    
                    // 天氣信息
                    if let weather = journal.weatherCondition {
                        HStack {
                            Image(systemName: "cloud.sun.fill")
                                .foregroundStyle(Color.hikingSky)
                            Text(weather)
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
                            Text("Photos")
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
            .navigationTitle("Journal Entry")
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
                    Button("Close") {
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
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
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
            .confirmationDialog("Delete Journal Entry", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    do {
                        try viewModel.deleteJournal(journal)
                        dismiss()
                    } catch {
                        // Handle error
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
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
            content += "Weather: \(weather)\n"
        }
        
        content += "\n\(journal.content)\n\n"
        content += "Shared from Hiking HK"
        
        return content
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
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
}

