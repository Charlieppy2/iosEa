//
//  LocationShareSession.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class LocationShareSession {
    var id: UUID
    var isActive: Bool
    var startedAt: Date?
    var lastLocationUpdate: Date?
    var lastLocationLatitude: Double?
    var lastLocationLongitude: Double?
    var shareLink: String? // 分享鏈接（可選）
    var expiresAt: Date?
    var emergencyContacts: [EmergencyContact]?
    
    init(
        id: UUID = UUID(),
        isActive: Bool = false,
        startedAt: Date? = nil,
        lastLocationUpdate: Date? = nil,
        lastLocationLatitude: Double? = nil,
        lastLocationLongitude: Double? = nil,
        shareLink: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
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

