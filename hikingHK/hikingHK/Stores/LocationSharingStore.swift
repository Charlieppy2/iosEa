//
//  LocationSharingStore.swift
//  hikingHK
//
//  Created by user on 17/11/2025.

import Foundation
import SwiftData

/// Store responsible for persisting emergency contacts and location-sharing sessions.
@MainActor
final class LocationSharingStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func seedDefaultsIfNeeded() throws {
        // Check if there are already emergency contacts.
        let contactDescriptor = FetchDescriptor<EmergencyContact>()
        let existingContacts = try context.fetch(contactDescriptor)
        guard existingContacts.isEmpty else { return }
        
        // Optional: add default sample contacts.
        // In a real app, users should be prompted to add their own contacts.
    }
    
    func loadAllContacts() throws -> [EmergencyContact] {
        let descriptor = FetchDescriptor<EmergencyContact>()
        let contacts = try context.fetch(descriptor)
        // Manual sorting because SwiftData's SortDescriptor has limitations with @Model types.
        return contacts.sorted { contact1, contact2 in
            if contact1.isPrimary != contact2.isPrimary {
                return contact1.isPrimary // Primary contacts should appear first.
            }
            return contact1.name < contact2.name
        }
    }
    
    func saveContact(_ contact: EmergencyContact) throws {
        context.insert(contact)
        try context.save()
    }
    
    func deleteContact(_ contact: EmergencyContact) throws {
        context.delete(contact)
        try context.save()
    }
    
    func loadActiveSession() throws -> LocationShareSession? {
        var descriptor = FetchDescriptor<LocationShareSession>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    func saveSession(_ session: LocationShareSession) throws {
        context.insert(session)
        try context.save()
    }
}

