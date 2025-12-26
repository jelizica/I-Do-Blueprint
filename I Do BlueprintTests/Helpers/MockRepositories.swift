//
//  MockRepositories.swift
//  I Do BlueprintTests
//
//  Mock repository implementations for testing
//

import Foundation
import Dependencies
@testable import I_Do_Blueprint

// MARK: - Mock Guest Repository

class MockGuestRepository: GuestRepositoryProtocol {
    var guests: [Guest] = []
    var guestStats: GuestStats = GuestStats(totalGuests: 0, attendingGuests: 0, pendingGuests: 0, declinedGuests: 0, responseRate: 0.0)
    var shouldThrowError = false
    var errorToThrow: GuestError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchGuests() async throws -> [Guest] {
        if shouldThrowError { throw errorToThrow }
        return guests
    }

    func fetchGuestStats() async throws -> GuestStats {
        if shouldThrowError { throw errorToThrow }
        return guestStats
    }

    func createGuest(_ guest: Guest) async throws -> Guest {
        if shouldThrowError { throw errorToThrow }
        guests.append(guest)
        return guest
    }

    func updateGuest(_ guest: Guest) async throws -> Guest {
        if shouldThrowError { throw errorToThrow }
        if let index = guests.firstIndex(where: { $0.id == guest.id }) {
            guests[index] = guest
        }
        return guest
    }

    func deleteGuest(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        guests.removeAll(where: { $0.id == id })
    }

    func searchGuests(query: String) async throws -> [Guest] {
        if shouldThrowError { throw errorToThrow }
        return guests.filter {
            $0.firstName.localizedCaseInsensitiveContains(query) ||
            $0.lastName.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Mock Budget Repository

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
    var shouldThrowError = false
    var errorToThrow: BudgetError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchBudgetSummary() async throws -> BudgetSummary? {
        if shouldThrowError { throw errorToThrow }
        return budgetSummary
    }

    func fetchCategories() async throws -> [BudgetCategory] {
        if shouldThrowError { throw errorToThrow }
        return categories
    }

    func fetchExpenses() async throws -> [Expense] {
        if shouldThrowError { throw errorToThrow }
        return expenses
    }

    func fetchPaymentSchedules() async throws -> [PaymentSchedule] {
        if shouldThrowError { throw errorToThrow }
        return paymentSchedules
    }

    func fetchGiftsAndOwed() async throws -> [GiftOrOwed] {
        if shouldThrowError { throw errorToThrow }
        return giftsAndOwed
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

    func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule] {
        if shouldThrowError { throw errorToThrow }
        return paymentSchedules.filter { $0.vendorId == vendorId }
    }

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

    // MARK: - Gift Received Operations

    var giftsReceived: [GiftReceived] = []

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

    var moneyOwed: [MoneyOwed] = []

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

    var expenseAllocations: [ExpenseAllocation] = []

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

    func linkGiftToBudgetItem(giftId: UUID, budgetItemId: String) async throws {
        if shouldThrowError { throw errorToThrow }
    }

    var primaryBudgetScenario: BudgetDevelopmentScenario?

    func fetchPrimaryBudgetScenario() async throws -> BudgetDevelopmentScenario? {
        if shouldThrowError { throw errorToThrow }
        return primaryBudgetScenario
    }

    func fetchExpenseAllocationsForScenario(scenarioId: String) async throws -> [ExpenseAllocation] {
        if shouldThrowError { throw errorToThrow }
        return expenseAllocations.filter { $0.scenarioId == scenarioId }
    }

    func saveBudgetScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int) {
        if shouldThrowError { throw errorToThrow }
        scenarios.append(scenario)
        budgetItems.append(contentsOf: items)
        return (scenario.id, items.count)
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
}

// MARK: - Mock Task Repository

class MockTaskRepository: TaskRepositoryProtocol {
    var tasks: [WeddingTask] = []
    var subtasks: [Subtask] = []
    var taskStats: TaskStats = TaskStats(total: 0, notStarted: 0, inProgress: 0, completed: 0, overdue: 0)
    var shouldThrowError = false
    var errorToThrow: TaskError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchTasks() async throws -> [WeddingTask] {
        if shouldThrowError { throw errorToThrow }
        return tasks
    }

    func fetchTask(id: UUID) async throws -> WeddingTask? {
        if shouldThrowError { throw errorToThrow }
        return tasks.first(where: { $0.id == id })
    }

    func createTask(_ insertData: TaskInsertData) async throws -> WeddingTask {
        if shouldThrowError { throw errorToThrow }
        let task = WeddingTask.makeTest(taskName: insertData.taskName)
        tasks.append(task)
        return task
    }

    func updateTask(_ task: WeddingTask) async throws -> WeddingTask {
        if shouldThrowError { throw errorToThrow }
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
        return task
    }

    func deleteTask(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        tasks.removeAll(where: { $0.id == id })
    }

    func fetchSubtasks(taskId: UUID) async throws -> [Subtask] {
        if shouldThrowError { throw errorToThrow }
        return subtasks.filter { $0.taskId == taskId }
    }

    func createSubtask(taskId: UUID, insertData: SubtaskInsertData) async throws -> Subtask {
        if shouldThrowError { throw errorToThrow }
        let subtask = Subtask.makeTest(taskId: taskId, subtaskName: insertData.subtaskName)
        subtasks.append(subtask)
        return subtask
    }

    func updateSubtask(_ subtask: Subtask) async throws -> Subtask {
        if shouldThrowError { throw errorToThrow }
        if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
            subtasks[index] = subtask
        }
        return subtask
    }

    func deleteSubtask(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        subtasks.removeAll(where: { $0.id == id })
    }

    func fetchTaskStats() async throws -> TaskStats {
        if shouldThrowError { throw errorToThrow }
        return taskStats
    }
}

// MARK: - Mock Timeline Repository

class MockTimelineRepository: TimelineRepositoryProtocol {
    var timelineItems: [TimelineItem] = []
    var milestones: [Milestone] = []
    var shouldThrowError = false
    var errorToThrow: TimelineError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchTimelineItems() async throws -> [TimelineItem] {
        if shouldThrowError { throw errorToThrow }
        return timelineItems
    }

