//
//  DeveloperSettingsView.swift
//  My Wedding Planning App
//
//  Developer-only settings for configuring OAuth credentials
//

import SwiftUI

struct DeveloperSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var googleAuthManager = GoogleAuthManager()

    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var showSuccess = false
    @State private var hasExistingCredentials = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Configure Google OAuth credentials for Google Drive and Sheets integration.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Google OAuth Configuration")
                }

                Section {
                    if hasExistingCredentials {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Credentials are configured")
                                .foregroundColor(.secondary)
                        }

                        Button("Clear Credentials", role: .destructive) {
                            clearCredentials()
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("No credentials configured")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Status")
                }

                Section {
                    TextField("Client ID", text: $clientID)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Client Secret", text: $clientSecret)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Credentials")
                } footer: {
                    Text("Get these from Google Cloud Console > APIs & Services > Credentials")
                        .font(.caption)
                }

                Section {
                    Button("Save Credentials") {
                        saveCredentials()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(clientID.isEmpty || clientSecret.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Developer Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Credentials Saved", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Google OAuth credentials have been securely stored in Keychain.")
            }
            .onAppear {
                checkExistingCredentials()
            }
        }
        .frame(width: 500, height: 400)
    }

    private func saveCredentials() {
        googleAuthManager.storeCredentials(
            clientID: clientID.trimmingCharacters(in: .whitespacesAndNewlines),
            clientSecret: clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        // Clear the text fields
        clientID = ""
        clientSecret = ""

        hasExistingCredentials = true
        showSuccess = true
    }

    private func clearCredentials() {
        // Store empty credentials to clear them
        googleAuthManager.storeCredentials(clientID: "", clientSecret: "")
        hasExistingCredentials = false
    }

    private func checkExistingCredentials() {
        // Check if credentials exist by seeing if authError is nil
        hasExistingCredentials = googleAuthManager.authError == nil
    }
}

#Preview {
    DeveloperSettingsView()
}
