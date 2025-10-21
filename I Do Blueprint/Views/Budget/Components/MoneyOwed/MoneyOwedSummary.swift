//
//  MoneyOwedSummary.swift
//  I Do Blueprint
//
//  Summary components for money owed view
//

import SwiftUI

// MARK: - Money Owed Summary Section

struct MoneyOwedSummarySection: View {
    let totalOwed: Double
    let outstandingAmount: Double
    let overdueAmount: Double
    let pendingCount: Int
    let paidCount: Int
    let overdueCount: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Owed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(totalOwed, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.Budget.expense)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Outstanding")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(outstandingAmount, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.Budget.pending)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Overdue")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(overdueAmount, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.Budget.overBudget)
                }
            }

            // Status breakdown
            HStack(spacing: 20) {
                StatusCard(
                    title: "Pending",
                    count: pendingCount,
                    color: AppColors.Budget.pending)

                StatusCard(
                    title: "Paid",
                    count: paidCount,
                    color: AppColors.Budget.income)

                StatusCard(
                    title: "Overdue",
                    count: overdueCount,
                    color: AppColors.Budget.overBudget)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
