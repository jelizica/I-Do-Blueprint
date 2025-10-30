//
//  APIKeysSettingsView.swift
//  I Do Blueprint
//
//  API key configuration interface with secure Keychain storage
//

import SwiftUI

struct APIKeysSettingsView: View {
    @StateObject private var apiKeyManager = SecureAPIKeyManager.shared
    
    @State private var unsplashKey = ""
    @State private var pinterestKey = ""
    @State private var vendorKey = ""
    @State private var resendKey = ""

    @State private var validationError: String?
    @State private var isValidating = false
    @State private var validatingType: SecureAPIKeyManager.APIKeyType?
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        Form {
            // Header Section
            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "key.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.primary)
                        
                        Text("API Key Management")
                            .font(Typography.heading)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Text("Configure API keys for third-party integrations. Keys are securely stored in macOS Keychain and never leave your device.")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppColors.primary)
                            .font(.caption)
                        Text("Note: Email invitations work out-of-the-box using a shared service. Only add a Resend API key if you need custom email domain support.")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, Spacing.xs)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.primary.opacity(0.05))
                    .cornerRadius(CornerRadius.sm)
                }
                .padding(.vertical, Spacing.xs)
            }
            .listRowBackground(Color.clear)
            
            // Unsplash API Key
            apiKeySection(
                type: .unsplash,
                isConfigured: apiKeyManager.hasUnsplashKey,
                keyBinding: $unsplashKey,
                description: "Access millions of high-quality wedding inspiration photos"
            )
            
            // Pinterest API Key
            apiKeySection(
                type: .pinterest,
                isConfigured: apiKeyManager.hasPinterestKey,
                keyBinding: $pinterestKey,
                description: "Import and sync Pinterest boards for wedding planning"
            )
            
            // Vendor API Key
            apiKeySection(
                type: .vendor,
                isConfigured: apiKeyManager.hasVendorKey,
                keyBinding: $vendorKey,
                description: "Connect with vendor marketplaces and services"
            )

            // Resend Email API Key (Optional)
            apiKeySection(
                type: .resend,
                isConfigured: apiKeyManager.hasResendKey,
                keyBinding: $resendKey,
                description: "Optional: The app uses a shared email service for invitations. Add your own Resend API key only if you want to use your custom email domain."
            )
        }
        .formStyle(.grouped)
        .alert("Validation Error", isPresented: .constant(validationError != nil)) {
            Button("OK") {
                validationError = nil
            }
        } message: {
            if let error = validationError {
                Text(error)
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                showSuccessAlert = false
            }
        } message: {
            Text(successMessage)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("API Keys Settings")
    }
    
    // MARK: - API Key Section
    
    @ViewBuilder
    private func apiKeySection(
        type: SecureAPIKeyManager.APIKeyType,
        isConfigured: Bool,
        keyBinding: Binding<String>,
        description: String
    ) -> some View {
        Section {
            if isConfigured {
                configuredKeyView(for: type)
            } else {
                unconfiguredKeyView(for: type, keyBinding: keyBinding)
            }
        } header: {
            HStack {
                Text(type.displayName)
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
                
                if isConfigured {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                        .font(.caption)
                }
            }
        } footer: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(description)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Link("Get API Key →", destination: URL(string: type.helpURL)!)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.primary)
            }
        }
    }
    
    // MARK: - Configured Key View
    
    @ViewBuilder
    private func configuredKeyView(for type: SecureAPIKeyManager.APIKeyType) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(AppColors.success)
                .font(.title3)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(type.displayName) API key configured")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Stored securely in Keychain")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button(role: .destructive) {
                removeKey(for: type)
            } label: {
                Label("Remove", systemImage: "trash")
                    .font(Typography.bodySmall)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .accessibilityLabel("Remove \(type.displayName) API key")
            .accessibilityHint("Deletes the stored API key from Keychain")
        }
        .padding(.vertical, Spacing.xs)
    }
    
    // MARK: - Unconfigured Key View
    
    @ViewBuilder
    private func unconfiguredKeyView(
        for type: SecureAPIKeyManager.APIKeyType,
        keyBinding: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "key")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.title3)
                    .accessibilityHidden(true)
                
                Text("No API key configured")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("API Key")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                SecureField("Enter your \(type.displayName) API key", text: keyBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(Typography.bodyRegular)
                    .disabled(isValidating)
                    .accessibilityLabel("\(type.displayName) API key input")
                    .accessibilityHint("Enter your API key from \(type.displayName)")
            }
            
            HStack(spacing: Spacing.sm) {
                Button {
                    Task {
                        await saveAndValidateKey(keyBinding.wrappedValue, for: type)
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        if isValidating && validatingType == type {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isValidating && validatingType == type ? "Validating..." : "Save & Validate")
                    }
                    .font(Typography.bodySmall)
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyBinding.wrappedValue.isEmpty || isValidating)
                .accessibilityLabel("Save and validate \(type.displayName) API key")
                .accessibilityHint("Validates the API key and stores it securely in Keychain")
                
                if !keyBinding.wrappedValue.isEmpty {
                    Button {
                        keyBinding.wrappedValue = ""
                    } label: {
                        Text("Clear")
                            .font(Typography.bodySmall)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Clear API key input")
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
    
    // MARK: - Actions
    
    private func saveAndValidateKey(_ key: String, for type: SecureAPIKeyManager.APIKeyType) async {
        isValidating = true
        validatingType = type
        validationError = nil
        
        do {
            // Validate key first
            let isValid = try await apiKeyManager.validateAPIKey(key, for: type)
            
            guard isValid else {
                validationError = "API key validation failed. Please check your key and try again."
                isValidating = false
                validatingType = nil
                return
            }
            
            // Store if valid
            try apiKeyManager.storeAPIKey(key, for: type)
            
            // Clear input and show success
            await MainActor.run {
                switch type {
                case .unsplash:
                    unsplashKey = ""
                case .pinterest:
                    pinterestKey = ""
                case .vendor:
                    vendorKey = ""
                case .resend:
                    resendKey = ""
                }

                successMessage = "\(type.displayName) API key saved successfully!"
                showSuccessAlert = true
            }
        } catch {
            validationError = error.localizedDescription
        }
        
        isValidating = false
        validatingType = nil
    }
    
    private func removeKey(for type: SecureAPIKeyManager.APIKeyType) {
        apiKeyManager.deleteAPIKey(for: type)
        successMessage = "\(type.displayName) API key removed"
        showSuccessAlert = true
    }
}

#Preview {
    APIKeysSettingsView()
        .frame(width: 600, height: 700)
}
