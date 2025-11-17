//
//  AccountStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class AccountStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

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

    func credential(for email: String) throws -> UserCredential? {
        var descriptor = FetchDescriptor<UserCredential>(
            predicate: #Predicate { $0.email == email }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

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

