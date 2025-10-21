//
//  ErrorStateView.swift
//  I Do Blueprint
//
//  Error state display with retry functionality
//

import SwiftUI

/// View displaying error state with retry option
struct ErrorStateView: View {
    let error: Error
    let onRetry: (() -> Void)?
    
    init(error: Error, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.error)
                .accessibilityHidden(true)
            
            // Error message
            VStack(spacing: Spacing.sm) {
                Text("Something Went Wrong")
                    .font(Typography.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .accessibleHeading(level: 2)
                
                Text(error.localizedDescription)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.lg)
            
            // Retry button
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibleActionButton(
                    label: "Try again",
                    hint: "Attempts to reload the content"
                )
            }
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

/// Inline error view for smaller spaces
struct InlineErrorView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    init(message: String, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(AppColors.error)
                .accessibilityHidden(true)
            
            Text(message)
                .font(Typography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
            
            if let onRetry = onRetry {
                Button("Retry", action: onRetry)
                    .font(Typography.bodySmall)
                    .buttonStyle(.plain)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.errorLight)
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .contain)
    }
}

/// Banner error view for top-of-screen notifications
struct ErrorBannerView: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(AppColors.error)
                .accessibilityHidden(true)
            
            Text(message)
                .font(Typography.bodySmall)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss error")
            }
        }
        .padding(Spacing.md)
        .background(AppColors.errorLight)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppColors.shadowLight, radius: 4, y: 2)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("Error State View") {
    ErrorStateView(
        error: NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to load data. Please check your internet connection and try again."]
        ),
        onRetry: {
            print("Retry tapped")
        }
    )
}

#Preview("Error State View - No Retry") {
    ErrorStateView(
        error: NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "This feature is not available at the moment."]
        )
    )
}

#Preview("Inline Error View") {
    InlineErrorView(
        message: "Failed to save changes",
        onRetry: {
            print("Retry tapped")
        }
    )
    .padding()
}

#Preview("Error Banner View") {
    VStack {
        ErrorBannerView(
            message: "Unable to sync data. Check your connection.",
            onDismiss: {
                print("Dismissed")
            }
        )
        .padding()
        
        Spacer()
    }
}

#Preview("Multiple Error Styles") {
    VStack(spacing: Spacing.lg) {
        ErrorBannerView(
            message: "Network error occurred",
            onDismiss: {}
        )
        
        InlineErrorView(
            message: "Failed to load guests",
            onRetry: {}
        )
        
        Spacer()
    }
    .padding()
}
