import Foundation

/// Mock implementation for testing
/// Provides in-memory storage and testing hooks
@MainActor
class MockBudgetRepository: BudgetRepositoryProtocol {
    // Storage
    var budgetSummary: BudgetSummary?
    var categories: [BudgetCategory] = []
    var expenses: [Expense] = []
    var paymentSchedules: [PaymentSchedule] = []
    var giftsAndOwed: [GiftOrOwed] = []

    // Testing flags
    var fetchSummaryCalled = false
    var fetchCategoriesCalled = false
    var createCategoryCalled = false
    var updateCategoryCalled = false
    var deleteCategoryCalled = false
    var fetchExpensesCalled = false
    var createExpenseCalled = false

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    // Delays for simulating network
    var delay: TimeInterval = 0

    init() {}

    // MARK: - Budget Summary

    func fetchBudgetSummary() async throws -> BudgetSummary? {
        fetchSummaryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return budgetSummary
    }

    // MARK: - Category Budget Metrics

    var categoryMetrics: [CategoryBudgetMetrics] = []
    var fetchCategoryMetricsCalled = false

    func fetchCategoryBudgetMetrics() async throws -> [CategoryBudgetMetrics] {
        fetchCategoryMetricsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return categoryMetrics
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [BudgetCategory] {
        fetchCategoriesCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return categories
    }

    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        createCategoryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        categories.append(category)
        return category
    }

    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        updateCategoryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
        return category
    }

    func deleteCategory(id: UUID) async throws {
        deleteCategoryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        categories.removeAll { $0.id == id }
    }

    // MARK: - Expenses

    func fetchExpenses() async throws -> [Expense] {
        fetchExpensesCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return expenses
    }

    func createExpense(_ expense: Expense) async throws -> Expense {
        createExpenseCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        expenses.append(expense)
        return expense
    }

    func updateExpense(_ expense: Expense) async throws -> Expense {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        }
        return expense
    }

    func deleteExpense(id: UUID) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        expenses.removeAll { $0.id == id }
    }

    func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return expenses.filter { $0.vendorId == vendorId }
    }

    // MARK: - Payment Schedules

    func fetchPaymentSchedules() async throws -> [PaymentSchedule] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return paymentSchedules
    }

    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        paymentSchedules.append(schedule)
        return schedule
    }

    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = paymentSchedules.firstIndex(where: { $0.id == schedule.id }) {
            paymentSchedules[index] = schedule
        }
        return schedule
    }

    func deletePaymentSchedule(id: Int64) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        paymentSchedules.removeAll { $0.id == id }
    }

    func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return paymentSchedules.filter { $0.vendorId == vendorId }
    }

    // MARK: - Payment Plan Summaries

    var paymentPlanSummaries: [PaymentPlanSummary] = []

    func fetchPaymentPlanSummaries() async throws -> [PaymentPlanSummary] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return paymentPlanSummaries
    }

    func fetchPaymentPlanSummary(expenseId: UUID) async throws -> PaymentPlanSummary? {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return paymentPlanSummaries.first { $0.expenseId == expenseId }
    }

    // MARK: - Gifts and Owed

    func fetchGiftsAndOwed() async throws -> [GiftOrOwed] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return giftsAndOwed
    }

    func createGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        giftsAndOwed.append(gift)
        return gift
    }

    func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = giftsAndOwed.firstIndex(where: { $0.id == gift.id }) {
            giftsAndOwed[index] = gift
            return gift
        }
        throw NSError(domain: "MockBudgetRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Gift not found"])
    }

    func deleteGiftOrOwed(id: UUID) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        giftsAndOwed.removeAll { $0.id == id }
    }

    // MARK: - Budget Development

    var budgetDevelopmentScenarios: [SavedScenario] = []
    var budgetDevelopmentItems: [BudgetItem] = []

    func saveBudgetScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int) {
        // Upsert scenario
        if let idx = budgetDevelopmentScenarios.firstIndex(where: { $0.id == scenario.id }) {
            budgetDevelopmentScenarios[idx] = scenario
        } else {
            budgetDevelopmentScenarios.append(scenario)
        }
        // Insert items (assign scenarioId)
        var count = 0
        for var item in items {
            item.scenarioId = scenario.id
            if let idx = budgetDevelopmentItems.firstIndex(where: { $0.id == item.id }) {
                budgetDevelopmentItems[idx] = item
            } else {
                budgetDevelopmentItems.append(item)
            }
            count += 1
        }
        return (scenario.id, count)
    }

    func fetchBudgetDevelopmentScenarios() async throws -> [SavedScenario] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return budgetDevelopmentScenarios
    }

    func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let scenarioId = scenarioId {
            return budgetDevelopmentItems.filter { $0.scenarioId == scenarioId }
        }
        return budgetDevelopmentItems
    }

    func fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async throws -> [BudgetOverviewItem] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        // Mock: return empty array
        return []
    }

    func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        budgetDevelopmentScenarios.append(scenario)
        return scenario
    }

    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = budgetDevelopmentScenarios.firstIndex(where: { $0.id == scenario.id }) {
            budgetDevelopmentScenarios[index] = scenario
        }
        return scenario
    }

    func deleteBudgetDevelopmentScenario(id: String) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        budgetDevelopmentScenarios.removeAll { $0.id == id }
        budgetDevelopmentItems.removeAll { $0.scenarioId == id }
    }

    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        budgetDevelopmentItems.append(item)
        return item
    }

    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = budgetDevelopmentItems.firstIndex(where: { $0.id == item.id }) {
            budgetDevelopmentItems[index] = item
        }
        return item
    }

    func deleteBudgetDevelopmentItem(id: String) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        budgetDevelopmentItems.removeAll { $0.id == id }
    }

    // MARK: - Tax Rates

    var taxRates: [TaxInfo] = []

    func fetchTaxRates() async throws -> [TaxInfo] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return taxRates
    }

    func createTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        taxRates.append(taxInfo)
        return taxInfo
    }

    func updateTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = taxRates.firstIndex(where: { $0.id == taxInfo.id }) {
            taxRates[index] = taxInfo
        }
        return taxInfo
    }

    func deleteTaxRate(id: Int64) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        taxRates.removeAll { $0.id == id }
    }

    // MARK: - Wedding Events

    var weddingEvents: [WeddingEvent] = []

    func fetchWeddingEvents() async throws -> [WeddingEvent] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return weddingEvents
    }
    
    func createWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        weddingEvents.append(event)
        return event
    }
    
    func updateWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = weddingEvents.firstIndex(where: { $0.id == event.id }) {
            weddingEvents[index] = event
        }
        return event
    }
    
    func deleteWeddingEvent(id: String) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        weddingEvents.removeAll(where: { $0.id == id })
    }

    // MARK: - Affordability Scenarios

    var affordabilityScenarios: [AffordabilityScenario] = []

    func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return affordabilityScenarios
    }

    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = affordabilityScenarios.firstIndex(where: { $0.id == scenario.id }) {
            affordabilityScenarios[index] = scenario
        } else {
            affordabilityScenarios.append(scenario)
        }
        return scenario
    }

    func deleteAffordabilityScenario(id: UUID) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        affordabilityScenarios.removeAll { $0.id == id }
    }

    // MARK: - Affordability Contributions

    var affordabilityContributions: [ContributionItem] = []

    func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return affordabilityContributions.filter { $0.scenarioId == scenarioId }
    }

    func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = affordabilityContributions.firstIndex(where: { $0.id == contribution.id }) {
            affordabilityContributions[index] = contribution
        } else {
            affordabilityContributions.append(contribution)
        }
        return contribution
    }

    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        affordabilityContributions.removeAll { $0.id == id && $0.scenarioId == scenarioId }
    }

    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        // Mock implementation - in real implementation this would update gifts_and_owed table
    }

    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        // Mock implementation - in real implementation this would set scenario_id to null
    }

    // MARK: - Expense Allocations

    private var expenseAllocations: [ExpenseAllocation] = []

    func fetchExpenseAllocations(scenarioId: String, budgetItemId: String) async throws -> [ExpenseAllocation] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return expenseAllocations.filter {
            $0.scenarioId == scenarioId && $0.budgetItemId == budgetItemId
        }
    }

    func fetchExpenseAllocationsForScenario(scenarioId: String) async throws -> [ExpenseAllocation] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return expenseAllocations.filter { $0.scenarioId == scenarioId }
    }

    func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws -> ExpenseAllocation {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        expenseAllocations.append(allocation)
        return allocation
    }

    func fetchAllocationsForExpense(expenseId: UUID, scenarioId: String) async throws -> [ExpenseAllocation] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return expenseAllocations.filter { $0.expenseId == expenseId.uuidString && $0.scenarioId == scenarioId }
    }

    func fetchAllocationsForExpenseAllScenarios(expenseId: UUID) async throws -> [ExpenseAllocation] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return expenseAllocations.filter { $0.expenseId == expenseId.uuidString }
    }

    func replaceAllocations(expenseId: UUID, scenarioId: String, with newAllocations: [ExpenseAllocation]) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        expenseAllocations.removeAll { $0.expenseId == expenseId.uuidString && $0.scenarioId == scenarioId }
        expenseAllocations.append(contentsOf: newAllocations)
    }

    func linkGiftToBudgetItem(giftId: UUID, budgetItemId: String) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        // Mock implementation - update in-memory budget items
        if let index = budgetDevelopmentItems.firstIndex(where: { $0.id == budgetItemId }) {
            budgetDevelopmentItems[index].linkedGiftOwedId = giftId.uuidString
        }
    }

    // MARK: - Gift Received Operations

    var giftsReceived: [GiftReceived] = []

    func fetchGiftsReceived() async throws -> [GiftReceived] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return giftsReceived
    }

    func createGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        giftsReceived.append(gift)
        return gift
    }

    func updateGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = giftsReceived.firstIndex(where: { $0.id == gift.id }) {
            giftsReceived[index] = gift
        }
        return gift
    }

    func deleteGiftReceived(id: UUID) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        giftsReceived.removeAll { $0.id == id }
    }

    // MARK: - Money Owed Operations

    var moneyOwed: [MoneyOwed] = []

    func fetchMoneyOwed() async throws -> [MoneyOwed] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return moneyOwed
    }

    func createMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        moneyOwed.append(money)
        return money
    }

    func updateMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = moneyOwed.firstIndex(where: { $0.id == money.id }) {
            moneyOwed[index] = money
        }
        return money
    }

    func deleteMoneyOwed(id: UUID) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        moneyOwed.removeAll { $0.id == id }
    }

    // MARK: - Testing Utilities

    /// Reset all testing flags
    func resetFlags() {
        fetchSummaryCalled = false
        fetchCategoriesCalled = false
        createCategoryCalled = false
        updateCategoryCalled = false
        deleteCategoryCalled = false
        fetchExpensesCalled = false
        createExpenseCalled = false
    }

    /// Reset all data
    func resetData() {
        budgetSummary = nil
        categories.removeAll()
        expenses.removeAll()
        paymentSchedules.removeAll()
        giftsAndOwed.removeAll()
        expenseAllocations.removeAll()
    }

    // MARK: - Primary Budget Scenario

    var primaryBudgetScenario: BudgetDevelopmentScenario?

    func fetchPrimaryBudgetScenario() async throws -> BudgetDevelopmentScenario? {
        if shouldThrowError { throw errorToThrow }
        return primaryBudgetScenario
    }

    // MARK: - Folder Operations

    func createFolder(name: String, scenarioId: String, parentFolderId: String?, displayOrder: Int) async throws -> BudgetItem {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        let folder = BudgetItem.createFolder(
            name: name,
            scenarioId: scenarioId,
            parentFolderId: parentFolderId,
            displayOrder: displayOrder,
            coupleId: UUID()
        )
        
        budgetDevelopmentItems.append(folder)
        return folder
    }

    func moveItemToFolder(itemId: String, targetFolderId: String?, displayOrder: Int) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        guard let index = budgetDevelopmentItems.firstIndex(where: { $0.id == itemId }) else {
            throw NSError(domain: "MockBudgetRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
        }
        
        var item = budgetDevelopmentItems[index]
        item.parentFolderId = targetFolderId
        item.displayOrder = displayOrder
        budgetDevelopmentItems[index] = item
    }

    func updateDisplayOrder(items: [(itemId: String, displayOrder: Int)]) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        // Fail fast: detect missing items before making any changes
        let missingIds = items.map { $0.itemId }.filter { itemId in
            !budgetDevelopmentItems.contains(where: { $0.id == itemId })
        }
        
        if !missingIds.isEmpty {
            let idsString = missingIds.joined(separator: ", ")
            throw NSError(
                domain: "MockBudgetRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Item(s) not found: \(idsString)"]
            )
        }
        
        // All items exist, proceed with updates
        for (itemId, order) in items {
            if let index = budgetDevelopmentItems.firstIndex(where: { $0.id == itemId }) {
                var item = budgetDevelopmentItems[index]
                item.displayOrder = order
                budgetDevelopmentItems[index] = item
            }
        }
    }

    func toggleFolderExpansion(folderId: String, isExpanded: Bool) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        // Verify item exists
        guard let index = budgetDevelopmentItems.firstIndex(where: { $0.id == folderId }) else {
            throw NSError(
                domain: "MockBudgetRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Item not found"]
            )
        }
        
        // Verify item is a folder
        guard budgetDevelopmentItems[index].isFolder else {
            throw NSError(
                domain: "MockBudgetRepository",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Item is not a folder"]
            )
        }
        
        // Note: isExpanded is managed in the view layer, not persisted in the model
        // This method validates the folder exists and is actually a folder, but doesn't persist state
    }

    func fetchBudgetItemsHierarchical(scenarioId: String) async throws -> [BudgetItem] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return budgetDevelopmentItems.filter { $0.scenarioId == scenarioId }.sorted { $0.displayOrder < $1.displayOrder }
    }

    func calculateFolderTotals(folderId: String) async throws -> FolderTotals {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        // Get all descendants of this folder
        func getAllDescendants(of folderId: String) -> [BudgetItem] {
            var result: [BudgetItem] = []
            var queue = [folderId]
            
            while !queue.isEmpty {
                let currentId = queue.removeFirst()
                let children = budgetDevelopmentItems.filter { $0.parentFolderId == currentId && !$0.isFolder }
                result.append(contentsOf: children)
                
                let childFolders = budgetDevelopmentItems.filter { $0.parentFolderId == currentId && $0.isFolder }
                queue.append(contentsOf: childFolders.map { $0.id })
            }
            
            return result
        }
        
        let descendants = getAllDescendants(of: folderId)
        let withoutTax = descendants.reduce(0) { $0 + $1.vendorEstimateWithoutTax }
        let tax = descendants.reduce(0) { $0 + ($1.vendorEstimateWithoutTax * $1.taxRate) }
        let withTax = descendants.reduce(0) { $0 + $1.vendorEstimateWithTax }
        
        return FolderTotals(withoutTax: withoutTax, tax: tax, withTax: withTax)
    }

    func canMoveItem(itemId: String, toFolder targetFolderId: String?) async throws -> Bool {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        // Can't move to itself
        if itemId == targetFolderId { return false }
        
        // If moving to root, check if item's subtree would fit
        if targetFolderId == nil {
            let subtreeHeight = getSubtreeHeight(of: itemId)
            // At root level (depth 0), item will be at depth 1, so: 1 + subtreeHeight <= 3
            return 1 + subtreeHeight <= 3
        }
        
        // Check if target is a folder
        guard let targetFolder = budgetDevelopmentItems.first(where: { $0.id == targetFolderId }),
              targetFolder.isFolder else {
            return false
        }
        
        // Check for circular reference (item is ancestor of target)
        var visited = Set<String>()
        var currentId: String? = targetFolderId
        
        while let id = currentId {
            if visited.contains(id) || id == itemId { return false }
            visited.insert(id)
            
            guard let item = budgetDevelopmentItems.first(where: { $0.id == id }) else { break }
            currentId = item.parentFolderId
        }
        
        // Calculate target depth (how deep the target folder is)
        func getDepth(of itemId: String) -> Int {
            var depth = 0
            var currentId: String? = itemId
            
            while let id = currentId,
                  let item = budgetDevelopmentItems.first(where: { $0.id == id }),
                  let parentId = item.parentFolderId {
                depth += 1
                currentId = parentId
            }
            
            return depth
        }
        
        let targetDepth = getDepth(of: targetFolderId!)
        
        // Calculate subtree height of the item being moved
        let subtreeHeight = getSubtreeHeight(of: itemId)
        
        // Validate combined depth: targetDepth + 1 (item becomes child) + subtreeHeight <= 3
        // This ensures the deepest descendant won't exceed max depth
        return targetDepth + 1 + subtreeHeight <= 3
    }
    
    /// Calculates the maximum depth (height) of the subtree rooted at the given item
    /// - Parameter itemId: The root item ID
    /// - Returns: The height of the subtree (0 for leaf nodes, 1+ for nodes with children)
    private func getSubtreeHeight(of itemId: String) -> Int {
        // Get all direct children of this item
        let children = budgetDevelopmentItems.filter { $0.parentFolderId == itemId }
        
        // If no children, height is 0
        guard !children.isEmpty else { return 0 }
        
        // Recursively find the maximum height among all children
        var maxChildHeight = 0
        for child in children {
            let childHeight = getSubtreeHeight(of: child.id)
            maxChildHeight = max(maxChildHeight, childHeight)
        }
        
        // Height is 1 (for this level) + max child height
        return 1 + maxChildHeight
    }

    func deleteFolder(folderId: String, deleteContents: Bool) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        guard let folder = budgetDevelopmentItems.first(where: { $0.id == folderId }) else {
            throw NSError(domain: "MockBudgetRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Folder not found"])
        }
        
        // Verify item is a folder
        guard folder.isFolder else {
            throw NSError(
                domain: "MockBudgetRepository",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Item is not a folder"]
            )
        }
        
        if deleteContents {
            // Delete folder and all contents recursively
            func deleteRecursively(folderId: String) {
                let children = budgetDevelopmentItems.filter { $0.parentFolderId == folderId }
                for child in children {
                    if child.isFolder {
                        deleteRecursively(folderId: child.id)
                    }
                    budgetDevelopmentItems.removeAll(where: { $0.id == child.id })
                }
            }
            
            deleteRecursively(folderId: folderId)
            budgetDevelopmentItems.removeAll(where: { $0.id == folderId })
        } else {
            // Move contents to parent, then delete folder
            let children = budgetDevelopmentItems.filter { $0.parentFolderId == folderId }
            
            for child in children {
                if let index = budgetDevelopmentItems.firstIndex(where: { $0.id == child.id }) {
                    var updatedChild = budgetDevelopmentItems[index]
                    updatedChild.parentFolderId = folder.parentFolderId
                    budgetDevelopmentItems[index] = updatedChild
                }
            }
            
            budgetDevelopmentItems.removeAll(where: { $0.id == folderId })
        }
    }
    
    // MARK: - Category Dependencies
    
    var categoryDependencies: [UUID: CategoryDependencies] = [:]
    var shouldFailDelete: [UUID: Bool] = [:]
    
    func checkCategoryDependencies(id: UUID) async throws -> CategoryDependencies {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        // Return stored dependencies if available
        if let deps = categoryDependencies[id] {
            return deps
        }
        
        // Otherwise return empty dependencies (can delete)
        guard let category = categories.first(where: { $0.id == id }) else {
            throw NSError(domain: "MockBudgetRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Category not found"])
        }
        
        return CategoryDependencies(
            categoryId: id,
            categoryName: category.categoryName,
            expenseCount: 0,
            budgetItemCount: 0,
            subcategoryCount: 0,
            taskCount: 0,
            vendorCount: 0
        )
    }
    
    func batchDeleteCategories(ids: [UUID]) async throws -> BatchDeleteResult {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        var succeeded: [UUID] = []
        var failed: [(UUID, BatchDeleteResult.SendableErrorWrapper)] = []

        for id in ids {
            // Check if this category should fail
            if shouldFailDelete[id] == true {
                let error = NSError(
                    domain: "MockBudgetRepository",
                    code: 409,
                    userInfo: [NSLocalizedDescriptionKey: "Category has dependencies"]
                )
                failed.append((id, BatchDeleteResult.SendableErrorWrapper(error)))
            } else {
                // Delete the category
                categories.removeAll { $0.id == id }
                succeeded.append(id)
            }
        }
        
        return BatchDeleteResult(succeeded: succeeded, failed: failed)
    }

    // MARK: - Expense Bill Calculator Link Operations

    func fetchBillCalculatorLinksForExpense(expenseId: UUID) async throws -> [ExpenseBillCalculatorLink] {
        // Return mock links filtered by expense ID
        return []
    }

    func fetchExpenseLinksForBillCalculator(billCalculatorId: UUID) async throws -> [ExpenseBillCalculatorLink] {
        // Return mock links filtered by bill calculator ID
        return []
    }

    func linkBillCalculatorsToExpense(
        expenseId: UUID,
        billCalculatorIds: [UUID],
        linkType: ExpenseBillCalculatorLink.LinkType,
        notes: String?
    ) async throws -> [ExpenseBillCalculatorLink] {
        // Create and return mock links
        return billCalculatorIds.map { billCalculatorId in
            ExpenseBillCalculatorLink(
                expenseId: expenseId,
                billCalculatorId: billCalculatorId,
                coupleId: UUID(),
                linkType: linkType,
                notes: notes
            )
        }
    }

    func unlinkBillCalculatorFromExpense(linkId: UUID) async throws {
        // No-op for mock
    }

    func unlinkAllBillCalculatorsFromExpense(expenseId: UUID) async throws {
        // No-op for mock
    }
}
