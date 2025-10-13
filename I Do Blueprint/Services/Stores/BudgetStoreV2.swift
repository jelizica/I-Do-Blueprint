import Combine
import Dependencies
import Foundation
import SwiftUI

/// New architecture version of BudgetStore using repository pattern
/// - Uses dependency injection for testability
/// - Implements optimistic updates for better UX
/// - Includes automatic rollback on errors
@MainActor
class BudgetStoreV2: ObservableObject {
    // MARK: - Published State

    @Published private(set) var budgetSummary: BudgetSummary?
    @Published private(set) var categories: [BudgetCategory] = []
    @Published private(set) var expenses: [Expense] = []
    @Published private(set) var paymentSchedules: [PaymentSchedule] = []
    @Published private(set) var giftsAndOwed: [GiftOrOwed] = []
    @Published private(set) var giftsReceived: [GiftReceived] = []
    @Published private(set) var moneyOwed: [MoneyOwed] = []
    @Published private(set) var categoryBenchmarks: [CategoryBenchmark] = []
    @Published var savedScenarios: [SavedScenario] = []
    @Published var taxRates: [TaxInfo] = []
    @Published var weddingEvents: [WeddingEvent] = []
    @Published var cashFlowData: [CashFlowDataPoint] = []
    @Published var incomeItems: [CashFlowItem] = []
    @Published var expenseItems: [CashFlowItem] = []
    @Published var cashFlowInsights: [CashFlowInsight] = []
    @Published var recentActivities: [BudgetActivity] = []

    // Affordability Calculator
    @Published var affordabilityScenarios: [AffordabilityScenario] = []
    @Published var affordabilityContributions: [ContributionItem] = []
    @Published var selectedScenarioId: UUID?

    @Published var isLoading = false
    @Published var error: BudgetError?

    // MARK: - Dependencies

    @Dependency(\.budgetRepository) var repository
    private let logger = AppLogger.database

    // MARK: - Computed Properties

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var totalAllocated: Double {
        categories.reduce(0) { $0 + $1.allocatedAmount }
    }

    var actualTotalBudget: Double {
        if let summary = budgetSummary, summary.totalBudget > 0 {
            return summary.totalBudget
        }
        return totalAllocated
    }

    var remainingBudget: Double {
        actualTotalBudget - totalSpent
    }

    var percentageSpent: Double {
        guard actualTotalBudget > 0 else { return 0 }
        return (totalSpent / actualTotalBudget) * 100
    }

    var percentageAllocated: Double {
        guard actualTotalBudget > 0 else { return 0 }
        return (totalAllocated / actualTotalBudget) * 100
    }

    var isOverBudget: Bool {
        totalSpent > actualTotalBudget
    }

    var totalPending: Double {
        giftsAndOwed.reduce(0) { $0 + $1.amount }
    }

    var totalReceived: Double {
        giftsReceived.reduce(0) { $0 + $1.amount }
    }

    var totalConfirmed: Double {
        giftsAndOwed.filter { $0.status == .confirmed }.reduce(0) { $0 + $1.amount }
    }

    var totalBudgetAddition: Double {
        totalReceived + totalPending + totalConfirmed
    }

    var totalInflows: Double {
        totalBudgetAddition
    }

    var totalOutflows: Double {
        totalSpent
    }

    var netCashFlow: Double {
        totalInflows - totalOutflows
    }

    var stats: BudgetStats {
        BudgetStats(
            totalCategories: categories.count,
            categoriesOverBudget: categories.filter { $0.spentAmount > $0.allocatedAmount }.count,
            categoriesOnTrack: categories.filter { $0.spentAmount <= $0.allocatedAmount }.count,
            totalExpenses: expenses.count,
            expensesPending: expenses.filter { $0.paymentStatus == .pending }.count,
            expensesOverdue: expenses.filter { $0.isOverdue }.count,
            averageSpendingPerCategory: categories.isEmpty ? 0 : totalSpent / Double(categories.count),
            projectedOverage: max(0, totalSpent - actualTotalBudget),
            monthlyBurnRate: 0)
    }

