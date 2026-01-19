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

    // MARK: - Category Budget Metrics Operations

    /// Fetches calculated budget metrics per category using the database RPC function.
    /// These metrics are computed from actual data sources:
    /// - allocated: Sum of budget_development_items.vendor_estimate_with_tax per category
    /// - spent: Sum of paid payment_plans linked to vendors in each category
    /// - forecasted: Sum of vendor_information.quoted_amount per category
    ///
    /// - Returns: Array of CategoryBudgetMetrics with calculated values
    /// - Throws: Repository errors if fetch fails
    func fetchCategoryBudgetMetrics() async throws -> [CategoryBudgetMetrics]

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

    /// Checks dependencies for a budget category before deletion
    /// - Parameter id: The UUID of the category to check
    /// - Returns: CategoryDependencies struct with counts and deletion status
    /// - Throws: Repository errors if check fails or category not found
    func checkCategoryDependencies(id: UUID) async throws -> CategoryDependencies

    /// Batch deletes multiple budget categories
    /// - Parameter ids: Array of category UUIDs to delete
    /// - Returns: BatchDeleteResult with success/failure counts
    /// - Throws: Repository errors if the batch delete operation fails (database, validation, or authorization errors)
    func batchDeleteCategories(ids: [UUID]) async throws -> BatchDeleteResult

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

    /// Batch deletes multiple payment schedules
    /// - Parameter ids: Array of payment schedule IDs to delete
    /// - Returns: Number of successfully deleted schedules
    /// - Throws: Repository errors if the batch delete operation fails
    func batchDeletePaymentSchedules(ids: [Int64]) async throws -> Int

    /// Fetches payment schedules for a specific vendor
    /// - Parameter vendorId: The ID of the vendor
    /// - Returns: Array of payment schedules linked to the vendor
    /// - Throws: Repository errors if fetch fails
    func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule]

    // MARK: - Payment Plan Summary Operations

    /// Fetches aggregated payment plan summaries for the current couple
    /// - Returns: Array of payment plan summaries showing plan-level details
    /// - Throws: Repository errors if fetch fails
    func fetchPaymentPlanSummaries() async throws -> [PaymentPlanSummary]

    /// Fetches a single payment plan summary by expense ID
    /// - Parameter expenseId: The UUID of the expense/plan to fetch
    /// - Returns: Optional payment plan summary, or nil if not found
    /// - Throws: Repository errors if fetch fails
    func fetchPaymentPlanSummary(expenseId: UUID) async throws -> PaymentPlanSummary?

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

    /// Deletes a budget development scenario and all its items
    /// - Parameter id: The ID of the scenario to delete
    /// - Throws: Repository errors if deletion fails or scenario not found
    func deleteBudgetDevelopmentScenario(id: String) async throws

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
    /// - Returns: Array of wedding events, sorted by event date
    /// - Throws: Repository errors if fetch fails
    func fetchWeddingEvents() async throws -> [WeddingEvent]
    
    /// Creates a new wedding event
    /// - Parameter event: The wedding event to create
    /// - Returns: The created event with server-assigned timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent
    
    /// Updates an existing wedding event
    /// - Parameter event: The event with updated values
    /// - Returns: The updated event with new timestamp
    /// - Throws: Repository errors if update fails or event not found
    func updateWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent
    
    /// Deletes a wedding event
    /// - Parameter id: The ID of the event to delete
    /// - Throws: Repository errors if deletion fails or event not found
    func deleteWeddingEvent(id: String) async throws

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

    /// Fetches all expense allocations for a specific scenario (bulk fetch to avoid N+1 queries)
    /// - Parameter scenarioId: The scenario ID to fetch allocations for
    /// - Returns: Array of expense allocations for the scenario
    /// - Throws: Repository errors if fetch fails
    func fetchExpenseAllocationsForScenario(scenarioId: String) async throws -> [ExpenseAllocation]

    /// Creates a new expense allocation
    /// - Parameter allocation: The expense allocation to create
    /// - Returns: The created allocation with server-assigned timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws -> ExpenseAllocation

    /// Fetches all allocations for a given expense within a scenario
    /// - Parameters:
    ///   - expenseId: Expense UUID
    ///   - scenarioId: Scenario ID
    func fetchAllocationsForExpense(expenseId: UUID, scenarioId: String) async throws -> [ExpenseAllocation]

    /// Fetches all allocations for a given expense across all scenarios
    /// - Parameter expenseId: Expense UUID
    func fetchAllocationsForExpenseAllScenarios(expenseId: UUID) async throws -> [ExpenseAllocation]

    /// Atomically replaces all allocations for an expense within a scenario
    /// - Parameters:
    ///   - expenseId: Expense UUID
    ///   - scenarioId: Scenario ID
    ///   - newAllocations: New set of allocations to persist
    func replaceAllocations(expenseId: UUID, scenarioId: String, with newAllocations: [ExpenseAllocation]) async throws

    /// Links a gift to a budget development item (legacy 1:1 linking - deprecated)
    /// - Parameters:
    ///   - giftId: The UUID of the gift to link
    ///   - budgetItemId: The ID of the budget item to link to
    /// - Throws: Repository errors if linking fails or item not found
    @available(*, deprecated, message: "Use gift allocation methods for proportional linking")
    func linkGiftToBudgetItem(giftId: UUID, budgetItemId: String) async throws

    /// Unlinks a gift from a budget development item by clearing the linked_gift_owed_id (legacy - deprecated)
    /// - Parameter budgetItemId: The ID of the budget item to unlink the gift from
    /// - Throws: Repository errors if unlinking fails or item not found
    @available(*, deprecated, message: "Use gift allocation methods for proportional linking")
    func unlinkGiftFromBudgetItem(budgetItemId: String) async throws

    // MARK: - Gift Allocation Operations (Proportional)

    /// Fetches gift allocations for a specific scenario and budget item
    /// - Parameters:
    ///   - scenarioId: The scenario ID to filter by
    ///   - budgetItemId: The budget item ID to filter by
    /// - Returns: Array of gift allocations
    /// - Throws: Repository errors if fetch fails
    func fetchGiftAllocations(scenarioId: String, budgetItemId: String) async throws -> [GiftAllocation]

    /// Fetches all gift allocations for a specific scenario (bulk fetch to avoid N+1 queries)
    /// - Parameter scenarioId: The scenario ID to fetch allocations for
    /// - Returns: Array of gift allocations for the scenario
    /// - Throws: Repository errors if fetch fails
    func fetchGiftAllocationsForScenario(scenarioId: String) async throws -> [GiftAllocation]

    /// Creates a new gift allocation
    /// - Parameter allocation: The gift allocation to create
    /// - Returns: The created allocation with server-assigned timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createGiftAllocation(_ allocation: GiftAllocation) async throws -> GiftAllocation

    /// Fetches all allocations for a given gift within a scenario
    /// - Parameters:
    ///   - giftId: Gift UUID
    ///   - scenarioId: Scenario ID
    /// - Returns: Array of gift allocations for this gift in the scenario
    func fetchAllocationsForGift(giftId: UUID, scenarioId: String) async throws -> [GiftAllocation]

    /// Fetches all allocations for a given gift across all scenarios
    /// - Parameter giftId: Gift UUID
    /// - Returns: Array of gift allocations across all scenarios
    func fetchAllocationsForGiftAllScenarios(giftId: UUID) async throws -> [GiftAllocation]

    /// Atomically replaces all allocations for a gift within a scenario
    /// - Parameters:
    ///   - giftId: Gift UUID
    ///   - scenarioId: Scenario ID
    ///   - newAllocations: New set of allocations to persist
    func replaceGiftAllocations(giftId: UUID, scenarioId: String, with newAllocations: [GiftAllocation]) async throws

    /// Links a bill calculator to a budget development item, replacing its amount with the bill's subtotal
    /// - Parameters:
    ///   - billCalculatorId: The UUID of the bill calculator to link
    ///   - budgetItemId: The ID of the budget item to link to
    ///   - billSubtotal: The pre-tax subtotal from the bill calculator
    /// - Throws: Repository errors if linking fails or item not found
    func linkBillCalculatorToBudgetItem(billCalculatorId: UUID, budgetItemId: String, billSubtotal: Double) async throws

    /// Unlinks a bill calculator from a budget development item, reverting to the pre-link amount
    /// - Parameters:
    ///   - budgetItemId: The ID of the budget item to unlink
    /// - Throws: Repository errors if unlinking fails or item not found
    func unlinkBillCalculatorFromBudgetItem(budgetItemId: String) async throws

    /// Fetches the primary budget development scenario
    /// - Returns: The primary scenario, or nil if none exists
    /// - Throws: Repository errors if fetch fails
    func fetchPrimaryBudgetScenario() async throws -> BudgetDevelopmentScenario?

    // MARK: - Composite Saves
    /// Saves a budget development scenario and its items atomically via RPC.
    /// - Parameters:
    ///   - scenario: Scenario to create or update (must include couple_id; id optional for create)
    ///   - items: Items to insert for the scenario (can be empty)
    /// - Returns: The persisted scenario ID and number of items inserted
    func saveBudgetScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int)

    // MARK: - Folder Operations

    /// Creates a new budget folder
    /// - Parameters:
    ///   - name: Folder display name
    ///   - scenarioId: Scenario ID the folder belongs to
    ///   - parentFolderId: Parent folder ID (nil for root level)
    ///   - displayOrder: Display order within parent
    /// - Returns: Created folder item
    /// - Throws: Repository errors if creation fails or validation errors
    func createFolder(name: String, scenarioId: String, parentFolderId: String?, displayOrder: Int) async throws -> BudgetItem

    /// Moves an item or folder to a different parent folder
    ///
    /// When moving a folder, all of its children (items and subfolders) move with it,
    /// preserving their relative hierarchical structure and displayOrder values within
    /// the folder. The folder itself is assigned the specified displayOrder in its new
    /// parent location.
    ///
    /// ## Circular Move Prevention
    /// Moving a folder into one of its own descendants is **disallowed** and will result
    /// in an error. The implementation must validate that the target folder is not:
    /// - The item itself
    /// - A descendant of the item being moved
    /// - Part of a circular reference chain
    ///
    /// ## Example
    /// ```
    /// // Valid move: Move "Catering" folder to "Venue" folder
    /// // Before:
    /// //   Root
    /// //   ├── Venue
    /// //   └── Catering
    /// //       └── Menu Items
    /// //
    /// // After moveItemToFolder(itemId: "catering-id", targetFolderId: "venue-id", displayOrder: 0):
    /// //   Root
    /// //   └── Venue
    /// //       └── Catering (displayOrder: 0)
    /// //           └── Menu Items (preserves original displayOrder)
    ///
    /// // Invalid move: Move "Venue" into its own child "Catering"
    /// // This would create: Venue → Catering → Venue (circular reference)
    /// // Throws: BudgetError.circularMove or BudgetError.invalidTarget
    /// ```
    ///
    /// - Parameters:
    ///   - itemId: ID of the item or folder to move
    ///   - targetFolderId: ID of the destination parent folder (nil for root level)
    ///   - displayOrder: New display order within the target folder
    ///
    /// - Throws:
    ///   - `BudgetError.circularMove`: When attempting to move a folder into one of its own descendants
    ///   - `BudgetError.invalidTarget`: When the target folder is invalid or doesn't exist
    ///   - `BudgetError.itemNotFound`: When the item to move doesn't exist
    ///   - Repository errors for database/network failures
    func moveItemToFolder(itemId: String, targetFolderId: String?, displayOrder: Int) async throws

    /// Updates display order for multiple items (drag-and-drop)
    /// - Parameter items: Array of (itemId, displayOrder) tuples
    /// - Throws: Repository errors if update fails
    func updateDisplayOrder(items: [(itemId: String, displayOrder: Int)]) async throws

    /// Toggles folder expansion state
    ///
    /// This method updates the expansion state for a budget folder, controlling whether
    /// its children are displayed in the UI. The implementation **must validate** that
    /// the specified ID refers to an actual folder (item with `isFolder = true`) and
    /// throw an error if it does not.
    ///
    /// ## Type Validation
    /// The implementation is required to:
    /// 1. Fetch the item with the specified ID
    /// 2. Verify that `isFolder == true`
    /// 3. Throw `BudgetError.notAFolder` if the item is not a folder
    /// 4. Throw `BudgetError.itemNotFound` if the item doesn't exist
    ///
    /// ## Example
    /// ```swift
    /// // Valid: Toggle expansion for a folder
    /// try await repository.toggleFolderExpansion(folderId: "folder-123", isExpanded: true)
    ///
    /// // Invalid: Attempt to toggle expansion for a regular item
    /// try await repository.toggleFolderExpansion(folderId: "item-456", isExpanded: true)
    /// // Throws: BudgetError.notAFolder("Cannot toggle expansion: item-456 is not a folder")
    /// ```
    ///
    /// - Parameters:
    ///   - folderId: ID of the folder to update (must refer to an item with `isFolder = true`)
    ///   - isExpanded: New expansion state (true = expanded, false = collapsed)
    ///
    /// - Throws:
    ///   - `BudgetError.notAFolder`: When the ID refers to a non-folder item
    ///   - `BudgetError.itemNotFound`: When no item exists with the specified ID
    ///   - Repository errors for database/network failures
    func toggleFolderExpansion(folderId: String, isExpanded: Bool) async throws

    /// Fetches budget items with hierarchical structure
    ///
    /// Returns a flat array of all budget items (both folders and regular items) for the
    /// specified scenario. The hierarchy is encoded in each item's properties rather than
    /// in a nested structure.
    ///
    /// ## Hierarchy Representation
    /// Each `BudgetItem` contains the following properties that define its position in the hierarchy:
    /// - `parentFolderId: String?` - ID of the parent folder, or `nil` for root-level items
    /// - `isFolder: Bool` - `true` for folders, `false` for regular items
    /// - `displayOrder: Int` - Sort order within the parent folder (0-based)
    ///
    /// ## Ordering Guarantee
    /// Items are returned in **no guaranteed order**. Callers must sort and group items
    /// themselves to reconstruct the hierarchy. The array may contain items in any sequence.
    ///
    /// ## Reconstructing the Tree
    /// To rebuild the hierarchical structure from the flat array:
    ///
    /// ```swift
    /// let allItems = try await repository.fetchBudgetItemsHierarchical(scenarioId: scenarioId)
    ///
    /// // 1. Group items by parent
    /// let itemsByParent = Dictionary(grouping: allItems) { $0.parentFolderId }
    ///
    /// // 2. Get root-level items (parentFolderId == nil)
    /// let rootItems = (itemsByParent[nil] ?? [])
    ///     .sorted { $0.displayOrder < $1.displayOrder }
    ///
    /// // 3. For each folder, get its children recursively
    /// func getChildren(of folderId: String) -> [BudgetItem] {
    ///     return (itemsByParent[folderId] ?? [])
    ///         .sorted { $0.displayOrder < $1.displayOrder }
    /// }
    ///
    /// // 4. Render hierarchy
    /// for rootItem in rootItems {
    ///     renderItem(rootItem)
    ///     if rootItem.isFolder {
    ///         for child in getChildren(of: rootItem.id) {
    ///             renderItem(child, indented: true)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Example Structure
    /// ```
    /// // Returned flat array (order not guaranteed):
    /// [
    ///   BudgetItem(id: "1", parentFolderId: nil, isFolder: true, displayOrder: 0, itemName: "Venue"),
    ///   BudgetItem(id: "2", parentFolderId: "1", isFolder: false, displayOrder: 0, itemName: "Hall Rental"),
    ///   BudgetItem(id: "3", parentFolderId: nil, isFolder: false, displayOrder: 1, itemName: "Rings"),
    ///   BudgetItem(id: "4", parentFolderId: "1", isFolder: false, displayOrder: 1, itemName: "Chairs")
    /// ]
    ///
    /// // Reconstructed hierarchy (after grouping and sorting):
    /// Root
    /// ├── Venue (folder, displayOrder: 0)
    /// │   ├── Hall Rental (item, displayOrder: 0)
    /// │   └── Chairs (item, displayOrder: 1)
    /// └── Rings (item, displayOrder: 1)
    /// ```
    ///
    /// - Parameter scenarioId: Scenario ID to fetch items for
    /// - Returns: Flat array of all items with hierarchy encoded in properties
    /// - Throws: Repository errors if fetch fails
    func fetchBudgetItemsHierarchical(scenarioId: String) async throws -> [BudgetItem]

    /// Calculates folder totals using database function
    /// - Parameter folderId: Folder ID
    /// - Returns: FolderTotals struct with withoutTax, tax, withTax
    /// - Throws: Repository errors if calculation fails or folder not found
    func calculateFolderTotals(folderId: String) async throws -> FolderTotals

    /// Validates if an item can be moved to a target folder
    ///
    /// Performs comprehensive validation to determine whether a move operation would be valid
    /// according to business rules, hierarchy constraints, and data integrity requirements.
    /// Returns `true` if the move is allowed, `false` if it violates any rules.
    ///
    /// ## Validation Rules
    /// The following conditions make a move **invalid** (returns `false`):
    ///
    /// ### 1. Circular Reference Prevention
    /// - **Cannot move an item to itself**: `itemId == targetFolderId`
    /// - **Cannot move a folder into its own descendants**: Would create a cycle in the hierarchy
    /// - **Cannot move a folder into itself**: Direct self-reference
    /// - Example: Moving "Venue" folder into its child "Catering" folder is forbidden
    ///
    /// ### 2. Target Validation
    /// - **Target folder must exist**: If `targetFolderId` is non-nil, it must reference an existing item
    /// - **Target must be a folder**: If `targetFolderId` is non-nil, the item must have `isFolder = true`
    /// - **Target must be in same scenario**: Cannot move items across different budget scenarios
    /// - Root-level moves (`targetFolderId = nil`) are always valid for target validation
    ///
    /// ### 3. Hierarchy Depth Limits
    /// - **Maximum depth constraint**: Moving would not exceed maximum folder nesting depth (typically 3 levels)
    /// - Depth is calculated from root to the deepest descendant after the move
    ///
    /// ### 4. Item Existence
    /// - **Source item must exist**: The `itemId` must reference an existing budget item
    /// - **Source item must be in current couple's context**: Multi-tenant isolation enforced
    ///
    /// ### 5. Cross-Context Prevention
    /// - **Same couple/tenant**: Cannot move items between different couples' budgets
    /// - **Same scenario**: Cannot move items between different budget scenarios
    /// - All items must belong to the current authenticated couple
    ///
    /// ## Error Handling
    /// This method throws errors for **system failures**, not validation failures:
    /// - `BudgetError.itemNotFound`: When `itemId` doesn't exist (system error, not validation)
    /// - `BudgetError.tenantContextMissing`: When no couple is authenticated
    /// - Repository errors: For database/network failures during validation
    ///
    /// **Note**: Validation failures (circular references, invalid targets, etc.) return `false`,
    /// they do **not** throw errors. Only use this method to check if a move is allowed before
    /// attempting it with `moveItemToFolder`.
    ///
    /// ## Usage Example
    /// ```swift
    /// // Check if move is valid before attempting
    /// let canMove = try await repository.canMoveItem(
    ///     itemId: "catering-folder-id",
    ///     toFolder: "venue-folder-id"
    /// )
    ///
    /// if canMove {
    ///     // Move is valid - proceed
    ///     try await repository.moveItemToFolder(
    ///         itemId: "catering-folder-id",
    ///         targetFolderId: "venue-folder-id",
    ///         displayOrder: 0
    ///     )
    /// } else {
    ///     // Move is invalid - show error to user
    ///     showError("Cannot move item to this location")
    /// }
    /// ```
    ///
    /// ## Validation Scenarios
    /// ```
    /// // ✅ Valid: Move item to different folder
    /// canMoveItem(itemId: "item-1", toFolder: "folder-2") → true
    ///
    /// // ✅ Valid: Move item to root level
    /// canMoveItem(itemId: "item-1", toFolder: nil) → true
    ///
    /// // ❌ Invalid: Move folder into itself
    /// canMoveItem(itemId: "folder-1", toFolder: "folder-1") → false
    ///
    /// // ❌ Invalid: Move folder into its own child
    /// // Hierarchy: Venue → Catering → Menu
    /// canMoveItem(itemId: "venue-id", toFolder: "catering-id") → false
    ///
    /// // ❌ Invalid: Target is not a folder
    /// canMoveItem(itemId: "item-1", toFolder: "item-2") → false
    ///
    /// // ❌ Invalid: Target doesn't exist
    /// canMoveItem(itemId: "item-1", toFolder: "nonexistent-id") → false
    ///
    /// // ❌ Invalid: Would exceed depth limit
    /// // Moving deep folder would create 4+ levels
    /// canMoveItem(itemId: "deep-folder", toFolder: "level-3-folder") → false
    /// ```
    ///
    /// - Parameters:
    ///   - itemId: ID of the item to validate for moving
    ///   - targetFolderId: ID of the destination folder, or `nil` for root level
    ///
    /// - Returns: `true` if the move is valid and allowed, `false` if it violates any validation rules
    ///
    /// - Throws:
    ///   - `BudgetError.itemNotFound`: When the source item doesn't exist
    ///   - `BudgetError.tenantContextMissing`: When no couple is authenticated
    ///   - Repository errors for database/network failures during validation
    func canMoveItem(itemId: String, toFolder targetFolderId: String?) async throws -> Bool

    /// Deletes a folder and optionally moves contents to parent
    /// - Parameters:
    ///   - folderId: Folder to delete
    ///   - deleteContents: If true, delete all contents; if false, move to parent
    /// - Throws: Repository errors if deletion fails or folder not found
    func deleteFolder(folderId: String, deleteContents: Bool) async throws

    // MARK: - Expense Bill Calculator Link Operations

    /// Fetches all bill calculator links for a specific expense
    /// - Parameter expenseId: The UUID of the expense
    /// - Returns: Array of expense bill calculator links
    /// - Throws: Repository errors if fetch fails
    func fetchBillCalculatorLinksForExpense(expenseId: UUID) async throws -> [ExpenseBillCalculatorLink]

    /// Fetches all expense links for a specific bill calculator
    /// - Parameter billCalculatorId: The UUID of the bill calculator
    /// - Returns: Array of expense bill calculator links
    /// - Throws: Repository errors if fetch fails
    func fetchExpenseLinksForBillCalculator(billCalculatorId: UUID) async throws -> [ExpenseBillCalculatorLink]

    /// Creates links between an expense and multiple bill calculators
    /// - Parameters:
    ///   - expenseId: The UUID of the expense to link
    ///   - billCalculatorIds: Array of bill calculator UUIDs to link
    ///   - linkType: The type of link (defaults to .full)
    ///   - notes: Optional notes for the links
    /// - Returns: Array of created links
    /// - Throws: Repository errors if creation fails
    func linkBillCalculatorsToExpense(
        expenseId: UUID,
        billCalculatorIds: [UUID],
        linkType: ExpenseBillCalculatorLink.LinkType,
        notes: String?
    ) async throws -> [ExpenseBillCalculatorLink]

    /// Removes a link between an expense and a bill calculator
    /// - Parameter linkId: The UUID of the link to remove
    /// - Throws: Repository errors if deletion fails
    func unlinkBillCalculatorFromExpense(linkId: UUID) async throws

    /// Removes all bill calculator links for a specific expense
    /// - Parameter expenseId: The UUID of the expense
    /// - Throws: Repository errors if deletion fails
    func unlinkAllBillCalculatorsFromExpense(expenseId: UUID) async throws

    /// Fetches aggregated bill total for an expense from all linked bill calculators
    /// Used for optionally overriding expense amount in payment plan creation
    /// - Parameter expenseId: The UUID of the expense
    /// - Returns: ExpenseBillTotal with aggregated amounts, or nil if no bills linked
    /// - Throws: Repository errors if fetch fails
    func fetchBillTotalForExpense(expenseId: UUID) async throws -> ExpenseBillTotal?

    // MARK: - Budget Item Bill Calculator Link Operations (Multi-Bill Support)

    /// Fetches all bill calculator links for a specific budget item
    /// - Parameter budgetItemId: The ID of the budget item (as String, matching BudgetItem.id)
    /// - Returns: Array of budget item bill calculator links
    /// - Throws: Repository errors if fetch fails
    func fetchBillCalculatorLinksForBudgetItem(budgetItemId: String) async throws -> [BudgetItemBillCalculatorLink]

    /// Links multiple bill calculators to a budget item
    /// The budget item's amount will be updated to the sum of all linked bill subtotals (excluding tax).
    /// This is handled automatically via database triggers.
    /// - Parameters:
    ///   - budgetItemId: The ID of the budget item to link to
    ///   - billCalculatorIds: Array of bill calculator UUIDs to link
    ///   - notes: Optional notes for the links
    /// - Returns: Array of created links
    /// - Throws: Repository errors if creation fails
    func linkBillCalculatorsToBudgetItem(
        budgetItemId: String,
        billCalculatorIds: [UUID],
        notes: String?
    ) async throws -> [BudgetItemBillCalculatorLink]

    /// Removes a specific bill calculator link from a budget item
    /// - Parameter linkId: The UUID of the link to remove
    /// - Throws: Repository errors if deletion fails
    func unlinkBillCalculatorFromBudgetItemByLinkId(linkId: UUID) async throws

    /// Removes all bill calculator links for a specific budget item
    /// - Parameter budgetItemId: The ID of the budget item
    /// - Throws: Repository errors if deletion fails
    func unlinkAllBillCalculatorsFromBudgetItem(budgetItemId: String) async throws

    // MARK: - Payment Plan Config Operations

    /// Fetches the configuration for a payment plan
    /// - Parameter paymentPlanId: The UUID of the payment plan
    /// - Returns: The config if found, nil otherwise
    /// - Throws: Repository errors if fetch fails
    func fetchPaymentPlanConfig(paymentPlanId: UUID) async throws -> PaymentPlanConfig?

    /// Creates a new payment plan configuration
    /// - Parameter config: The configuration to create
    /// - Returns: The created config
    /// - Throws: Repository errors if creation fails
    func createPaymentPlanConfig(_ config: PaymentPlanConfig) async throws -> PaymentPlanConfig

    /// Updates an existing payment plan configuration
    /// - Parameter config: The configuration to update
    /// - Returns: The updated config
    /// - Throws: Repository errors if update fails
    func updatePaymentPlanConfig(_ config: PaymentPlanConfig) async throws -> PaymentPlanConfig

    /// Fetches payment plan configs linked to specific bill calculators
    /// Used to find async payment plans that need recalculation when bill totals change
    /// - Parameter billCalculatorIds: Array of bill calculator UUIDs to search for
    /// - Returns: Array of payment plan configs that have any of the specified bill calculators linked
    /// - Throws: Repository errors if fetch fails
    func fetchPaymentPlanConfigsLinkedToBills(billCalculatorIds: [UUID]) async throws -> [PaymentPlanConfig]

    /// Fetches payment schedules for a specific payment plan
    /// - Parameter paymentPlanId: The UUID of the payment plan
    /// - Returns: Array of payment schedules belonging to this plan
    /// - Throws: Repository errors if fetch fails
    func fetchPaymentSchedulesByPlanId(paymentPlanId: UUID) async throws -> [PaymentSchedule]
}
