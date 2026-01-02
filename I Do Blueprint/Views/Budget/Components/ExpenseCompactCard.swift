//
//  ExpenseCompactCard.swift
//  I Do Blueprint
//
//  Compact card view for expenses in narrow windows
//  Follows Dynamic Content-Aware Grid Width Pattern from Budget Overview
//

import SwiftUI

struct ExpenseCompactCard: View {
    let expense: Expense
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
    
    /// Only show approval status badge if it's meaningful
    private var shouldShowApprovalStatus: Bool {
        guard let approvalStatus = expense.approvalStatus else {
            return false
        }
        let normalizedStatus = approvalStatus.lowercased()
        return normalizedStatus != "pending"
    }
    
    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Amount + Menu row
                HStack {
                    Text(String(format: "$%.2f", expense.amount))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Menu {
                        Button("Edit", action: onEdit)
                        Divider()
                        Button("Delete", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .padding(Spacing.xs)
                            .background(AppColors.textPrimary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Status badges row
                HStack(spacing: Spacing.xs) {
                    // Payment Status Badge
                    Text(expense.paymentStatus.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(4)
                    
                    // Approval Status Badge (only if meaningful)
                    if shouldShowApprovalStatus {
                        Text((expense.approvalStatus ?? "Pending").capitalized)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 2)
                            .background(approvalStatusColor.opacity(0.2))
                            .foregroundColor(approvalStatusColor)
                            .cornerRadius(4)
                    }
                }
                
                // Expense name
                Text(expense.expenseName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Category + Date row
                HStack(spacing: Spacing.sm) {
                    if let category {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: category.color) ?? AppColors.Budget.allocated)
                                .frame(width: 6, height: 6)
                            Text(category.categoryName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(expense.expenseDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Payment method
                HStack(spacing: 4) {
                    Image(systemName: paymentMethodIcon)
                        .font(.caption2)
                    Text(paymentMethodDisplayName)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
}