    func fetchTimelineItem(id: UUID) async throws -> TimelineItem? {
        if shouldThrowError { throw errorToThrow }
        return timelineItems.first(where: { $0.id == id })
    }

    func createTimelineItem(_ insertData: TimelineItemInsertData) async throws -> TimelineItem {
        if shouldThrowError { throw errorToThrow }
        let item = TimelineItem.makeTest(title: insertData.title)
        timelineItems.append(item)
        return item
    }

    func updateTimelineItem(_ item: TimelineItem) async throws -> TimelineItem {
        if shouldThrowError { throw errorToThrow }
        if let index = timelineItems.firstIndex(where: { $0.id == item.id }) {
            timelineItems[index] = item
        }
        return item
    }

    func deleteTimelineItem(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        timelineItems.removeAll(where: { $0.id == id })
    }

    func fetchMilestones() async throws -> [Milestone] {
        if shouldThrowError { throw errorToThrow }
        return milestones
    }

    func fetchMilestone(id: UUID) async throws -> Milestone? {
        if shouldThrowError { throw errorToThrow }
        return milestones.first(where: { $0.id == id })
    }

    func createMilestone(_ insertData: MilestoneInsertData) async throws -> Milestone {
        if shouldThrowError { throw errorToThrow }
        let milestone = Milestone.makeTest(milestoneName: insertData.milestoneName)
        milestones.append(milestone)
        return milestone
    }

    func updateMilestone(_ milestone: Milestone) async throws -> Milestone {
        if shouldThrowError { throw errorToThrow }
        if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
            milestones[index] = milestone
        }
        return milestone
    }

    func deleteMilestone(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        milestones.removeAll(where: { $0.id == id })
    }
}

// MARK: - Mock Settings Repository

class MockSettingsRepository: SettingsRepositoryProtocol {
    var settings: CoupleSettings = CoupleSettings.makeTest()
    var customVendorCategories: [CustomVendorCategory] = []
    var shouldThrowError = false
    var errorToThrow: SettingsError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchSettings() async throws -> CoupleSettings {
        if shouldThrowError { throw errorToThrow }
        return settings
    }

    func updateSettings(_ partialSettings: [String: Any]) async throws -> CoupleSettings {
        if shouldThrowError { throw errorToThrow }
        return settings
    }

    func updateGlobalSettings(_ newSettings: GlobalSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.global = newSettings
    }

    func updateThemeSettings(_ newSettings: ThemeSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.theme = newSettings
    }

