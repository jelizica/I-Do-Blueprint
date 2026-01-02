// Extracted from BudgetDevelopmentView.swift

import SwiftUI

struct BudgetSummaryCardsSection: View {
    let windowSize: WindowSize
    let totalWithoutTax: Double
    let totalTax: Double
    let totalWithTax: Double

    var body: some View {
        Group {
            if windowSize == .compact {
                // Compact: Use smaller inline cards in horizontal layout
                compactLayout
            } else {
                // Regular/Large: Full-size horizontal cards
                HStack(spacing: 16) {
                    SummaryCardView(
                        title: "Total Without Tax",
                        value: totalWithoutTax,
                        icon: "dollarsign.circle",
                        color: AppColors.Budget.allocated)

                    SummaryCardView(
                        title: "Total Tax",
                        value: totalTax,
                        icon: "percent",
                        color: AppColors.Budget.pending)

                    SummaryCardView(
                        title: "Total With Tax",
                        value: totalWithTax,
                        icon: "calculator",
                        color: AppColors.Budget.income)
                }
            }
        }
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        // Use adaptive grid that prefers 3 columns, then 2, then 1
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 140, maximum: 200), spacing: Spacing.sm)
        ], spacing: Spacing.sm) {
            BudgetCompactCard(
                title: "Without Tax",
                value: totalWithoutTax,
                icon: "dollarsign.circle",
                color: AppColors.Budget.allocated
            )
            
            BudgetCompactCard(
                title: "Tax",
                value: totalTax,
                icon: "percent",
                color: AppColors.Budget.pending
            )
            
            BudgetCompactCard(
                title: "With Tax",
                value: totalWithTax,
                icon: "calculator",
                color: AppColors.Budget.income
            )
        }
    }
}

// MARK: - Budget Compact Card

/// A smaller, inline version of SummaryCardView specifically for budget development compact mode
private struct BudgetCompactCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Smaller icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                    .lineLimit(1)
                
                Text(formatCurrency(value))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.03), color.opacity(0.01)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(isHovered ? 0.3 : 0.1), lineWidth: 1)
                )
        )
        .shadow(
            color: color.opacity(0.05),
            radius: 3,
            x: 0,
            y: 1
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
