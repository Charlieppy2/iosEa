//
//  SessionManager.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
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
    /// Flag to prevent automatic session restoration after explicit sign out.
    private var hasExplicitlySignedOut = false
    
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
            // Only restore session if user hasn't explicitly signed out
            if !hasExplicitlySignedOut {
                restoreSession()
            } else {
                print("🔍 SessionManager: Skipping session restore because user explicitly signed out")
            }
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
        
        let lowercasedEmail = email.lowercased()
        print("🔐 SessionManager: Attempting to sign in with email: \(lowercasedEmail)")
        
        do {
            guard let credential = try store.credential(for: lowercasedEmail) else {
                print("❌ SessionManager: No credential found for email: \(lowercasedEmail)")
                throw AccountStoreError.invalidCredentials
            }
            
            print("✅ SessionManager: Found credential for \(lowercasedEmail), checking password...")
            print("   Input password length: \(password.count), stored password length: \(credential.password.count)")
            print("   Input password: \"\(password)\", stored password: \"\(credential.password)\"")
            
            guard credential.password == password else {
                print("❌ SessionManager: Password mismatch for \(lowercasedEmail)")
                print("   Password comparison failed: stored='\(credential.password)' != input='\(password)'")
                throw AccountStoreError.invalidCredentials
            }
            
            print("✅ SessionManager: Password verified, creating user session...")
            currentUser = UserAccount(
                id: credential.accountId,
                name: credential.name,
                email: credential.email,
                avatarSymbol: credential.avatarSymbol
            )
            storedEmail = credential.email
            authError = nil
            // Reset the sign out flag when user successfully signs in
            hasExplicitlySignedOut = false
            print("✅ SessionManager: Successfully signed in as \(credential.email), accountId: \(credential.accountId)")
        } catch {
            print("❌ SessionManager: Sign in failed: \(error.localizedDescription)")
            authError = error.localizedDescription
            currentUser = nil
        }
    }

    /// Validates email format.
    /// - Parameter email: The email address to validate.
    /// - Returns: `true` if the email format is valid, `false` otherwise.
    private func isValidEmail(_ email: String) -> Bool {
        // Basic email validation: must contain @ and have valid domain
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Registers a new account and signs the user in immediately on success.
    func signUp(name: String, email: String, password: String) async {
        guard let store = accountStore else {
            authError = "Account store not ready."
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        // Validate password length
        guard password.count >= 6 else {
            print("❌ SessionManager: Password too short (length: \(password.count))")
            authError = AccountStoreError.passwordTooShort.localizedDescription
            return
        }
        
        // Validate email format
        guard isValidEmail(email) else {
            print("❌ SessionManager: Invalid email format: \(email)")
            authError = AccountStoreError.invalidEmail.localizedDescription
            return
        }
        
        let lowercasedEmail = email.lowercased()
        print("📝 SessionManager: Attempting to sign up with email: \(lowercasedEmail)")
        
        do {
            // Check if email already exists
            if let existingCredential = try store.credential(for: lowercasedEmail) {
                print("❌ SessionManager: Email already exists: \(lowercasedEmail)")
                throw AccountStoreError.emailExists
            }
            
            print("✅ SessionManager: Email available, creating credential...")
            let credential = try store.createCredential(name: name, email: lowercasedEmail, password: password)
            
            // Give SwiftData a moment to ensure the save is complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            currentUser = UserAccount(
                id: credential.accountId,
                name: credential.name,
                email: credential.email,
                avatarSymbol: credential.avatarSymbol
            )
            storedEmail = credential.email
            authError = nil
            // Reset the sign out flag when user successfully signs up
            hasExplicitlySignedOut = false
            print("✅ SessionManager: Successfully signed up and signed in as \(credential.email), accountId: \(credential.accountId)")
        } catch {
            print("❌ SessionManager: Sign up failed: \(error.localizedDescription)")
            authError = error.localizedDescription
        }
    }

    /// Clears the current session and removes the stored email, without deleting any user data.
    func signOut() {
        // If already signed out and flag is set, just return
        if currentUser == nil && hasExplicitlySignedOut {
            print("⚠️ SessionManager: signOut() called but user is already signed out, ignoring")
            return
        }
        
        print("🔐 SessionManager: signOut() called, current user: \(currentUser?.email ?? "nil")")
        
        // Set flag to prevent automatic session restoration
        hasExplicitlySignedOut = true
        
        // Remove the stored email from UserDefaults first
        UserDefaults.standard.removeObject(forKey: storedEmailKey)
        UserDefaults.standard.synchronize() // Ensure the change is persisted immediately
        
        // Clear in-memory session state – this will trigger @Published updates
        // Since SessionManager is @MainActor, this is already on the main thread
        currentUser = nil
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
    case invalidEmail
    case passwordTooShort

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email or password is incorrect."
        case .emailExists:
            return "This email is already registered."
        case .invalidEmail:
            return "Please enter a valid email address (e.g., example@gmail.com)."
        case .passwordTooShort:
            return "Password must be at least 6 characters long."
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

