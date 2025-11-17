//
//  FavoriteTrailRecord.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@Model
final class FavoriteTrailRecord {
    @Attribute(.unique) var trailId: UUID

    init(trailId: UUID) {
        self.trailId = trailId
    }
}

