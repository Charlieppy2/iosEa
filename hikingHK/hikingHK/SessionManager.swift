//
//  SessionManager.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import Combine
import SwiftData

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var currentUser: UserAccount?
    @Published private(set) var authError: String?
    @Published var isAuthenticating = false
    @Published private(set) var isConfigured = false

    private let storedEmailKey = "auth_email"
    private var accountStore: AccountStore?

    func configureIfNeeded(context: ModelContext) async {
        guard !isConfigured else { return }
        let store = AccountStore(context: context)
        do {
            try store.seedDefaultsIfNeeded()
            accountStore = store
            isConfigured = true
            restoreSession()
        } catch {
            authError = "Unable to prepare account database."
            print("Account store error: \(error)")
        }
    }

    func signIn(email: String, password: String) async {
        guard let store = accountStore else {
            authError = "Account store not ready."
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            guard let credential = try store.credential(for: email.lowercased()),
                  credential.password == password else {
                throw AccountStoreError.invalidCredentials
            }
            currentUser = UserAccount(
                id: credential.accountId,
                name: credential.name,
                email: credential.email,
                avatarSymbol: credential.avatarSymbol
            )
            storedEmail = credential.email
            authError = nil
        } catch {
            authError = error.localizedDescription
            currentUser = nil
        }
    }

    func signUp(name: String, email: String, password: String) async {
        guard let store = accountStore else {
            authError = "Account store not ready."
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            guard try store.credential(for: email.lowercased()) == nil else {
                throw AccountStoreError.emailExists
            }
            let credential = try store.createCredential(name: name, email: email.lowercased(), password: password)
            currentUser = UserAccount(
                id: credential.accountId,
                name: credential.name,
                email: credential.email,
                avatarSymbol: credential.avatarSymbol
            )
            storedEmail = credential.email
            authError = nil
        } catch {
            authError = error.localizedDescription
        }
    }

    func signOut() {
        currentUser = nil
        storedEmail = ""
    }

    private func restoreSession() {
        guard !storedEmail.isEmpty,
              let store = accountStore,
              let credential = try? store.credential(for: storedEmail.lowercased())
        else { return }

        currentUser = UserAccount(
            id: credential.accountId,
            name: credential.name,
            email: credential.email,
            avatarSymbol: credential.avatarSymbol
        )
    }

    private var storedEmail: String {
        get { UserDefaults.standard.string(forKey: storedEmailKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: storedEmailKey) }
    }
}

enum AccountStoreError: LocalizedError {
    case invalidCredentials
    case emailExists

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email or password is incorrect."
        case .emailExists:
            return "This email is already registered."
        }
    }
}

#if DEBUG
extension SessionManager {
    static func previewSignedIn() -> SessionManager {
        let manager = SessionManager()
        manager.currentUser = UserAccount.sampleHiker
        manager.isConfigured = true
        return manager
    }
}
#endif

