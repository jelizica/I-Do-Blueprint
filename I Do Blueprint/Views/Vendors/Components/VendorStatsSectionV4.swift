//
//  VendorStatsSectionV4.swift
//  I Do Blueprint
//
//  Premium glassmorphism stats cards with circular progress indicator
//

import SwiftUI

struct VendorStatsSectionV4: View {
    let windowSize: WindowSize
    let vendors: [Vendor]

    private var activeVendors: [Vendor] {
        vendors.filter { !$0.isArchived }
    }

    private var bookedVendors: [Vendor] {
        vendors.filter { $0.isBooked == true && !$0.isArchived }
    }

    private var availableVendors: [Vendor] {
        vendors.filter { $0.isBooked != true && !$0.isArchived }
    }

    private var totalQuoted: Double {
        activeVendors.reduce(0) { $0 + ($1.quotedAmount ?? 0) }
    }

    private var budgetPercentage: Double {
        // Calculate percentage of budget used (assume 100k total for demo)
        let totalBudget: Double = 100_000
        return min((totalQuoted / totalBudget) * 100, 100)
    }

    var body: some View {
        if windowSize == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }

    // MARK: - Compact Layout (2x2 grid)

    private var compactLayout: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                StatCardV4(
                    title: "Total Vendors",
                    value: "\(activeVendors.count)",
                    icon: "building.2.fill",
                    iconColor: SemanticColors.primaryAction
                )

                BudgetStatCardV4(
                    title: "Budget Quoted",
                    value: formatCurrency(totalQuoted),
                    percentage: budgetPercentage,
                    progressColor: AppGradients.sageGreen
                )
            }

            HStack(spacing: Spacing.md) {
                StatCardV4(
                    title: "Booked",
                    value: "\(bookedVendors.count)",
                    icon: "checkmark.seal.fill",
                    iconColor: SemanticColors.statusSuccess
                )

                StatCardV4(
                    title: "Considering",
                    value: "\(availableVendors.count)",
                    icon: "clock.fill",
                    iconColor: SemanticColors.statusPending
                )
            }
        }
    }

    // MARK: - Regular Layout (horizontal row)

    private var regularLayout: some View {
        HStack(spacing: Spacing.lg) {
            StatCardV4(
                title: "Total Vendors",
                value: "\(activeVendors.count)",
                icon: "building.2.fill",
                iconColor: SemanticColors.primaryAction
            )

            BudgetStatCardV4(
                title: "Budget Quoted",
                value: formatCurrency(totalQuoted),
                percentage: budgetPercentage,
                progressColor: AppGradients.sageGreen
            )

            StatCardV4(
                title: "Booked",
                value: "\(bookedVendors.count)",
                icon: "checkmark.seal.fill",
                iconColor: SemanticColors.statusSuccess
            )

            StatCardV4(
                title: "Considering",
                value: "\(availableVendors.count)",
                icon: "clock.fill",
                iconColor: SemanticColors.statusPending
            )
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

// MARK: - Standard Stat Card

struct StatCardV4: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Icon badge
            Circle()
                .fill(iconColor.opacity(Opacity.light))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Text(value)
                    .font(Typography.displayMedium)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: 0)
        .padding(Spacing.sm)
    }
}

// MARK: - Budget Stat Card with Circular Progress

struct BudgetStatCardV4: View {
    let title: String
    let value: String
    let percentage: Double
    let progressColor: Color

    @State private var isHovered = false
    @State private var animatedPercentage: Double = 0

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Circular progress indicator
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        progressColor.opacity(0.2),
                        lineWidth: 6
                    )

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedPercentage / 100)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(
                            lineWidth: 6,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedPercentage)

                // Percentage text
                Text("\(Int(percentage))%")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Text(value)
                    .font(Typography.displayMedium)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: 0)
        .padding(Spacing.sm)
        .onAppear {
            // Animate the progress on appear
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedPercentage = percentage
            }
        }
        .onChange(of: percentage) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedPercentage = newValue
            }
        }
    }
}
