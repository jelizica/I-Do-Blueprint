//
//  ExpenseCategoriesSummaryCards.swift
//  I Do Blueprint
//
//  Summary cards for Expense Categories page showing key metrics
//  Follows pattern from BudgetOverviewSummaryCards
//

import SwiftUI

struct ExpenseCategoriesSummaryCards: View {
    let windowSize: WindowSize
    let totalCategories: Int
    let totalAllocated: Double
    let totalSpent: Double
    let overBudgetCount: Int

    var body: some View {
        switch windowSize {
        case .compact:
            compactLayout
        case .regular, .large:
            regularLayout
        }
    }
    
    // MARK: - Compact Layout (Adaptive Grid)
    
    private var compactLayout: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 140, maximum: 200), spacing: Spacing.sm)
        ], spacing: Spacing.sm) {
            ExpenseCategoriesCompactCard(
                title: "Categories",
                value: Double(totalCategories),
                icon: "folder.fill",
                color: .purple,
                formatAsCurrency: false
            )
            
            ExpenseCategoriesCompactCard(
                title: "Allocated",
                value: totalAllocated,
                icon: "dollarsign.circle",
                color: AppColors.Budget.allocated
            )
            
            ExpenseCategoriesCompactCard(
                title: "Spent",
                value: totalSpent,
                icon: "creditcard.fill",
                color: AppColors.Budget.pending
            )
            
            ExpenseCategoriesCompactCard(
                title: "Over Budget",
                value: Double(overBudgetCount),
                icon: "exclamationmark.triangle.fill",
                color: AppColors.Budget.overBudget,
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
                title: "Total Categories",
                value: Double(totalCategories),
                icon: "folder.fill",
                color: .purple,
                formatAsCurrency: false
            )

            SummaryCardView(
                title: "Total Allocated",
                value: totalAllocated,
                icon: "dollarsign.circle",
                color: AppColors.Budget.allocated
            )

            SummaryCardView(
                title: "Total Spent",
                value: totalSpent,
                icon: "creditcard.fill",
                color: AppColors.Budget.pending
            )

            SummaryCardView(
                title: "Over Budget",
                value: Double(overBudgetCount),
                icon: "exclamationmark.triangle.fill",
                color: AppColors.Budget.overBudget,
                formatAsCurrency: false
            )
        }
    }
}

// MARK: - Expense Categories Compact Card

/// Compact card specifically for expense categories metrics
/// Matches the design from BudgetOverviewCompactCard
private struct ExpenseCategoriesCompactCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    var formatAsCurrency: Bool = true
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon with background circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                // Title: size 9, uppercase
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                    .lineLimit(1)
                
                // Value: size 14, bold, rounded
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

// MARK: - Preview

#Preview("Regular") {
    ExpenseCategoriesSummaryCards(
        windowSize: .regular,
        totalCategories: 36,
        totalAllocated: 50000,
        totalSpent: 42500,
        overBudgetCount: 3
    )
    .padding()
    .frame(width: 900)
}

#Preview("Compact") {
    ExpenseCategoriesSummaryCards(
        windowSize: .compact,
        totalCategories: 36,
        totalAllocated: 50000,
        totalSpent: 42500,
        overBudgetCount: 3
    )
    .padding()
    .frame(width: 640)
}
