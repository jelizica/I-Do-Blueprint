//
//  BudgetTableRow.swift
//  I Do Blueprint
//
//  Created by Claude on 10/9/25.
//

import SwiftUI

struct BudgetTableRow: View {
    let item: BudgetOverviewItem
    let onAddExpense: () -> Void
    let onAddGift: () -> Void
    let onRemoveExpense: (String) -> Void
    let onRemoveGift: (String) -> Void

    @State private var isExpanded = false

    private var categoryColor: Color {
        CategoryIcons.color(for: item.category)
    }

    private var categoryIcon: String {
        CategoryIcons.icon(for: item.category)
    }

    private var remaining: Double {
        item.budgeted - (item.effectiveSpent ?? 0)
    }

    private var remainingColor: Color {
        remaining >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    // Item name
                    HStack(spacing: 8) {
                        Image(systemName: categoryIcon)
                            .font(.caption)
                            .foregroundColor(categoryColor)
                            .frame(width: 20)

                        Text(item.itemName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                    .frame(width: 200, alignment: .leading)

                    // Category
                    HStack(spacing: 6) {
                        Circle()
                            .fill(categoryColor)
                            .frame(width: 6, height: 6)
                        Text(item.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 120, alignment: .leading)

                    Spacer()

                    // Budgeted
                    Text(formatCurrency(item.budgeted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .trailing)

                    // Spent
                    Text(formatCurrency(item.effectiveSpent ?? 0))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(categoryColor)
                        .frame(width: 100, alignment: .trailing)

                    // Remaining
                    Text(formatCurrency(remaining))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(remainingColor)
                        .frame(width: 100, alignment: .trailing)

                    // Menu
                    Menu {
                        Button {
                            onAddExpense()
                        } label: {
                            Label("Add Expense", systemImage: "plus.circle")
                        }

                        Button {
                            onAddGift()
                        } label: {
                            Label("Add Gift", systemImage: "gift")
                        }

                        if !item.expenses.isEmpty || !item.gifts.isEmpty {
                            Divider()

                            if !item.expenses.isEmpty {
                                if item.expenses.count == 1, let expense = item.expenses.first {
                                    Button {
                                        onRemoveExpense(expense.id)
                                    } label: {
                                        Label("Unlink Expense", systemImage: "minus.circle")
                                    }
                                } else {
                                    Menu("Unlink Expense") {
                                        ForEach(item.expenses, id: \.id) { expense in
                                            Button("Unlink \(expense.title)") {
                                                onRemoveExpense(expense.id)
                                            }
                                        }
                                    }
                                }
                            }

                            if !item.gifts.isEmpty {
                                if item.gifts.count == 1, let gift = item.gifts.first {
                                    Button {
                                        onRemoveGift(gift.id)
                                    } label: {
                                        Label("Unlink Gift", systemImage: "gift.fill")
                                    }
                                } else {
                                    Menu("Unlink Gift") {
                                        ForEach(item.gifts, id: \.id) { gift in
                                            Button("Unlink \(gift.title)") {
                                                onRemoveGift(gift.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                    .buttonStyle(.plain)
                    .menuStyle(.borderlessButton)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content - linked items
            if isExpanded && (!item.expenses.isEmpty || !item.gifts.isEmpty) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LINKED ITEMS")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.huge)

                    VStack(spacing: 4) {
                        ForEach(item.expenses, id: \.id) { expense in
                            HStack(spacing: 12) {
                                Image(systemName: "creditcard.fill")
                                    .font(.caption)
                                    .foregroundColor(AppColors.Budget.allocated)
                                    .frame(width: 20)

                                Text(expense.title)
                                    .font(.caption)
                                    .lineLimit(1)

                                Spacer()

                                Text(formatCurrency(expense.amount))
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Button {
                                    onRemoveExpense(expense.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(AppColors.Budget.overBudget.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(AppColors.Budget.allocated.opacity(0.05))
                            .cornerRadius(6)
                        }

                        ForEach(item.gifts, id: \.id) { gift in
                            HStack(spacing: 12) {
                                Image(systemName: "gift.fill")
                                    .font(.caption)
                                    .foregroundColor(AppColors.Budget.income)
                                    .frame(width: 20)

                                Text(gift.title)
                                    .font(.caption)
                                    .lineLimit(1)

                                Spacer()

                                Text(formatCurrency(gift.amount))
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Button {
                                    onRemoveGift(gift.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(AppColors.Budget.overBudget.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(AppColors.Budget.income.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, Spacing.huge)
                }
                .padding(.vertical, Spacing.md)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
