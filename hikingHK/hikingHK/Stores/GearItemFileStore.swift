//
//  GearItemFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist gear items, avoiding SwiftData synchronization issues.
//  Uses the unified BaseFileStore architecture.
//

import Foundation

/// DTO for JSON persistence of a gear item.
struct PersistedGearItem: FileStoreDTO {
    var id: String
    var category: GearItem.GearCategory
    var name: String
    var iconName: String
    var isRequired: Bool
    var isCompleted: Bool
    var lastUpdated: Date
    var hikeId: UUID?
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns a UUID derived from the gear item ID for identification.
    /// Since GearItem uses String IDs, we convert them to UUID using a deterministic hash.
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

/// Manages saving and loading gear items using the file system.
/// Uses the unified BaseFileStore architecture.
@MainActor
final class GearItemFileStore: BaseFileStore<GearItem, PersistedGearItem> {
    
    init() {
        super.init(fileName: "gear_items.json")
    }
    
    // MARK: - Custom Loading (with sorting)
    
    /// Loads all gear items sorted by category, then by required status, then by name.
    override func loadAll() throws -> [GearItem] {
        let all = try super.loadAll()
        return all.sorted { item1, item2 in
            // First by category
            if item1.category != item2.category {
                return item1.category.rawValue < item2.category.rawValue
            }
            // Then by required status (required first)
            if item1.isRequired != item2.isRequired {
                return item1.isRequired
            }
            // Finally by name
            return item1.name < item2.name
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Gets all gear items for a specific hike.
    func getItemsForHike(_ hikeId: UUID) throws -> [GearItem] {
        let all = try loadAll()
        return all.filter { $0.hikeId == hikeId }
    }
    
    /// Gets all gear items by category.
    func getItemsByCategory(_ category: GearItem.GearCategory) throws -> [GearItem] {
        let all = try loadAll()
        return all.filter { $0.category == category }
    }
    
    /// Gets all required gear items.
    func getRequiredItems() throws -> [GearItem] {
        let all = try loadAll()
        return all.filter { $0.isRequired }
    }
    
    /// Toggles the completion status of a gear item.
    func toggleCompletion(_ item: GearItem) throws {
        var updated = item
        updated.isCompleted.toggle()
        updated.lastUpdated = Date()
        try saveOrUpdate(updated)
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedGearItem {
    init(from model: GearItem) {
        self.id = model.id
        self.category = model.category
        self.name = model.name
        self.iconName = model.iconName
        self.isRequired = model.isRequired
        self.isCompleted = model.isCompleted
        self.lastUpdated = model.lastUpdated
        self.hikeId = model.hikeId
    }
    
    func toModel() -> GearItem {
        GearItem(
            id: id,
            category: category,
            name: name,
            iconName: iconName,
            isRequired: isRequired,
            isCompleted: isCompleted,
            hikeId: hikeId
        )
    }
}

