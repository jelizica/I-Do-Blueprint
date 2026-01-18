//
//  BudgetSummaryCardsSection.swift
//  I Do Blueprint
//
//  Summary stats cards for Budget Development using glassmorphism styling
//  Follows BudgetOverviewSummaryCards pattern with glassPanel() modifier
//

import SwiftUI

struct BudgetSummaryCardsSection: View {
    let windowSize: WindowSize
    let totalWithoutTax: Double
    let totalTax: Double
    let totalWithTax: Double

    var body: some View {
        if windowSize == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }

    // MARK: - Compact Layout (Adaptive grid matching BudgetOverviewSummaryCards)

    private var compactLayout: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 140, maximum: 200), spacing: Spacing.sm)
        ], spacing: Spacing.sm) {
            BudgetDevelopmentCompactCard(
                title: "Without Tax",
                value: totalWithoutTax,
                icon: "dollarsign.circle",
                color: AppColors.Budget.allocated
            )

            BudgetDevelopmentCompactCard(
                title: "Tax",
                value: totalTax,
                icon: "percent",
                color: AppColors.Budget.pending
            )

            BudgetDevelopmentCompactCard(
                title: "With Tax",
                value: totalWithTax,
                icon: "calculator",
                color: AppColors.Budget.income
            )
        }
    }

    // MARK: - Regular Layout (Matching BudgetOverviewSummaryCards: large card + stacked cards)

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Total With Tax - main wide card with large number (the final total)
            BudgetDevelopmentTotalCard(
                title: "TOTAL WITH TAX",
                amount: totalWithTax,
                icon: "calculator"
            )
            .frame(maxWidth: .infinity)

            // Stacked cards - Without Tax (top) + Tax Amount (bottom)
            VStack(spacing: Spacing.md) {
                BudgetDevelopmentStatCard(
                    title: "WITHOUT TAX",
                    value: formatCurrency(totalWithoutTax),
                    icon: "dollarsign.circle.fill",
                    iconColor: AppColors.Budget.allocated
                )

                BudgetDevelopmentStatCard(
                    title: "TAX AMOUNT",
                    value: formatCurrency(totalTax),
                    icon: "percent",
                    iconColor: AppColors.Budget.pending
                )
            }
            .frame(width: 180)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Budget Development Compact Card

/// Compact card with glassmorphism styling for Budget Development
/// Matches BudgetOverviewStatCard pattern
private struct BudgetDevelopmentCompactCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon with circle background
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                    .lineLimit(1)

                Text(formatCurrency(value))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44)
        .glassPanel(cornerRadius: CornerRadius.md, padding: 0)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Budget Development Total Card

/// Large card showing main total amount with glassmorphism styling
/// Matches BudgetTotalCard pattern from BudgetOverviewSummaryCards
private struct BudgetDevelopmentTotalCard: View {
    let title: String
    let amount: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header with icon
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.textSecondary)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .tracking(0.5)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }

            // Large amount
            Text(formatCurrency(amount))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(SemanticColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: 0)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Budget Development Stat Card

/// Small stat card for stacked layout with glassmorphism styling
/// Matches BudgetSmallStatCard pattern from BudgetOverviewSummaryCards
private struct BudgetDevelopmentStatCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .tracking(0.5)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 52)
        .glassPanel(cornerRadius: CornerRadius.lg, padding: 0)
    }
}
