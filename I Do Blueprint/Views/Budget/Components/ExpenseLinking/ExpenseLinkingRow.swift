//
//  ExpenseLinkingRow.swift
//  I Do Blueprint
//
//  Expense row component for expense linking view
//

import SwiftUI

// MARK: - Expense Linking Row

extension ExpenseLinkingView {

    func expenseRow(_ expense: Expense) -> some View {
        let isLinked = linkedExpenseIds.contains(expense.id)
        let isSelected = selectedExpenses.contains(expense.id)

        return HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                if !isLinked {
                    toggleExpenseSelection(expense)
                }
            }) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isLinked ? .gray : (isSelected ? .accentColor : .secondary))
            }
            .buttonStyle(.plain)
            .disabled(isLinked)

            // Expense details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.expenseName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isLinked ? .secondary : .primary)

                    if isLinked {
                        Label("Already Linked", systemImage: "link")
                            .font(.caption)
                            .foregroundColor(AppColors.Budget.allocated)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(AppColors.Budget.allocated.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Payment status badge
                    paymentStatusBadge(expense.paymentStatus)
                }

                HStack(spacing: 16) {
                    // Amount
                    Label(formatCurrency(expense.amount), systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(AppColors.Budget.income)

                    // Date
                    Label(formatDate(expense.expenseDate), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Vendor
                    if let vendorId = expense.vendorId,
                       let vendor = vendorCache[vendorId] {
                        Label(vendor.vendorName, systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Category
                    if let category = categoryCache[expense.budgetCategoryId] {
                        Label(category.categoryName, systemImage: "tag")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) :
                    (isLinked ? SemanticColors.textSecondary.opacity(Opacity.verySubtle) : Color(NSColor.controlBackgroundColor)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)))
        .opacity(isLinked ? 0.6 : 1.0)
    }

    func paymentStatusBadge(_ status: PaymentStatus) -> some View {
        let config = paymentStatusConfig(status)
        return HStack(spacing: 4) {
            Image(systemName: config.icon)
                .font(.caption2)
            Text(config.label)
                .font(.caption)
        }
        .foregroundColor(config.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(config.color.opacity(0.1))
        .clipShape(Capsule())
    }
}
