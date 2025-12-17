//
//  AuthView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI

/// Authentication screen that lets the user sign in or create a new account.
struct AuthView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var languageManager: LanguageManager
    
    /// Local form state for the user's name, email and password.
    @State private var name = ""
    @State private var email = "jamie@trailcollective.hk"
    @State private var password = "GoHike123"
    @State private var isRegistering = false
    @FocusState private var focusedField: Field?

    /// Fields that can receive keyboard focus inside the form.
    enum Field {
        case name
        case email
        case password
    }

    /// Main view hierarchy: branding, form fields, error display and action buttons.
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.hiking")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.hikingGreen)
                    Text(languageManager.localizedString(for: "app.name"))
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.hikingDarkGreen)
                    Text(isRegistering ? languageManager.localizedString(for: "auth.create.account") : languageManager.localizedString(for: "auth.sign.in.description"))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.hikingBrown)
                }
                VStack(spacing: 16) {
                    if isRegistering {
                        TextField(languageManager.localizedString(for: "auth.name"), text: $name)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .focused($focusedField, equals: .name)
                    }
                    TextField(languageManager.localizedString(for: "auth.email"), text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .focused($focusedField, equals: .email)
                    SecureField(languageManager.localizedString(for: "auth.password"), text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .focused($focusedField, equals: .password)
                }
                if let error = sessionManager.authError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
                authActionButton
                modeToggle
                Spacer()
            }
            .padding()
            .background(
                ZStack {
                    Color.hikingBackgroundGradient
                    HikingPatternBackground()
                        .opacity(0.2)
                }
                .ignoresSafeArea()
            )
            // Status pill shown while the underlying account store is being prepared.
            .overlay(alignment: .top) {
                if !sessionManager.isConfigured {
                    Label(languageManager.localizedString(for: "auth.preparing.storage"), systemImage: "lock.rectangle.stack")
                        .padding(12)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.top, 16)
                }
            }
            // Add a "Done" button above the keyboard to dismiss the keyboard.
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(languageManager.localizedString(for: "done")) { focusedField = nil }
                }
            }
        }
    }
}

extension AuthView {
    /// Primary button that triggers sign in or sign up depending on the current mode.
    private var authActionButton: some View {
        Button {
            if isRegistering {
                Task { await sessionManager.signUp(name: name, email: email, password: password) }
            } else {
                Task { await sessionManager.signIn(email: email, password: password) }
            }
        } label: {
            if sessionManager.isAuthenticating {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity)
            } else {
                Text(isRegistering ? languageManager.localizedString(for: "auth.create.account.button") : languageManager.localizedString(for: "auth.sign.in"))
                    .bold()
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.hikingGreen)
        .disabled(isRegistering ? (name.isEmpty || email.isEmpty || password.isEmpty || sessionManager.isAuthenticating) : (email.isEmpty || password.isEmpty || sessionManager.isAuthenticating))
    }

    /// Switch between "already have an account" and "new hiker" modes.
    private var modeToggle: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation {
                    isRegistering.toggle()
                }
            } label: {
                Text(isRegistering ? languageManager.localizedString(for: "auth.have.account") : languageManager.localizedString(for: "auth.new.hiker"))
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(SessionManager())
        .environmentObject(LanguageManager.shared)
}

