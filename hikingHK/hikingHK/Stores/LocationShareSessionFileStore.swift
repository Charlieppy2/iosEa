//
//  LocationShareSessionFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist location sharing sessions, avoiding SwiftData synchronization issues.
//  Uses the unified BaseFileStore architecture.
//

import Foundation
import CoreLocation

/// DTO for JSON persistence of a location sharing session.
struct PersistedLocationShareSession: FileStoreDTO {
    struct PersistedEmergencyContact: Codable {
        var id: UUID
        var name: String
        var phoneNumber: String
        var email: String?
        var isPrimary: Bool
        var createdAt: Date
    }
    
    var id: UUID
    var isActive: Bool
    var startedAt: Date?
    var lastLocationUpdate: Date?
    var lastLocationLatitude: Double?
    var lastLocationLongitude: Double?
    var shareLink: String?
    var expiresAt: Date?
    var emergencyContacts: [PersistedEmergencyContact]?
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns the ID of the session for identification.
    var modelId: UUID { id }
}

/// Manages saving and loading location sharing sessions using the file system.
/// Uses the unified BaseFileStore architecture.
@MainActor
final class LocationShareSessionFileStore: BaseFileStore<LocationShareSession, PersistedLocationShareSession> {
    
    init() {
        super.init(fileName: "location_share_sessions.json")
    }
    
    // MARK: - Custom Loading (with sorting)
    
    /// Loads all sessions sorted by start time (most recent first).
    override func loadAll() throws -> [LocationShareSession] {
        let all = try super.loadAll()
        return all.sorted { session1, session2 in
            let time1 = session1.startedAt ?? Date.distantPast
            let time2 = session2.startedAt ?? Date.distantPast
            return time1 > time2
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Gets the currently active session.
    func getActiveSession() throws -> LocationShareSession? {
        let all = try loadAll()
        return all.first { $0.isActive }
    }
    
    /// Deactivates all sessions.
    func deactivateAllSessions() throws {
        let all = try loadAll()
        for var session in all where session.isActive {
            session.isActive = false
            try saveOrUpdate(session)
        }
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedLocationShareSession {
    init(from model: LocationShareSession) {
        self.id = model.id
        self.isActive = model.isActive
        self.startedAt = model.startedAt
        self.lastLocationUpdate = model.lastLocationUpdate
        self.lastLocationLatitude = model.lastLocationLatitude
        self.lastLocationLongitude = model.lastLocationLongitude
        self.shareLink = model.shareLink
        self.expiresAt = model.expiresAt
        self.emergencyContacts = model.emergencyContacts?.map {
            PersistedEmergencyContact(
                id: $0.id,
                name: $0.name,
                phoneNumber: $0.phoneNumber,
                email: $0.email,
                isPrimary: $0.isPrimary,
                createdAt: $0.createdAt
            )
        }
    }
    
    func toModel() -> LocationShareSession {
        let session = LocationShareSession(
            id: id,
            isActive: isActive,
            startedAt: startedAt,
            lastLocationUpdate: lastLocationUpdate,
            lastLocationLatitude: lastLocationLatitude,
            lastLocationLongitude: lastLocationLongitude,
            shareLink: shareLink,
            expiresAt: expiresAt
        )
        
        // Restore emergency contacts if present
        if let persistedContacts = emergencyContacts {
            session.emergencyContacts = persistedContacts.map {
                EmergencyContact(
                    id: $0.id,
                    name: $0.name,
                    phoneNumber: $0.phoneNumber,
                    email: $0.email,
                    isPrimary: $0.isPrimary,
                    createdAt: $0.createdAt
                )
            }
        }
        
        return session
    }
}

