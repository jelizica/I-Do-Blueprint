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
    @State private var showDeleteConfirmation = false
    @State private var confirmationText = ""
    @State private var keepBudgetSandbox = false
    @State private var keepAffordability = false
    @State private var keepCategories = false
    @State private var isAuthenticating = false
    @State private var authenticationError: String?

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
            .padding(.bottom, 8)

            Divider()

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
    }

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
                // Reload settings after deletion
                await viewModel.loadSettings()
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
