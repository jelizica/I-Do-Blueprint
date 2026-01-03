import SwiftUI

/// Card view for displaying an expense in grid mode
struct ExpenseCardView: View {
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
    
    /// Only show approval status badge if it's meaningful (not nil/pending, or explicitly set to something other than pending)
    private var shouldShowApprovalStatus: Bool {
        guard let approvalStatus = expense.approvalStatus else {
            return false // Don't show if nil
        }
        
        let normalizedStatus = approvalStatus.lowercased()
        
        // Don't show if it's "pending" (redundant with payment status)
        if normalizedStatus == "pending" {
            return false
        }
        
        // Show if it's approved, denied, or any other meaningful status
        return true
    }

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with amount and status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "$%.2f", expense.amount))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        HStack(spacing: 8) {
                            // Payment Status Badge
                            Text(expense.paymentStatus.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(statusColor.opacity(0.2))
                                .foregroundColor(statusColor)
                                .clipShape(Capsule())

                            // Approval Status Badge (only show if meaningful)
                            if shouldShowApprovalStatus {
                                Text((expense.approvalStatus ?? "Pending").capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xxs)
                                    .background(approvalStatusColor.opacity(0.2))
                                    .foregroundColor(approvalStatusColor)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer()

                    // Menu button
                    Menu {
                        Button("Edit", action: onEdit)
                        Divider()
                        Button("Delete", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .padding(Spacing.xs)
                            .background(SemanticColors.textPrimary.opacity(Opacity.verySubtle))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Expense Name
                Text(expense.expenseName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Category info
                if let category {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: category.color) ?? AppColors.Budget.allocated)
                            .frame(width: 8, height: 8)
                        Text(category.categoryName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Date and Payment Method
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(expense.expenseDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: paymentMethodIcon(expense.paymentMethod ?? "credit_card"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(paymentMethodDisplayName(expense.paymentMethod ?? "credit_card"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Notes preview (if available)
                if let notes = expense.notes, !notes.isEmpty {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(SemanticColors.textSecondary.opacity(Opacity.light), lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func paymentMethodIcon(_ method: String) -> String {
        switch method.lowercased() {
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

    private func paymentMethodDisplayName(_ method: String) -> String {
        switch method.lowercased() {
        case "credit_card": "Credit Card"
        case "debit_card": "Debit Card"
        case "cash": "Cash"
        case "check": "Check"
        case "bank_transfer": "Bank Transfer"
        case "venmo": "Venmo"
        case "paypal": "PayPal"
        default: method.capitalized
        }
    }
}
