//
//  FavoriteTrailRecord.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

/// Lightweight SwiftData model storing the identifier of a favorited trail.
@Model
final class FavoriteTrailRecord {
    var accountId: UUID // User account ID to associate this record with a specific user
    var trailId: UUID

    init(accountId: UUID, trailId: UUID) {
        self.accountId = accountId
        self.trailId = trailId
    }
}

