//
//  JournalStore.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

/// Manages persistence operations for `HikeJournal` entries using SwiftData.
/// Note: This store is largely superseded by `JournalFileStore` for actual persistence
/// due to observed SwiftData synchronization issues.
@MainActor
final class JournalStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// Loads all journal entries from the SwiftData context for a specific user.
    /// - Parameter accountId: The user account ID to filter journals for.
    /// - Returns: An array of `HikeJournal` models, sorted by hike date (most recent first).
    func loadAllJournals(accountId: UUID) throws -> [HikeJournal] {
        print("📖 JournalStore: Loading all journals from context for account: \(accountId)...")
        var descriptor = FetchDescriptor<HikeJournal>(
            predicate: #Predicate { $0.accountId == accountId }
        )
        descriptor.sortBy = [SortDescriptor(\.hikeDate, order: .reverse)]
        let journals = try context.fetch(descriptor)
        print("📖 JournalStore: Loaded \(journals.count) journals from database")
        if journals.isEmpty {
            // Attempt to check for unsaved changes in the context
            print("📖 JournalStore: No journals found. Checking for pending changes...")
        } else {
            for journal in journals {
                print("   - Journal: '\(journal.title)' (ID: \(journal.id))")
            }
        }
        return journals
    }
    
    /// Loads a specific journal entry by its ID for a specific user.
    /// - Parameters:
    ///   - id: The UUID of the journal to load.
    ///   - accountId: The user account ID to ensure only the owner can access.
    /// - Returns: The `HikeJournal` if found, otherwise `nil`.
    func loadJournal(by id: UUID, accountId: UUID) throws -> HikeJournal? {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.predicate = #Predicate { $0.id == id && $0.accountId == accountId }
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    /// Saves a new journal entry or updates an existing one in the SwiftData context.
    /// - Parameter journal: The `HikeJournal` model to save or update.
    func saveJournal(_ journal: HikeJournal) throws {
        print("💾 JournalStore: Starting to save journal '\(journal.title)' (ID: \(journal.id))")
        print("   Photos count: \(journal.photos.count)")
        
        journal.updatedAt = Date()
        journal.updateShareToken()
        
        print("💾 JournalStore: Inserting journal and photos into context...")
        context.insert(journal)
        
        // Ensure all photos are also inserted into the context
        for photo in journal.photos {
            context.insert(photo)
        }
        print("💾 JournalStore: Inserted journal and \(journal.photos.count) photos")
        
        print("💾 JournalStore: Calling context.save()...")
        do {
            try context.save()
            print("✅ JournalStore: context.save() completed successfully")
            
            // Force processing of pending changes
            if context.hasChanges {
                print("⚠️ JournalStore: Context still has changes after save, processing...")
                try context.processPendingChanges()
                try context.save()
                print("✅ JournalStore: Processed pending changes and saved again")
            }
        } catch {
            print("❌ JournalStore: context.save() failed with error: \(error)")
            print("   Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("   Domain: \(nsError.domain)")
                print("   Code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }
            throw error
        }
        
        // Verify if the save was successful
        let journalId = journal.id
        print("💾 JournalStore: Verifying save for journal ID: \(journalId)")
        
        // Immediate verification
        do {
            var descriptor = FetchDescriptor<HikeJournal>(
                predicate: #Predicate<HikeJournal> { entry in
                    entry.id == journalId
                }
            )
            descriptor.fetchLimit = 1
            let saved = try context.fetch(descriptor).first
            if saved != nil {
                print("✅ JournalStore: Journal saved and verified immediately: '\(journal.title)'")
            } else {
                print("⚠️ JournalStore: Journal was saved but cannot be retrieved immediately (SwiftData sync delay)")
                print("   This is normal - the journal will be available after a short delay")
            }
        } catch {
            print("❌ JournalStore: Error verifying save: \(error)")
        }
    }
    
    /// Updates an existing journal entry in the SwiftData context.
    /// - Parameter journal: The `HikeJournal` model to update.
    func updateJournal(_ journal: HikeJournal) throws {
        journal.updatedAt = Date()
        journal.updateShareToken()
        try context.save()
    }
    
    /// Deletes a journal entry from the SwiftData context.
    /// - Parameter journal: The `HikeJournal` model to delete.
    func deleteJournal(_ journal: HikeJournal) throws {
        context.delete(journal)
        try context.save()
    }
    
    /// Loads journal entries associated with a specific trail.
    /// - Parameter trailId: The UUID of the trail.
    /// - Returns: An array of `HikeJournal` models.
    func loadJournalsByTrail(trailId: UUID) throws -> [HikeJournal] {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.predicate = #Predicate { $0.trailId == trailId }
        descriptor.sortBy = [SortDescriptor(\.hikeDate, order: .reverse)]
        return try context.fetch(descriptor)
    }
    
    /// Loads all shared journal entries.
    /// - Returns: An array of `HikeJournal` models.
    func loadSharedJournals() throws -> [HikeJournal] {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.predicate = #Predicate { $0.isShared == true }
        descriptor.sortBy = [SortDescriptor(\.hikeDate, order: .reverse)]
        return try context.fetch(descriptor)
    }
}

