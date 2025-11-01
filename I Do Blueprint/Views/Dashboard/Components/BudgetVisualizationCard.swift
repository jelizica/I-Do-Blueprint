//
//  BudgetVisualizationCard.swift
//  My Wedding Planning App
//
//  Extracted from DashboardViewV2.swift
//

import SwiftUI

struct BudgetVisualizationCard: View {
    let totalBudget: Double
    let spent: Double
    let remaining: Double
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        HStack(spacing: 0) {
            // Left side - Text info
            VStack(alignment: .leading, spacing: 16) {
                Text("Wedding Budget —")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(foregroundColor.opacity(0.7))

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(foregroundColor.opacity(0.6))
                    Text("\(Int(remaining))")
                        .font(.system(size: 52, weight: .black))
                        .foregroundColor(foregroundColor)
                }

                Text("Remaining Budget")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(foregroundColor.opacity(0.8))

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.system(size: 11))
                            .foregroundColor(foregroundColor.opacity(0.5))
                        Text("$\(Int(totalBudget))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(foregroundColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent")
                            .font(.system(size: 11))
                            .foregroundColor(foregroundColor.opacity(0.5))
                        Text("$\(Int(spent))")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(foregroundColor)
                    }
                }
            }
            .padding(Spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side - Visual element
            VStack {
                Spacer()
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(foregroundColor.opacity(0.1))
                        .frame(width: 120)

                    Rectangle()
                        .fill(AppColors.Dashboard.rsvpCard)
                        .frame(width: 120, height: CGFloat(spent / totalBudget * 240))
                }
                .frame(height: 240)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(AppColors.textPrimary, lineWidth: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Budget overview")
        .accessibilityValue(budgetAccessibilityDescription)
    }

    private var budgetAccessibilityDescription: String {
        let percentSpent = (spent / totalBudget * 100).rounded()
        return """
        Total budget: \(Int(totalBudget)) dollars, \
        Spent: \(Int(spent)) dollars, \
        Remaining: \(Int(remaining)) dollars, \
        \(Int(percentSpent)) percent of budget used
        """
    }
}
