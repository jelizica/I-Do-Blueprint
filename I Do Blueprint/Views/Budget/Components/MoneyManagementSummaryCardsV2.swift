//
//  MoneyManagementSummaryCardsV2.swift
//  I Do Blueprint
//
//  Summary cards for Money Management page with 120px height pattern
//  Follows BudgetOverviewSummaryCards and AffordabilitySummaryHeroSection patterns
//  with glassmorphism styling
//

import SwiftUI

struct MoneyManagementSummaryCardsV2: View {
    let windowSize: WindowSize
    let totalContributions: Double
    let giftsReceived: Double
    let pledgedAmount: Double
    let goalProgress: Double
    let contributorCount: Int
    let giftItemCount: Int
    let goalAmount: Double

    var body: some View {
        if windowSize == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }

    // MARK: - Compact Layout (2x2 grid matching GuestStatsSection)

    private var compactLayout: some View {
        VStack(spacing: Spacing.lg) {
            // Row 1: Total Contributions + Goal Progress
            HStack(spacing: Spacing.lg) {
                MoneyManagementStatCardV2(
                    title: "Total Contributions",
                    value: formatCurrency(totalContributions),
                    subtitle: "From \(contributorCount) contributors",
                    subtitleColor: SemanticColors.textSecondary,
                    icon: "hand.raised.fill"
                )

                MoneyManagementStatCardV2(
                    title: "Goal Progress",
                    value: "\(Int(goalProgress * 100))%",
                    subtitle: "of goal reached",
                    subtitleColor: goalProgress > 0.75 ? SemanticColors.success : SemanticColors.textSecondary,
                    icon: "target"
                )
            }

            // Row 2: Gifts Received + Pledged
            HStack(spacing: Spacing.lg) {
                MoneyManagementStatCardV2(
                    title: "Gifts Received",
                    value: formatCurrency(giftsReceived),
                    subtitle: "\(giftItemCount) items",
                    subtitleColor: BlushPink.shade500,
                    icon: "gift.fill"
                )

                MoneyManagementStatCardV2(
                    title: "Pledged",
                    value: formatCurrency(pledgedAmount),
                    subtitle: "pending",
                    subtitleColor: Terracotta.shade500,
                    icon: "clock.arrow.circlepath"
                )
            }
        }
    }

    // MARK: - Regular Layout (Matching BudgetOverviewSummaryCards style)

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Total Contributions - narrower card with large number (160px)
            MoneyTotalCard(
                amount: totalContributions,
                contributorCount: contributorCount
            )
            .frame(width: 160)

            // Goal Progress - main wide card with circular progress
            MoneyGoalProgressCard(
                current: totalContributions,
                goal: goalAmount,
                percentage: goalProgress
            )
            .frame(maxWidth: .infinity)

            // Stacked cards - Gifts Received + Pledged (180px)
            VStack(spacing: Spacing.md) {
                MoneySmallStatCard(
                    title: "GIFTS RECEIVED",
                    value: formatCurrency(giftsReceived),
                    icon: "gift.fill",
                    iconColor: BlushPink.shade500,
                    badge: "\(giftItemCount)"
                )

                MoneySmallStatCard(
                    title: "PLEDGED",
                    value: formatCurrency(pledgedAmount),
                    icon: "clock.arrow.circlepath",
                    iconColor: Terracotta.shade500,
                    badge: nil
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

// MARK: - Money Management Stat Card (Glassmorphism - Compact)

/// Stat card with glassmorphism styling matching BudgetOverviewStatCard
struct MoneyManagementStatCardV2: View {
    let title: String
    let value: String
    let subtitle: String?
    let subtitleColor: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text(value)
                        .font(Typography.displayMedium)
                        .foregroundColor(SemanticColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundColor(subtitleColor)
                    }
                }

                Spacer()

                NativeIconBadge(
                    systemName: icon,
                    color: SageGreen.shade500,
                    size: 40
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel()
    }
}

// MARK: - Money Total Card (Large Number with Contributor Count)

/// Large card showing total contributions with contributor count
/// Matches BudgetTotalCard style (160px width, 120px height)
struct MoneyTotalCard: View {
    let amount: Double
    let contributorCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header with icon
            HStack(spacing: Spacing.xs) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.textSecondary)

                Text("TOTAL")
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

            // Contributor count indicator
            HStack(spacing: Spacing.xs) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(SageGreen.shade500)

                Text("\(contributorCount) contributors")
                    .font(.system(size: 11))
                    .foregroundColor(SageGreen.shade500)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
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

// MARK: - Money Goal Progress Card (With Circular Progress)

/// Wide card showing goal progress with circular indicator
/// Matches BudgetProgressCard style (maxWidth, 120px height)
struct MoneyGoalProgressCard: View {
    let current: Double
    let goal: Double
    let percentage: Double

    @State private var animatedPercentage: Double = 0

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Left side: Labels and value
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Header with icon
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "target")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(progressColor)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(progressColor.opacity(0.15))
                        )

                    Text("GOAL PROGRESS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(SemanticColors.textSecondary)
                        .tracking(0.5)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                // Large percentage
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                // Subtitle with amounts
                Text("\(formatCurrency(current)) of \(formatCurrency(goal))")
                    .font(.system(size: 11))
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }

            Spacer()

            // Right side: Circular progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        progressColor.opacity(0.2),
                        lineWidth: 6
                    )

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedPercentage)
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
                Image(systemName: "target")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(progressColor)
            }
            .frame(width: 60, height: 60)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: 0)
        .onAppear {
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

    /// Color based on progress status
    private var progressColor: Color {
        if percentage >= 1.0 {
            return SemanticColors.success
        } else if percentage > 0.75 {
            return SageGreen.shade500
        } else if percentage > 0.5 {
            return BlushPink.shade500
        } else {
            return Terracotta.shade500
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

// MARK: - Money Small Stat Card

/// Small stat card for stacked layout (52px height)
/// Matches BudgetSmallStatCard style
struct MoneySmallStatCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let badge: String?

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

            // Optional badge
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(iconColor)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(iconColor.opacity(0.15))
                    )
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 52)
        .glassPanel(cornerRadius: CornerRadius.lg, padding: 0)
    }
}
