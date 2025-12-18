//
//  RecommendationRecordFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist recommendation records, avoiding SwiftData synchronization issues.
//  Uses the unified BaseFileStore architecture.
//

import Foundation

/// DTO for JSON persistence of a recommendation record.
struct PersistedRecommendationRecord: FileStoreDTO {
    var id: UUID
    var trailId: UUID
    var recommendedAt: Date
    var userAction: RecommendationRecord.UserAction?
    var recommendationScore: Double
    var reason: String
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns the ID of the recommendation record for identification.
    var modelId: UUID { id }
}

/// Manages saving and loading recommendation records using the file system.
/// Uses the unified BaseFileStore architecture.
@MainActor
final class RecommendationRecordFileStore: BaseFileStore<RecommendationRecord, PersistedRecommendationRecord> {
    
    init() {
        super.init(fileName: "recommendation_records.json")
    }
    
    // MARK: - Custom Loading (with sorting)
    
    /// Loads all recommendation records sorted by recommendation date (most recent first).
    override func loadAll() throws -> [RecommendationRecord] {
        let all = try super.loadAll()
        return all.sorted { $0.recommendedAt > $1.recommendedAt }
    }
    
    // MARK: - Convenience Methods
    
    /// Gets all records for a specific trail.
    func getRecordsForTrail(_ trailId: UUID) throws -> [RecommendationRecord] {
        let all = try loadAll()
        return all.filter { $0.trailId == trailId }
    }
    
    /// Gets all records with a specific user action.
    func getRecordsWithAction(_ action: RecommendationRecord.UserAction) throws -> [RecommendationRecord] {
        let all = try loadAll()
        return all.filter { $0.userAction == action }
    }
    
    /// Gets the most recent recommendation for a trail.
    func getMostRecentForTrail(_ trailId: UUID) throws -> RecommendationRecord? {
        let records = try getRecordsForTrail(trailId)
        return records.first
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedRecommendationRecord {
    init(from model: RecommendationRecord) {
        self.id = model.id
        self.trailId = model.trailId
        self.recommendedAt = model.recommendedAt
        self.userAction = model.userAction
        self.recommendationScore = model.recommendationScore
        self.reason = model.reason
    }
    
    func toModel() -> RecommendationRecord {
        RecommendationRecord(
            id: id,
            trailId: trailId,
            recommendedAt: recommendedAt,
            userAction: userAction,
            recommendationScore: recommendationScore,
            reason: reason
        )
    }
}

