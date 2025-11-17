//
//  AuthView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var sessionManager: SessionManager
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
                        .foregroundStyle(.green)
                    Text("Hiking HK")
                        .font(.largeTitle.bold())
                    Text(isRegistering ? "Create your hiking account." : "Sign in to sync your hikes, badges and plans.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 16) {
                    if isRegistering {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .focused($focusedField, equals: .name)
                    }
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .focused($focusedField, equals: .email)
                    SecureField("Password", text: $password)
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
            .overlay(alignment: .top) {
                if !sessionManager.isConfigured {
                    Label("Preparing secure storage…", systemImage: "lock.rectangle.stack")
                        .padding(12)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.top, 16)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
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
                Text(isRegistering ? "Create Account" : "Sign In")
                    .bold()
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isRegistering ? (name.isEmpty || email.isEmpty || password.isEmpty || sessionManager.isAuthenticating) : (email.isEmpty || password.isEmpty || sessionManager.isAuthenticating))
    }

    private var modeToggle: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation {
                    isRegistering.toggle()
                }
            } label: {
                Text(isRegistering ? "Have an account? Sign in" : "New hiker? Create account")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(SessionManager())
}

