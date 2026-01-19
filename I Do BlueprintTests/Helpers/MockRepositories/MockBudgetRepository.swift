//
//  MockBudgetRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of BudgetRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockBudgetRepository: BudgetRepositoryProtocol {
    var budgetSummary: BudgetSummary?
    var categories: [BudgetCategory] = []
    var expenses: [Expense] = []
    var paymentSchedules: [PaymentSchedule] = []
    var giftsAndOwed: [GiftOrOwed] = []
    var scenarios: [SavedScenario] = []
    var budgetItems: [BudgetItem] = []
    var budgetOverviewItems: [BudgetOverviewItem] = []
    var taxRates: [TaxInfo] = []
    var weddingEvents: [WeddingEvent] = []
    var affordabilityScenarios: [AffordabilityScenario] = []
    var affordabilityContributions: [ContributionItem] = []
    var giftsReceived: [GiftReceived] = []
    var moneyOwed: [MoneyOwed] = []
    var expenseAllocations: [ExpenseAllocation] = []
    var primaryBudgetScenario: BudgetDevelopmentScenario?
    var shouldThrowError = false
    var errorToThrow: BudgetError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    // MARK: - Budget Summary

    func fetchBudgetSummary() async throws -> BudgetSummary? {
        if shouldThrowError { throw errorToThrow }
        return budgetSummary
    }

    // MARK: - Category Budget Metrics

    var categoryMetrics: [CategoryBudgetMetrics] = []

    func fetchCategoryBudgetMetrics() async throws -> [CategoryBudgetMetrics] {
        if shouldThrowError { throw errorToThrow }
        return categoryMetrics
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [BudgetCategory] {
        if shouldThrowError { throw errorToThrow }
        return categories
    }

    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        if shouldThrowError { throw errorToThrow }
        categories.append(category)
        return category
    }

    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        if shouldThrowError { throw errorToThrow }
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
        return category
    }

    func deleteCategory(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        categories.removeAll(where: { $0.id == id })
    }

    // MARK: - Expenses

    func fetchExpenses() async throws -> [Expense] {
        if shouldThrowError { throw errorToThrow }
        return expenses
    }

    func createExpense(_ expense: Expense) async throws -> Expense {
        if shouldThrowError { throw errorToThrow }
        expenses.append(expense)
        return expense
    }

    func updateExpense(_ expense: Expense) async throws -> Expense {
        if shouldThrowError { throw errorToThrow }
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        }
        return expense
    }

    func deleteExpense(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        expenses.removeAll(where: { $0.id == id })
    }

    func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense] {
        if shouldThrowError { throw errorToThrow }
        return expenses.filter { $0.vendorId == vendorId }
    }

    // MARK: - Payment Schedules

    func fetchPaymentSchedules() async throws -> [PaymentSchedule] {
        if shouldThrowError { throw errorToThrow }
        return paymentSchedules
    }

    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        if shouldThrowError { throw errorToThrow }
        paymentSchedules.append(schedule)
        return schedule
    }

    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        if shouldThrowError { throw errorToThrow }
        if let index = paymentSchedules.firstIndex(where: { $0.id == schedule.id }) {
            paymentSchedules[index] = schedule
        }
        return schedule
    }

    func deletePaymentSchedule(id: Int64) async throws {
        if shouldThrowError { throw errorToThrow }
        paymentSchedules.removeAll(where: { $0.id == id })
    }

    func batchDeletePaymentSchedules(ids: [Int64]) async throws -> Int {
        if shouldThrowError { throw errorToThrow }
        let originalCount = paymentSchedules.count
        paymentSchedules.removeAll { ids.contains($0.id) }
        return originalCount - paymentSchedules.count
    }

    func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule] {
        if shouldThrowError { throw errorToThrow }
        return paymentSchedules.filter { $0.vendorId == vendorId }
    }

    // MARK: - Budget Development

    func fetchBudgetDevelopmentScenarios() async throws -> [SavedScenario] {
        if shouldThrowError { throw errorToThrow }
        return scenarios
    }

    func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem] {
        if shouldThrowError { throw errorToThrow }
        return budgetItems
    }

    func fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async throws -> [BudgetOverviewItem] {
        if shouldThrowError { throw errorToThrow }
        return budgetOverviewItems
    }

    func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        if shouldThrowError { throw errorToThrow }
        scenarios.append(scenario)
        return scenario
    }

    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        if shouldThrowError { throw errorToThrow }
        if let index = scenarios.firstIndex(where: { $0.id == scenario.id }) {
            scenarios[index] = scenario
        }
        return scenario
    }

    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        if shouldThrowError { throw errorToThrow }
        budgetItems.append(item)
        return item
    }

    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        if shouldThrowError { throw errorToThrow }
        if let index = budgetItems.firstIndex(where: { $0.id == item.id }) {
            budgetItems[index] = item
        }
        return item
    }

    func deleteBudgetDevelopmentItem(id: String) async throws {
        if shouldThrowError { throw errorToThrow }
        budgetItems.removeAll(where: { $0.id == id })
    }

    func fetchPrimaryBudgetScenario() async throws -> BudgetDevelopmentScenario? {
        if shouldThrowError { throw errorToThrow }
        return primaryBudgetScenario
    }

    func saveBudgetScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int) {
        if shouldThrowError { throw errorToThrow }
        scenarios.append(scenario)
        budgetItems.append(contentsOf: items)
        return (scenario.id, items.count)
    }

    // MARK: - Tax Rates

    func fetchTaxRates() async throws -> [TaxInfo] {
        if shouldThrowError { throw errorToThrow }
        return taxRates
    }

    func createTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        if shouldThrowError { throw errorToThrow }
        taxRates.append(taxInfo)
        return taxInfo
    }

    func updateTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        if shouldThrowError { throw errorToThrow }
        if let index = taxRates.firstIndex(where: { $0.id == taxInfo.id }) {
            taxRates[index] = taxInfo
        }
        return taxInfo
    }

    func deleteTaxRate(id: Int64) async throws {
        if shouldThrowError { throw errorToThrow }
        taxRates.removeAll(where: { $0.id == id })
    }

    // MARK: - Wedding Events

    func fetchWeddingEvents() async throws -> [WeddingEvent] {
        if shouldThrowError { throw errorToThrow }
        return weddingEvents
    }
    
    func createWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent {
        if shouldThrowError { throw errorToThrow }
        weddingEvents.append(event)
        return event
    }
    
    func updateWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent {
        if shouldThrowError { throw errorToThrow }
        if let index = weddingEvents.firstIndex(where: { $0.id == event.id }) {
            weddingEvents[index] = event
        }
        return event
    }
    
    func deleteWeddingEvent(id: String) async throws {
        if shouldThrowError { throw errorToThrow }
        weddingEvents.removeAll(where: { $0.id == id })
    }

    // MARK: - Affordability

    func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario] {
        if shouldThrowError { throw errorToThrow }
        return affordabilityScenarios
    }

    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario {
        if shouldThrowError { throw errorToThrow }
        affordabilityScenarios.append(scenario)
        return scenario
    }

    func deleteAffordabilityScenario(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        affordabilityScenarios.removeAll(where: { $0.id == id })
    }

    func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem] {
        if shouldThrowError { throw errorToThrow }
        return affordabilityContributions.filter { $0.scenarioId == scenarioId }
    }

    func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem {
        if shouldThrowError { throw errorToThrow }
        affordabilityContributions.append(contribution)
        return contribution
    }

    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        affordabilityContributions.removeAll(where: { $0.id == id && $0.scenarioId == scenarioId })
    }

    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    // MARK: - Gifts and Owed

    func fetchGiftsAndOwed() async throws -> [GiftOrOwed] {
        if shouldThrowError { throw errorToThrow }
        return giftsAndOwed
    }

    func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        if shouldThrowError { throw errorToThrow }
        return gift
    }

    func createGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        if shouldThrowError { throw errorToThrow }
        giftsAndOwed.append(gift)
        return gift
    }

    func deleteGiftOrOwed(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        giftsAndOwed.removeAll(where: { $0.id == id })
    }

    func linkGiftToBudgetItem(giftId: UUID, budgetItemId: String) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    func unlinkGiftFromBudgetItem(budgetItemId: String) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    func linkBillCalculatorToBudgetItem(billCalculatorId: UUID, budgetItemId: String, billSubtotal: Double) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    func unlinkBillCalculatorFromBudgetItem(budgetItemId: String) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    // MARK: - Budget Item Bill Calculator Link Operations (Multi-Bill Support)

    var budgetItemBillCalculatorLinks: [BudgetItemBillCalculatorLink] = []

    func fetchBillCalculatorLinksForBudgetItem(budgetItemId: String) async throws -> [BudgetItemBillCalculatorLink] {
        if shouldThrowError { throw errorToThrow }
        guard let itemUUID = UUID(uuidString: budgetItemId) else { return [] }
        return budgetItemBillCalculatorLinks.filter { $0.budgetItemId == itemUUID }
    }

    func linkBillCalculatorsToBudgetItem(budgetItemId: String, billCalculatorIds: [UUID], notes: String?) async throws -> [BudgetItemBillCalculatorLink] {
        if shouldThrowError { throw errorToThrow }
        guard let itemUUID = UUID(uuidString: budgetItemId) else { return [] }

        var createdLinks: [BudgetItemBillCalculatorLink] = []
        for billCalcId in billCalculatorIds {
            let link = BudgetItemBillCalculatorLink(
                id: UUID(),
                budgetItemId: itemUUID,
                billCalculatorId: billCalcId,
                coupleId: UUID(),
                notes: notes,
                createdAt: Date(),
                updatedAt: Date()
            )
            budgetItemBillCalculatorLinks.append(link)
            createdLinks.append(link)
        }
        return createdLinks
    }

    func unlinkBillCalculatorFromBudgetItemByLinkId(linkId: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        budgetItemBillCalculatorLinks.removeAll { $0.id == linkId }
    }

    func unlinkAllBillCalculatorsFromBudgetItem(budgetItemId: String) async throws {
        if shouldThrowError { throw errorToThrow }
        guard let itemUUID = UUID(uuidString: budgetItemId) else { return }
        budgetItemBillCalculatorLinks.removeAll { $0.budgetItemId == itemUUID }
    }

    // MARK: - Gift Received Operations

    func fetchGiftsReceived() async throws -> [GiftReceived] {
        if shouldThrowError { throw errorToThrow }
        return giftsReceived
    }

    func createGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        if shouldThrowError { throw errorToThrow }
        giftsReceived.append(gift)
        return gift
    }

    func updateGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        if shouldThrowError { throw errorToThrow }
        if let index = giftsReceived.firstIndex(where: { $0.id == gift.id }) {
            giftsReceived[index] = gift
        }
        return gift
    }

    func deleteGiftReceived(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        giftsReceived.removeAll(where: { $0.id == id })
    }

    // MARK: - Money Owed Operations

    func fetchMoneyOwed() async throws -> [MoneyOwed] {
        if shouldThrowError { throw errorToThrow }
        return moneyOwed
    }

    func createMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        if shouldThrowError { throw errorToThrow }
        moneyOwed.append(money)
        return money
    }

    func updateMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        if shouldThrowError { throw errorToThrow }
        if let index = moneyOwed.firstIndex(where: { $0.id == money.id }) {
            moneyOwed[index] = money
        }
        return money
    }

    func deleteMoneyOwed(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        moneyOwed.removeAll(where: { $0.id == id })
    }

    // MARK: - Expense Allocations

    func fetchExpenseAllocations(scenarioId: String, budgetItemId: String) async throws -> [ExpenseAllocation] {
        if shouldThrowError { throw errorToThrow }
        return expenseAllocations.filter { $0.scenarioId == scenarioId && $0.budgetItemId == budgetItemId }
    }

    func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws -> ExpenseAllocation {
        if shouldThrowError { throw errorToThrow }
        expenseAllocations.append(allocation)
        return allocation
    }

    func fetchAllocationsForExpense(expenseId: UUID, scenarioId: String) async throws -> [ExpenseAllocation] {
        if shouldThrowError { throw errorToThrow }
        return expenseAllocations.filter { $0.expenseId == expenseId.uuidString && $0.scenarioId == scenarioId }
    }

    func fetchAllocationsForExpenseAllScenarios(expenseId: UUID) async throws -> [ExpenseAllocation] {
        if shouldThrowError { throw errorToThrow }
        return expenseAllocations.filter { $0.expenseId == expenseId.uuidString }
    }

    func replaceAllocations(expenseId: UUID, scenarioId: String, with newAllocations: [ExpenseAllocation]) async throws {
        if shouldThrowError { throw errorToThrow }
        expenseAllocations.removeAll { $0.expenseId == expenseId.uuidString && $0.scenarioId == scenarioId }
        expenseAllocations.append(contentsOf: newAllocations)
    }

    func fetchExpenseAllocationsForScenario(scenarioId: String) async throws -> [ExpenseAllocation] {
        if shouldThrowError { throw errorToThrow }
        return expenseAllocations.filter { $0.scenarioId == scenarioId }
    }

    // MARK: - Gift Allocations (Proportional)

    var giftAllocations: [GiftAllocation] = []

    func fetchGiftAllocations(scenarioId: String, budgetItemId: String) async throws -> [GiftAllocation] {
        if shouldThrowError { throw errorToThrow }
        return giftAllocations.filter { $0.scenarioId == scenarioId && $0.budgetItemId == budgetItemId }
    }

    func fetchGiftAllocationsForScenario(scenarioId: String) async throws -> [GiftAllocation] {
        if shouldThrowError { throw errorToThrow }
        return giftAllocations.filter { $0.scenarioId == scenarioId }
    }

    func createGiftAllocation(_ allocation: GiftAllocation) async throws -> GiftAllocation {
        if shouldThrowError { throw errorToThrow }
        giftAllocations.append(allocation)
        return allocation
    }

    func fetchAllocationsForGift(giftId: UUID, scenarioId: String) async throws -> [GiftAllocation] {
        if shouldThrowError { throw errorToThrow }
        return giftAllocations.filter { $0.giftId == giftId.uuidString && $0.scenarioId == scenarioId }
    }

    func fetchAllocationsForGiftAllScenarios(giftId: UUID) async throws -> [GiftAllocation] {
        if shouldThrowError { throw errorToThrow }
        return giftAllocations.filter { $0.giftId == giftId.uuidString }
    }

    func replaceGiftAllocations(giftId: UUID, scenarioId: String, with newAllocations: [GiftAllocation]) async throws {
        if shouldThrowError { throw errorToThrow }
        giftAllocations.removeAll { $0.giftId == giftId.uuidString && $0.scenarioId == scenarioId }
        giftAllocations.append(contentsOf: newAllocations)
    }

    // MARK: - Folder Operations

    func createFolder(name: String, scenarioId: String, parentFolderId: String?, displayOrder: Int) async throws -> BudgetItem {
        if shouldThrowError { throw errorToThrow }
        
        let folder = BudgetItem.createFolder(
            name: name,
            scenarioId: scenarioId,
            parentFolderId: parentFolderId,
            displayOrder: displayOrder,
            coupleId: UUID().uuidString
        )
        
        budgetItems.append(folder)
        return folder
    }

    func moveItemToFolder(itemId: String, targetFolderId: String?, displayOrder: Int) async throws {
        if shouldThrowError { throw errorToThrow }
        
        guard let index = budgetItems.firstIndex(where: { $0.id == itemId }) else {
            throw BudgetError.updateFailed(underlying: NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Item not found"]))
        }
        
        var item = budgetItems[index]
        item.parentFolderId = targetFolderId
        item.displayOrder = displayOrder
        budgetItems[index] = item
    }

    func updateDisplayOrder(items: [(itemId: String, displayOrder: Int)]) async throws {
        if shouldThrowError { throw errorToThrow }
        
        for (itemId, order) in items {
            if let index = budgetItems.firstIndex(where: { $0.id == itemId }) {
                var item = budgetItems[index]
                item.displayOrder = order
                budgetItems[index] = item
            }
        }
    }

    func toggleFolderExpansion(folderId: String, isExpanded: Bool) async throws {
        if shouldThrowError { throw errorToThrow }
        // isExpanded is now managed in the view layer, not persisted in the model
        // This method is kept for protocol conformance but does nothing
    }

    func fetchBudgetItemsHierarchical(scenarioId: String) async throws -> [BudgetItem] {
        if shouldThrowError { throw errorToThrow }
        return budgetItems.filter { $0.scenarioId == scenarioId }.sorted { $0.displayOrder < $1.displayOrder }
    }

    func calculateFolderTotals(folderId: String) async throws -> FolderTotals {
        if shouldThrowError { throw errorToThrow }
        
        // Get all descendants of this folder
        func getAllDescendants(of folderId: String) -> [BudgetItem] {
            var result: [BudgetItem] = []
            var queue = [folderId]
            
            while !queue.isEmpty {
                let currentId = queue.removeFirst()
                let children = budgetItems.filter { $0.parentFolderId == currentId && !$0.isFolder }
                result.append(contentsOf: children)
                
                let childFolders = budgetItems.filter { $0.parentFolderId == currentId && $0.isFolder }
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
        if shouldThrowError { throw errorToThrow }
        
        // Can't move to itself
        if itemId == targetFolderId { return false }
        
        // If moving to root, always allowed
        guard let targetFolderId = targetFolderId else { return true }
        
        // Check if target is a folder
        guard let targetFolder = budgetItems.first(where: { $0.id == targetFolderId }),
              targetFolder.isFolder else {
            return false
        }
        
        // Check depth limit (max 3 levels)
        func getDepth(of itemId: String) -> Int {
            var depth = 0
            var currentId: String? = itemId
            
            while let id = currentId,
                  let item = budgetItems.first(where: { $0.id == id }),
                  let parentId = item.parentFolderId {
                depth += 1
                currentId = parentId
            }
            
            return depth
        }
        
        let targetDepth = getDepth(of: targetFolderId)
        if targetDepth >= 3 { return false }
        
        // Check for circular reference
        var visited = Set<String>()
        var currentId: String? = targetFolderId
        
        while let id = currentId {
            if visited.contains(id) || id == itemId { return false }
            visited.insert(id)
            
            guard let item = budgetItems.first(where: { $0.id == id }) else { break }
            currentId = item.parentFolderId
        }
        
        return true
    }

    func deleteFolder(folderId: String, deleteContents: Bool) async throws {
        if shouldThrowError { throw errorToThrow }
        
        guard let folder = budgetItems.first(where: { $0.id == folderId }) else {
            throw BudgetError.deleteFailed(underlying: NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Folder not found"]))
        }
        
        if deleteContents {
            // Delete folder and all contents recursively
            func deleteRecursively(folderId: String) {
                let children = budgetItems.filter { $0.parentFolderId == folderId }
                for child in children {
                    if child.isFolder {
                        deleteRecursively(folderId: child.id)
                    }
                    budgetItems.removeAll(where: { $0.id == child.id })
                }
            }
            
            deleteRecursively(folderId: folderId)
            budgetItems.removeAll(where: { $0.id == folderId })
        } else {
            // Move contents to parent, then delete folder
            let children = budgetItems.filter { $0.parentFolderId == folderId }
            
            for child in children {
                if let index = budgetItems.firstIndex(where: { $0.id == child.id }) {
                    var updatedChild = budgetItems[index]
                    updatedChild.parentFolderId = folder.parentFolderId
                    budgetItems[index] = updatedChild
                }
            }
            
            budgetItems.removeAll(where: { $0.id == folderId })
        }
    }

    // MARK: - Expense Bill Calculator Link Operations

    func fetchBillCalculatorLinksForExpense(expenseId: UUID) async throws -> [ExpenseBillCalculatorLink] {
        return []
    }

    func fetchExpenseLinksForBillCalculator(billCalculatorId: UUID) async throws -> [ExpenseBillCalculatorLink] {
        return []
    }

    func linkBillCalculatorsToExpense(expenseId: UUID, billCalculatorIds: [UUID], linkType: ExpenseBillCalculatorLink.LinkType, notes: String?) async throws -> [ExpenseBillCalculatorLink] {
        return []
    }

    func unlinkBillCalculatorFromExpense(linkId: UUID) async throws {
        // No-op for mock
    }

    func unlinkAllBillCalculatorsFromExpense(expenseId: UUID) async throws {
        // No-op for mock
    }

    func fetchBillTotalForExpense(expenseId: UUID) async throws -> ExpenseBillTotal? {
        return nil
    }

    // MARK: - Budget Item Bill Calculator Link Operations

    func fetchBillCalculatorLinksForBudgetItem(budgetItemId: String) async throws -> [BudgetItemBillCalculatorLink] {
        return []
    }

    func linkBillCalculatorsToBudgetItem(budgetItemId: String, billCalculatorIds: [UUID], notes: String?) async throws -> [BudgetItemBillCalculatorLink] {
        return []
    }

    func unlinkBillCalculatorFromBudgetItemByLinkId(linkId: UUID) async throws {
        // No-op for mock
    }

    func unlinkAllBillCalculatorsFromBudgetItem(budgetItemId: String) async throws {
        // No-op for mock
    }

    // MARK: - Payment Plan Config Operations

    func fetchPaymentPlanConfig(paymentPlanId: UUID) async throws -> PaymentPlanConfig? {
        return nil
    }

    func createPaymentPlanConfig(_ config: PaymentPlanConfig) async throws -> PaymentPlanConfig {
        return config
    }

    func updatePaymentPlanConfig(_ config: PaymentPlanConfig) async throws -> PaymentPlanConfig {
        return config
    }

    func fetchPaymentPlanConfigsLinkedToBills(billCalculatorIds: [UUID]) async throws -> [PaymentPlanConfig] {
        return []
    }

    func fetchPaymentSchedulesByPlanId(paymentPlanId: UUID) async throws -> [PaymentSchedule] {
        return paymentSchedules.filter { $0.paymentPlanId == paymentPlanId }
    }
}