    var budgetUtilization: Double {
        guard actualTotalBudget > 0 else { return 0 }
        return (totalSpent / actualTotalBudget) * 100
    }

    var totalExpensesAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var paidExpensesAmount: Double {
        expenses.filter { $0.paymentStatus == .paid }.reduce(0) { $0 + $1.amount }
    }

    var pendingExpensesAmount: Double {
        expenses.filter { $0.paymentStatus == .pending }.reduce(0) { $0 + $1.amount }
    }

    func expensesForCategory(_ categoryId: UUID) -> [Expense] {
        expenses.filter { $0.budgetCategoryId == categoryId }
    }

    var averageMonthlySpend: Double {
        // Simplified calculation - divide total by 12 months
        totalSpent / 12.0
    }

    var daysToWedding: Int {
        // Calculate days from today to wedding date
        // Return 0 if no wedding date set
        guard let weddingDate = budgetSummary?.weddingDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: weddingDate)
        return max(0, components.day ?? 0)
    }

    var pendingPayments: Double {
        paymentSchedules.filter { $0.paymentStatus == .pending }.reduce(0) { $0 + $1.amount }
    }

    @available(*, deprecated, message: "Vendor data not available in BudgetStore - use VendorStore instead")
    var vendorsBooked: Int {
        #if DEBUG
        // This would need vendor data - return 0 for now
        return 0
        #else
        return 0
        #endif
    }

    @available(*, deprecated, message: "Vendor data not available in BudgetStore - use VendorStore instead")
    var totalVendors: Int {
        #if DEBUG
        // This would need vendor data - return 0 for now
        return 0
        #else
        return 0
        #endif
    }

    var parentCategories: [BudgetCategory] {
        categories.filter { $0.parentCategoryId == nil }
    }

    var budgetAlerts: [BudgetAlert] {
        var alerts: [BudgetAlert] = []

        // Check for overspending in categories
        for category in categories {
            let spent = expenses
                .filter { $0.budgetCategoryId == category.id }
                .reduce(0.0) { $0 + $1.amount }

            let percentSpent = category.allocatedAmount > 0 ? (spent / category.allocatedAmount) : 0

            if spent > category.allocatedAmount {
                alerts.append(BudgetAlert(
                    severity: .critical,
                    title: "\(category.categoryName) Over Budget",
                    message: "Spent \(String(format: "$%.2f", spent)) of \(String(format: "$%.2f", category.allocatedAmount)) budget",
                    timestamp: Date()
                ))
            } else if percentSpent >= 0.9 {
                alerts.append(BudgetAlert(
                    severity: .warning,
                    title: "\(category.categoryName) Near Budget Limit",
                    message: "Used \(Int(percentSpent * 100))% of budget",
                    timestamp: Date()
                ))
            }
        }

        // Check for upcoming payments
        let upcomingPayments = paymentSchedules.filter { schedule in
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: schedule.dueDate).day ?? 0
            return daysUntilDue >= 0 && daysUntilDue <= 7 && schedule.paymentStatus == .pending
        }

        if !upcomingPayments.isEmpty {
            let totalDue = upcomingPayments.reduce(0.0) { $0 + $1.amount }
            alerts.append(BudgetAlert(
                severity: .info,
                title: "Upcoming Payments",
                message: "\(upcomingPayments.count) payment(s) due in the next week (\(String(format: "$%.2f", totalDue)))",
                timestamp: Date()
            ))
        }

        // Check overall budget status
        if let summary = budgetSummary {
            let percentUsed = summary.totalBudget > 0 ? (summary.totalSpent / summary.totalBudget) : 0

            if summary.totalSpent > summary.totalBudget {
                alerts.append(BudgetAlert(
                    severity: .critical,
                    title: "Overall Budget Exceeded",
                    message: "Spent \(String(format: "$%.2f", summary.totalSpent)) of \(String(format: "$%.2f", summary.totalBudget)) total budget",
                    timestamp: Date()
                ))
            } else if percentUsed >= 0.85 {
                alerts.append(BudgetAlert(
                    severity: .warning,
                    title: "Budget Alert",
                    message: "Used \(Int(percentUsed * 100))% of total budget",
                    timestamp: Date()
                ))
            }
        }

        // Sort by severity (critical first) and timestamp
        return alerts.sorted { alert1, alert2 in
            if alert1.severity != alert2.severity {
                switch (alert1.severity, alert2.severity) {
                case (.critical, _): return true
                case (_, .critical): return false
                case (.warning, .info): return true
                case (.info, .warning): return false
                default: return alert1.timestamp > alert2.timestamp
                }
            }
            return alert1.timestamp > alert2.timestamp
        }
    }

    // MARK: - Public Interface

    /// Load all budget data in parallel
    func loadBudgetData() async {
        isLoading = true
        error = nil

        do {
            // Parallel fetch for better performance
            async let summary = repository.fetchBudgetSummary()
            async let categories = repository.fetchCategories()
            async let expenses = repository.fetchExpenses()
            async let schedules = repository.fetchPaymentSchedules()
            async let giftsOwed = repository.fetchGiftsAndOwed()

            budgetSummary = try await summary
            let categoriesResult = try await categories
            let expensesResult = try await expenses
            self.categories = categoriesResult
            self.expenses = expensesResult
            paymentSchedules = try await schedules
            giftsAndOwed = try await giftsOwed

            // Load additional data from repository
            do {
                savedScenarios = try await repository.fetchBudgetDevelopmentScenarios()
                taxRates = try await repository.fetchTaxRates()
                weddingEvents = try await repository.fetchWeddingEvents()
                logger.debug("Loaded scenarios: \(savedScenarios.count), tax rates: \(taxRates.count), events: \(weddingEvents.count)")
            } catch {
                logger.error("Failed to load additional data", error: error)
            }

            // Placeholder for data without repository methods yet
            #if DEBUG
            logger.warning("Placeholder data being used: giftsReceived, moneyOwed, categoryBenchmarks, cashFlowData, incomeItems, expenseItems, cashFlowInsights, recentActivities")
            #endif
            giftsReceived = []
            moneyOwed = []
            categoryBenchmarks = []
            cashFlowData = []
            incomeItems = []
            expenseItems = []
            cashFlowInsights = []
            recentActivities = []

            logger.info("Loaded budget data: \(categoriesResult.count) categories, \(expensesResult.count) expenses")
        } catch {
            self.error = .fetchFailed(underlying: error)
            logger.error("Error loading budget data", error: error)
        }

        isLoading = false
    }

    // MARK: - Category Operations

    func addCategory(_ category: BudgetCategory) async {
        isLoading = true
        error = nil

        do {
            let created = try await repository.createCategory(category)
            categories.append(created)
            categories.sort { $0.priorityLevel < $1.priorityLevel }
            logger.info("Added category: \(created.categoryName)")
        } catch {
            self.error = .createFailed(underlying: error)
            logger.error("Error adding category", error: error)
        }

        isLoading = false
    }

    func updateCategory(_ category: BudgetCategory) async {
        // Optimistic update
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            return
        }

        let original = categories[index]
        categories[index] = category

        do {
            let updated = try await repository.updateCategory(category)
            categories[index] = updated
            logger.info("Updated category: \(updated.categoryName)")
        } catch {
            // Rollback on error
            categories[index] = original
            self.error = .updateFailed(underlying: error)
            logger.error("Error updating category, rolled back", error: error)
        }
    }

    func deleteCategory(id: UUID) async {
        // Optimistic delete
        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = categories.remove(at: index)

        do {
            try await repository.deleteCategory(id: id)
            logger.info("Deleted category: \(removed.categoryName)")
        } catch {
            // Rollback on error
            categories.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
            logger.error("Error deleting category, rolled back", error: error)
        }
    }

    // MARK: - Expense Operations

    func loadExpenses() async {
        // Expenses are loaded as part of loadBudgetData()
        // This method exists for compatibility
        await loadBudgetData()
    }

    func addExpense(_ expense: Expense) async {
        isLoading = true
        error = nil

        do {
            let created = try await repository.createExpense(expense)
            expenses.insert(created, at: 0) // Add to beginning
            logger.info("Added expense: \(created.expenseName)")
        } catch {
            self.error = .createFailed(underlying: error)
            logger.error("Error adding expense", error: error)
        }

        isLoading = false
    }

    func createExpense(_ expense: Expense) async {
        // Alias for addExpense for compatibility
        await addExpense(expense)
    }

    func updateExpense(_ expense: Expense) async {
        // Optimistic update
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else {
            return
        }

        let original = expenses[index]
        expenses[index] = expense

        do {
            let updated = try await repository.updateExpense(expense)
            expenses[index] = updated
            logger.info("Updated expense: \(updated.expenseName)")
        } catch {
            // Rollback on error
            expenses[index] = original
            self.error = .updateFailed(underlying: error)
            logger.error("Error updating expense, rolled back", error: error)
        }
    }

    func deleteExpense(id: UUID) async {
        // Optimistic delete
        guard let index = expenses.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = expenses.remove(at: index)

        do {
            try await repository.deleteExpense(id: id)
            logger.info("Deleted expense: \(removed.expenseName)")
        } catch {
            // Rollback on error
            expenses.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
            logger.error("Error deleting expense, rolled back", error: error)
        }
    }

    // MARK: - Helper Methods

    func projectedSpending(for categoryId: UUID) -> Double {
        let categoryExpenses = expenses.filter { $0.budgetCategoryId == categoryId }
        return categoryExpenses.reduce(0) { $0 + $1.amount }
    }

    func actualSpending(for categoryId: UUID) -> Double {
        let categoryExpenses = expenses.filter { $0.budgetCategoryId == categoryId }
        return categoryExpenses.reduce(0) { $0 + ($1.paymentStatus == .paid ? $1.amount : 0) }
    }

    func enhancedCategory(_ category: BudgetCategory) -> EnhancedBudgetCategory {
        let projectedAmount = projectedSpending(for: category.id)
        let actualPaidAmount = actualSpending(for: category.id)
        return EnhancedBudgetCategory(
            category: category,
            projectedSpending: projectedAmount,
            actualSpending: actualPaidAmount)
    }

    // MARK: - Payment Schedule Operations

    func addPaymentSchedule(_ schedule: PaymentSchedule) async {
        isLoading = true
        error = nil

        do {
            let created = try await repository.createPaymentSchedule(schedule)
            paymentSchedules.append(created)
            logger.info("Added payment schedule")
        } catch {
            self.error = .createFailed(underlying: error)
            logger.error("Error adding payment schedule", error: error)
        }

        isLoading = false
    }

    func updatePaymentSchedule(_ schedule: PaymentSchedule) async {
        guard let index = paymentSchedules.firstIndex(where: { $0.id == schedule.id }) else {
            return
        }

        // Optimistic update - update UI immediately
        let previousSchedule = paymentSchedules[index]
        paymentSchedules[index] = schedule

        do {
            // Save to database via repository
            let updated = try await repository.updatePaymentSchedule(schedule)
            paymentSchedules[index] = updated
            logger.info("Updated payment schedule in database")
        } catch {
            // Rollback on error
            paymentSchedules[index] = previousSchedule
            self.error = .updateFailed(underlying: error)
            logger.error("Error updating payment schedule", error: error)
        }
    }

    func deletePaymentSchedule(id: Int64) async {
        // Optimistic delete
        guard let index = paymentSchedules.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = paymentSchedules.remove(at: index)

        do {
            try await repository.deletePaymentSchedule(id: id)
            logger.info("Deleted payment schedule")
        } catch {
            // Rollback on error
            paymentSchedules.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
            logger.error("Error deleting payment schedule, rolled back", error: error)
        }
    }

    // MARK: - Gift and Money Owed Operations

    @available(*, deprecated, message: "Local-only operation - no database persistence implemented")
    func addGiftOrOwed(_ gift: GiftOrOwed) async {
        #if DEBUG
        logger.warning("addGiftOrOwed: Local-only operation - changes will not persist")
        #endif
        giftsAndOwed.append(gift)
        logger.info("Added gift or owed")
    }

    @available(*, deprecated, message: "Local-only operation - no database persistence implemented")
    func updateGiftOrOwed(_ gift: GiftOrOwed) async {
        #if DEBUG
        logger.warning("updateGiftOrOwed: Local-only operation - changes will not persist")
        #endif
        guard let index = giftsAndOwed.firstIndex(where: { $0.id == gift.id }) else {
            return
        }
        giftsAndOwed[index] = gift
        logger.info("Updated gift or owed")
    }

    @available(*, deprecated, message: "Local-only operation - no database persistence implemented")
    func deleteGiftOrOwed(id: UUID) async {
        #if DEBUG
        logger.warning("deleteGiftOrOwed: Local-only operation - changes will not persist")
        #endif
        giftsAndOwed.removeAll { $0.id == id }
        logger.info("Deleted gift or owed")
    }

    @available(*, deprecated, message: "Local-only operation - no database persistence implemented")
    func addGiftReceived(_ gift: GiftReceived) async {
        #if DEBUG
        logger.warning("addGiftReceived: Local-only operation - changes will not persist")
        #endif
        giftsReceived.append(gift)
        logger.info("Added gift received")
    }

    @available(*, deprecated, message: "Local-only operation - no database persistence implemented")
    func updateGiftReceived(_ gift: GiftReceived) async {
        #if DEBUG
        logger.warning("updateGiftReceived: Local-only operation - changes will not persist")
        #endif
        guard let index = giftsReceived.firstIndex(where: { $0.id == gift.id }) else {
            return
        }
        giftsReceived[index] = gift
        logger.info("Updated gift received")
    }

    @available(*, deprecated, message: "Local-only operation - no database persistence implemented")
    func deleteGiftReceived(id: UUID) async {
        #if DEBUG
        logger.warning("deleteGiftReceived: Local-only operation - changes will not persist")
        #endif
        giftsReceived.removeAll { $0.id == id }
        logger.info("Deleted gift received")
    }

    @available(*, deprecated, message: "Local-only operation - no database persistence implemented")
    func addMoneyOwed(_ money: MoneyOwed) async {
        #if DEBUG
        logger.warning("addMoneyOwed: Local-only operation - changes will not persist")
        #endif
        moneyOwed.append(money)
        logger.info("Added money owed")
    }

    @available(*, deprecated, message: "Local-only operation - no database persistence implemented")
    func updateMoneyOwed(_ money: MoneyOwed) async {
        #if DEBUG
        logger.warning("updateMoneyOwed: Local-only operation - changes will not persist")
        #endif
        guard let index = moneyOwed.firstIndex(where: { $0.id == money.id }) else {
            return
        }
        moneyOwed[index] = money
        logger.info("Updated money owed")
    }

    @available(*, deprecated, message: "Local-only operation - no database persistence implemented")
    func deleteMoneyOwed(id: UUID) async {
        #if DEBUG
        logger.warning("deleteMoneyOwed: Local-only operation - changes will not persist")
        #endif
        moneyOwed.removeAll { $0.id == id }
        logger.info("Deleted money owed")
    }

    // MARK: - Budget Development Operations (stub implementations)

    func loadBudgetDevelopmentItems(scenarioId: String? = nil) async -> [BudgetItem] {
        do {
            let items = try await repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
            logger.debug("Loaded \(items.count) budget development items")
            return items
        } catch {
            logger.error("Failed to load budget development items", error: error)
            return []
        }
    }

    func loadBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async -> [BudgetOverviewItem] {
        do {
            let items = try await repository.fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: scenarioId)
            logger.debug("Loaded \(items.count) budget overview items with spent amounts")
            return items
        } catch {
            logger.error("Failed to load budget overview items", error: error)
            return []
        }
    }

    func saveBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        // Determine if this is a new item or an update by checking if it exists in the database
        // New items will be created, existing items will be updated
        let existingItems = try await repository.fetchBudgetDevelopmentItems(scenarioId: item.scenarioId)
        let isExisting = existingItems.contains { $0.id == item.id }

        let savedItem: BudgetItem
        if isExisting {
            savedItem = try await repository.updateBudgetDevelopmentItem(item)
            logger.info("Updated budget development item: \(savedItem.itemName)")
        } else {
            savedItem = try await repository.createBudgetDevelopmentItem(item)
            logger.info("Created budget development item: \(savedItem.itemName)")
        }
        return savedItem
    }

    func deleteBudgetDevelopmentItem(id: String) async throws {
        try await repository.deleteBudgetDevelopmentItem(id: id)
        logger.info("Deleted budget development item: \(id)")
    }

    func saveBudgetDevelopmentScenario(
        _ scenario: SavedScenario,
        isUpdate: Bool = false) async throws -> SavedScenario {
        if isUpdate {
            if let index = savedScenarios.firstIndex(where: { $0.id == scenario.id }) {
                savedScenarios[index] = scenario
            }
        } else {
            savedScenarios.append(scenario)
        }
        logger.info("Saved budget development scenario")
        return scenario
    }

    // MARK: - Expense Linking Operations (stub implementations)

    @available(*, deprecated, message: "Not yet implemented in V2")
    func unlinkExpense(expenseId: String, budgetItemId: String) async throws {
        #if DEBUG
        logger.warning("unlinkExpense: Not yet implemented in V2")
        #endif
        throw BudgetError.notImplemented
    }

    @available(*, deprecated, message: "Not yet implemented in V2")
    func unlinkGift(budgetItemId: String) async throws {
        #if DEBUG
        logger.warning("unlinkGift: Not yet implemented in V2")
        #endif
        throw BudgetError.notImplemented
    }

    // MARK: - Refresh Operations

    func refresh() async {
        await loadBudgetData()
    }

    @available(*, deprecated, message: "Use refresh() instead")
    func refreshData() async {
        await refresh()
    }

    @available(*, deprecated, message: "Use refresh() instead")
    func refreshBudgetData() async {
        await refresh()
    }

    @available(*, deprecated, message: "Use refresh() instead")
    func loadCashFlowData() async {
        await refresh()
    }

    // MARK: - Category Filter and Sort Operations

    func filteredCategories(by filter: BudgetFilterOption) -> [BudgetCategory] {
        switch filter {
        case .all:
            return categories
        case .overBudget:
            return categories.filter { $0.spentAmount > $0.allocatedAmount }
        case .onTrack:
            return categories.filter { $0.spentAmount <= $0.allocatedAmount }
        case .underBudget:
            return categories.filter { $0.spentAmount < $0.allocatedAmount }
        case .highPriority:
            return categories.filter { $0.priorityLevel <= 2 }
        case .essential:
            return categories.filter { $0.isEssential == true }
        }
    }

    func sortedCategories(
        _ categories: [BudgetCategory],
        by sort: BudgetSortOption,
        ascending: Bool) -> [BudgetCategory] {
        let sorted: [BudgetCategory]
        switch sort {
        case .category:
            sorted = categories.sorted { $0.categoryName < $1.categoryName }
        case .amount:
            sorted = categories.sorted { $0.allocatedAmount < $1.allocatedAmount }
        case .spent:
            sorted = categories.sorted { $0.spentAmount < $1.spentAmount }
        case .remaining:
            sorted = categories.sorted { ($0.allocatedAmount - $0.spentAmount) < ($1.allocatedAmount - $1.spentAmount) }
        case .priority:
            sorted = categories.sorted { $0.priorityLevel < $1.priorityLevel }
        case .dueDate:
            // Categories don't have due dates, so sort by priority as fallback
            sorted = categories.sorted { $0.priorityLevel < $1.priorityLevel }
        }
        return ascending ? sorted : sorted.reversed()
    }

    func spentAmount(for categoryId: UUID) -> Double {
        expenses.filter { $0.budgetCategoryId == categoryId }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Category Aliases for Compatibility

    func addBudgetCategory(_ category: BudgetCategory) async {
        await addCategory(category)
    }

    func updateBudgetCategory(_ category: BudgetCategory) async {
        await updateCategory(category)
    }

    // MARK: - Payment Aliases for Compatibility

    func addPayment(_ payment: PaymentSchedule) async {
        await addPaymentSchedule(payment)
    }

    func deletePayment(_ payment: PaymentSchedule) async {
        await deletePaymentSchedule(id: payment.id)
    }

    func updatePayment(_ payment: PaymentSchedule) async {
        await updatePaymentSchedule(payment)
    }

    // MARK: - Affordability Calculator Methods

    func loadAffordabilityScenarios() async {
        do {
            logger.debug("Loading affordability scenarios...")
            affordabilityScenarios = try await repository.fetchAffordabilityScenarios()
            logger.info("Loaded \(affordabilityScenarios.count) scenarios")

            // Auto-select primary or first scenario
            if selectedScenarioId == nil {
                selectedScenarioId = affordabilityScenarios.first(where: { $0.isPrimary })?.id ?? affordabilityScenarios.first?.id
                logger.debug("Auto-selected scenario: \(selectedScenarioId?.uuidString ?? "none")")
            }

            // Load contributions for selected scenario
            if let scenarioId = selectedScenarioId {
                await loadAffordabilityContributions(scenarioId: scenarioId)
            }
        } catch {
            logger.error("Failed to load affordability scenarios", error: error)
            self.error = .fetchFailed(underlying: error)
        }
    }

    func loadAffordabilityContributions(scenarioId: UUID) async {
        do {
            affordabilityContributions = try await repository.fetchAffordabilityContributions(scenarioId: scenarioId)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }
    }

    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async {
        do {
            let saved = try await repository.saveAffordabilityScenario(scenario)
            if let index = affordabilityScenarios.firstIndex(where: { $0.id == saved.id }) {
                affordabilityScenarios[index] = saved
            } else {
                affordabilityScenarios.append(saved)
            }
        } catch {
            self.error = .createFailed(underlying: error)
        }
    }

    func deleteAffordabilityScenario(id: UUID) async {
        do {
            try await repository.deleteAffordabilityScenario(id: id)
            affordabilityScenarios.removeAll { $0.id == id }
            if selectedScenarioId == id {
                selectedScenarioId = affordabilityScenarios.first?.id
                if let scenarioId = selectedScenarioId {
                    await loadAffordabilityContributions(scenarioId: scenarioId)
                }
            }
        } catch {
            self.error = .deleteFailed(underlying: error)
        }
    }

    func saveAffordabilityContribution(_ contribution: ContributionItem) async {
        do {
            let saved = try await repository.saveAffordabilityContribution(contribution)
            if let index = affordabilityContributions.firstIndex(where: { $0.id == saved.id }) {
                affordabilityContributions[index] = saved
            } else {
                affordabilityContributions.append(saved)
            }
        } catch {
            self.error = .createFailed(underlying: error)
        }
    }

    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async {
        do {
            try await repository.deleteAffordabilityContribution(id: id, scenarioId: scenarioId)
            affordabilityContributions.removeAll { $0.id == id }
        } catch {
            self.error = .deleteFailed(underlying: error)
        }
    }

    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async {
        do {
            try await repository.linkGiftsToScenario(giftIds: giftIds, scenarioId: scenarioId)
            logger.info("Linked \(giftIds.count) gifts to scenario")
        } catch {
            logger.error("Failed to link gifts to scenario", error: error)
            self.error = .updateFailed(underlying: error)
        }
    }

    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async {
        do {
            try await repository.unlinkGiftFromScenario(giftId: giftId, scenarioId: scenarioId)
            logger.info("Unlinked gift from scenario")
        } catch {
            logger.error("Failed to unlink gift from scenario", error: error)
            self.error = .updateFailed(underlying: error)
        }
    }
}
