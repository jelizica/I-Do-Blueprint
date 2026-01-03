//
//  ConfigurationErrorView.swift
//  I Do Blueprint
//
//  Error view displayed when app configuration fails
//

import SwiftUI

struct ConfigurationErrorView: View {
    private let logger = AppLogger.ui
    let error: ConfigurationError
    let onRetry: () -> Void
    let onContactSupport: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(SemanticColors.warning)
                .accessibilityLabel("Configuration error icon")

            // Title
            Text("Configuration Error")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)

            // Error Description
            if let description = error.errorDescription {
                Text(description)
                    .font(Typography.bodyRegular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(SemanticColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                VStack(spacing: Spacing.sm) {
                    Text("What to do:")
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text(suggestion)
                        .font(Typography.bodyRegular)
                        .multilineTextAlignment(.center)
                        .foregroundColor(SemanticColors.textSecondary)
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
                .tint(SemanticColors.primaryAction)
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
                .tint(SemanticColors.primaryAction)
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
                        .foregroundColor(SemanticColors.textPrimary)

                    Text(String(describing: error))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(SemanticColors.textSecondary)

                    if let failureReason = error.failureReason {
                        Divider()
                            .padding(.vertical, Spacing.xs)

                        Text("Failure Reason:")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(SemanticColors.textPrimary)

                        Text(failureReason)
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SemanticColors.backgroundSecondary)
                .cornerRadius(CornerRadius.sm)
            } label: {
                Text("Technical Details")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .padding(.top, Spacing.md)
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SemanticColors.backgroundPrimary)
    }
}

// MARK: - Preview

#Preview("Config File Not Found") {
    ConfigurationErrorView(
        error: .configFileNotFound,
        onRetry: { },
        onContactSupport: { }
    )
}

#Preview("Missing Supabase URL") {
    ConfigurationErrorView(
        error: .missingSupabaseURL,
        onRetry: { },
        onContactSupport: { }
    )
}

#Preview("Invalid URL Format") {
    ConfigurationErrorView(
        error: .invalidURLFormat("not-a-valid-url"),
        onRetry: { },
        onContactSupport: { }
    )
}

#Preview("Security Violation") {
    ConfigurationErrorView(
        error: .securityViolation("Service-role key found in bundle"),
        onRetry: { },
        onContactSupport: { }
    )
}
