//
//  RecommendationRecord.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@Model
final class RecommendationRecord {
    var id: UUID
    var trailId: UUID
    var recommendedAt: Date
    var userAction: UserAction? // 用戶對推薦的反應
    var recommendationScore: Double // 推薦分數
    var reason: String // 推薦理由
    
    enum UserAction: String, Codable {
        case viewed = "查看"
        case planned = "計劃"
        case completed = "完成"
        case dismissed = "忽略"
    }
    
    init(
        id: UUID = UUID(),
        trailId: UUID,
        recommendedAt: Date = Date(),
        userAction: UserAction? = nil,
        recommendationScore: Double = 0,
        reason: String = ""
    ) {
        self.id = id
        self.trailId = trailId
        self.recommendedAt = recommendedAt
        self.userAction = userAction
        self.recommendationScore = recommendationScore
        self.reason = reason
    }
}