    func updateBudgetSettings(_ newSettings: BudgetSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.budget = newSettings
    }

    func updateCashFlowSettings(_ newSettings: CashFlowSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.cashFlow = newSettings
    }

    func updateTasksSettings(_ newSettings: TasksSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.tasks = newSettings
    }

    func updateVendorsSettings(_ newSettings: VendorsSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.vendors = newSettings
    }

    func updateGuestsSettings(_ newSettings: GuestsSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.guests = newSettings
    }

    func updateDocumentsSettings(_ newSettings: DocumentsSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.documents = newSettings
    }

    func updateNotificationsSettings(_ newSettings: NotificationsSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.notifications = newSettings
    }

    func updateLinksSettings(_ newSettings: LinksSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.links = newSettings
    }

    func fetchCustomVendorCategories() async throws -> [CustomVendorCategory] {
        if shouldThrowError { throw errorToThrow }
        return customVendorCategories
    }

    func createVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory {
        if shouldThrowError { throw errorToThrow }
        customVendorCategories.append(category)
        return category
    }

    func createCustomVendorCategory(name: String, description: String?, typicalBudgetPercentage: String?) async throws -> CustomVendorCategory {
        if shouldThrowError { throw errorToThrow }
        let category = CustomVendorCategory(
            id: UUID().uuidString,
            coupleId: UUID().uuidString,
            name: name,
            description: description,
            typicalBudgetPercentage: typicalBudgetPercentage,
            createdAt: Date(),
            updatedAt: Date()
        )
        customVendorCategories.append(category)
        return category
    }

    func updateVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory {
        if shouldThrowError { throw errorToThrow }
        if let index = customVendorCategories.firstIndex(where: { $0.id == category.id }) {
            customVendorCategories[index] = category
        }
        return category
    }

    func updateCustomVendorCategory(id: String, name: String?, description: String?, typicalBudgetPercentage: String?) async throws -> CustomVendorCategory {
        if shouldThrowError { throw errorToThrow }
        guard let index = customVendorCategories.firstIndex(where: { $0.id == id }) else {
            throw errorToThrow
        }
        var category = customVendorCategories[index]
        if let name = name { category.name = name }
        if let description = description { category.description = description }
        if let typicalBudgetPercentage = typicalBudgetPercentage {
            category.typicalBudgetPercentage = typicalBudgetPercentage
        }
        customVendorCategories[index] = category
        return category
    }

    func deleteVendorCategory(id: String) async throws {
        if shouldThrowError { throw errorToThrow }
        customVendorCategories.removeAll(where: { $0.id == id })
    }

    func deleteCustomVendorCategory(id: String) async throws {
        if shouldThrowError { throw errorToThrow }
        customVendorCategories.removeAll(where: { $0.id == id })
    }

    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        if shouldThrowError { throw errorToThrow }
        return []
    }

    func formatPhoneNumbers() async throws -> PhoneFormatResult {
        if shouldThrowError { throw errorToThrow }
        return PhoneFormatResult(message: "Success", vendors: nil, contacts: nil)
    }

    func resetData(keepBudgetSandbox: Bool, keepAffordability: Bool, keepCategories: Bool) async throws {
        if shouldThrowError { throw errorToThrow }
    }
}

// MARK: - Mock Notes Repository

class MockNotesRepository: NotesRepositoryProtocol {
    var notes: [Note] = []
    var shouldThrowError = false
    var errorToThrow: NotesError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchNotes() async throws -> [Note] {
        if shouldThrowError { throw errorToThrow }
        return notes
    }

    func fetchNoteById(_ id: UUID) async throws -> Note {
        if shouldThrowError { throw errorToThrow }
        guard let note = notes.first(where: { $0.id == id }) else {
            throw NotesError.notFound(id: id)
        }
        return note
    }

    func fetchNotesByType(_ type: NoteRelatedType) async throws -> [Note] {
        if shouldThrowError { throw errorToThrow }
        return notes.filter { $0.relatedType == type }
    }

    func fetchNotesByRelatedEntity(type: NoteRelatedType, relatedId: String) async throws -> [Note] {
        if shouldThrowError { throw errorToThrow }
        return notes.filter { $0.relatedType == type && $0.relatedId == relatedId }
    }

    func createNote(_ data: NoteInsertData) async throws -> Note {
        if shouldThrowError { throw errorToThrow }
        let note = Note.makeTest(content: data.content, relatedType: data.relatedType)
        notes.append(note)
        return note
    }

