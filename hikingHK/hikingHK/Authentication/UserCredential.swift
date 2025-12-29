//
//  UserCredential.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import SwiftData

@Model
/// SwiftData model that persists login credentials and profile metadata.
final class UserCredential {
    /// Stable identifier used to link credentials to higher-level `UserAccount`s.
    var accountId: UUID
    /// Unique email address used for authentication.
    @Attribute(.unique) var email: String
    /// Hashed or plain-text password for demo purposes (do not use plain text in production).
    var password: String
    /// Display name of the user.
    var name: String
    /// SF Symbol name used as the avatar in the UI.
    var avatarSymbol: String
    /// Timestamp when this credential was created.
    var createdAt: Date
    
    /// Creates a new credential instance with a fresh account identifier and creation date.
    init(email: String, password: String, name: String, avatarSymbol: String) {
        self.accountId = UUID()
        self.email = email
        self.password = password
        self.name = name
        self.avatarSymbol = avatarSymbol
        self.createdAt = Date()
    }
}

