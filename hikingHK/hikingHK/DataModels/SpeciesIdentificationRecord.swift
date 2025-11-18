//
//  SpeciesIdentificationRecord.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class SpeciesIdentificationRecord {
    var id: UUID
    var speciesId: UUID?
    var speciesName: String
    var scientificName: String
    var category: String
    var confidence: Double // 識別置信度 0-1
    var identifiedAt: Date
    var locationLatitude: Double?
    var locationLongitude: Double?
    var imageData: Data? // 識別的照片數據
    
    init(
        id: UUID = UUID(),
        speciesId: UUID? = nil,
        speciesName: String,
        scientificName: String,
        category: String,
        confidence: Double,
        identifiedAt: Date = Date(),
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.speciesId = speciesId
        self.speciesName = speciesName
        self.scientificName = scientificName
        self.category = category
        self.confidence = confidence
        self.identifiedAt = identifiedAt
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.imageData = imageData
    }
    
    var location: CLLocationCoordinate2D? {
        guard let lat = locationLatitude, let lon = locationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}

