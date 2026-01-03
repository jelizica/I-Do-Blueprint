//
//  AuthenticationView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 1/10/25.
//

import Auth
import SwiftUI

struct AuthenticationView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo/Title area
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("I Do Blueprint")
                        .font(.system(size: 40, weight: .bold, design: .rounded))

                    Text("Your Wedding Planning Companion")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, Spacing.huge)

                // Auth form
                if showSignUp {
                    SignUpView(showSignUp: $showSignUp)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    LoginView(showSignUp: $showSignUp)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }

                Spacer()
            }
            .frame(maxWidth: 500)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSignUp)
    }
}

// MARK: - Login View

struct LoginView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email
        case password
    }

    var body: some View {
        VStack(spacing: 24) {
            // Login form
            VStack(alignment: .leading, spacing: 16) {
                Text("Sign In")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("your.email@example.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .email)
                            .accessibilityLabel("Email address")
                            .accessibilityHint("Enter your email address")
                            .onSubmit {
                                focusedField = .password
                            }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .accessibilityLabel("Password")
                            .accessibilityHint("Enter your password")
                            .onSubmit {
                                if !email.isEmpty && !password.isEmpty {
                                    handleLogin()
                                }
                            }
                    }
                }

                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .accessibilityHidden(true)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, Spacing.sm)
                    .padding(.horizontal, Spacing.md)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error: \(error)")
                }

                Button(action: handleLogin) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                                .accessibilityHidden(true)
                            Text("Signing In...")
                        }
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityLabel("Sign in")
                .accessibilityHint("Signs you in to your account")

                Divider()
                    .padding(.vertical, Spacing.sm)

                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign Up") {
                        showSignUp = true
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                .font(.subheadline)
            }
            .padding(Spacing.xxxl)
            .background(Color(nsColor: .windowBackgroundColor))
            .cornerRadius(16)
            .shadow(color: SemanticColors.textPrimary.opacity(Opacity.subtle), radius: 20, x: 0, y: 10)
        }
    }

    private func handleLogin() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await supabaseManager.signIn(email: email, password: password)
                // Success - authentication state change will be handled automatically
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 24) {
            // Sign up form
            VStack(alignment: .leading, spacing: 16) {
                Text("Create Account")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("your.email@example.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        SecureField("Create a password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                        Text("Must be at least 6 characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                    }
                }

                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, Spacing.sm)
                    .padding(.horizontal, Spacing.md)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                if showSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Account created! Check your email to verify your account.")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, Spacing.sm)
                    .padding(.horizontal, Spacing.md)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                Button(action: handleSignUp) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Creating Account...")
                        }
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(isLoading || !isFormValid)

                Divider()
                    .padding(.vertical, Spacing.sm)

                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign In") {
                        showSignUp = false
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                .font(.subheadline)
            }
            .padding(Spacing.xxxl)
            .background(Color(nsColor: .windowBackgroundColor))
            .cornerRadius(16)
            .shadow(color: SemanticColors.textPrimary.opacity(Opacity.subtle), radius: 20, x: 0, y: 10)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    private func handleSignUp() {
        errorMessage = nil
        showSuccess = false
        isLoading = true

        Task {
            do {
                try await supabaseManager.signUp(email: email, password: password)
                isLoading = false
                showSuccess = true

                // Clear form
                email = ""
                password = ""
                confirmPassword = ""

                // Switch to login after delay
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                showSignUp = false
            } catch {
                isLoading = false
                errorMessage = "Sign up failed: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .frame(width: 900, height: 600)
}
