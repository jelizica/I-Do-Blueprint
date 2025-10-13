//
//  CredentialsErrorView.swift
//  My Wedding Planning App
//
//  Actionable error UI for missing Google OAuth credentials
//

import SwiftUI

struct CredentialsErrorView: View {
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
                .padding(.horizontal, 40)

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
                    .padding(.vertical, 12)
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
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                #if DEBUG
                // Demo mode button (DEBUG only)
                Button(action: {
                    // TODO: Implement demo mode bypass
                    AppLogger.auth.warning("Demo mode not yet implemented")
                }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Continue in Demo Mode")
                    }
                    .frame(maxWidth: 300)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderless)
                .controlSize(.large)
                .foregroundColor(AppColors.textTertiary)
                #endif
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    CredentialsErrorView(onRetry: {
        print("Retry tapped")
    })
}
