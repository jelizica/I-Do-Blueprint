//
//  CircularProgressBudgetCard.swift
//  I Do Blueprint
//
//  Created by Claude on 10/9/25.
//

import SwiftUI

struct CircularProgressBudgetCard: View {
    let item: BudgetOverviewItem
    let onEditExpense: (String, String) -> Void
    let onRemoveExpense: (String, String) async -> Void
    let onEditGift: (String, String) -> Void
    let onRemoveGift: (String) async -> Void
    let onAddExpense: (String) -> Void
    let onAddGift: (String) -> Void

    private var progress: Double {
        item.budgeted > 0 ? (item.effectiveSpent ?? 0) / item.budgeted : 0
    }

    private var progressPercentage: Double {
        min(progress * 100, 100)
    }

    private var categoryColor: Color {
        CategoryIcons.color(for: item.category)
    }

    private var categoryIcon: String {
        CategoryIcons.icon(for: item.category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category and menu
            HStack {
                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: categoryIcon)
                        .font(.caption)
                        .foregroundColor(categoryColor)
                    Text(item.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(categoryColor.opacity(0.1))
                .cornerRadius(8)

                Spacer()

                // Menu button
                Menu {
                    Button {
                        onAddExpense(item.id)
                    } label: {
                        Label("Add Expense", systemImage: "plus.circle")
                    }

                    Button {
                        onAddGift(item.id)
                    } label: {
                        Label("Add Gift", systemImage: "gift")
                    }

                    if !item.expenses.isEmpty || !item.gifts.isEmpty {
                        Divider()

                        if !item.expenses.isEmpty {
                            if item.expenses.count == 1 {
                                if let expense = item.expenses.first {
                                    Button {
                                        Task {
                                            await onRemoveExpense(expense.id, item.id)
                                        }
                                    } label: {
                                        Label("Unlink Expense", systemImage: "minus.circle")
                                    }
                                }
                            } else {
                                Menu("Unlink Expense") {
                                    ForEach(item.expenses, id: \.id) { expense in
                                        Button("Unlink \(expense.title)") {
                                            Task {
                                                await onRemoveExpense(expense.id, item.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !item.gifts.isEmpty {
                            if item.gifts.count == 1 {
                                Button {
                                    Task {
                                        await onRemoveGift(item.id)
                                    }
                                } label: {
                                    Label("Unlink Gift", systemImage: "gift.fill")
                                }
                            } else {
                                Menu("Unlink Gift") {
                                    ForEach(item.gifts, id: \.id) { gift in
                                        Button("Unlink \(gift.title)") {
                                            Task {
                                                await onRemoveGift(item.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            // Circular progress indicator
            HStack {
                Spacer()

                ZStack {
                    // Background circle
                    Circle()
                        .stroke(categoryColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: min(progress, 1.0))
                        .stroke(
                            categoryColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: progress)

                    // Center text
                    VStack(spacing: 2) {
                        Text("\(Int(progressPercentage))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("spent")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Item name
            Text(item.itemName)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // Budget amounts
            VStack(spacing: 8) {
                HStack {
                    Text("BUDGETED")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(item.budgeted))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("SPENT")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(item.effectiveSpent ?? 0))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(categoryColor)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(categoryColor)
                        .frame(width: min(CGFloat(progress), 1.0) * geometry.size.width, height: 6)
                        .animation(.easeInOut(duration: 0.8), value: progress)
                }
            }
            .frame(height: 6)

            // Linked items section (fixed height)
            VStack(alignment: .leading, spacing: 6) {
                if !item.expenses.isEmpty || !item.gifts.isEmpty {
                    Text("LINKED ITEMS")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    VStack(spacing: 4) {
                        ForEach(item.expenses.prefix(2), id: \.id) { expense in
                            HStack(spacing: 6) {
                                Image(systemName: "creditcard.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(expense.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                Button {
                                    Task {
                                        await onRemoveExpense(expense.id, item.id)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }

                        ForEach(item.gifts.prefix(2), id: \.id) { gift in
                            HStack(spacing: 6) {
                                Image(systemName: "gift.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text(gift.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                Button {
                                    Task {
                                        await onRemoveGift(item.id)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .frame(minHeight: 60)
        }
        .padding(16)
        .frame(minHeight: 380)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
