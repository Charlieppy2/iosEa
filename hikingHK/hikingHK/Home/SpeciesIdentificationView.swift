//
//  SpeciesIdentificationView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData
import UIKit
import PhotosUI

struct SpeciesIdentificationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel: SpeciesIdentificationViewModel
    @State private var isShowingCamera = false
    @State private var isShowingPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isShowingHistory = false
    
    init(locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: SpeciesIdentificationViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let image = viewModel.capturedImage {
                    // 顯示拍攝的照片
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                } else {
                    // 默認背景
                    Color.hikingBackgroundGradient
                        .ignoresSafeArea()
                }
                
                VStack {
                    Spacer()
                    
                    // 識別結果卡片
                    if let result = viewModel.identificationResult {
                        identificationResultCard(result)
                            .padding()
                            .transition(.move(edge: .bottom))
                    }
                    
                    // 控制按鈕
                    controlButtons
                        .padding()
                }
            }
            .navigationTitle(languageManager.localizedString(for: "species.identification.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(languageManager.localizedString(for: "close")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                CameraView { image in
                    Task {
                        await viewModel.identifySpecies(from: image)
                    }
                }
            }
            .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await viewModel.identifySpecies(from: image)
                    }
                }
            }
            .sheet(isPresented: $isShowingHistory) {
                SpeciesIdentificationHistoryView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.configureIfNeeded(context: modelContext)
            }
        }
    }
    
    private var controlButtons: some View {
        VStack(spacing: 16) {
            if viewModel.isIdentifying {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text(languageManager.localizedString(for: "species.identification.identifying"))
                        .foregroundStyle(.white)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.hikingGreen.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
            } else {
                HStack(spacing: 16) {
                    Button {
                        isShowingCamera = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.title)
                            Text(languageManager.localizedString(for: "species.identification.take.photo"))
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.hikingGreen, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                    }
                    
                    Button {
                        isShowingPhotoPicker = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title)
                            Text(languageManager.localizedString(for: "species.identification.photo.library"))
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.hikingSky, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                    }
                }
            }
        }
    }
    
    private func identificationResultCard(_ result: SpeciesIdentificationResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let species = result.species {
                // 物種信息
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(species.commonName)
                            .font(.title2.bold())
                            .foregroundStyle(Color.hikingDarkGreen)
                        Text(species.scientificName)
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown)
                            .italic()
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Label(species.category.rawValue, systemImage: species.category.icon)
                            .font(.caption)
                            .foregroundStyle(Color.hikingStone)
                        Text("\(Int(result.confidence * 100))%")
                            .font(.headline)
                            .foregroundStyle(Color.hikingGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.hikingGreen.opacity(0.1), in: Capsule())
                    }
                }
                
                Divider()
                
                // 保護狀態
                HStack {
                    Label(species.protectionStatus.rawValue, systemImage: species.protectionStatus.icon)
                        .font(.subheadline)
                        .foregroundStyle(protectionStatusColor(species.protectionStatus))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(protectionStatusColor(species.protectionStatus).opacity(0.1), in: Capsule())
                
                // 描述
                Text(species.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingBrown)
                
                // 棲息地
                if !species.habitat.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Habitat")
                            .font(.caption.bold())
                            .foregroundStyle(Color.hikingStone)
                        Text(species.habitat)
                            .font(.caption)
                            .foregroundStyle(Color.hikingBrown)
                    }
                }
                
                // Distribution
                if !species.distribution.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Distribution")
                            .font(.caption.bold())
                            .foregroundStyle(Color.hikingStone)
                        Text(species.distribution)
                            .font(.caption)
                            .foregroundStyle(Color.hikingBrown)
                    }
                }
                
                // 替代選項
                if !result.alternatives.isEmpty {
                    Divider()
                    Text("Other Possibilities")
                        .font(.caption.bold())
                        .foregroundStyle(Color.hikingStone)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(result.alternatives.prefix(3)) { alt in
                                AlternativeSpeciesCard(species: alt)
                            }
                        }
                    }
                }
            } else {
                // 識別失敗
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Unable to Identify")
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    if let error = result.error {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color.hikingBrown)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
    
    private func protectionStatusColor(_ status: Species.ProtectionStatus) -> Color {
        switch status {
        case .protected, .endangered: return .red
        case .vulnerable: return .orange
        case .common: return .green
        case .unknown: return .gray
        }
    }
}

struct AlternativeSpeciesCard: View {
    let species: Species
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(species.category.rawValue, systemImage: species.category.icon)
                .font(.caption2)
                .foregroundStyle(Color.hikingStone)
            Text(species.commonName)
                .font(.caption.bold())
                .foregroundStyle(Color.hikingDarkGreen)
            Text(species.scientificName)
                .font(.caption2)
                .foregroundStyle(Color.hikingBrown)
                .italic()
        }
        .padding(8)
        .frame(width: 120)
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        
        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct SpeciesIdentificationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SpeciesIdentificationViewModel
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.identificationHistory.isEmpty {
                    ContentUnavailableView(
                        "No Identification History",
                        systemImage: "camera.metering.unknown",
                        description: Text("Start identifying species to view history")
                    )
                } else {
                    ForEach(viewModel.identificationHistory) { record in
                        IdentificationHistoryRow(record: record) {
                            viewModel.deleteIdentification(record)
                        }
                    }
                }
            }
            .navigationTitle("Identification History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct IdentificationHistoryRow: View {
    let record: SpeciesIdentificationRecord
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 縮略圖
            if let imageData = record.imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.hikingStone.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(Color.hikingStone)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.speciesName)
                    .font(.headline)
                    .foregroundStyle(Color.hikingDarkGreen)
                Text(record.scientificName)
                    .font(.caption)
                    .foregroundStyle(Color.hikingBrown)
                    .italic()
                HStack {
                    Label(record.category, systemImage: "tag")
                        .font(.caption2)
                        .foregroundStyle(Color.hikingStone)
                    Spacer()
                    Text("\(record.confidencePercentage)%")
                        .font(.caption.bold())
                        .foregroundStyle(Color.hikingGreen)
                }
            }
            
            Spacer()
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SpeciesIdentificationView(locationManager: LocationManager())
        .modelContainer(for: [SpeciesIdentificationRecord.self], inMemory: true)
}

