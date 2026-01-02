//
//  BudgetOverviewSummaryCards.swift
//  I Do Blueprint
//
//  Created by Claude on 10/9/25.
//

import SwiftUI

struct BudgetOverviewSummaryCards: View {
    let windowSize: WindowSize
    let totalBudget: Double
    let totalExpenses: Double
    let totalRemaining: Double
    let itemCount: Int

    var body: some View {
        switch windowSize {
        case .compact:
            compactLayout
        case .regular, .large:
            regularLayout
        }
    }
    
    // MARK: - Compact Layout (Adaptive Grid - fits as many as possible)
    
    private var compactLayout: some View {
        // Use adaptive grid like Budget Builder - fits as many cards as possible
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 140, maximum: 200), spacing: Spacing.sm)
        ], spacing: Spacing.sm) {
            BudgetOverviewCompactCard(
                title: "Budget",
                value: totalBudget,
                icon: "dollarsign.circle",
                color: AppColors.Budget.allocated
            )
            
            BudgetOverviewCompactCard(
                title: "Expenses",
                value: totalExpenses,
                icon: "receipt",
                color: AppColors.Budget.pending
            )
            
            BudgetOverviewCompactCard(
                title: "Remaining",
                value: totalRemaining,
                icon: "target",
                color: totalRemaining >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget
            )
            
            BudgetOverviewCompactCard(
                title: "Items",
                value: Double(itemCount),
                icon: "list.bullet",
                color: .purple,
                formatAsCurrency: false
            )
        }
    }
    
    // MARK: - Regular Layout (4-Column)
    
    private var regularLayout: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            SummaryCardView(
                title: "Total Budget",
                value: totalBudget,
                icon: "dollarsign.circle",
                color: AppColors.Budget.allocated)

            SummaryCardView(
                title: "Total Expenses",
                value: totalExpenses,
                icon: "receipt",
                color: AppColors.Budget.pending)

            SummaryCardView(
                title: "Remaining",
                value: totalRemaining,
                icon: "target",
                color: totalRemaining >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget)

            SummaryCardView(
                title: "Budget Items",
                value: Double(itemCount),
                icon: "list.bullet",
                color: .purple,
                formatAsCurrency: false)
        }
    }
}

// MARK: - Budget Overview Compact Card

/// A smaller, inline version of SummaryCardView specifically for budget overview compact mode
/// Matches the text sizes from BudgetSummaryCardsSection.swift (Budget Builder)
private struct BudgetOverviewCompactCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    var formatAsCurrency: Bool = true
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Smaller icon with background circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                // Title: matches Budget Builder - size 9, uppercase
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                    .lineLimit(1)
                
                // Value: matches Budget Builder - size 14, bold, rounded
                Text(formattedValue)
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
    
    private var formattedValue: String {
        if formatAsCurrency {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            formatter.groupingSeparator = ","
            formatter.usesGroupingSeparator = true
            return formatter.string(from: NSNumber(value: value)) ?? "$0"
        } else {
            return String(format: "%.0f", value)
        }
    }
}
