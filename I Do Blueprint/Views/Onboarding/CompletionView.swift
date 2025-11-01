//
//  CompletionView.swift
//  I Do Blueprint
//
//  Completion screen for onboarding
//

import SwiftUI

struct CompletionView: View {
    @Environment(\.onboardingStore) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isCompleting = false
    
    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()
            
            // Success animation/icon
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.success)
            }
            .accessibilityLabel("Setup complete")
            
            // Success message
            VStack(spacing: Spacing.md) {
                Text("All Set!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Your wedding planning journey begins now")
                    .font(Typography.bodyLarge)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Summary
            VStack(spacing: Spacing.md) {
                let details = store.weddingDetails
                if !details.partner1Name.isEmpty && !details.partner2Name.isEmpty {
                    SummaryRow(
                        icon: "heart.fill",
                        title: "Partners",
                        value: "\(details.partner1Name) & \(details.partner2Name)"
                    )
                }
                
                if let date = details.weddingDate {
                    SummaryRow(
                        icon: "calendar",
                        title: "Wedding Date",
                        value: formatDate(date)
                    )
                }
                
                if !details.venue.isEmpty {
                    SummaryRow(
                        icon: "mappin.circle.fill",
                        title: "Venue",
                        value: details.venue
                    )
                }
                
                SummaryRow(
                    icon: "dollarsign.circle.fill",
                    title: "Currency",
                    value: store.defaultSettings.currency
                )
            }
            .padding(Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, Spacing.xl)
            
            // Next steps
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Next Steps")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)
                
                NextStepItem(
                    icon: "list.bullet",
                    title: "Explore your dashboard",
                    description: "See an overview of your wedding planning progress"
                )
                
                NextStepItem(
                    icon: "person.2.fill",
                    title: "Add guests",
                    description: "Build your guest list and track RSVPs"
                )
                
                NextStepItem(
                    icon: "briefcase.fill",
                    title: "Find vendors",
                    description: "Connect with vendors and manage contracts"
                )
                
                NextStepItem(
                    icon: "checkmark.circle",
                    title: "Create tasks",
                    description: "Stay organized with your wedding to-do list"
                )
            }
            .padding(.horizontal, Spacing.xl)
            
            Spacer()
            
            // Go to dashboard button
            Button(action: {
                guard !isCompleting else { return }
                isCompleting = true
                
                Task {
                    // Complete onboarding
                    await store.completeOnboarding()
                    
                    // Give SwiftUI a moment to process the state change
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    
                    // The RootFlowView should now detect isCompleted = true and transition
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    Text("Go to Dashboard")
                        .font(Typography.bodyLarge)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: 400)
                .padding(.vertical, Spacing.lg)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
            .accessibilityLabel("Go to dashboard")
            .accessibilityHint("Completes onboarding and navigates to the main dashboard")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .task {
            // Automatically complete onboarding when this view appears
            if !store.isCompleted {
                await store.completeOnboarding()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(value)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Next Step Item

struct NextStepItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.bodyRegular)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(description)
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(description)
    }
}

// MARK: - Preview

#Preview("Completion View") {
    CompletionView()
}

#Preview("Summary Row") {
    SummaryRow(
        icon: "heart.fill",
        title: "Partners",
        value: "Alice & Bob"
    )
    .padding()
}

#Preview("Next Step Item") {
    NextStepItem(
        icon: "list.bullet",
        title: "Explore your dashboard",
        description: "See an overview of your wedding planning progress"
    )
    .padding()
}
