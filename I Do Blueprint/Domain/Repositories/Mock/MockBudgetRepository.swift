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
    
    func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws -> ExpenseAllocation {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        expenseAllocations.append(allocation)
        return allocation
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
}
