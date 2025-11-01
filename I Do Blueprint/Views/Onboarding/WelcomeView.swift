//
//  WelcomeView.swift
//  I Do Blueprint
//
//  Welcome screen for onboarding with mode selection
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.onboardingStore) private var store
    @State private var selectedMode: OnboardingMode = .guided
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xxl) {
                Spacer()
                    .frame(height: Spacing.xxl)
                
                // App icon/logo
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.primary)
                    .accessibilityHidden(true)
                
                // Welcome message
                VStack(spacing: Spacing.md) {
                    Text("Welcome to")
                        .font(Typography.title2)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("I Do Blueprint")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Welcome to I Do Blueprint")
                
                // Description
                Text("Let's get started planning your perfect wedding. We'll guide you through setting up your account and importing your data.")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Mode selection
                VStack(spacing: Spacing.lg) {
                    Text("Choose your setup style")
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: Spacing.md) {
                        ModeSelectionCard(
                            mode: .guided,
                            isSelected: selectedMode == .guided,
                            onSelect: { selectedMode = .guided }
                        )
                        
                        ModeSelectionCard(
                            mode: .express,
                            isSelected: selectedMode == .express,
                            onSelect: { selectedMode = .express }
                        )
                    }
                    .padding(.horizontal, Spacing.xl)
                }
                
                // Get started button
                Button(action: {
                    Task {
                        // Start onboarding and move to next step
                        // The moveToNextStep will update UI immediately
                        await store.startOnboarding(mode: selectedMode)
                        await store.moveToNextStep()
                    }
                }) {
                    HStack(spacing: Spacing.sm) {
                        Text("Get Started")
                            .font(Typography.bodyLarge)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: 400)
                    .padding(.vertical, Spacing.lg)
                    .background(AppColors.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)
                .accessibilityLabel("Get started with \(selectedMode.displayName)")
                .accessibilityHint("Begins the onboarding process")
                
                Spacer()
                    .frame(height: Spacing.xxl)
            }
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.background)
    }
}

// MARK: - Mode Selection Card

struct ModeSelectionCard: View {
    let mode: OnboardingMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.primary : AppColors.textSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                .accessibilityHidden(true)
                
                // Mode info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(mode.displayName)
                        .font(Typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(mode.description)
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding(Spacing.lg)
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mode.displayName)
        .accessibilityValue(mode.description)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint("Tap to select \(mode.displayName)")
    }
}

// MARK: - Preview

#Preview("Welcome View") {
    WelcomeView()
}

#Preview("Mode Selection Card - Selected") {
    ModeSelectionCard(
        mode: .guided,
        isSelected: true,
        onSelect: {}
    )
    .padding()
}

#Preview("Mode Selection Card - Unselected") {
    ModeSelectionCard(
        mode: .express,
        isSelected: false,
        onSelect: {}
    )
    .padding()
}
