//
//  BudgetRepositoryProtocol.swift
//  I Do Blueprint
//
//  Created as part of JES-43: Create Missing Repository Protocols
//  Protocol for budget-related data operations
//

import Foundation

/// Protocol for budget-related data operations
///
/// This protocol defines the contract for all budget data access operations including:
/// - Budget summaries and categories
/// - Expenses and payment schedules
/// - Gifts and money owed tracking
/// - Affordability calculator scenarios
/// - Budget development planning
/// - Tax rates and wedding events
///
/// ## Implementation Requirements
/// Implementations must handle:
/// - Multi-tenant data scoping (couple_id filtering)
/// - Proper error handling and propagation
/// - Cache invalidation on mutations
/// - Analytics tracking for performance monitoring
///
/// ## Thread Safety
/// All methods are async and can be called from any actor context.
/// The protocol conforms to `Sendable` for safe concurrent access.
///
/// ## Error Handling
/// Methods throw errors for:
/// - Network failures
/// - Database errors
/// - Authentication/authorization failures
/// - Validation errors
/// - Missing tenant context
protocol BudgetRepositoryProtocol: Sendable {
    
    // MARK: - Budget Summary Operations
    
    /// Fetches the budget summary for the current couple
    /// - Returns: Optional budget summary containing totals and metadata
    /// - Throws: Repository errors if fetch fails
    func fetchBudgetSummary() async throws -> BudgetSummary?
    
    // MARK: - Category Operations
    
    /// Fetches all budget categories for the current couple
    /// - Returns: Array of budget categories, sorted by priority
    /// - Throws: Repository errors if fetch fails
    func fetchCategories() async throws -> [BudgetCategory]
    
    /// Creates a new budget category
    /// - Parameter category: The category to create
    /// - Returns: The created category with server-assigned ID and timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory
    
    /// Updates an existing budget category
    /// - Parameter category: The category with updated values
    /// - Returns: The updated category with new timestamp
    /// - Throws: Repository errors if update fails or category not found
    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory
    
    /// Deletes a budget category
    /// - Parameter id: The UUID of the category to delete
    /// - Throws: Repository errors if deletion fails or category not found
    func deleteCategory(id: UUID) async throws
    
    // MARK: - Expense Operations
    
    /// Fetches all expenses for the current couple
    /// - Returns: Array of expenses, sorted by date
    /// - Throws: Repository errors if fetch fails
    func fetchExpenses() async throws -> [Expense]
    
    /// Creates a new expense
    /// - Parameter expense: The expense to create
    /// - Returns: The created expense with server-assigned ID and timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createExpense(_ expense: Expense) async throws -> Expense
    
    /// Updates an existing expense
    /// - Parameter expense: The expense with updated values
    /// - Returns: The updated expense with new timestamp
    /// - Throws: Repository errors if update fails or expense not found
    func updateExpense(_ expense: Expense) async throws -> Expense
    
    /// Deletes an expense
    /// - Parameter id: The UUID of the expense to delete
    /// - Throws: Repository errors if deletion fails or expense not found
    func deleteExpense(id: UUID) async throws
    
