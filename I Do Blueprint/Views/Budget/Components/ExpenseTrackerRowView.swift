import SwiftUI

/// Row view for displaying an expense in list mode
struct ExpenseTrackerRowView: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var budgetStore: BudgetStoreV2

    private var category: BudgetCategory? {
        budgetStore.categories.first { $0.id == expense.budgetCategoryId }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(expense.paymentStatus == .paid ? AppColors.Budget.income : AppColors.Budget.pending)
                .frame(width: 8, height: 8)

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.expenseName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    if let vendorId = expense.vendorId {
                        Label("Vendor #\(vendorId)", systemImage: "building")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let category {
                        Label(category.categoryName, systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label(formatDate(expense.expenseDate), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let notes = expense.notes, !notes.isEmpty {
                        Label("Has notes", systemImage: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if expense.invoiceDocumentUrl != nil {
                        Label("Invoice", systemImage: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Amount and status
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", expense.amount))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(expense.paymentStatus.displayName)
                    .font(.caption)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(expense.paymentStatus == .paid ? AppColors.Budget.income.opacity(0.2) : AppColors.Budget.pending.opacity(0.2))
                    .foregroundColor(expense.paymentStatus == .paid ? AppColors.Budget.income : AppColors.Budget.pending)
                    .cornerRadius(4)
            }

            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(AppColors.Budget.allocated)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.Budget.overBudget)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
