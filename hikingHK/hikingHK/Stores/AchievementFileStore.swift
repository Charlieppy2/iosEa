//
//  AchievementFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist achievements, avoiding SwiftData synchronization issues.
//  Uses the unified BaseFileStore architecture.
//

import Foundation

/// DTO for JSON persistence of an achievement.
struct PersistedAchievement: FileStoreDTO {
    var id: String
    var badgeType: Achievement.BadgeType
    var title: String
    var achievementDescription: String
    var icon: String
    var targetValue: Double
    var currentValue: Double
    var isUnlocked: Bool
    var unlockedAt: Date?
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns a UUID derived from the achievement ID for identification.
    /// Since Achievement uses String IDs, we convert them to UUID using a deterministic hash.
    var modelId: UUID {
        // Convert String ID to UUID using a deterministic method
        // This ensures the same String ID always maps to the same UUID
        if let uuid = UUID(uuidString: id) {
            return uuid
        }
        // If the ID is not a valid UUID string, create a deterministic UUID from the string
        // Use a simple hash function to generate a stable UUID
        var hash: UInt64 = 0
        for char in id.utf8 {
            hash = hash &* 31 &+ UInt64(char)
        }
        // Format as UUID: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
        let hexString = String(format: "%016llx", hash)
        let uuidString = "\(hexString.prefix(8))-\(hexString.dropFirst(8).prefix(4))-4\(hexString.dropFirst(12).prefix(3))-8\(hexString.dropFirst(15).prefix(3))-\(hexString.suffix(12))"
        return UUID(uuidString: uuidString) ?? UUID()
    }
}

/// Manages saving and loading achievements using the file system.
/// Uses the unified BaseFileStore architecture.
@MainActor
final class AchievementFileStore: BaseFileStore<Achievement, PersistedAchievement> {
    
    init() {
        super.init(fileName: "achievements.json")
    }
    
    // MARK: - Custom Loading (with sorting)
    
    /// Loads all achievements sorted by badge type and then by target value.
    override func loadAll() throws -> [Achievement] {
        let all = try super.loadAll()
        return all.sorted { achievement1, achievement2 in
            // First sort by badge type
            if achievement1.badgeType != achievement2.badgeType {
                return achievement1.badgeType.rawValue < achievement2.badgeType.rawValue
            }
            // Then sort by target value (ascending)
            return achievement1.targetValue < achievement2.targetValue
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Finds an achievement by its String ID.
    func findById(_ id: String) throws -> Achievement? {
        let all = try loadAll()
        return all.first { $0.id == id }
    }
    
    /// Updates the progress of an achievement by its String ID.
    func updateProgress(forId id: String, value: Double) throws {
        guard var achievement = try findById(id) else {
            throw FileStoreError.invalidData
        }
        achievement.updateProgress(value)
        try saveOrUpdate(achievement)
    }
    
    /// Unlocks an achievement by its String ID.
    func unlock(achievementId id: String) throws {
        guard var achievement = try findById(id) else {
            throw FileStoreError.invalidData
        }
        achievement.unlock()
        try saveOrUpdate(achievement)
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedAchievement {
    init(from model: Achievement) {
        self.id = model.id
        self.badgeType = model.badgeType
        self.title = model.title
        self.achievementDescription = model.achievementDescription
        self.icon = model.icon
        self.targetValue = model.targetValue
        self.currentValue = model.currentValue
        self.isUnlocked = model.isUnlocked
        self.unlockedAt = model.unlockedAt
    }
    
    func toModel() -> Achievement {
        Achievement(
            id: id,
            badgeType: badgeType,
            title: title,
            achievementDescription: achievementDescription,
            icon: icon,
            targetValue: targetValue,
            currentValue: currentValue,
            isUnlocked: isUnlocked,
            unlockedAt: unlockedAt
        )
    }
}

