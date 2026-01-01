//
//  AccountStore.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
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
        // Ensure email is lowercased for consistent lookup
        let lowercasedEmail = email.lowercased()
        var descriptor = FetchDescriptor<UserCredential>(
            predicate: #Predicate { $0.email == lowercasedEmail }
        )
        descriptor.fetchLimit = 1
        
        do {
            let results = try context.fetch(descriptor)
            if let credential = results.first {
                print("✅ AccountStore: Found credential for \(lowercasedEmail), accountId: \(credential.accountId)")
            } else {
                print("⚠️ AccountStore: No credential found for \(lowercasedEmail)")
            }
            return results.first
        } catch {
            print("❌ AccountStore: Error fetching credential for \(lowercasedEmail): \(error)")
            throw error
        }
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
        do {
            try context.save()
            print("✅ AccountStore: Successfully created credential for \(email), accountId: \(credential.accountId)")
            print("   Saved password length: \(credential.password.count), password: \"\(credential.password)\"")
            
            // Verify the saved credential can be retrieved immediately
            if let verification = try? self.credential(for: email) {
                print("   Verification: Credential can be retrieved, password length: \(verification.password.count)")
            }
        } catch {
            print("❌ AccountStore: Failed to save credential: \(error)")
            // Try to process pending changes and save again
            context.processPendingChanges()
            try context.save()
            print("✅ AccountStore: Successfully saved credential after processing pending changes")
        }
        return credential
    }
}

