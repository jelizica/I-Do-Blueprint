//
//  OnboardingContainerView.swift
//  I Do Blueprint
//
//  Container view managing the onboarding flow
//

import SwiftUI

/// Main container for the onboarding flow with step navigation
struct OnboardingContainerView: View {
    @Environment(\.appStores) private var appStores
    @Environment(\.dismiss) private var dismiss
    
    // ✅ CRITICAL: Use @ObservedObject to actually observe store changes
    @ObservedObject private var store: OnboardingStoreV2
    
    init() {
        // Get the store from AppStores singleton
        self.store = AppStores.shared.onboarding
    }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                if store.currentStep != .welcome && store.currentStep != .completion {
                    OnboardingProgressBar(
                        currentStep: store.currentStep,
                        completedSteps: store.completedSteps
                    )
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)
                }
                
                // Current step content
                currentStepView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Navigation buttons
                if store.currentStep != .welcome && store.currentStep != .completion {
                    OnboardingNavigationBar(
                        canGoBack: store.canMoveToPreviousStep,
                        canGoForward: store.canMoveToNextStep,
                        isOptionalStep: store.currentStep.isOptional,
                        isLoading: store.isLoading,
                        onBack: {
                            Task {
                                await store.moveToPreviousStep()
                            }
                        },
                        onNext: {
                            Task {
                                await store.moveToNextStep()
                            }
                        },
                        onSkip: {
                            Task {
                                await store.skipCurrentStep()
                            }
                        }
                    )
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xl)
                }
            }
            
            // Loading overlay
            if store.isLoading {
                LoadingView(message: "Saving your progress...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.background.opacity(0.8))
            }
        }
        .alert("Error", isPresented: .constant(store.error != nil), presenting: store.error) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
        .task {
            await store.loadProgress()
        }
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch store.currentStep {
        case .welcome:
            WelcomeView()
        case .weddingDetails:
            WeddingDetailsView()
        case .defaultSettings:
            DefaultSettingsView()
        case .featurePreferences:
            FeaturePreferencesView()
        case .guestImport:
            OnboardingGuestImportView()
        case .vendorImport:
            OnboardingVendorImportView()
        case .budgetSetup:
            BudgetSetupView()
        case .completion:
            CompletionView()
        }
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: OnboardingStep
    let completedSteps: Set<OnboardingStep>
    
    private var allSteps: [OnboardingStep] {
        OnboardingStep.allCases.filter { $0 != .welcome && $0 != .completion }
    }
    
    private var progress: Double {
        let currentIndex = allSteps.firstIndex(of: currentStep) ?? 0
        return Double(currentIndex) / Double(max(allSteps.count - 1, 1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Step indicator
            HStack(spacing: Spacing.xs) {
                ForEach(allSteps, id: \.self) { step in
                    stepIndicator(for: step)
                }
            }
            
            // Current step label
            Text(currentStep.title)
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress: \(currentStep.title)")
        .accessibilityValue("\(Int(progress * 100))% complete")
    }
    
    @ViewBuilder
    private func stepIndicator(for step: OnboardingStep) -> some View {
        let isCompleted = completedSteps.contains(step)
        let isCurrent = step == currentStep
        
        RoundedRectangle(cornerRadius: 2)
            .fill(isCompleted || isCurrent ? AppColors.primary : AppColors.textSecondary.opacity(0.3))
            .frame(height: 4)
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.3), value: isCompleted)
            .animation(.easeInOut(duration: 0.3), value: isCurrent)
    }
}

// MARK: - Navigation Bar

struct OnboardingNavigationBar: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let isOptionalStep: Bool
    let isLoading: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Back button
            Button(action: onBack) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(Typography.bodyRegular)
                }
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(AppColors.cardBackground)
                .cornerRadius(8)
            }
            .disabled(!canGoBack || isLoading)
            .opacity(canGoBack ? 1.0 : 0.5)
            .accessibilityLabel("Go back to previous step")
            .accessibilityHint(canGoBack ? "Returns to the previous onboarding step" : "Cannot go back from this step")
            
            Spacer()
            
            // Skip button (for optional steps)
            if isOptionalStep {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                }
                .disabled(isLoading)
                .accessibilityLabel("Skip this optional step")
                .accessibilityHint("Moves to the next step without completing this one")
            }
            
            // Next button
            Button(action: onNext) {
                HStack(spacing: Spacing.xs) {
                    Text("Continue")
                        .font(Typography.bodyRegular)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(canGoForward ? AppColors.primary : AppColors.textSecondary.opacity(0.5))
                .cornerRadius(8)
            }
            .disabled(!canGoForward || isLoading)
            .accessibilityLabel("Continue to next step")
            .accessibilityHint(canGoForward ? "Proceeds to the next onboarding step" : "Complete required fields to continue")
        }
    }
}

// MARK: - Placeholder Views (for import steps)

struct GuestImportPlaceholderView: View {
    @Environment(\.onboardingStore) private var store
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)
            
            Text("Import Guest List")
                .font(Typography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text("You can import your guest list from a CSV or Excel file, or skip this step and add guests later.")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
            
            Text("Guest import functionality coming in Stage 4")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, Spacing.lg)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

struct VendorImportPlaceholderView: View {
    @Environment(\.onboardingStore) private var store
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "briefcase.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)
            
            Text("Import Vendor List")
                .font(Typography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text("You can import your vendor list from a CSV or Excel file, or skip this step and add vendors later.")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
            
            Text("Vendor import functionality coming in Stage 4")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, Spacing.lg)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

struct BudgetSetupPlaceholderView: View {
    @Environment(\.onboardingStore) private var store
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)
            
            Text("Budget Setup")
                .font(Typography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Set up your wedding budget with categories and allocations, or skip this step and configure it later.")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
            
            Text("Budget wizard coming in Stage 4")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, Spacing.lg)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Preview

#Preview("Onboarding Container") {
    OnboardingContainerView()
}

#Preview("Progress Bar") {
    OnboardingProgressBar(
        currentStep: .weddingDetails,
        completedSteps: [.welcome]
    )
    .padding()
}

#Preview("Navigation Bar") {
    OnboardingNavigationBar(
        canGoBack: true,
        canGoForward: true,
        isOptionalStep: false,
        isLoading: false,
        onBack: {},
        onNext: {},
        onSkip: {}
    )
    .padding()
}
