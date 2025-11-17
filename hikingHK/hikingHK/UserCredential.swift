//
//  UserCredential.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@Model
final class UserCredential {
    var accountId: UUID
    @Attribute(.unique) var email: String
    var password: String
    var name: String
    var avatarSymbol: String
    var createdAt: Date

    init(email: String, password: String, name: String, avatarSymbol: String) {
        self.accountId = UUID()
        self.email = email
        self.password = password
        self.name = name
        self.avatarSymbol = avatarSymbol
        self.createdAt = Date()
    }
}

