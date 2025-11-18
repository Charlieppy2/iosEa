//
//  AuthView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var name = ""
    @State private var email = "jamie@trailcollective.hk"
    @State private var password = "GoHike123"
    @State private var isRegistering = false
    @FocusState private var focusedField: Field?

    enum Field {
        case name
        case email
        case password
    }

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
            .overlay(alignment: .top) {
                if !sessionManager.isConfigured {
                    Label(languageManager.localizedString(for: "auth.preparing.storage"), systemImage: "lock.rectangle.stack")
                        .padding(12)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.top, 16)
                }
            }
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

