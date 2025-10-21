//
//  ConfigurationErrorView.swift
//  I Do Blueprint
//
//  Error view displayed when app configuration fails
//

import SwiftUI

struct ConfigurationErrorView: View {
    let error: ConfigurationError
    let onRetry: () -> Void
    let onContactSupport: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.warning)
                .accessibilityLabel("Configuration error icon")
            
            // Title
            Text("Configuration Error")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
            
            // Error Description
            if let description = error.errorDescription {
                Text(description)
                    .font(Typography.bodyRegular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                VStack(spacing: Spacing.sm) {
                    Text("What to do:")
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(suggestion)
                        .font(Typography.bodyRegular)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity)
                .background(AppColors.warning.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }
            
            // Actions
            HStack(spacing: Spacing.md) {
                Button(action: onRetry) {
                    Text("Restart App")
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .accessibleActionButton(
                    label: "Restart application",
                    hint: "Restarts the application to retry configuration"
                )
                
                Button(action: onContactSupport) {
                    Text("Contact Support")
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.primary)
                .accessibleActionButton(
                    label: "Contact support",
                    hint: "Opens email to contact support team"
                )
            }
            
            // Technical Details (Expandable)
            DisclosureGroup {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Error Type:")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(String(describing: error))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(AppColors.textSecondary)
                    
                    if let failureReason = error.failureReason {
                        Divider()
                            .padding(.vertical, Spacing.xs)
                        
                        Text("Failure Reason:")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(failureReason)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(CornerRadius.sm)
            } label: {
                Text("Technical Details")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, Spacing.md)
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Preview

#Preview("Config File Not Found") {
    ConfigurationErrorView(
        error: .configFileNotFound,
        onRetry: { print("Retry tapped") },
        onContactSupport: { print("Contact support tapped") }
    )
}

#Preview("Missing Supabase URL") {
    ConfigurationErrorView(
        error: .missingSupabaseURL,
        onRetry: { print("Retry tapped") },
        onContactSupport: { print("Contact support tapped") }
    )
}

#Preview("Invalid URL Format") {
    ConfigurationErrorView(
        error: .invalidURLFormat("not-a-valid-url"),
        onRetry: { print("Retry tapped") },
        onContactSupport: { print("Contact support tapped") }
    )
}

#Preview("Security Violation") {
    ConfigurationErrorView(
        error: .securityViolation("Service-role key found in bundle"),
        onRetry: { print("Retry tapped") },
        onContactSupport: { print("Contact support tapped") }
    )
}
