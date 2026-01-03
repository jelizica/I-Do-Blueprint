//
//  PostOnboardingOverlayView.swift
//  I Do Blueprint
//
//  Lightweight overlay to show staged post-onboarding loads with a Skip option.
//

import SwiftUI

struct PostOnboardingOverlayView: View {
    @ObservedObject var loader: PostOnboardingLoader
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Setting things up…")
                .font(Typography.title3)
            Text(loader.currentMessage)
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            ProgressView(value: loader.progress)
                .frame(width: 360)

            HStack(spacing: Spacing.md) {
                Button("Skip for now") {
                    onSkip()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Skip setup")
                .accessibilityHint("Hide this overlay and continue. Data will keep loading in the background.")
            }
        }
        .padding(Spacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColors.backgroundSecondary)
                .shadow(color: SemanticColors.shadow, radius: 8, x: 0, y: 4)
        )
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.opacity(0.6))
    }
}
