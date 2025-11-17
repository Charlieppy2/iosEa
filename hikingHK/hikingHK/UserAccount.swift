//
//  UserAccount.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation

struct UserAccount: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let email: String
    let avatarSymbol: String

    init(id: UUID = UUID(), name: String, email: String, avatarSymbol: String = "figure.walk") {
        self.id = id
        self.name = name
        self.email = email
        self.avatarSymbol = avatarSymbol
    }
}

extension UserAccount {
    static let sampleHiker = UserAccount(
        name: "Jamie Ho",
        email: "jamie@trailcollective.hk",
        avatarSymbol: "person.hiking"
    )
}