    func updateNote(id: UUID, data: NoteInsertData) async throws -> Note {
        if shouldThrowError { throw errorToThrow }
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            throw NotesError.notFound(id: id)
        }
        var note = notes[index]
        note.content = data.content
        notes[index] = note
        return note
    }

    func deleteNote(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        notes.removeAll(where: { $0.id == id })
    }

    func searchNotes(query: String) async throws -> [Note] {
        if shouldThrowError { throw errorToThrow }
        return notes.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }
}

// MARK: - Mock Document Repository

class MockDocumentRepository: DocumentRepositoryProtocol {
    var documents: [Document] = []
    var shouldThrowError = false
    var errorToThrow: DocumentError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchDocuments() async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents
    }

    func fetchDocuments(type: DocumentType) async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents.filter { $0.documentType == type }
    }

    func fetchDocuments(bucket: DocumentBucket) async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents.filter { $0.bucketName == bucket.rawValue }
    }

    func fetchDocuments(vendorId: Int) async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents.filter { $0.vendorId == vendorId }
    }

    func fetchDocument(id: UUID) async throws -> Document? {
        if shouldThrowError { throw errorToThrow }
        return documents.first(where: { $0.id == id })
    }

    func createDocument(_ insertData: DocumentInsertData) async throws -> Document {
        if shouldThrowError { throw errorToThrow }
        let document = Document.makeTest(originalFilename: insertData.originalFilename, fileSize: insertData.fileSize)
        documents.append(document)
        return document
    }

    func updateDocument(_ document: Document) async throws -> Document {
        if shouldThrowError { throw errorToThrow }
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
        }
        return document
    }

    func deleteDocument(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        documents.removeAll(where: { $0.id == id })
    }

    func batchDeleteDocuments(ids: [UUID]) async throws {
        if shouldThrowError { throw errorToThrow }
        documents.removeAll(where: { ids.contains($0.id) })
    }

    func updateDocumentTags(id: UUID, tags: [String]) async throws -> Document {
        if shouldThrowError { throw errorToThrow }
        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw DocumentError.notFound(id: id)
        }
        var document = documents[index]
        document.tags = tags
        documents[index] = document
        return document
    }

    func updateDocumentType(id: UUID, type: DocumentType) async throws -> Document {
        if shouldThrowError { throw errorToThrow }
        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw DocumentError.notFound(id: id)
        }
        var document = documents[index]
        document.documentType = type
        documents[index] = document
        return document
    }

    func searchDocuments(query: String) async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents.filter { $0.originalFilename.localizedCaseInsensitiveContains(query) }
    }

    func fetchAllTags() async throws -> [String] {
        if shouldThrowError { throw errorToThrow }
        let allTags = documents.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    func uploadDocument(fileData: Data, metadata: FileUploadMetadata, coupleId: UUID) async throws -> Document {
        if shouldThrowError { throw errorToThrow }
        let document = Document.makeTest(originalFilename: metadata.fileName, fileSize: Int64(fileData.count))
        documents.append(document)
        return document
    }

    func downloadDocument(document: Document) async throws -> Data {
        if shouldThrowError { throw errorToThrow }
        return Data()
    }

    func getPublicURL(for document: Document) async throws -> URL {
        if shouldThrowError { throw errorToThrow }
        return URL(string: "https://example.com/\(document.originalFilename)")!
    }
}

// MARK: - Mock Vendor Repository

class MockVendorRepository: VendorRepositoryProtocol {
    var vendors: [Vendor] = []
    var vendorStats: VendorStats = VendorStats(total: 0, booked: 0, available: 0, archived: 0, totalCost: 0.0, averageRating: 0.0)
    var reviews: [VendorReview] = []
    var vendorTypes: [VendorType] = []
    var shouldThrowError = false
    var errorToThrow: VendorError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchVendors() async throws -> [Vendor] {
        if shouldThrowError { throw errorToThrow }
        return vendors
    }

    func fetchVendorStats() async throws -> VendorStats {
        if shouldThrowError { throw errorToThrow }
        return vendorStats
    }

    func createVendor(_ vendor: Vendor) async throws -> Vendor {
        if shouldThrowError { throw errorToThrow }
        vendors.append(vendor)
        return vendor
    }

