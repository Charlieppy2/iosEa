//
//  HikeJournal.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation

/// SwiftData model for a hiking journal entry, including trail, weather and sharing metadata.
@Model
final class HikeJournal {
    var id: UUID
    var title: String
    var content: String
    var hikeDate: Date
    var createdAt: Date
    var updatedAt: Date
    
    // Linked trail information
    var trailId: UUID?
    var trailName: String?
    
    // Weather information
    var weatherCondition: String?
    var temperature: Double?
    var humidity: Double?
    
    // Location information
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationName: String?
    
    // Linked hike tracking record
    var hikeRecordId: UUID?
    
    // Photos associated with this journal entry
    @Relationship(deleteRule: .cascade)
    var photos: [JournalPhoto] = []
    
    // Sharing settings
    var isShared: Bool
    var shareToken: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        hikeDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        trailId: UUID? = nil,
        trailName: String? = nil,
        weatherCondition: String? = nil,
        temperature: Double? = nil,
        humidity: Double? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        locationName: String? = nil,
        hikeRecordId: UUID? = nil,
        isShared: Bool = false,
        shareToken: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.hikeDate = hikeDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.trailId = trailId
        self.trailName = trailName
        self.weatherCondition = weatherCondition
        self.temperature = temperature
        self.humidity = humidity
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.locationName = locationName
        self.hikeRecordId = hikeRecordId
        self.isShared = isShared
        self.shareToken = shareToken
    }
    
    var location: CLLocationCoordinate2D? {
        get {
            guard let lat = locationLatitude, let lon = locationLongitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        set {
            locationLatitude = newValue?.latitude
            locationLongitude = newValue?.longitude
        }
    }
    
    func updateShareToken() {
        if isShared && shareToken == nil {
            shareToken = UUID().uuidString
        } else if !isShared {
            shareToken = nil
        }
    }
}

/// Photo associated with a `HikeJournal`, stored as SwiftData for ordering and captions.
@Model
final class JournalPhoto {
    var id: UUID
    var imageData: Data
    var caption: String?
    var takenAt: Date
    var order: Int
    
    @Relationship(inverse: \HikeJournal.photos)
    var journal: HikeJournal?
    
    init(
        id: UUID = UUID(),
        imageData: Data,
        caption: String? = nil,
        takenAt: Date = Date(),
        order: Int = 0
    ) {
        self.id = id
        self.imageData = imageData
        self.caption = caption
        self.takenAt = takenAt
        self.order = order
    }
}

