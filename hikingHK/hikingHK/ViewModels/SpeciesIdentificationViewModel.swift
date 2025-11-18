//
//  SpeciesIdentificationViewModel.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import UIKit
import CoreLocation
import Combine

@MainActor
final class SpeciesIdentificationViewModel: ObservableObject {
    @Published var isIdentifying: Bool = false
    @Published var identificationResult: SpeciesIdentificationResult?
    @Published var identificationHistory: [SpeciesIdentificationRecord] = []
    @Published var error: String?
    @Published var capturedImage: UIImage?
    
    private var store: SpeciesIdentificationStore?
    private var modelContext: ModelContext?
    private let identificationService: SpeciesIdentificationServiceProtocol
    private let locationManager: LocationManager
    
    init(
        locationManager: LocationManager,
        identificationService: SpeciesIdentificationServiceProtocol = SpeciesIdentificationService()
    ) {
        self.locationManager = locationManager
        self.identificationService = identificationService
    }
    
    func configureIfNeeded(context: ModelContext) {
        guard store == nil else { return }
        self.modelContext = context
        store = SpeciesIdentificationStore(context: context)
        
        // 載入識別歷史
        loadHistory()
    }
    
    func identifySpecies(from image: UIImage) async {
        guard !isIdentifying else { return }
        
        isIdentifying = true
        error = nil
        identificationResult = nil
        capturedImage = image
        
        // 獲取當前位置
        let location = locationManager.currentLocation?.coordinate
        
        do {
            let result = try await identificationService.identifySpecies(from: image, location: location)
            identificationResult = result
            
            // 保存識別記錄
            if let species = result.species {
                await saveIdentification(species: species, confidence: result.confidence, image: image, location: location)
            }
        } catch let identificationError {
            self.error = "Identification failed: \(identificationError.localizedDescription)"
            identificationResult = SpeciesIdentificationResult(
                species: nil,
                confidence: 0,
                error: identificationError.localizedDescription
            )
        }
        
        isIdentifying = false
    }
    
    private func saveIdentification(
        species: Species,
        confidence: Double,
        image: UIImage,
        location: CLLocationCoordinate2D?
    ) async {
        guard let store = store else { return }
        
        // 壓縮圖片數據
        let imageData = image.jpegData(compressionQuality: 0.7)
        
        let record = SpeciesIdentificationRecord(
            speciesId: species.id,
            speciesName: species.name,
            scientificName: species.scientificName,
            category: species.category.rawValue,
            confidence: confidence,
            locationLatitude: location?.latitude,
            locationLongitude: location?.longitude,
            imageData: imageData
        )
        
        do {
            try store.saveIdentification(record)
            loadHistory()
        } catch {
            self.error = "Failed to save identification record: \(error.localizedDescription)"
        }
    }
    
    func loadHistory() {
        guard let store = store else { return }
        do {
            identificationHistory = try store.loadAllIdentifications()
        } catch {
            self.error = "Failed to load identification history: \(error.localizedDescription)"
        }
    }
    
    func deleteIdentification(_ record: SpeciesIdentificationRecord) {
        guard let store = store else { return }
        do {
            try store.deleteIdentification(record)
            loadHistory()
        } catch {
            self.error = "Failed to delete record: \(error.localizedDescription)"
        }
    }
}

