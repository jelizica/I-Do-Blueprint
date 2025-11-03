import SwiftUI

struct ExpenseTrackerView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var showAddExpenseSheet = false
    @State private var showEditExpenseSheet = false
    @State private var selectedExpense: Expense?
    @State private var searchText = ""
    @State private var selectedFilterStatus: PaymentStatus? = nil
    @State private var selectedCategoryFilter: UUID?
    @State private var showDeleteAlert = false
    @State private var expenseToDelete: Expense?
    @State private var isLoadingExpenses = false
    @State private var showBenchmarks = false
    @State private var viewMode: ExpenseViewMode = .cards

    private let logger = AppLogger.ui

    var filteredExpenses: [Expense] {
        var results = budgetStore.expenses

        // Apply search filter
        if !searchText.isEmpty {
            results = results.filter { expense in
                expense.expenseName.localizedCaseInsensitiveContains(searchText) ||
                    (expense.notes ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply status filter
        if let filterStatus = selectedFilterStatus {
            results = results.filter { expense in
                expense.paymentStatus == filterStatus
            }
        }

        // Apply category filter
        if let categoryId = selectedCategoryFilter {
            results = results.filter { $0.budgetCategoryId == categoryId }
        }

        return results.sorted { $0.expenseDate > $1.expenseDate }
    }

    // Calculate category benchmarks
    var categoryBenchmarks: [CategoryBenchmarkData] {
        budgetStore.categories.compactMap { category in
            let categoryExpenses = budgetStore.expensesForCategory(category.id)
            let spent = categoryExpenses.reduce(0) { $0 + $1.amount }
            let budgeted = category.allocatedAmount
            let percentage = budgeted > 0 ? (spent / budgeted) * 100 : 0

            let status: BenchmarkStatus = if percentage > 100 {
                .over
            } else if percentage > 50 {
                .onTrack
            } else {
                .under
            }

            return CategoryBenchmarkData(
                category: category,
                spent: spent,
                percentage: percentage,
                status: status
            )
        }
    }

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header with stats
                ExpenseTrackerHeader(
                    totalSpent: budgetStore.totalExpensesAmount,
                    pendingAmount: budgetStore.pendingExpensesAmount,
                    paidAmount: budgetStore.paidExpensesAmount,
                    expenseCount: budgetStore.expenses.count,
                    onAddExpense: { showAddExpenseSheet = true })

                // Filters
                ExpenseFiltersBar(
                    searchText: $searchText,
                    selectedFilterStatus: $selectedFilterStatus,
                    selectedCategoryFilter: $selectedCategoryFilter,
                    viewMode: $viewMode,
                    showBenchmarks: $showBenchmarks,
                    categories: budgetStore.categories)

                // Expense List
                ExpenseListView(
                    expenses: filteredExpenses,
                    viewMode: viewMode,
                    isLoading: isLoadingExpenses,
                    onExpenseSelected: { expense in
                        selectedExpense = expense
                    },
                    onExpenseDelete: { expense in
                        expenseToDelete = expense
                        showDeleteAlert = true
                    },
                    onAddExpense: { showAddExpenseSheet = true })

                // Category Benchmarks (collapsible)
                if showBenchmarks {
                    CategoryBenchmarksSection(benchmarks: categoryBenchmarks)
                }
            }
            .padding()
        }
        .onAppear {
            loadExpenses()
        }
        .sheet(isPresented: $showAddExpenseSheet) {
            ExpenseTrackerAddView()
                .environmentObject(budgetStore)
                .environmentObject(settingsStore)
                #if os(macOS)
                .frame(minWidth: 700, idealWidth: 750, maxWidth: 800, minHeight: 650, idealHeight: 750, maxHeight: 850)
                #endif
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseTrackerEditView(expense: expense)
                .environmentObject(budgetStore)
                .environmentObject(settingsStore)
                #if os(macOS)
                .frame(minWidth: 700, idealWidth: 750, maxWidth: 800, minHeight: 650, idealHeight: 750, maxHeight: 850)
                #endif
        }
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    deleteExpense(expense)
                }
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
    }

    // MARK: - Helper Methods

    private func loadExpenses() {
        Task {
            isLoadingExpenses = true
            defer { isLoadingExpenses = false }

            do {
                try await budgetStore.loadExpenses()
            } catch {
                logger.error("Failed to load expenses", error: error)
            }
        }
    }

    private func deleteExpense(_ expense: Expense) {
        Task {
            do {
                try await budgetStore.deleteExpense(id: expense.id)
                expenseToDelete = nil
            } catch {
                logger.error("Failed to delete expense", error: error)
            }
        }
    }
}
