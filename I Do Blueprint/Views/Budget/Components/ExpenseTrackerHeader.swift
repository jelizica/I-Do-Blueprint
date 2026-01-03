import SwiftUI

/// Header component for Expense Tracker with title and stats cards
struct ExpenseTrackerHeader: View {
    let totalSpent: Double
    let pendingAmount: Double
    let paidAmount: Double
    let expenseCount: Int
    let onAddExpense: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Expense Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button(action: onAddExpense) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Expense")
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(AppColors.Budget.allocated)
                    .foregroundColor(SemanticColors.textPrimary)
                    .cornerRadius(8)
                }
            }

            // Stats Cards - Using Component Library
            StatsGridView(
                stats: [
                    StatItem(
                        icon: "dollarsign.circle.fill",
                        label: "Total Spent",
                        value: String(format: "$%.2f", totalSpent),
                        color: AppColors.Budget.expense
                    ),
                    StatItem(
                        icon: "clock.fill",
                        label: "Pending",
                        value: String(format: "$%.2f", pendingAmount),
                        color: AppColors.Budget.pending
                    ),
                    StatItem(
                        icon: "checkmark.circle.fill",
                        label: "Paid",
                        value: String(format: "$%.2f", paidAmount),
                        color: AppColors.Budget.income
                    ),
                    StatItem(
                        icon: "doc.text.fill",
                        label: "Total Expenses",
                        value: "\(expenseCount)",
                        color: .purple
                    )
                ],
                columns: 4
            )
        }
    }
}

// Note: ExpenseStatCard replaced with StatsGridView from component library
