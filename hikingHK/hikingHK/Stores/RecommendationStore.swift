//
//  RecommendationStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class RecommendationStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func loadUserPreference() throws -> UserPreference? {
        var descriptor = FetchDescriptor<UserPreference>()
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    func saveUserPreference(_ preference: UserPreference) throws {
        // 刪除舊的偏好設置
        if let existing = try loadUserPreference() {
            context.delete(existing)
        }
        context.insert(preference)
        try context.save()
    }
    
    func loadRecommendationHistory(trailId: UUID? = nil) throws -> [RecommendationRecord] {
        var descriptor = FetchDescriptor<RecommendationRecord>(
            sortBy: [SortDescriptor(\.recommendedAt, order: .reverse)]
        )
        
        if let trailId = trailId {
            descriptor.predicate = #Predicate { $0.trailId == trailId }
        }
        
        return try context.fetch(descriptor)
    }
    
    func saveRecommendation(_ recommendation: RecommendationRecord) throws {
        context.insert(recommendation)
        try context.save()
    }
    
    func updateRecommendationAction(_ record: RecommendationRecord, action: RecommendationRecord.UserAction) throws {
        record.userAction = action
        try context.save()
    }
}

