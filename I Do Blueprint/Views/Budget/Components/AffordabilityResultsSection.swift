//
//  AffordabilityResultsSection.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-09.
//

import SwiftUI

struct AffordabilityResultsSection: View {
    let totalAffordableBudget: Double
    let alreadyPaid: Double
    let projectedSavings: Double
    let monthsLeft: Int
    let progressPercentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Affordability Results")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Your calculated wedding budget based on your inputs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Total Affordable Budget Card
            VStack(spacing: 16) {
                Text("Total Affordable Budget")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(formatCurrency(totalAffordableBudget))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), AppColors.Budget.allocated.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Summary Metrics
            HStack(spacing: 16) {
                // Already Paid
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(AppColors.Budget.income)
                        Text("Already Paid")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(formatCurrency(alreadyPaid))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Projected Savings
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(AppColors.Budget.allocated)
                        Text("Projected Savings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(formatCurrency(projectedSavings))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Progress Section
            HStack(spacing: 32) {
                // Months Left
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundStyle(AppColors.Budget.pending)
                        Text("Months Left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(monthsLeft)")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(String(format: "%.1f", progressPercentage))%")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Informational Note
            HStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppColors.Budget.allocated)

                Text("This calculation includes payments already made, projected monthly savings, and additional contributions from gifts and external sources.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding(16)
            .background(AppColors.Budget.allocated.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
