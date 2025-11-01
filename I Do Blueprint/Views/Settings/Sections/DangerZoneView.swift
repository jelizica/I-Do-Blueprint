//
//  DangerZoneView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import LocalAuthentication
import SwiftUI

struct DangerZoneView: View {
    @ObservedObject var viewModel: SettingsStoreV2
    
    // Delete My Data states
    @State private var showDeleteConfirmation = false
    @State private var confirmationText = ""
    @State private var keepBudgetSandbox = false
    @State private var keepAffordability = false
    @State private var keepCategories = false
    @State private var isAuthenticating = false
    @State private var authenticationError: String?
    
    // Delete Account states
    @State private var accountDeletionConfirmationText = ""
    @State private var isAuthenticatingForAccount = false
    @State private var isDeletingAccount = false
    @State private var accountDeletionError: String?
    @State private var showAccountDeletionSuccess = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header (No save button for danger zone)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Danger Zone")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                Text("Irreversible actions that permanently affect your wedding data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, Spacing.sm)

            Divider()
            
            // MARK: - Delete Account Section (Most Destructive)
            
            GroupBox(label: Text("")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .foregroundColor(.red)
                            .font(.title3)
                        Text("Delete Account Permanently")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    Text("This will permanently delete your entire account AND all wedding data. You will not be able to log in again.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ **This action is irreversible and includes:**")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("All wedding planning data", systemImage: "checkmark.circle.fill")
                            Label("Your account and login credentials", systemImage: "checkmark.circle.fill")
                            Label("Settings and preferences", systemImage: "checkmark.circle.fill")
                            Label("Couple profile and memberships", systemImage: "checkmark.circle.fill")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To confirm, type: **DELETE MY ACCOUNT**")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        TextField("Type here...", text: $accountDeletionConfirmationText)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: accountDeletionConfirmationText) { _, _ in
                                accountDeletionError = nil
                            }
                    }
                    
                    if let error = accountDeletionError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(Spacing.sm)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    Button(action: handleAccountDeletionWithAuth) {
                        if isAuthenticatingForAccount || isDeletingAccount {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(isAuthenticatingForAccount ? "Authenticating..." : "Deleting Account...")
                            }
                        } else {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.xmark")
                                Text("Delete My Account Forever")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(accountDeletionConfirmationText != "DELETE MY ACCOUNT" || isAuthenticatingForAccount || isDeletingAccount)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .background(Color.red.opacity(0.1))
            
            Divider()
                .padding(.vertical, Spacing.sm)
            
            // MARK: - Delete My Data Section (Less Destructive)

            // Warning Card
            GroupBox(label: Text("")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Nuclear Data Deletion")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }

                    Text("This action will permanently delete most of your wedding planning data.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Options to preserve specific data:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Keep Budget Sandbox data", isOn: $keepBudgetSandbox)
                        Toggle("Keep Affordability calculator data", isOn: $keepAffordability)
                        Toggle("Keep custom categories", isOn: $keepCategories)
                    }
                    .toggleStyle(.checkbox)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("To confirm, type: **DELETE MY DATA**")
                            .font(.subheadline)

                        TextField("Type here...", text: $confirmationText)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: confirmationText) { _, _ in
                                authenticationError = nil
                            }
                    }

                    if let authError = authenticationError {
                        Text(authError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button(action: handleDeleteWithAuth) {
                        if isAuthenticating || viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(isAuthenticating ? "Authenticating..." : "Deleting...")
                            }
                        } else {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete My Data")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(confirmationText != "DELETE MY DATA" || isAuthenticating || viewModel.isLoading)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .background(Color.red.opacity(0.05))
        }
        .alert("Data Deletion Complete", isPresented: $showDeleteConfirmation) {
            Button("OK") {
                confirmationText = ""
            }
        } message: {
            Text("Your wedding data has been permanently deleted.")
        }
        .alert("Account Deleted", isPresented: $showAccountDeletionSuccess) {
            Button("OK") {
                // User will be automatically signed out and redirected to login
            }
        } message: {
            Text("Your account has been permanently deleted. You will be signed out.")
        }
    }
    
    // MARK: - Account Deletion Methods
    
    private func handleAccountDeletionWithAuth() {
        // First authenticate with biometrics
        accountDeletionError = nil
        isAuthenticatingForAccount = true
        
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to permanently delete your account"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    isAuthenticatingForAccount = false
                    
                    if success {
                        // Authentication successful, proceed with account deletion
                        performAccountDeletion()
                    } else {
                        // Authentication failed
                        accountDeletionError = "Authentication failed. Please try again."
                    }
                }
            }
        } else {
            // Biometrics not available, fall back to password authentication
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "Authenticate to permanently delete your account"
                
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                    DispatchQueue.main.async {
                        isAuthenticatingForAccount = false
                        
                        if success {
                            performAccountDeletion()
                        } else {
                            accountDeletionError = "Authentication failed. Please try again."
                        }
                    }
                }
            } else {
                // No authentication available
                isAuthenticatingForAccount = false
                accountDeletionError = "Device authentication not available"
            }
        }
    }
    
    private func performAccountDeletion() {
        isDeletingAccount = true
        accountDeletionError = nil
        
        Task {
            do {
                try await viewModel.deleteAccount()
                
                // Show success message briefly before user is signed out
                await MainActor.run {
                    isDeletingAccount = false
                    showAccountDeletionSuccess = true
                }
                
                // Wait 2 seconds for user to see the success message
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                // User will be automatically redirected to login screen
                // because SessionManager.clearSession() was called in the repository
                
            } catch {
                await MainActor.run {
                    isDeletingAccount = false
                    accountDeletionError = "Account deletion failed: \(error.localizedDescription)"
                    AppLogger.ui.error("Account deletion failed", error: error)
                }
            }
        }
    }
    
    // MARK: - Data Deletion Methods

    private func handleDeleteWithAuth() {
        // First authenticate with biometrics
        authenticationError = nil
        isAuthenticating = true

        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to delete your wedding data"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    isAuthenticating = false

                    if success {
                        // Authentication successful, proceed with deletion
                        performDataDeletion()
                    } else {
                        // Authentication failed
                        authenticationError = "Authentication failed. Please try again."
                    }
                }
            }
        } else {
            // Biometrics not available, fall back to password authentication
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "Authenticate to delete your wedding data"

                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                    DispatchQueue.main.async {
                        isAuthenticating = false

                        if success {
                            performDataDeletion()
                        } else {
                            authenticationError = "Authentication failed. Please try again."
                        }
                    }
                }
            } else {
                // No authentication available
                isAuthenticating = false
                authenticationError = "Device authentication not available"
            }
        }
    }

    private func performDataDeletion() {
        Task {
            do {
                try await viewModel.resetData(
                    keepBudgetSandbox: keepBudgetSandbox,
                    keepAffordability: keepAffordability,
                    keepCategories: keepCategories)
                showDeleteConfirmation = true
                // Try to reload settings after deletion, but don't fail if no settings exist
                // (e.g., for new users who haven't completed onboarding)
                do {
                    await viewModel.loadSettings()
                } catch {
                    // Ignore settings load errors - user may not have settings yet
                    print("Note: Could not reload settings after deletion (this is normal for new users): \(error.localizedDescription)")
                }
            } catch {
                authenticationError = "Deletion failed: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    DangerZoneView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 700)
}
