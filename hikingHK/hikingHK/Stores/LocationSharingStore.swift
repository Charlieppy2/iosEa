//
//  LocationSharingStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class LocationSharingStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func seedDefaultsIfNeeded() throws {
        // 檢查是否已有緊急聯繫人
        let contactDescriptor = FetchDescriptor<EmergencyContact>()
        let existingContacts = try context.fetch(contactDescriptor)
        guard existingContacts.isEmpty else { return }
        
        // 可以添加默認示例聯繫人（可選）
        // 實際應用中，應該讓用戶自己添加
    }
    
    func loadAllContacts() throws -> [EmergencyContact] {
        let descriptor = FetchDescriptor<EmergencyContact>()
        let contacts = try context.fetch(descriptor)
        // 手動排序，因為 SwiftData 的 SortDescriptor 對 @Model 類有限制
        return contacts.sorted { contact1, contact2 in
            if contact1.isPrimary != contact2.isPrimary {
                return contact1.isPrimary // 主要聯繫人排在前面
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

