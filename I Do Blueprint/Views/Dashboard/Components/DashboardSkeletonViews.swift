//
//  DashboardSkeletonViews.swift
//  I Do Blueprint
//
//  Skeleton loading views for dashboard cards
//

import SwiftUI

// MARK: - Hero Skeleton

struct DashboardHeroSkeleton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(SemanticColors.backgroundSecondary)
            .frame(height: 180)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(SemanticColors.borderPrimaryLight)
                    .opacity(0.6)
                    .shimmer()
            )
            .accessibilityIdentifier("dashboard.skeleton.hero")
            .accessibilityHidden(true)
    }
}

// MARK: - Budget Card Skeleton

struct DashboardBudgetCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 6)
                .fill(SemanticColors.borderPrimaryLight)
                .frame(width: 140, height: 14)
                .shimmer()
            ForEach(0..<4, id: \.self) { _ in
                BudgetItemSkeleton()
            }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .shadow(color: SemanticColors.shadowLight, radius: 2, x: 0, y: 1)
        .accessibilityIdentifier("dashboard.skeleton.budget")
        .accessibilityHidden(true)
    }
}

// MARK: - Tasks Card Skeleton

struct DashboardTasksCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 6)
                .fill(SemanticColors.borderPrimaryLight)
                .frame(width: 120, height: 14)
                .shimmer()
            ForEach(0..<5, id: \.self) { _ in
                TaskCardSkeleton()
            }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .shadow(color: SemanticColors.shadowLight, radius: 2, x: 0, y: 1)
        .accessibilityIdentifier("dashboard.skeleton.tasks")
        .accessibilityHidden(true)
    }
}

// MARK: - Guests Card Skeleton

struct DashboardGuestsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 6)
                .fill(SemanticColors.borderPrimaryLight)
                .frame(width: 160, height: 14)
                .shimmer()
            ForEach(0..<6, id: \.self) { _ in
                GuestRowSkeleton()
            }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .shadow(color: SemanticColors.shadowLight, radius: 2, x: 0, y: 1)
        .accessibilityIdentifier("dashboard.skeleton.guests")
        .accessibilityHidden(true)
    }
}

// MARK: - Vendors Card Skeleton

struct DashboardVendorsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 6)
                .fill(SemanticColors.borderPrimaryLight)
                .frame(width: 140, height: 14)
                .shimmer()
            ForEach(0..<5, id: \.self) { _ in
                VendorCardSkeleton()
            }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .shadow(color: SemanticColors.shadowLight, radius: 2, x: 0, y: 1)
        .accessibilityIdentifier("dashboard.skeleton.vendors")
        .accessibilityHidden(true)
    }
}

// MARK: - Quick Actions Skeleton

struct DashboardQuickActionsSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.lg) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(spacing: Spacing.md) {
                    Circle()
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(width: 32, height: 32)
                        .shimmer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(width: 80, height: 12)
                        .shimmer()
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.lg)
                .background(SemanticColors.backgroundSecondary)
                .cornerRadius(CornerRadius.md)
            }
        }
        .accessibilityIdentifier("dashboard.skeleton.quickactions")
        .accessibilityHidden(true)
    }
}
