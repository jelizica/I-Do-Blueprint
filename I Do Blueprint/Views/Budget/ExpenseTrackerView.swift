import SwiftUI

struct ExpenseTrackerView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @ObservedObject private var guestStore = AppStores.shared.guest
    
    // Navigation state - receives binding from parent (BudgetDashboardHubView)
    @Binding var currentPage: BudgetPage
    @State private var showAddExpenseSheet = false
    @State private var showEditExpenseSheet = false
    @State private var selectedExpense: Expense?
    @State private var searchText = ""
    @State private var selectedFilterStatus: PaymentStatus? = nil
    @State private var selectedCategoryFilter: Set<UUID> = []
    @State private var showDeleteAlert = false
    @State private var expenseToDelete: Expense?
    @State private var isLoadingExpenses = false
    @State private var showBenchmarks = false
    @State private var viewMode: ExpenseViewMode = .cards
    @State private var guestCountMode: ExpenseTrackerStaticHeader.GuestCountMode = .total

    private let logger = AppLogger.ui
    
    // MARK: - Computed Properties for Static Header
    
    /// Total budget from primary scenario (sum of budget categories' allocated amounts)
    private var totalBudget: Double {
        // Sum all parent category allocated amounts (not subcategories to avoid double-counting)
        return budgetStore.categoryStore.categories
            .filter { $0.parentCategoryId == nil }
            .reduce(0) { $0 + $1.allocatedAmount }
    }
    
    /// Count of overdue expenses
    private var overdueCount: Int {
        budgetStore.expenseStore.expenses.filter { $0.paymentStatus == .overdue }.count
    }
    
    /// Days until wedding from settings
    private var daysUntilWedding: Int? {
        let weddingDateString = settingsStore.settings.global.weddingDate
        guard !weddingDateString.isEmpty, !settingsStore.settings.global.isWeddingDateTBD else { return nil }
        
        // Parse date string (format: "YYYY-MM-DD")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let weddingDate = formatter.date(from: weddingDateString) else { return nil }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let wedding = calendar.startOfDay(for: weddingDate)
        let components = calendar.dateComponents([.day], from: today, to: wedding)
        return components.day
    }
    
    /// Guest count based on selected mode
    private var guestCount: Int {
        let guestStore = AppStores.shared.guest
        switch guestCountMode {
        case .total:
            return guestStore.guests.count
        case .attending:
            return guestStore.guests.filter { $0.rsvpStatus == .confirmed && $0.attendingCeremony }.count
        case .confirmed:
            return guestStore.guests.filter { $0.rsvpStatus == .confirmed }.count
        }
    }

    var filteredExpenses: [Expense] {
        var results = budgetStore.expenseStore.expenses

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

        // Apply category filter (OR logic - show expenses from ANY selected category)
        if !selectedCategoryFilter.isEmpty {
            results = results.filter { expense in
                selectedCategoryFilter.contains(expense.budgetCategoryId)
            }
        }

        return results.sorted { $0.expenseDate > $1.expenseDate }
    }

    // Calculate category benchmarks (parent categories only)
    var categoryBenchmarks: [CategoryBenchmarkData] {
        budgetStore.categoryStore.categories
            .filter { $0.parentCategoryId == nil }  // Parent categories only
            .compactMap { category in
            let categoryExpenses = budgetStore.expenseStore.expensesForCategory(category.id)
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
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            
            VStack(spacing: 0) {
                // Unified header (STATIC - title + navigation)
                ExpenseTrackerUnifiedHeader(
                    windowSize: windowSize,
                    currentPage: $currentPage,
                    onAddExpense: { showAddExpenseSheet = true })
                
                // Static header (STATIC - wedding countdown + budget health dashboard)
                ExpenseTrackerStaticHeader(
                    windowSize: windowSize,
                    totalSpent: budgetStore.totalExpensesAmount,
                    totalBudget: totalBudget,
                    pendingAmount: budgetStore.pendingExpensesAmount,
                    overdueCount: overdueCount,
                    guestCount: guestCount,
                    daysUntilWedding: daysUntilWedding,
                    onAddExpense: { showAddExpenseSheet = true },
                    onOverdueClick: {
                        // Filter to overdue expenses
                        selectedFilterStatus = .overdue
                    },
                    guestCountMode: $guestCountMode
                )
                
                // Scrollable content (matches Budget Builder pattern exactly)
                ScrollView {
                    VStack(spacing: windowSize == .compact ? Spacing.lg : Spacing.xl) {
                        // Filters
                        ExpenseFiltersBarV2(
                            windowSize: windowSize,
                            searchText: $searchText,
                            selectedFilterStatus: $selectedFilterStatus,
                            selectedCategoryFilter: $selectedCategoryFilter,
                            viewMode: $viewMode,
                            showBenchmarks: $showBenchmarks,
                            categories: budgetStore.categoryStore.categories)

                        // Expense List
                        ExpenseListViewV2(
                            windowSize: windowSize,
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
                            CategoryBenchmarksSectionV2(benchmarks: categoryBenchmarks)
                        }
                    }
                    .frame(width: availableWidth)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
                }
            }
        }
        .onAppear {
            loadExpenses()
            loadGuestData()
        }
        .sheet(isPresented: $showAddExpenseSheet) {
            ExpenseTrackerAddView()
                .environmentObject(budgetStore)
                .environmentObject(settingsStore)
                .environmentObject(AppCoordinator.shared)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseTrackerEditView(expense: expense)
                .environmentObject(budgetStore)
                .environmentObject(settingsStore)
                .environmentObject(AppCoordinator.shared)
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
                await budgetStore.expenseStore.loadExpenses()
            } catch {
                logger.error("Failed to load expenses", error: error)
            }
        }
    }
    
    private func loadGuestData() {
        Task {
            logger.info("ExpenseTracker: Loading guest data...")
            await AppStores.shared.guest.loadGuestData()
            let count = AppStores.shared.guest.guests.count
            logger.info("ExpenseTracker: Loaded \(count) guests")
            
            // Log current tenant for debugging
            if let tenantId = SessionManager.shared.getTenantId() {
                logger.info("ExpenseTracker: Current tenant ID: \(tenantId.uuidString)")
            } else {
                logger.warning("ExpenseTracker: No tenant ID set!")
            }
        }
    }

    private func deleteExpense(_ expense: Expense) {
        Task {
            do {
                try await budgetStore.expenseStore.deleteExpense(id: expense.id)
                expenseToDelete = nil
            } catch {
                logger.error("Failed to delete expense", error: error)
            }
        }
    }
}
