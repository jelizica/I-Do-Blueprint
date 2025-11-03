//
//  CategoryHeaderComponents.swift
//  I Do Blueprint
//
//  Header and stats components for budget category detail view
//

import SwiftUI

// MARK: - Category Header View

struct CategoryHeaderView: View {
    let category: BudgetCategory

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Category color
                Circle()
                    .fill(Color(hex: category.color) ?? AppColors.Budget.allocated)
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.categoryName)
                        .font(.title)
                        .fontWeight(.bold)

                    if let description = category.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(NumberFormatter.currency.string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.Budget.allocated)

                    Text("Budget Allocated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Priority and status badges
            HStack {
                PriorityBadge(priority: category.priority)

                if category.isEssential {
                    StatusBadge(text: "Essential", color: AppColors.Budget.income)
                }

                if category.isOverBudget {
                    StatusBadge(text: "Over Budget", color: AppColors.Budget.overBudget)
                }

                Spacer()

                Text("Updated \(category.updatedAt ?? category.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Category Stats View

struct ExpenseStats {
    let total: Int
    let pending: Int
    let paid: Int
    let overdue: Int
}

struct CategoryStatsView: View {
    let category: BudgetCategory
    let expenses: [Expense]

    private var expenseStats: ExpenseStats {
        let total = expenses.count
        let pending = expenses.filter { $0.paymentStatus == .pending }.count
        let paid = expenses.filter { $0.paymentStatus == .paid }.count
        let overdue = expenses.filter(\.isOverdue).count
        return ExpenseStats(total: total, pending: pending, paid: paid, overdue: overdue)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Budget progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Budget Progress")
                        .font(.headline)

                    Spacer()

                    Text("\(Int(category.percentageSpent))% spent")
                        .font(.subheadline)
                        .foregroundColor(category.isOverBudget ? AppColors.Budget.overBudget : .secondary)
                }

                ProgressView(value: min(category.percentageSpent / 100, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: category.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.allocated))
                    .scaleEffect(x: 1, y: 3, anchor: .center)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(NumberFormatter.currency.string(from: NSNumber(value: category.spentAmount)) ?? "$0")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(category.isOverBudget ? AppColors.Budget.overBudget : .primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(NumberFormatter.currency.string(from: NSNumber(value: category.remainingAmount)) ?? "$0")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(category.remainingAmount >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget)
                    }
                }
            }

            Divider()

            // Expense stats
            HStack(spacing: 20) {
                BudgetStatItem(
                    title: "Total Expenses",
                    value: "\(expenseStats.total)",
                    icon: "doc.text.fill",
                    color: AppColors.Budget.allocated)

                BudgetStatItem(
                    title: "Pending",
                    value: "\(expenseStats.pending)",
                    icon: "clock.fill",
                    color: AppColors.Budget.pending)

                BudgetStatItem(
                    title: "Paid",
                    value: "\(expenseStats.paid)",
                    icon: "checkmark.circle.fill",
                    color: AppColors.Budget.income)

                if expenseStats.overdue > 0 {
                    BudgetStatItem(
                        title: "Overdue",
                        value: "\(expenseStats.overdue)",
                        icon: "exclamationmark.triangle.fill",
                        color: AppColors.Budget.overBudget)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Budget Stat Item

struct BudgetStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