    func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        if shouldThrowError { throw errorToThrow }
        if let index = vendors.firstIndex(where: { $0.id == vendor.id }) {
            vendors[index] = vendor
        }
        return vendor
    }

    func deleteVendor(id: Int64) async throws {
        if shouldThrowError { throw errorToThrow }
        vendors.removeAll(where: { $0.id == id })
    }

    func fetchVendorReviews(vendorId: Int64) async throws -> [VendorReview] {
        if shouldThrowError { throw errorToThrow }
        return reviews.filter { $0.vendorId == vendorId }
    }

    func fetchVendorReviewStats(vendorId: Int64) async throws -> VendorReviewStats? {
        if shouldThrowError { throw errorToThrow }
        return nil
    }

    func fetchVendorPaymentSummary(vendorId: Int64) async throws -> VendorPaymentSummary? {
        if shouldThrowError { throw errorToThrow }
        return nil
    }

    func fetchVendorContractSummary(vendorId: Int64) async throws -> VendorContract? {
        if shouldThrowError { throw errorToThrow }
        return nil
    }

    func fetchVendorDetails(id: Int64) async throws -> VendorDetails {
        if shouldThrowError { throw errorToThrow }
        return VendorDetails(
            vendor: vendors.first(where: { $0.id == id })!
        )
    }

    func fetchVendorTypes() async throws -> [VendorType] {
        if shouldThrowError { throw errorToThrow }
        return vendorTypes
    }
}

// MARK: - Mock Visual Planning Repository

class MockVisualPlanningRepository: VisualPlanningRepositoryProtocol {
    var moodBoards: [MoodBoard] = []
    var colorPalettes: [ColorPalette] = []
    var seatingCharts: [SeatingChart] = []
    var seatingGuests: [SeatingGuest] = []
    var tables: [Table] = []
    var seatAssignments: [SeatingAssignment] = []
    var shouldThrowError = false
    var errorToThrow: VisualPlanningError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchMoodBoards() async throws -> [MoodBoard] {
        if shouldThrowError { throw errorToThrow }
        return moodBoards
    }

    func fetchMoodBoard(id: UUID) async throws -> MoodBoard? {
        if shouldThrowError { throw errorToThrow }
        return moodBoards.first(where: { $0.id == id })
    }

    func createMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        if shouldThrowError { throw errorToThrow }
        moodBoards.append(moodBoard)
        return moodBoard
    }

    func updateMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        if shouldThrowError { throw errorToThrow }
        if let index = moodBoards.firstIndex(where: { $0.id == moodBoard.id }) {
            moodBoards[index] = moodBoard
        }
        return moodBoard
    }

    func deleteMoodBoard(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        moodBoards.removeAll(where: { $0.id == id })
    }

    func fetchColorPalettes() async throws -> [ColorPalette] {
        if shouldThrowError { throw errorToThrow }
        return colorPalettes
    }

    func fetchColorPalette(id: UUID) async throws -> ColorPalette? {
        if shouldThrowError { throw errorToThrow }
        return colorPalettes.first(where: { $0.id == id })
    }

    func createColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        if shouldThrowError { throw errorToThrow }
        colorPalettes.append(palette)
        return palette
    }

    func updateColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        if shouldThrowError { throw errorToThrow }
        if let index = colorPalettes.firstIndex(where: { $0.id == palette.id }) {
            colorPalettes[index] = palette
        }
        return palette
    }

    func deleteColorPalette(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        colorPalettes.removeAll(where: { $0.id == id })
    }

    func fetchSeatingCharts() async throws -> [SeatingChart] {
        if shouldThrowError { throw errorToThrow }
        return seatingCharts
    }

    func fetchSeatingChart(id: UUID) async throws -> SeatingChart? {
        if shouldThrowError { throw errorToThrow }
        return seatingCharts.first(where: { $0.id == id })
    }

    func createSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        if shouldThrowError { throw errorToThrow }
        seatingCharts.append(chart)
        return chart
    }

    func updateSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        if shouldThrowError { throw errorToThrow }
        if let index = seatingCharts.firstIndex(where: { $0.id == chart.id }) {
            seatingCharts[index] = chart
        }
        return chart
    }

    func deleteSeatingChart(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        seatingCharts.removeAll(where: { $0.id == id })
    }

    func fetchSeatingGuests(for tenantId: String) async throws -> [SeatingGuest] {
        if shouldThrowError { throw errorToThrow }
        return seatingGuests
    }

    func fetchTables(for chartId: UUID) async throws -> [Table] {
        if shouldThrowError { throw errorToThrow }
        guard let chart = seatingCharts.first(where: { $0.id == chartId }) else {
            return []
        }
        return chart.tables
    }

    func fetchSeatAssignments(for chartId: UUID) async throws -> [SeatingAssignment] {
        if shouldThrowError { throw errorToThrow }
        guard let chart = seatingCharts.first(where: { $0.id == chartId }) else {
            return []
        }
        return chart.seatingAssignments
    }
}

