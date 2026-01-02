import SwiftUI

/// V2 wrapper that accepts windowSize parameter
struct ExpenseListViewV2: View {
    let windowSize: WindowSize
    let expenses: [Expense]
    let viewMode: ExpenseViewMode
    let isLoading: Bool
    let onExpenseSelected: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    let onAddExpense: () -> Void
    
    var body: some View {
        ZStack {
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
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                if viewMode == .cards {
                    ExpenseCardsGridViewV2(
                        windowSize: windowSize,
                        expenses: expenses,
                        onExpenseSelected: onExpenseSelected,
                        onExpenseDelete: onExpenseDelete)
                } else {
                    ExpenseListRowsView(
                        expenses: expenses,
                        onExpenseSelected: onExpenseSelected,
                        onExpenseDelete: onExpenseDelete,
                        windowSize: windowSize)
                }
            }
            
            // Loading overlay
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.textPrimary.opacity(0.1))
            }
        }
    }
}

/// Main expense list view supporting both card and list layouts
struct ExpenseListView: View {
    let expenses: [Expense]
    let viewMode: ExpenseViewMode
    let isLoading: Bool
    let onExpenseSelected: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    let onAddExpense: () -> Void
    
    // WindowSize is now passed from parent
    var windowSize: WindowSize {
        // Default to regular if not in GeometryReader context
        .regular
    }

    var body: some View {
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
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        } else {
            if viewMode == .cards {
                ExpenseCardsGridViewV2(
                    windowSize: windowSize,
                    expenses: expenses,
                    onExpenseSelected: onExpenseSelected,
                    onExpenseDelete: onExpenseDelete)
            } else {
                ExpenseListRowsView(
                    expenses: expenses,
                    onExpenseSelected: onExpenseSelected,
                    onExpenseDelete: onExpenseDelete,
                    windowSize: windowSize)
            }
        }
    }
}

struct ExpenseCardsGridViewV2: View {
    let windowSize: WindowSize
    let expenses: [Expense]
    let onExpenseSelected: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    
    // MARK: - Grid Columns (no GeometryReader - parent handles width)
    
    private var columns: [GridItem] {
        if windowSize == .compact {
            // Adaptive columns for compact mode
            return [GridItem(.adaptive(minimum: 160, maximum: 250), spacing: Spacing.md)]
        } else {
            // 2 columns for regular/large
            return [
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg)
            ]
        }
    }

    var body: some View {
        let padding = windowSize == .compact ? Spacing.md : Spacing.lg
        
        LazyVGrid(columns: columns, spacing: windowSize == .compact ? Spacing.md : Spacing.lg) {
            ForEach(expenses, id: \.id) { expense in
                if windowSize == .compact {
                    ExpenseCompactCard(
                        expense: expense,
                        onEdit: { onExpenseSelected(expense) },
                        onDelete: { onExpenseDelete(expense) })
                        .id(expense.id)
                } else {
                    ExpenseCardView(
                        expense: expense,
                        onEdit: { onExpenseSelected(expense) },
                        onDelete: { onExpenseDelete(expense) })
                        .id(expense.id)
                }
            }
        }
        .padding(padding)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ExpenseListRowsView: View {
    let expenses: [Expense]
    let onExpenseSelected: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    let windowSize: WindowSize
    
    @State private var expandedExpenseIds: Set<UUID> = []

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(expenses, id: \.id) { expense in
                if windowSize == .compact {
                    // Use expandable rows in compact mode
                    ExpenseExpandableRow(
                        expense: expense,
                        isExpanded: expandedExpenseIds.contains(expense.id),
                        onToggleExpand: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedExpenseIds.contains(expense.id) {
                                    expandedExpenseIds.remove(expense.id)
                                } else {
                                    expandedExpenseIds.insert(expense.id)
                                }
                            }
                        },
                        onEdit: { onExpenseSelected(expense) },
                        onDelete: { onExpenseDelete(expense) })
                        .id(expense.id)
                } else {
                    // Use regular rows in regular/large mode
                    ExpenseTrackerRowView(
                        expense: expense,
                        onEdit: { onExpenseSelected(expense) },
                        onDelete: { onExpenseDelete(expense) })
                        .id(expense.id)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// Note: ExpenseEmptyStateView replaced with UnifiedEmptyStateView from component library
