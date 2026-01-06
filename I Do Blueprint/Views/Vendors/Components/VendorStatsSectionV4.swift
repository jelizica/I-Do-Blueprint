//
//  VendorStatsSectionV4.swift
//  I Do Blueprint
//
//  Premium glassmorphism stats cards matching design mockup layout
//

import SwiftUI

struct VendorStatsSectionV4: View {
    let windowSize: WindowSize
    let vendors: [Vendor]
    /// Total budget from primary budget development scenario
    let totalBudget: Double

    private var activeVendors: [Vendor] {
        vendors.filter { !$0.isArchived }
    }

    private var bookedVendors: [Vendor] {
        vendors.filter { $0.isBooked == true && !$0.isArchived }
    }

    private var consideringVendors: [Vendor] {
        vendors.filter { $0.isBooked != true && !$0.isArchived }
    }

    private var totalQuoted: Double {
        activeVendors.reduce(0) { $0 + ($1.quotedAmount ?? 0) }
    }

    /// Calculate vendors added in the last 7 days
    private var vendorsAddedThisWeek: Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return activeVendors.filter { $0.createdAt >= oneWeekAgo }.count
    }

    private var budgetPercentage: Double {
        guard totalBudget > 0 else { return 0 }
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
                TotalVendorsCardV4(
                    count: activeVendors.count,
                    addedThisWeek: vendorsAddedThisWeek
                )

                BudgetQuotedCardV4(
                    quotedAmount: totalQuoted,
                    totalBudget: totalBudget,
                    percentage: budgetPercentage
                )
            }

            HStack(spacing: Spacing.md) {
                SmallStatCardV4(
                    title: "BOOKED",
                    value: bookedVendors.count,
                    icon: "checkmark.circle.fill",
                    iconColor: SemanticColors.statusSuccess
                )

                SmallStatCardV4(
                    title: "CONSIDERING",
                    value: consideringVendors.count,
                    icon: "clock.fill",
                    iconColor: SemanticColors.statusPending
                )
            }
        }
    }

    // MARK: - Regular Layout (matching mockup: 2 large left, 2 small stacked right)

    private var regularLayout: some View {
        HStack(spacing: Spacing.lg) {
            // Left side: Two large cards
            TotalVendorsCardV4(
                count: activeVendors.count,
                addedThisWeek: vendorsAddedThisWeek
            )
            .frame(maxWidth: .infinity)

            BudgetQuotedCardV4(
                quotedAmount: totalQuoted,
                totalBudget: totalBudget,
                percentage: budgetPercentage
            )
            .frame(maxWidth: .infinity)

            // Right side: Two small cards stacked
            VStack(spacing: Spacing.md) {
                SmallStatCardV4(
                    title: "BOOKED",
                    value: bookedVendors.count,
                    icon: "checkmark.circle.fill",
                    iconColor: SemanticColors.statusSuccess
                )

                SmallStatCardV4(
                    title: "CONSIDERING",
                    value: consideringVendors.count,
                    icon: "clock.fill",
                    iconColor: SemanticColors.statusPending
                )
            }
            .frame(width: 180)
        }
    }
}

// MARK: - Total Vendors Card (with trend line)

struct TotalVendorsCardV4: View {
    let count: Int
    let addedThisWeek: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with icon
            HStack(spacing: Spacing.sm) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textSecondary)

                Text("TOTAL VENDORS")
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textSecondary)
                    .tracking(0.5)

                Spacer()

                // Mini trend line (decorative)
                TrendLineView()
                    .frame(width: 60, height: 24)
            }

            // Large count
            Text("\(count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(SemanticColors.textPrimary)

            Spacer()

            // Trend indicator
            if addedThisWeek > 0 {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppGradients.weddingPink)

                    Text("+\(addedThisWeek) this week")
                        .font(Typography.caption)
                        .foregroundColor(AppGradients.weddingPink)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(height: 160)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: 0)
    }
}

// MARK: - Budget Quoted Card (with circular progress)

struct BudgetQuotedCardV4: View {
    let quotedAmount: Double
    let totalBudget: Double
    let percentage: Double

    @State private var animatedPercentage: Double = 0

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Left side: Labels and value
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header with icon
                HStack(spacing: Spacing.sm) {
                    Text("$")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SemanticColors.statusSuccess)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(SemanticColors.statusSuccess.opacity(0.15))
                        )

                    Text("BUDGET QUOTED")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.textSecondary)
                        .tracking(0.5)
                }

                // Large amount - single line, no wrap
                Text(formatCurrency(quotedAmount))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                // Subtitle
                Text("\(formatCurrency(totalBudget)) Total Budget")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()

            // Right side: Circular progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        AppGradients.weddingPink.opacity(0.2),
                        lineWidth: 8
                    )

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedPercentage / 100)
                    .stroke(
                        AppGradients.weddingPink,
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedPercentage)

                // Percentage text
                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SemanticColors.textPrimary)
            }
            .frame(width: 72, height: 72)
        }
        .padding(Spacing.lg)
        .frame(height: 160)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Small Stat Card (for Booked/Considering)

struct SmallStatCardV4: View {
    let title: String
    let value: Int
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .tracking(0.5)

                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(SemanticColors.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: CornerRadius.lg, padding: 0)
    }
}

// MARK: - Trend Line View (decorative mini chart)

struct TrendLineView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                // Simple upward trend line
                let points: [CGPoint] = [
                    CGPoint(x: 0, y: height * 0.7),
                    CGPoint(x: width * 0.25, y: height * 0.5),
                    CGPoint(x: width * 0.5, y: height * 0.6),
                    CGPoint(x: width * 0.75, y: height * 0.3),
                    CGPoint(x: width, y: height * 0.2)
                ]

                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(
                AppGradients.sageGreen,
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }
}
