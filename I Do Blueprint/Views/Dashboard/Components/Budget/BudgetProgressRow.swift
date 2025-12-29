//
//  BudgetProgressRow.swift
//  I Do Blueprint
//
//  Extracted from DashboardViewV4.swift
//  Progress bar row showing budget category with amount and visual progress
//

import SwiftUI

struct BudgetProgressRow: View {
    let label: String
    let amount: Double
    let total: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)

                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("$\(formatAmount(amount))")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.borderLight)
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }

    private var progressPercentage: CGFloat {
        guard total > 0 else { return 0 }
        return min(CGFloat(amount / total), 1.0)
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}
