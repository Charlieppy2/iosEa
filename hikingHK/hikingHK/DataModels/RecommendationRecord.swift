//
//  RecommendationRecord.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

/// Historical record of a trail recommendation and how the user interacted with it.
@Model
final class RecommendationRecord {
    var id: UUID
    var accountId: UUID // User account ID to associate this record with a specific user
    var trailId: UUID
    var recommendedAt: Date
    var userAction: UserAction? // How the user responded to this recommendation
    var recommendationScore: Double // Final score used to rank this recommendation
    var reason: String // Human-readable explanation of why this trail was recommended
    
    enum UserAction: String, Codable {
        case viewed = "查看"
        case planned = "計劃"
        case completed = "完成"
        case dismissed = "忽略"
    }
    
    init(
        id: UUID = UUID(),
        accountId: UUID,
        trailId: UUID,
        recommendedAt: Date = Date(),
        userAction: UserAction? = nil,
        recommendationScore: Double = 0,
        reason: String = ""
    ) {
        self.id = id
        self.accountId = accountId
        self.trailId = trailId
        self.recommendedAt = recommendedAt
        self.userAction = userAction
        self.recommendationScore = recommendationScore
        self.reason = reason
    }
}

