import SwiftUI

/// Main expense list view supporting both card and list layouts
struct ExpenseListView: View {
    let expenses: [Expense]
    let viewMode: ExpenseViewMode
    let isLoading: Bool
    let onExpenseSelected: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    let onAddExpense: () -> Void
    
    var body: some View {
        ScrollView {
            if expenses.isEmpty {
                // Using Component Library - UnifiedEmptyStateView
                UnifiedEmptyStateView(
                    config: .custom(
                        icon: "doc.text",
                        title: "No Expenses Found",
                        message: "Start tracking your wedding expenses by adding your first expense",
                        actionTitle: "Add Your First Expense",
                        onAction: onAddExpense
                    )
                )
                .frame(maxHeight: 200)
                .padding()
            } else {
                if viewMode == .cards {
                    ExpenseCardsGridView(
                        expenses: expenses,
                        onExpenseSelected: onExpenseSelected,
                        onExpenseDelete: onExpenseDelete)
                } else {
                    ExpenseListRowsView(
                        expenses: expenses,
                        onExpenseSelected: onExpenseSelected,
                        onExpenseDelete: onExpenseDelete)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            Group {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColors.textPrimary.opacity(0.1))
                }
            })
    }
}

struct ExpenseCardsGridView: View {
    let expenses: [Expense]
    let onExpenseSelected: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(expenses, id: \.id) { expense in
                ExpenseCardView(
                    expense: expense,
                    onEdit: { onExpenseSelected(expense) },
                    onDelete: { onExpenseDelete(expense) })
                    .id(expense.id)
            }
        }
        .padding()
    }
}

struct ExpenseListRowsView: View {
    let expenses: [Expense]
    let onExpenseSelected: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(expenses, id: \.id) { expense in
                ExpenseTrackerRowView(
                    expense: expense,
                    onEdit: { onExpenseSelected(expense) },
                    onDelete: { onExpenseDelete(expense) })
                    .id(expense.id)
            }
        }
        .padding()
    }
}

// Note: ExpenseEmptyStateView replaced with UnifiedEmptyStateView from component library
