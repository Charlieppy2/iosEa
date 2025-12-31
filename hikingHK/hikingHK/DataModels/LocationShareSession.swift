//
//  LocationShareSession.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation

/// SwiftData model describing a live location-sharing session and its latest position.
@Model
final class LocationShareSession {
    var id: UUID
    var accountId: UUID // User account ID to associate this record with a specific user
    var isActive: Bool
    var startedAt: Date?
    var lastLocationUpdate: Date?
    var lastLocationLatitude: Double?
    var lastLocationLongitude: Double?
    var shareLink: String? // Optional shareable URL for this live session
    var expiresAt: Date?
    var emergencyContacts: [EmergencyContact]?
    
    init(
        id: UUID = UUID(),
        accountId: UUID,
        isActive: Bool = false,
        startedAt: Date? = nil,
        lastLocationUpdate: Date? = nil,
        lastLocationLatitude: Double? = nil,
        lastLocationLongitude: Double? = nil,
        shareLink: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.accountId = accountId
        self.isActive = isActive
        self.startedAt = startedAt
        self.lastLocationUpdate = lastLocationUpdate
        self.lastLocationLatitude = lastLocationLatitude
        self.lastLocationLongitude = lastLocationLongitude
        self.shareLink = shareLink
        self.expiresAt = expiresAt
    }
    
    var lastLocation: CLLocationCoordinate2D? {
        guard let lat = lastLocationLatitude, let lon = lastLocationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func updateLocation(_ location: CLLocation) {
        lastLocationLatitude = location.coordinate.latitude
        lastLocationLongitude = location.coordinate.longitude
        lastLocationUpdate = Date()
    }
}

