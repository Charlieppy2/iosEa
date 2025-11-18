//
//  EditJournalView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: JournalViewModel
    let journal: HikeJournal
    
    @State private var title: String
    @State private var content: String
    @State private var hikeDate: Date
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var isSaving = false
    
    init(journal: HikeJournal, viewModel: JournalViewModel) {
        self.journal = journal
        self.viewModel = viewModel
        _title = State(initialValue: journal.title)
        _content = State(initialValue: journal.content)
        _hikeDate = State(initialValue: journal.hikeDate)
        
        // 加載現有照片
        _photoData = State(initialValue: journal.photos.sorted(by: { $0.order < $1.order }).compactMap { $0.imageData })
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Title", text: $title)
                    DatePicker("Hike Date", selection: $hikeDate, displayedComponents: .date)
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                
                Section("Photos") {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Label("Add Photos", systemImage: "photo.on.rectangle")
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
                                                if index < selectedPhotos.count {
                                                    selectedPhotos.remove(at: index)
                                                }
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
            .navigationTitle("Edit Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveJournal()
                    }
                    .disabled(title.isEmpty || content.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photoData.append(data)
            }
        }
    }
    
    private func saveJournal() {
        isSaving = true
        
        do {
            try viewModel.updateJournal(
                journal,
                title: title,
                content: content,
                hikeDate: hikeDate,
                photos: photoData
            )
            dismiss()
        } catch {
            // Handle error
            print("Error updating journal: \(error)")
        }
        
        isSaving = false
    }
}

#Preview {
    let journal = HikeJournal(
        title: "Test",
        content: "Test content"
    )
    return EditJournalView(journal: journal, viewModel: JournalViewModel())
        .modelContainer(for: [HikeJournal.self, JournalPhoto.self], inMemory: true)
}

