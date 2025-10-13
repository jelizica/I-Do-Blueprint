//
//  AccountSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 1/10/25.
//

import Auth
import SwiftUI

struct AccountSettingsView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var showLogoutConfirmation = false
    @State private var isLoggingOut = false
    @State private var logoutError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Account Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                Text("Manage your account and authentication")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            Divider()

            // Account Information
            GroupBox(label: Text("Account Information").font(.headline)) {
                VStack(alignment: .leading, spacing: 16) {
                    if supabaseManager.isAuthenticated {
                        HStack {
                            Text("Status:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Signed In")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }

                        if let user = supabaseManager.currentUser {
                            Divider()

                            HStack {
                                Text("Email:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(user.email ?? "Not available")
                                    .font(.subheadline)
                            }

                            HStack {
                                Text("User ID:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(user.id.uuidString.prefix(8) + "...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Text("Status:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 8, height: 8)
                                Text("Not Signed In")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding()
            }

            // Logout Section
            if supabaseManager.isAuthenticated {
                GroupBox(label: Text("Sign Out").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sign out of your account. You'll need to sign in again to access your wedding planning data.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let error = logoutError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }

                        Button(action: { showLogoutConfirmation = true }) {
                            if isLoggingOut {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Signing Out...")
                                }
                            } else {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoggingOut)
                    }
                    .padding()
                }
            }
        }
        .confirmationDialog("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Sign Out", role: .destructive) {
                performLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out of your account?")
        }
    }

    private func performLogout() {
        logoutError = nil
        isLoggingOut = true

        Task {
            do {
                let logger = AppLogger.auth

                // 1. Sign out from Supabase
                try await supabaseManager.signOut()
                logger.info("User signed out successfully")

                // 2. Clear session
                await SessionManager.shared.clearSession()
                logger.info("Session cleared")

                // 3. Clear all repository caches
                await RepositoryCache.clearAll()
                logger.info("Repository caches cleared")

                // 4. Reset AppCoordinator stores (handled by AppCoordinator observation of auth state)
                logger.info("Store reset triggered by auth state change")

                // 5. Log analytics event (non-PII)
                logger.info("auth_logout completed")

                // Successfully signed out
                isLoggingOut = false
            } catch {
                isLoggingOut = false
                logoutError = "Failed to sign out: \(error.localizedDescription)"
                AppLogger.auth.error("Logout failed", error: error)
            }
        }
    }
}

#Preview {
    AccountSettingsView()
        .padding()
        .frame(width: 700)
}
