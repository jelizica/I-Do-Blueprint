//
//  DeveloperSettingsView.swift
//  My Wedding Planning App
//
//  Developer-only settings for configuring OAuth credentials
//

import SwiftUI
// Performance feature flags for verbose logging
import Foundation

struct DeveloperSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var googleAuthManager = GoogleAuthManager()

    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var showSuccess = false
    @State private var hasExistingCredentials = false

    // JES-199 diagnostics
    @State private var configSummary: ConfigValidationSummary? = nil

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Configuration Diagnostics (read-only)
                Section {
                    diagnosticsRow(
                        icon: "bolt.fill",
                        title: "SUPABASE_URL",
                        present: configSummary?.supabaseURLPresent == true,
                        valid: configSummary?.supabaseURLValid == true
                    )
                    diagnosticsRow(
                        icon: "key.fill",
                        title: "SUPABASE_ANON_KEY",
                        present: configSummary?.supabaseAnonKeyPresent == true,
                        valid: true
                    )
                    diagnosticsRow(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "SENTRY_DSN",
                        present: configSummary?.sentryDSNPresent == true,
                        valid: configSummary?.sentryDSNValid == true
                    )

                    HStack {
                        Button("Re-run Validation") {
                            configSummary = ConfigValidator.validateAll()
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        if let summary = configSummary {
                            let allGood = summary.supabaseURLPresent
                                && summary.supabaseURLValid
                                && summary.supabaseAnonKeyPresent
                                && summary.sentryDSNPresent
                                && summary.sentryDSNValid
                            let iconName = allGood ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
                            let helpText = allGood
                                ? "All configuration looks valid"
                                : "One or more configuration items require attention"
                            Image(systemName: iconName)
                                .foregroundColor(allGood ? .green : .orange)
                                .help(helpText)
                        }
                    }
                } header: {
                    Text("Configuration Diagnostics")
                }

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

                // MARK: - Performance Logging (DEBUG only)
                #if DEBUG
                Section("Performance Logging") {
                    Toggle(isOn: Binding(
                        get: { PerformanceFeatureFlags.enablePerformanceMonitoring },
                        set: { PerformanceFeatureFlags.setPerformanceMonitoring(enabled: $0) }
                    )) {
                        Text("Enable verbose performance logging")
                    }
                    .help("When enabled, store loads and key operations record timing metrics and breadcrumbs.")
                }
                #endif
            }
            .navigationTitle("Developer Settings")

            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: PerformanceDiagnosticsView()) {
                        Label("Perf Diagnostics", systemImage: "speedometer")
                    }
                }
            }
            #endif
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
                configSummary = ConfigValidator.validateAll()
            }
        }
        .frame(width: 500, height: 400)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func diagnosticsRow(icon: String, title: String, present: Bool, valid: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text(title)
            Spacer()
            Group {
                if present {
                    Image(systemName: valid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(valid ? .green : .orange)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .help(present ? (valid ? "Present and valid" : "Present but may be invalid") : "Missing")
        }
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
