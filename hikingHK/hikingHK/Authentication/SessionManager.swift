//
//  SessionManager.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import Combine
import SwiftData

/// Central controller that manages the authenticated user session and login state.
@MainActor
final class SessionManager: ObservableObject {
    /// Currently signed-in user, or `nil` when logged out.
    @Published private(set) var currentUser: UserAccount?
    /// Latest authentication error message to show in the UI.
    @Published private(set) var authError: String?
    /// Indicates that a sign-in or sign-up request is in progress.
    @Published var isAuthenticating = false
    /// Becomes `true` once the underlying SwiftData store has been configured.
    @Published private(set) var isConfigured = false
    
    /// UserDefaults key used to persist the last signed-in email.
    private let storedEmailKey = "auth_email"
    /// Backing store used for reading and writing credentials.
    private var accountStore: AccountStore?
    /// SwiftData context provided by the app at startup.
    private var modelContext: ModelContext?

    /// Lazily configures the backing `AccountStore` and attempts to restore a previous session.
    func configureIfNeeded(context: ModelContext) async {
        guard !isConfigured else { return }
        self.modelContext = context
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

    /// Attempts to sign in with the given email and password.
    /// Updates `currentUser`, `authError` and `isAuthenticating` accordingly.
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

    /// Registers a new account and signs the user in immediately on success.
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

    /// Clears the current session and removes the stored email, without deleting any user data.
    func signOut() {
        print("🔐 SessionManager: signOut() called, current user: \(currentUser?.email ?? "nil")")
        
        // Clear in-memory session state only and keep user data for the next login
        // Reset user state – this will trigger @Published updates
        currentUser = nil
        
        // Remove the stored email from UserDefaults completely
        UserDefaults.standard.removeObject(forKey: storedEmailKey)
        UserDefaults.standard.synchronize() // Ensure the change is persisted immediately
        
        authError = nil
        
        // Explicitly notify views (in addition to @Published) to guarantee UI refresh
        objectWillChange.send()
        
        print("✅ SessionManager: User signed out, session cleared. Data preserved for next login. currentUser is now: \(currentUser?.email ?? "nil")")
    }

    /// Rehydrates `currentUser` from the stored email if a matching credential exists.
    private func restoreSession() {
        let email = storedEmail
        guard !email.isEmpty else {
            print("🔍 SessionManager: No stored email, skipping session restore")
            return
        }
        
        guard let store = accountStore else {
            print("⚠️ SessionManager: Account store not available, skipping session restore")
            return
        }
        
        guard let credential = try? store.credential(for: email.lowercased()) else {
            print("⚠️ SessionManager: No credential found for stored email, clearing stored email")
            UserDefaults.standard.removeObject(forKey: storedEmailKey)
            return
        }

        currentUser = UserAccount(
            id: credential.accountId,
            name: credential.name,
            email: credential.email,
            avatarSymbol: credential.avatarSymbol
        )
        print("✅ SessionManager: Session restored for user: \(credential.email)")
    }

    /// Convenience wrapper for reading and writing the persisted email in UserDefaults.
    private var storedEmail: String {
        get { UserDefaults.standard.string(forKey: storedEmailKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: storedEmailKey) }
    }
}

/// Errors that can be thrown while working with the `AccountStore`.
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
    /// Helper used in SwiftUI previews to simulate a signed-in state.
    static func previewSignedIn() -> SessionManager {
        let manager = SessionManager()
        manager.currentUser = UserAccount.sampleHiker
        manager.isConfigured = true
        return manager
    }
}
#endif

