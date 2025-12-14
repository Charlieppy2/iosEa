//
//  CreateJournalView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation

struct CreateJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @ObservedObject var viewModel: JournalViewModel
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var hikeDate: Date = Date()
    @State private var selectedTrail: Trail?
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var isShowingTrailPicker = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(languageManager.localizedString(for: "journal.basic.information")) {
                    TextField(languageManager.localizedString(for: "journal.title.field"), text: $title)
                    DatePicker(languageManager.localizedString(for: "journal.hike.date"), selection: $hikeDate, displayedComponents: .date)
                }
                
                Section(languageManager.localizedString(for: "journal.trail")) {
                    if let trail = selectedTrail {
                        HStack {
                            Text(trail.localizedName(languageManager: languageManager))
                                .foregroundStyle(Color.hikingDarkGreen)
                            Spacer()
                            Button(languageManager.localizedString(for: "journal.change")) {
                                isShowingTrailPicker = true
                            }
                            .foregroundStyle(Color.hikingGreen)
                        }
                    } else {
                        Button(languageManager.localizedString(for: "journal.select.trail")) {
                            isShowingTrailPicker = true
                        }
                        .foregroundStyle(Color.hikingGreen)
                    }
                }
                
                Section(languageManager.localizedString(for: "journal.content")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                
                Section(languageManager.localizedString(for: "journal.photos")) {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Label(languageManager.localizedString(for: "journal.add.photos"), systemImage: "photo.on.rectangle")
                            .foregroundStyle(Color.hikingGreen)
                    }
                    .onChange(of: selectedPhotos) { _, newItems in
                        Task {
                            await loadPhotos(from: newItems)
                        }
                    }
                    
                    if !photoData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(photoData.enumerated()), id: \.offset) { index, data in
                                    if let uiImage = UIImage(data: data) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Button {
                                                photoData.remove(at: index)
                                                selectedPhotos.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white)
                                                    .background(Color.black.opacity(0.6), in: Circle())
                                            }
                                            .padding(4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "journal.new.entry"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(languageManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localizedString(for: "save")) {
                        saveJournal()
                    }
                    .disabled(title.isEmpty || content.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $isShowingTrailPicker) {
                TrailPickerView(selectedTrail: $selectedTrail)
            }
            .onAppear {
                viewModel.configureIfNeeded(context: modelContext)
            }
            .alert(languageManager.localizedString(for: "journal.save.error"), isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button(languageManager.localizedString(for: "ok")) {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        photoData.removeAll()
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photoData.append(data)
            }
        }
    }
    
    private func saveJournal() {
        isSaving = true
        
        // 獲取天氣信息（如果可用）
        let weatherCondition = appViewModel.weatherSnapshot.suggestion
        let temperature = appViewModel.weatherSnapshot.temperature
        let humidity = Double(appViewModel.weatherSnapshot.humidity)
        
        // 獲取位置信息（可以從 LocationManager 獲取，這裡暫時為 nil）
        let location: CLLocationCoordinate2D? = nil
        
        do {
            try viewModel.createJournal(
                title: title,
                content: content,
                hikeDate: hikeDate,
                trailId: selectedTrail?.id,
                trailName: selectedTrail?.name,
                weatherCondition: weatherCondition,
                temperature: temperature,
                humidity: humidity,
                location: location,
                locationName: selectedTrail?.district,
                photos: photoData
            )
            print("✅ CreateJournalView: Journal saved successfully")
            isSaving = false
            
            // 等待一小段时间确保数据已保存，然后关闭
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                dismiss()
            }
        } catch {
            // Handle error
            print("❌ CreateJournalView: Error saving journal: \(error)")
            viewModel.error = "Failed to save journal: \(error.localizedDescription)"
            isSaving = false
        }
    }
}

struct TrailPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Binding var selectedTrail: Trail?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(appViewModel.trails) { trail in
                    Button {
                        selectedTrail = trail
                        dismiss()
                    }                     label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trail.localizedName(languageManager: languageManager))
                                    .foregroundStyle(Color.hikingDarkGreen)
                                Text(trail.localizedDistrict(languageManager: languageManager))
                                    .font(.caption)
                                    .foregroundStyle(Color.hikingBrown)
                            }
                            Spacer()
                            if selectedTrail?.id == trail.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.hikingGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "journal.select.trail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localizedString(for: "done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateJournalView(viewModel: JournalViewModel())
        .environmentObject(AppViewModel())
        .modelContainer(for: [HikeJournal.self, JournalPhoto.self], inMemory: true)
}