// MARK: - Mock Collaboration Repository

class MockCollaborationRepository: CollaborationRepositoryProtocol {
    var collaborators: [Collaborator] = []
    var roles: [CollaborationRole] = []
    var currentUserCollaborator: Collaborator?
    var currentUserRole: RoleName?
    var permissions: [String: Bool] = [:]
    var shouldThrowError = false
    var errorToThrow: CollaborationError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchCollaborators() async throws -> [Collaborator] {
        if shouldThrowError { throw errorToThrow }
        return collaborators
    }

    func fetchRoles() async throws -> [CollaborationRole] {
        if shouldThrowError { throw errorToThrow }
        return roles
    }

    func fetchCollaborator(id: UUID) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }
        guard let collaborator = collaborators.first(where: { $0.id == id }) else {
            throw CollaborationError.notFound(id: id)
        }
        return collaborator
    }

    func fetchCurrentUserCollaborator() async throws -> Collaborator? {
        if shouldThrowError { throw errorToThrow }
        return currentUserCollaborator
    }

    func inviteCollaborator(email: String, roleId: UUID, displayName: String?) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }
        let collaborator = Collaborator.makeTest(email: email, displayName: displayName, status: .pending)
        collaborators.append(collaborator)
        return collaborator
    }

    func acceptInvitation(id: UUID) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }
        guard let index = collaborators.firstIndex(where: { $0.id == id }) else {
            throw CollaborationError.notFound(id: id)
        }
        var collaborator = collaborators[index]
        collaborator.status = .active
        collaborator.acceptedAt = Date()
        collaborators[index] = collaborator
        return collaborator
    }

    func updateCollaboratorRole(id: UUID, roleId: UUID) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }
        guard let index = collaborators.firstIndex(where: { $0.id == id }) else {
            throw CollaborationError.notFound(id: id)
        }
        var collaborator = collaborators[index]
        collaborator.roleId = roleId
        collaborators[index] = collaborator
        return collaborator
    }

    func removeCollaborator(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        collaborators.removeAll(where: { $0.id == id })
    }

    func hasPermission(_ permission: String) async throws -> Bool {
        if shouldThrowError { throw errorToThrow }
        return permissions[permission] ?? false
    }

    func getCurrentUserRole() async throws -> RoleName? {
        if shouldThrowError { throw errorToThrow }
        return currentUserRole
    }

    func fetchInvitationByToken(_ token: String) async throws -> InvitationDetails {
        if shouldThrowError { throw errorToThrow }
        throw CollaborationError.invitationNotFound
    }

    func createOwnerCollaborator(
        coupleId: UUID,
        userId: UUID,
        email: String,
        displayName: String?
    ) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }

        // Check if already exists (idempotency)
        if let existing = collaborators.first(where: { $0.coupleId == coupleId && $0.userId == userId }) {
            return existing
        }

        // Create owner collaborator
        let ownerRole = roles.first(where: { $0.roleName == .owner })
        let collaborator = Collaborator.makeTest(
            coupleId: coupleId,
            userId: userId,
            roleId: ownerRole?.id ?? UUID(),
            invitedBy: userId,
            acceptedAt: Date(),
            status: .active,
            email: email,
            displayName: displayName
        )
        collaborators.append(collaborator)
        return collaborator
    }
}

// MARK: - Mock Presence Repository

class MockPresenceRepository: PresenceRepositoryProtocol {
    var presenceRecords: [Presence] = []
    var shouldThrowError = false
    var errorToThrow: PresenceError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchActivePresence() async throws -> [Presence] {
        if shouldThrowError { throw errorToThrow }
        return presenceRecords.filter { !$0.isStale }
    }

