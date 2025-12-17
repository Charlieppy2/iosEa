//
//  AccountStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

/// Store responsible for reading and writing authentication data in SwiftData.
@MainActor
final class AccountStore {
    /// Backing SwiftData context used for all account queries.
    private let context: ModelContext

    /// Creates a new store bound to the given SwiftData context.
    init(context: ModelContext) {
        self.context = context
    }

    /// Seeds a couple of demo user accounts the first time the store is empty.
    func seedDefaultsIfNeeded() throws {
        let descriptor = FetchDescriptor<UserCredential>()
        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else { return }

        let defaults = [
            UserCredential(
                email: "jamie@trailcollective.hk",
                password: "GoHike123",
                name: "Jamie Ho",
                avatarSymbol: "person.hiking"
            ),
            UserCredential(
                email: "alex@trailcollective.hk",
                password: "DragonBack!",
                name: "Alex Chan",
                avatarSymbol: "figure.walk"
            )
        ]

        defaults.forEach { context.insert($0) }
        try context.save()
    }

    /// Returns the credential for the given email if it exists; otherwise `nil`.
    func credential(for email: String) throws -> UserCredential? {
        var descriptor = FetchDescriptor<UserCredential>(
            predicate: #Predicate { $0.email == email }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Creates and persists a new credential for a registered user.
    func createCredential(name: String, email: String, password: String) throws -> UserCredential {
        let credential = UserCredential(
            email: email,
            password: password,
            name: name,
            avatarSymbol: "figure.hiking"
        )
        context.insert(credential)
        try context.save()
        return credential
    }
}

