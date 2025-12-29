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
    @Attribute(.unique) var trailId: UUID

    init(trailId: UUID) {
        self.trailId = trailId
    }
}