    func trackPresence(
        status: PresenceStatus,
        currentView: String?,
        currentResourceType: String?,
        currentResourceId: UUID?
    ) async throws -> Presence {
        if shouldThrowError { throw errorToThrow }
        let presence = Presence.makeTest(status: status, currentView: currentView)
        presenceRecords.append(presence)
        return presence
    }

    func updateEditingState(
        isEditing: Bool,
        resourceType: String?,
        resourceId: UUID?
    ) async throws -> Presence {
        if shouldThrowError { throw errorToThrow }
        guard let index = presenceRecords.firstIndex(where: { !$0.isStale }) else {
            throw PresenceError.notFound
        }
        var presence = presenceRecords[index]
        presence.isEditing = isEditing
        presence.editingResourceType = resourceType
        presence.editingResourceId = resourceId
        presenceRecords[index] = presence
        return presence
    }

    func sendHeartbeat() async throws -> Presence {
        if shouldThrowError { throw errorToThrow }
        guard let index = presenceRecords.firstIndex(where: { !$0.isStale }) else {
            throw PresenceError.notFound
        }
        var presence = presenceRecords[index]
        presence.lastHeartbeat = Date()
        presenceRecords[index] = presence
        return presence
    }

    func stopTracking() async throws {
        if shouldThrowError { throw errorToThrow }
        if let index = presenceRecords.firstIndex(where: { !$0.isStale }) {
            var presence = presenceRecords[index]
            presence.status = .offline
            presenceRecords[index] = presence
        }
    }

    func cleanupStalePresence() async throws {
        if shouldThrowError { throw errorToThrow }
        presenceRecords.removeAll(where: { $0.isStale })
    }
}

// MARK: - Mock Activity Feed Repository

class MockActivityFeedRepository: ActivityFeedRepositoryProtocol {
    var activities: [ActivityEvent] = []
    var shouldThrowError = false
    var errorToThrow: ActivityFeedError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchActivities(limit: Int, offset: Int) async throws -> [ActivityEvent] {
        if shouldThrowError { throw errorToThrow }
        let start = min(offset, activities.count)
        let end = min(offset + limit, activities.count)
        return Array(activities[start..<end])
    }

    func fetchActivities(actionType: ActionType, limit: Int) async throws -> [ActivityEvent] {
        if shouldThrowError { throw errorToThrow }
        return activities.filter { $0.actionType == actionType }.prefix(limit).map { $0 }
    }

    func fetchActivities(resourceType: ResourceType, limit: Int) async throws -> [ActivityEvent] {
        if shouldThrowError { throw errorToThrow }
        return activities.filter { $0.resourceType == resourceType }.prefix(limit).map { $0 }
    }

    func fetchActivities(actorId: UUID, limit: Int) async throws -> [ActivityEvent] {
        if shouldThrowError { throw errorToThrow }
        return activities.filter { $0.actorId == actorId }.prefix(limit).map { $0 }
    }

    func fetchUnreadCount() async throws -> Int {
        if shouldThrowError { throw errorToThrow }
        return activities.filter { !$0.isRead }.count
    }

    func markAsRead(id: UUID) async throws -> ActivityEvent {
        if shouldThrowError { throw errorToThrow }
        guard let index = activities.firstIndex(where: { $0.id == id }) else {
            throw ActivityFeedError.fetchFailed(underlying: NSError(domain: "Test", code: -1))
        }
        var activity = activities[index]
        activity.isRead = true
        activities[index] = activity
        return activity
    }

    func markAllAsRead() async throws -> Int {
        if shouldThrowError { throw errorToThrow }
        let unreadCount = activities.filter { !$0.isRead }.count
        for index in activities.indices {
            activities[index].isRead = true
        }
        return unreadCount
    }

    func fetchActivityStats() async throws -> ActivityStats {
        if shouldThrowError { throw errorToThrow }
        var activitiesByAction: [ActionType: Int] = [:]
        var activitiesByResource: [ResourceType: Int] = [:]

        for activity in activities {
            activitiesByAction[activity.actionType, default: 0] += 1
            activitiesByResource[activity.resourceType, default: 0] += 1
        }

        let oneDayAgo = Date().addingTimeInterval(-86400)
        let recentCount = activities.filter { $0.createdAt > oneDayAgo }.count

        return ActivityStats(
            totalActivities: activities.count,
            activitiesByAction: activitiesByAction,
            activitiesByResource: activitiesByResource,
            recentActivityCount: recentCount
        )
    }
}
