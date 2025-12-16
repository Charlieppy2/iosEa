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
    private var modelContext: ModelContext?

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
        print("🔐 SessionManager: signOut() called, current user: \(currentUser?.email ?? "nil")")
        
        // 只清除会话状态，保留所有数据以便下次登录时恢复
        // 清除用户状态 - 这会触发 @Published 更新
        currentUser = nil
        
        // 完全清除 UserDefaults 中的存储值
        UserDefaults.standard.removeObject(forKey: storedEmailKey)
        UserDefaults.standard.synchronize() // 确保立即同步
        
        authError = nil
        
        // 显式触发视图更新（@Published 应该自动处理，但确保一下）
        objectWillChange.send()
        
        print("✅ SessionManager: User signed out, session cleared. Data preserved for next login. currentUser is now: \(currentUser?.email ?? "nil")")
    }

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

