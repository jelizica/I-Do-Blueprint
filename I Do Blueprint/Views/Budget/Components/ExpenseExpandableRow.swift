//
//  ExpenseExpandableRow.swift
//  I Do Blueprint
//
//  Expandable row for expense list view in compact mode
//  Follows Expandable Table Row Pattern from Budget Overview
//

import SwiftUI

struct ExpenseExpandableRow: View {
    let expense: Expense
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    private var category: BudgetCategory? {
        budgetStore.categoryStore.categories.first { $0.id == expense.budgetCategoryId }
    }
    
    private var statusColor: Color {
        switch expense.paymentStatus {
        case .paid: AppColors.Budget.income
        case .pending: AppColors.Budget.pending
        case .partial: .yellow
        case .overdue: AppColors.Budget.overBudget
        case .cancelled: .gray
        case .refunded: AppColors.Budget.allocated
        }
    }
    
    private var approvalStatusColor: Color {
        switch (expense.approvalStatus ?? "pending").lowercased() {
        case "approved": AppColors.Budget.income
        case "pending": AppColors.Budget.pending
        case "denied": AppColors.Budget.overBudget
        default: .gray
        }
    }
    
    private var shouldShowApprovalStatus: Bool {
        guard let approvalStatus = expense.approvalStatus else {
            return false
        }
        let normalizedStatus = approvalStatus.lowercased()
        return normalizedStatus != "pending"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsed row (always visible)
            collapsedRow
            
            // Expanded content (conditionally visible)
            if isExpanded {
                expandedContent
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Collapsed Row
    
    private var collapsedRow: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: Spacing.sm) {
                // Chevron indicator
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                // Status indicator dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                // Expense name
                Text(expense.expenseName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Amount
                Text(String(format: "$%.2f", expense.amount))
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 80, alignment: .trailing)
                
                // Status badge
                Text(expense.paymentStatus.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Row 1: Category + Date
            HStack(spacing: Spacing.lg) {
                if let category {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: category.color) ?? AppColors.Budget.allocated)
                            .frame(width: 6, height: 6)
                        Text(category.categoryName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(expense.expenseDate, style: .date)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            // Row 2: Payment method + Approval status
            HStack(spacing: Spacing.lg) {
                HStack(spacing: 4) {
                    Image(systemName: paymentMethodIcon)
                        .font(.caption2)
                    Text(paymentMethodDisplayName)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                if shouldShowApprovalStatus {
                    HStack(spacing: 4) {
                        Image(systemName: approvalStatusIcon)
                            .font(.caption2)
                        Text((expense.approvalStatus ?? "Pending").capitalized)
                            .font(.caption)
                    }
                    .foregroundColor(approvalStatusColor)
                }
            }
            
            // Notes (if any)
            if let notes = expense.notes, !notes.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                    Text(notes)
                        .font(.caption)
                        .lineLimit(2)
                }
                .foregroundColor(.secondary)
            }
            
            // Action buttons
            HStack {
                Button("Edit", action: onEdit)
                    .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Delete", role: .destructive, action: onDelete)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Helper Properties
    
    private var paymentMethodIcon: String {
        switch (expense.paymentMethod ?? "credit_card").lowercased() {
        case "credit_card": "creditcard"
        case "debit_card": "creditcard"
        case "cash": "banknote"
        case "check": "doc.text"
        case "bank_transfer": "building.columns"
        case "venmo": "iphone"
        case "paypal": "globe"
        default: "dollarsign.circle"
        }
    }
    
    private var paymentMethodDisplayName: String {
        switch (expense.paymentMethod ?? "credit_card").lowercased() {
        case "credit_card": "Credit Card"
        case "debit_card": "Debit Card"
        case "cash": "Cash"
        case "check": "Check"
        case "bank_transfer": "Bank Transfer"
        case "venmo": "Venmo"
        case "paypal": "PayPal"
        default: (expense.paymentMethod ?? "Unknown").capitalized
        }
    }
    
    private var approvalStatusIcon: String {
        switch (expense.approvalStatus ?? "pending").lowercased() {
        case "approved": "checkmark.circle.fill"
        case "denied": "xmark.circle.fill"
        default: "clock.fill"
        }
    }
}
