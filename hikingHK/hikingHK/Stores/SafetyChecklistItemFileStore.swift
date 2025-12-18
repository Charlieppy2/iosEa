//
//  SafetyChecklistItemFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist safety checklist items, avoiding SwiftData synchronization issues.
//  Uses the unified BaseFileStore architecture.
//

import Foundation

/// DTO for JSON persistence of a safety checklist item.
struct PersistedSafetyChecklistItem: FileStoreDTO {
    var id: String
    var iconName: String
    var title: String
    var isCompleted: Bool
    var lastUpdated: Date
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns a UUID derived from the item ID for identification.
    /// Since SafetyChecklistItem uses String IDs, we convert them to UUID using a deterministic hash.
    var modelId: UUID {
        // Convert String ID to UUID using a deterministic method
        if let uuid = UUID(uuidString: id) {
            return uuid
        }
        // Create a deterministic UUID from the string hash
        var hash: UInt64 = 0
        for char in id.utf8 {
            hash = hash &* 31 &+ UInt64(char)
        }
        let hexString = String(format: "%016llx", hash)
        let uuidString = "\(hexString.prefix(8))-\(hexString.dropFirst(8).prefix(4))-4\(hexString.dropFirst(12).prefix(3))-8\(hexString.dropFirst(15).prefix(3))-\(hexString.suffix(12))"
        return UUID(uuidString: uuidString) ?? UUID()
    }
}

/// Manages saving and loading safety checklist items using the file system.
/// Uses the unified BaseFileStore architecture.
@MainActor
final class SafetyChecklistItemFileStore: BaseFileStore<SafetyChecklistItem, PersistedSafetyChecklistItem> {
    
    init() {
        super.init(fileName: "safety_checklist_items.json")
    }
    
    // MARK: - Custom Loading
    
    /// Loads all items sorted by last updated date (most recently updated first).
    override func loadAll() throws -> [SafetyChecklistItem] {
        let all = try super.loadAll()
        return all.sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    // MARK: - Convenience Methods
    
    /// Toggles the completion status of an item.
    func toggleCompletion(_ item: SafetyChecklistItem) throws {
        var updated = item
        updated.isCompleted.toggle()
        updated.lastUpdated = Date()
        try saveOrUpdate(updated)
    }
    
    /// Gets all completed items.
    func getCompletedItems() throws -> [SafetyChecklistItem] {
        let all = try loadAll()
        return all.filter { $0.isCompleted }
    }
    
    /// Gets all incomplete items.
    func getIncompleteItems() throws -> [SafetyChecklistItem] {
        let all = try loadAll()
        return all.filter { !$0.isCompleted }
    }
    
    /// Gets the completion percentage.
    func getCompletionPercentage() throws -> Double {
        let all = try loadAll()
        guard !all.isEmpty else { return 0 }
        let completed = all.filter { $0.isCompleted }.count
        return Double(completed) / Double(all.count)
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedSafetyChecklistItem {
    init(from model: SafetyChecklistItem) {
        self.id = model.id
        self.iconName = model.iconName
        self.title = model.title
        self.isCompleted = model.isCompleted
        self.lastUpdated = model.lastUpdated
    }
    
    func toModel() -> SafetyChecklistItem {
        SafetyChecklistItem(
            id: id,
            iconName: iconName,
            title: title,
            isCompleted: isCompleted
        )
    }
}

