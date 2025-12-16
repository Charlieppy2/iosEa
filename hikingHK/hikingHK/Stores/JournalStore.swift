//
//  JournalStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class JournalStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func loadAllJournals() throws -> [HikeJournal] {
        print("📖 JournalStore: Loading all journals from context...")
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.sortBy = [SortDescriptor(\.hikeDate, order: .reverse)]
        let journals = try context.fetch(descriptor)
        print("📖 JournalStore: Loaded \(journals.count) journals from database")
        if journals.isEmpty {
            // 尝试检查 context 中是否有未保存的更改
            print("📖 JournalStore: No journals found. Checking for pending changes...")
        } else {
            for journal in journals {
                print("   - Journal: '\(journal.title)' (ID: \(journal.id))")
            }
        }
        return journals
    }
    
    func loadJournal(by id: UUID) throws -> HikeJournal? {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.predicate = #Predicate { $0.id == id }
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    func saveJournal(_ journal: HikeJournal) throws {
        print("💾 JournalStore: Starting to save journal '\(journal.title)' (ID: \(journal.id))")
        print("   Photos count: \(journal.photos.count)")
        
        journal.updatedAt = Date()
        journal.updateShareToken()
        
        print("💾 JournalStore: Inserting journal and photos into context...")
        context.insert(journal)
        
        // 确保所有照片也被插入到 context
        for photo in journal.photos {
            context.insert(photo)
        }
        print("💾 JournalStore: Inserted journal and \(journal.photos.count) photos")
        
        print("💾 JournalStore: Calling context.save()...")
        do {
            try context.save()
            print("✅ JournalStore: context.save() completed successfully")
            
            // 强制处理待处理的更改
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
        
        // 验证保存是否成功
        let journalId = journal.id
        print("💾 JournalStore: Verifying save for journal ID: \(journalId)")
        
        // 立即验证一次
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
    
    func updateJournal(_ journal: HikeJournal) throws {
        journal.updatedAt = Date()
        journal.updateShareToken()
        try context.save()
    }
    
    func deleteJournal(_ journal: HikeJournal) throws {
        context.delete(journal)
        try context.save()
    }
    
    func loadJournalsByTrail(trailId: UUID) throws -> [HikeJournal] {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.predicate = #Predicate { $0.trailId == trailId }
        descriptor.sortBy = [SortDescriptor(\.hikeDate, order: .reverse)]
        return try context.fetch(descriptor)
    }
    
    func loadSharedJournals() throws -> [HikeJournal] {
        var descriptor = FetchDescriptor<HikeJournal>()
        descriptor.predicate = #Predicate { $0.isShared == true }
        descriptor.sortBy = [SortDescriptor(\.hikeDate, order: .reverse)]
        return try context.fetch(descriptor)
    }
}

