//
//  CredentialsErrorView.swift
//  My Wedding Planning App
//
//  Actionable error UI for missing Google OAuth credentials
//

import SwiftUI

struct CredentialsErrorView: View {
    private let logger = AppLogger.auth
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.warning)

            // Title
            Text("Setup Required")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)

            // Description
            Text("Google OAuth credentials are not configured. Please complete the setup to enable Google Sign-In.")
                .font(.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.huge)

            // Action buttons
            VStack(spacing: 12) {
                // Open Setup Guide button
                Button(action: {
                    if let url = URL(string: "https://docs.google.com/document/d/YOUR_SETUP_GUIDE_URL") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Open Setup Guide")
                    }
                    .frame(maxWidth: 300)
                    .padding(.vertical, Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // Retry button
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .frame(maxWidth: 300)
                    .padding(.vertical, Spacing.md)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                #if DEBUG
                // Demo mode button (DEBUG only)
                Button(action: {
                    // Demo mode: Future feature for testing without authentication
                    // Would allow users to explore app features with sample data
                    AppLogger.auth.warning("Demo mode not yet implemented")
                }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Continue in Demo Mode")
                    }
                    .frame(maxWidth: 300)
                    .padding(.vertical, Spacing.md)
                }
                .buttonStyle(.borderless)
                .controlSize(.large)
                .foregroundColor(AppColors.textTertiary)
                #endif
            }
            .padding(.top, Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    CredentialsErrorView(onRetry: {
        // TODO: Implement action - print("Retry tapped")
    })
}
