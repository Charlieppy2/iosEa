//
//  EmergencyContactFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist emergency contacts, avoiding SwiftData synchronization issues.
//  Uses the unified BaseFileStore architecture.
//

import Foundation

/// DTO for JSON persistence of an emergency contact.
struct PersistedEmergencyContact: FileStoreDTO {
    var id: UUID
    var name: String
    var phoneNumber: String
    var email: String?
    var isPrimary: Bool
    var createdAt: Date
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns the ID of the emergency contact for identification.
    var modelId: UUID { id }
}

/// Manages saving and loading emergency contacts using the file system.
/// Uses the unified BaseFileStore architecture.
@MainActor
final class EmergencyContactFileStore: BaseFileStore<EmergencyContact, PersistedEmergencyContact> {
    
    init() {
        super.init(fileName: "emergency_contacts.json")
    }
    
    // MARK: - Custom Loading (with sorting)
    
    /// Loads all emergency contacts sorted by primary status first, then by creation date.
    override func loadAll() throws -> [EmergencyContact] {
        let all = try super.loadAll()
        return all.sorted { contact1, contact2 in
            // Primary contacts first
            if contact1.isPrimary != contact2.isPrimary {
                return contact1.isPrimary
            }
            // Then by creation date (oldest first)
            return contact1.createdAt < contact2.createdAt
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Gets the primary emergency contact.
    func getPrimaryContact() throws -> EmergencyContact? {
        let all = try loadAll()
        return all.first { $0.isPrimary }
    }
    
    /// Sets a contact as primary and unmarks others.
    func setPrimaryContact(_ contact: EmergencyContact) throws {
        var all = try loadAll()
        
        // Unmark all as primary
        for var existing in all {
            if existing.id != contact.id && existing.isPrimary {
                existing.isPrimary = false
                try saveOrUpdate(existing)
            }
        }
        
        // Set this one as primary
        var updated = contact
        updated.isPrimary = true
        try saveOrUpdate(updated)
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedEmergencyContact {
    init(from model: EmergencyContact) {
        self.id = model.id
        self.name = model.name
        self.phoneNumber = model.phoneNumber
        self.email = model.email
        self.isPrimary = model.isPrimary
        self.createdAt = model.createdAt
    }
    
    func toModel() -> EmergencyContact {
        EmergencyContact(
            id: id,
            name: name,
            phoneNumber: phoneNumber,
            email: email,
            isPrimary: isPrimary,
            createdAt: createdAt
        )
    }
}