    /// Fetches expenses for a specific vendor
    /// - Parameter vendorId: The ID of the vendor
    /// - Returns: Array of expenses linked to the vendor
    /// - Throws: Repository errors if fetch fails
    func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense]
    
    // MARK: - Payment Schedule Operations
    
    /// Fetches all payment schedules for the current couple
    /// - Returns: Array of payment schedules, sorted by due date
    /// - Throws: Repository errors if fetch fails
    func fetchPaymentSchedules() async throws -> [PaymentSchedule]
    
    /// Creates a new payment schedule
    /// - Parameter schedule: The payment schedule to create
    /// - Returns: The created schedule with server-assigned ID
    /// - Throws: Repository errors if creation fails or validation errors
    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule
    
    /// Updates an existing payment schedule
    /// - Parameter schedule: The schedule with updated values
    /// - Returns: The updated schedule
    /// - Throws: Repository errors if update fails or schedule not found
    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule
    
    /// Deletes a payment schedule
    /// - Parameter id: The ID of the schedule to delete
    /// - Throws: Repository errors if deletion fails or schedule not found
    func deletePaymentSchedule(id: Int64) async throws
    
    /// Fetches payment schedules for a specific vendor
    /// - Parameter vendorId: The ID of the vendor
    /// - Returns: Array of payment schedules linked to the vendor
    /// - Throws: Repository errors if fetch fails
    func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule]
    
    // MARK: - Gifts and Money Owed Operations
    
    /// Fetches all gifts and money owed for the current couple
    /// - Returns: Array of gift/owed items
    /// - Throws: Repository errors if fetch fails
    func fetchGiftsAndOwed() async throws -> [GiftOrOwed]
    
    /// Creates a new gift or money owed item
    /// - Parameter gift: The gift/owed item to create
    /// - Returns: The created item with server-assigned ID and timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed
    
    /// Updates an existing gift or money owed item
    /// - Parameter gift: The gift/owed item with updated values
    /// - Returns: The updated item
    /// - Throws: Repository errors if update fails or item not found
    func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed
    
    /// Deletes a gift or money owed item
    /// - Parameter id: The UUID of the item to delete
    /// - Throws: Repository errors if deletion fails or item not found
    func deleteGiftOrOwed(id: UUID) async throws
    
    // MARK: - Gift Received Operations
    
    /// Fetches all gifts received for the current couple
    /// - Returns: Array of gift received items, sorted by date received (newest first)
    /// - Throws: Repository errors if fetch fails
    func fetchGiftsReceived() async throws -> [GiftReceived]
    
    /// Creates a new gift received item
    /// - Parameter gift: The gift to create
    /// - Returns: The created gift with server-assigned ID and timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived
    
    /// Updates an existing gift received item
    /// - Parameter gift: The gift with updated values
    /// - Returns: The updated gift with new timestamp
    /// - Throws: Repository errors if update fails or gift not found
    func updateGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived
    
    /// Deletes a gift received item
    /// - Parameter id: The UUID of the gift to delete
    /// - Throws: Repository errors if deletion fails or gift not found
    func deleteGiftReceived(id: UUID) async throws
    
    // MARK: - Money Owed Operations
    
    /// Fetches all money owed items for the current couple
    /// - Returns: Array of money owed items, sorted by due date (unpaid first, then by date)
    /// - Throws: Repository errors if fetch fails
    func fetchMoneyOwed() async throws -> [MoneyOwed]
    
    /// Creates a new money owed item
    /// - Parameter money: The money owed item to create
    /// - Returns: The created item with server-assigned ID and timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed
    
    /// Updates an existing money owed item
    /// - Parameter money: The money owed item with updated values
    /// - Returns: The updated item with new timestamp
    /// - Throws: Repository errors if update fails or item not found
    func updateMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed
    
    /// Deletes a money owed item
    /// - Parameter id: The UUID of the item to delete
    /// - Throws: Repository errors if deletion fails or item not found
    func deleteMoneyOwed(id: UUID) async throws
    
    // MARK: - Budget Development Operations
    
    /// Fetches all budget development scenarios for the current couple
    /// - Returns: Array of saved scenarios
    /// - Throws: Repository errors if fetch fails
    func fetchBudgetDevelopmentScenarios() async throws -> [SavedScenario]
    
    /// Fetches budget development items for a specific scenario
    /// - Parameter scenarioId: Optional scenario ID to filter by
    /// - Returns: Array of budget items
    /// - Throws: Repository errors if fetch fails
    func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem]
    
    /// Fetches budget development items with spent amounts
    /// - Parameter scenarioId: The scenario ID to fetch items for
    /// - Returns: Array of budget overview items with spending data
    /// - Throws: Repository errors if fetch fails
    func fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async throws -> [BudgetOverviewItem]
    
    /// Creates a new budget development scenario
    /// - Parameter scenario: The scenario to create
    /// - Returns: The created scenario with server-assigned ID
    /// - Throws: Repository errors if creation fails
    func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario
    
    /// Updates an existing budget development scenario
    /// - Parameter scenario: The scenario with updated values
    /// - Returns: The updated scenario
    /// - Throws: Repository errors if update fails or scenario not found
    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario
    
    /// Creates a new budget development item
    /// - Parameter item: The item to create
    /// - Returns: The created item with server-assigned ID
    /// - Throws: Repository errors if creation fails
    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem
    
    /// Updates an existing budget development item
    /// - Parameter item: The item with updated values
    /// - Returns: The updated item
    /// - Throws: Repository errors if update fails or item not found
    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem
    
    /// Deletes a budget development item
    /// - Parameter id: The ID of the item to delete
    /// - Throws: Repository errors if deletion fails or item not found
    func deleteBudgetDevelopmentItem(id: String) async throws
    
    // MARK: - Tax Rate Operations
    
    /// Fetches all tax rates for the current couple
    /// - Returns: Array of tax information
    /// - Throws: Repository errors if fetch fails
    func fetchTaxRates() async throws -> [TaxInfo]
    
    /// Creates a new tax rate
    /// - Parameter taxInfo: The tax information to create
    /// - Returns: The created tax info with server-assigned ID
    /// - Throws: Repository errors if creation fails
    func createTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo
    
    /// Updates an existing tax rate
    /// - Parameter taxInfo: The tax information with updated values
    /// - Returns: The updated tax info
    /// - Throws: Repository errors if update fails or tax rate not found
    func updateTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo
    
    /// Deletes a tax rate
    /// - Parameter id: The ID of the tax rate to delete
    /// - Throws: Repository errors if deletion fails or tax rate not found
    func deleteTaxRate(id: Int64) async throws
    
    // MARK: - Wedding Event Operations
    
    /// Fetches all wedding events for the current couple
    /// - Returns: Array of wedding events
    /// - Throws: Repository errors if fetch fails
    func fetchWeddingEvents() async throws -> [WeddingEvent]
    
    // MARK: - Affordability Calculator Operations
    
    /// Fetches all affordability scenarios for the current couple
    /// - Returns: Array of affordability scenarios
    /// - Throws: Repository errors if fetch fails
    func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario]
    
    /// Saves an affordability scenario (creates or updates)
    /// - Parameter scenario: The scenario to save
    /// - Returns: The saved scenario with updated timestamps
    /// - Throws: Repository errors if save fails
    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario
    
    /// Deletes an affordability scenario
    /// - Parameter id: The UUID of the scenario to delete
    /// - Throws: Repository errors if deletion fails or scenario not found
    func deleteAffordabilityScenario(id: UUID) async throws
    
    /// Fetches contributions for a specific affordability scenario
    /// - Parameter scenarioId: The UUID of the scenario
    /// - Returns: Array of contribution items
    /// - Throws: Repository errors if fetch fails
    func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem]
    
    /// Saves a contribution item (creates or updates)
    /// - Parameter contribution: The contribution to save
    /// - Returns: The saved contribution with updated timestamps
    /// - Throws: Repository errors if save fails
    func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem
    
    /// Deletes a contribution from a scenario
    /// - Parameters:
    ///   - id: The UUID of the contribution to delete
    ///   - scenarioId: The UUID of the scenario it belongs to
    /// - Throws: Repository errors if deletion fails or contribution not found
    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws
    
    /// Links existing gifts to an affordability scenario
    /// - Parameters:
    ///   - giftIds: Array of gift UUIDs to link
    ///   - scenarioId: The UUID of the scenario to link to
    /// - Throws: Repository errors if linking fails
    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async throws
    
    /// Unlinks a gift from an affordability scenario
    /// - Parameters:
    ///   - giftId: The UUID of the gift to unlink
    ///   - scenarioId: The UUID of the scenario to unlink from
    /// - Throws: Repository errors if unlinking fails
    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async throws
    
    // MARK: - Expense Allocation Operations
    
    /// Fetches expense allocations for a specific scenario and budget item
    /// - Parameters:
    ///   - scenarioId: The scenario ID to filter by
    ///   - budgetItemId: The budget item ID to filter by
    /// - Returns: Array of expense allocations
    /// - Throws: Repository errors if fetch fails
    func fetchExpenseAllocations(scenarioId: String, budgetItemId: String) async throws -> [ExpenseAllocation]
    
    /// Creates a new expense allocation
    /// - Parameter allocation: The expense allocation to create
    /// - Returns: The created allocation with server-assigned timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws -> ExpenseAllocation
    
    /// Links a gift to a budget development item
    /// - Parameters:
    ///   - giftId: The UUID of the gift to link
    ///   - budgetItemId: The ID of the budget item to link to
    /// - Throws: Repository errors if linking fails or item not found
    func linkGiftToBudgetItem(giftId: UUID, budgetItemId: String) async throws
}
