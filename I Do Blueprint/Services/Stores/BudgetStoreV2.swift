//
//  BudgetStoreV2.swift
//  I Do Blueprint
//
//  New architecture version of BudgetStore using repository pattern
//  - Uses dependency injection for testability
//  - Implements optimistic updates for better UX
//  - Includes automatic rollback on errors
//
//  ARCHITECTURE:
//  BudgetStoreV2 is a composition root that owns and coordinates 6 feature-specific sub-stores.
//  Views should access sub-stores directly for domain-specific operations:
//    - budgetStore.affordability.loadScenarios()
//    - budgetStore.payments.addPayment(schedule)
//    - budgetStore.categoryStore.addCategory(category)
//    - budgetStore.expenseStore.addExpense(expense)
//    - budgetStore.gifts.loadGiftsData()
//    - budgetStore.development.loadBudgetDevelopmentItems(scenarioId:)
//

import Combine
import Dependencies
import Foundation
import Supabase
import SwiftUI

@MainActor
class BudgetStoreV2: ObservableObject, CacheableStore {

    // MARK: - Composed Stores
    // These stores are publicly accessible for direct use in views
    // Views should call methods on these stores directly rather than through delegation
    // Note: Using `var` to allow SwiftUI bindings via `$budgetStore.affordability.property`

    /// Affordability calculator store - manages scenarios and contributions
    /// Access directly: `budgetStore.affordability.loadScenarios()`
    public var affordability: AffordabilityStore

    /// Payment schedule store - manages payment schedules
    /// Access directly: `budgetStore.payments.addPayment(schedule)`
    public var payments: PaymentScheduleStore

    /// Gifts store - manages gifts and money owed
    /// Access directly: `budgetStore.gifts.loadGiftsData()`
    public var gifts: GiftsStore
    
    /// Expense store - manages expenses
    /// Access directly: `budgetStore.expenseStore.addExpense(expense)`
    public var expenseStore: ExpenseStoreV2
    
    /// Category store - manages budget categories
    /// Access directly: `budgetStore.categoryStore.addCategory(category)`
    public var categoryStore: CategoryStoreV2
    
    /// Budget development store - manages scenarios, items, and folders
    /// Access directly: `budgetStore.development.loadBudgetDevelopmentItems(scenarioId:)`
    public var development: BudgetDevelopmentStoreV2

    // MARK: - Published State

    /// Main budget data loading state
    @Published var loadingState: LoadingState<BudgetData> = .idle

    @Published private(set) var categoryBenchmarks: [CategoryBenchmark] = []
    @Published var savedScenarios: [SavedScenario] = []
    @Published var taxRates: [TaxInfo] = []
    @Published var weddingEvents: [WeddingEvent] = []
    @Published var cashFlowData: [CashFlowDataPoint] = []
    @Published var incomeItems: [CashFlowItem] = []
    @Published var expenseItems: [CashFlowItem] = []
    @Published var cashFlowInsights: [CashFlowInsight] = []
    @Published var recentActivities: [BudgetActivity] = []

    /// Primary budget development scenario (cached)
    @Published private(set) var primaryScenario: BudgetDevelopmentScenario?

    // MARK: - Cache Management

    // Store-level caching
    var lastLoadTime: Date?
    let cacheValidityDuration: TimeInterval = 300 // 5 minutes

    /// Cache validity that also ensures we actually have loaded data
    func isCacheValid() -> Bool {
        guard case .loaded = loadingState,
              let last = lastLoadTime else { return false }
        return Date().timeIntervalSince(last) < cacheValidityDuration
    }
    
    // MARK: - Dependencies

    @Dependency(\.budgetRepository) var repository
    let logger = AppLogger.database

    // MARK: - Combine Subscriptions

    private var cancellables = Set<AnyCancellable>()

    // Task tracking for cancellation handling
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        // Initialize composed stores
        self.payments = PaymentScheduleStore()
        self.gifts = GiftsStore()
        self.expenseStore = ExpenseStoreV2()
        self.categoryStore = CategoryStoreV2()
        self.development = BudgetDevelopmentStoreV2()

        // Initialize affordability store with payment schedule provider
        self.affordability = AffordabilityStore(paymentSchedulesProvider: { [weak payments] in
            payments?.paymentSchedules ?? []
        })

        // Forward objectWillChange from composed stores to parent
        // This ensures SwiftUI detects changes in nested @Published properties
        payments.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        gifts.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        affordability.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        expenseStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        categoryStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        development.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        // Listen for settings changes
        NotificationCenter.default.addObserver(
            forName: .settingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleSettingsChanged()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .settingsDidChange, object: nil)
    }

    // MARK: - Settings Change Handler

    private func handleSettingsChanged() async {
        logger.info("Settings changed, reloading tax rates")
        // Get the updated settings from AppStores
        if let settingsStore = try? await MainActor.run(body: {
            // Access settings store from environment or app stores
            return AppStores.shared.settings
        }) {
            loadTaxRatesFromSettings(settingsStore.settings.budget.taxRates)
        }
    }

    // MARK: - Public Interface

    /// Load all budget data in parallel
    func loadBudgetData(force: Bool = false) async {
        // Use cached data if still valid
        if !force && isCacheValid() {
            logger.debug("Using cached budget data (age: \(Int(cacheAge()))s)")
            return
        }
        // Cancel any previous load task
        loadTask?.cancel()

        // Create new load task
        loadTask = Task { @MainActor in
            let totalStart = Date()
            var mainThreadAccumulated: TimeInterval = 0

            guard loadingState.isIdle || loadingState.hasError || force else {
                return
            }

            // mark main-thread: set loading
            do {
                let t0 = Date()
                loadingState = .loading
                mainThreadAccumulated += Date().timeIntervalSince(t0)
            }

            do {
                try Task.checkCancellation()

                // Measure sub-operations
                let sumStart = Date(); async let summary = repository.fetchBudgetSummary()
                let catStart = Date(); async let categories = repository.fetchCategories()
                let expStart = Date(); async let expenses = repository.fetchExpenses()

                let summaryResult = try await summary
                let categoriesResult = try await categories
                let expensesResult = try await expenses

                // Record sub-ops
                await PerformanceMonitor.shared.recordOperation("budget.fetchSummary", duration: Date().timeIntervalSince(sumStart))
                await PerformanceMonitor.shared.recordOperation("budget.fetchCategories", duration: Date().timeIntervalSince(catStart))
                await PerformanceMonitor.shared.recordOperation("budget.fetchExpenses", duration: Date().timeIntervalSince(expStart))

                try Task.checkCancellation()

                // Create budget data structure
                let t1 = Date()
                let budgetData = BudgetData(
                    summary: summaryResult,
                    categories: categoriesResult,
                    expenses: expensesResult
                )

                loadingState = .loaded(budgetData)
                lastLoadTime = Date()
                mainThreadAccumulated += Date().timeIntervalSince(t1)

                // Load data into composed stores (async work not counted toward main-thread)
                await payments.loadPaymentSchedules()
                await gifts.loadGiftsData()
                
                // Update category store with loaded categories
                categoryStore.updateCategories(categoriesResult)

                // Load primary budget scenario (may touch main-thread briefly)
                let t2 = Date()
                await loadPrimaryScenario()
                mainThreadAccumulated += Date().timeIntervalSince(t2)
                
                // Update expense payment statuses based on payment schedules
                await updateAllExpensePaymentStatuses()

                do {
                    let devStart = Date()
                    savedScenarios = try await repository.fetchBudgetDevelopmentScenarios()
                    weddingEvents = try await repository.fetchWeddingEvents()
                    await PerformanceMonitor.shared.recordOperation("budget.fetchDevData", duration: Date().timeIntervalSince(devStart))
                } catch {
                    logger.error("Failed to load additional data", error: error)
                }

                #if DEBUG
                logger.warning("Placeholder data being used: categoryBenchmarks, cashFlowData, incomeItems, expenseItems, cashFlowInsights, recentActivities")
                #endif
                let t3 = Date()
                categoryBenchmarks = []
                cashFlowData = []
                incomeItems = []
                expenseItems = []
                cashFlowInsights = []
                recentActivities = []
                mainThreadAccumulated += Date().timeIntervalSince(t3)

                logger.info("Loaded budget data: \(categoriesResult.count) categories, \(expensesResult.count) expenses")
            } catch is CancellationError {
                AppLogger.ui.debug("BudgetStoreV2.loadBudgetData: Load cancelled (expected during tenant switch)")
                let tCancel = Date(); loadingState = .idle; mainThreadAccumulated += Date().timeIntervalSince(tCancel)
            } catch let error as URLError where error.code == .cancelled {
                AppLogger.ui.debug("BudgetStoreV2.loadBudgetData: Load cancelled (URLError)")
                let tCancel = Date(); loadingState = .idle; mainThreadAccumulated += Date().timeIntervalSince(tCancel)
            } catch {
                let tErr = Date(); loadingState = .error(BudgetError.fetchFailed(underlying: error)); mainThreadAccumulated += Date().timeIntervalSince(tErr)
                await handleError(error, operation: "loadBudgetData", context: [
                    "force": force
                ]) { [weak self] in
                    await self?.loadBudgetData(force: force)
                }
            }

            await PerformanceMonitor.shared.recordOperation(
                "budget.loadBudgetData",
                duration: Date().timeIntervalSince(totalStart),
                mainThread: mainThreadAccumulated
            )
        }

        await loadTask?.value
    }

    /// Load budget summary
    func loadBudgetSummary() async {
        do {
            let summary = try await repository.fetchBudgetSummary()

            if case .loaded(var budgetData) = loadingState {
                budgetData.summary = summary
                loadingState = .loaded(budgetData)
            }
        } catch let fetchError {
            loadingState = .error(BudgetError.fetchFailed(underlying: fetchError))
            await handleError(fetchError, operation: "loadBudgetSummary") { [weak self] in
                await self?.loadBudgetSummary()
            }
        }
    }

    // MARK: - Refresh Operations

    /// Refresh all budget data
    func refresh() async {
        await loadBudgetData(force: true)
    }

    // MARK: - Tax Rates

    /// Load tax rates from settings
    /// Tax rates are stored in couple_settings.budget.taxRates, not in a separate table
    func loadTaxRatesFromSettings(_ settingsTaxRates: [SettingsTaxRate]) {
        // Convert SettingsTaxRate to TaxInfo for compatibility
        taxRates = settingsTaxRates.enumerated().map { index, settingsRate in
            TaxInfo(
                id: Int64(index + 1), // Generate sequential IDs
                createdAt: nil,
                region: settingsRate.name,
                taxRate: settingsRate.rate / 100.0 // Convert percentage to decimal (10.35 -> 0.1035)
            )
        }
        logger.info("Loaded \(taxRates.count) tax rates from settings")
    }

    // MARK: - Retry Helper

    /// Retry loading budget data
    func retryLoad() async {
        await loadBudgetData(force: true)
    }

    // MARK: - Payment Plan Summaries
    
    /// Fetch payment plan summaries with grouping strategy
    /// Delegates to PaymentScheduleStore
    /// - Parameter groupBy: Strategy for grouping payments (default: by expense)
    /// - Returns: Array of payment plan summaries grouped according to strategy
    func fetchPaymentPlanSummaries(
        groupBy strategy: PaymentPlanGroupingStrategy = .byExpense
    ) async throws -> [PaymentPlanSummary] {
        return try await payments.fetchPaymentPlanSummaries(groupBy: strategy, expenses: expenseStore.expenses)
    }
    
    /// Fetch hierarchical payment plan groups (for vendor/expense grouping)
    /// Delegates to PaymentScheduleStore
    /// - Parameter groupBy: Strategy for grouping payments
    /// - Returns: Array of hierarchical groups containing multiple plans
    func fetchPaymentPlanGroups(
        groupBy strategy: PaymentPlanGroupingStrategy
    ) async throws -> [PaymentPlanGroup] {
        return try await payments.fetchPaymentPlanGroups(groupBy: strategy, expenses: expenseStore.expenses)
    }

    // MARK: - Primary Budget Scenario

    /// Load the primary budget development scenario
    func loadPrimaryScenario() async {
        do {
            primaryScenario = try await repository.fetchPrimaryBudgetScenario()
            if let scenario = primaryScenario {
                logger.info("Loaded primary scenario: \(scenario.scenarioName) ($\(scenario.totalWithTax))")
            } else {
                logger.info("No primary scenario found")
            }
        } catch {
            await handleError(error, operation: "loadPrimaryScenario") { [weak self] in
                await self?.loadPrimaryScenario()
            }
        }
    }
    
    // MARK: - Batch Category Operations
    
    /// Batch delete multiple categories - delegates to CategoryStoreV2
    /// - Parameter ids: Array of category IDs to delete
    /// - Returns: Result with succeeded and failed deletions
    func batchDeleteCategories(ids: [UUID]) async -> BatchDeleteResult {
        let result = await categoryStore.batchDeleteCategories(ids: ids)
        
        // Reload budget data if any succeeded
        if !result.succeeded.isEmpty {
            await loadBudgetData(force: true)
        }
        
        return result
    }
    
    // MARK: - Wedding Events Management
    
    /// Fetches all wedding events for the current couple
    func fetchWeddingEvents() async throws -> [WeddingEvent] {
        return try await repository.fetchWeddingEvents()
    }
    
    /// Creates a new wedding event
    func createWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent {
        let createdEvent = try await repository.createWeddingEvent(event)
        
        // Update local state on main actor
        await MainActor.run {
            weddingEvents.append(createdEvent)
            logger.info("Added wedding event to local state: \(createdEvent.eventName)")
        }
        
        return createdEvent
    }
    
    /// Updates an existing wedding event
    func updateWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent {
        let updatedEvent = try await repository.updateWeddingEvent(event)
        
        // Update local state on main actor
        await MainActor.run {
            if let index = weddingEvents.firstIndex(where: { $0.id == updatedEvent.id }) {
                weddingEvents[index] = updatedEvent
                logger.info("Updated wedding event in local state: \(updatedEvent.eventName)")
            } else {
                logger.warning("Updated event not found in local state, appending: \(updatedEvent.id)")
                weddingEvents.append(updatedEvent)
            }
        }
        
        return updatedEvent
    }
    
    /// Deletes a wedding event
    func deleteWeddingEvent(id: String) async throws {
        try await repository.deleteWeddingEvent(id: id)
        
        // Update local state on main actor
        await MainActor.run {
            weddingEvents.removeAll { $0.id == id }
            logger.info("Removed wedding event from local state: \(id)")
        }
    }

    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        // Cancel in-flight tasks to avoid race conditions during tenant switch
        loadTask?.cancel()

        // Reset state and invalidate cache
        loadingState = .idle
        categoryBenchmarks = []
        savedScenarios = []
        taxRates = []
        weddingEvents = []
        cashFlowData = []
        incomeItems = []
        expenseItems = []
        cashFlowInsights = []
        recentActivities = []
        primaryScenario = nil
        lastLoadTime = nil

        // Reset composed stores
        payments.resetLoadedState()
        gifts.resetLoadedState()
        affordability.resetLoadedState()
        expenseStore.resetLoadedState()
        categoryStore.resetLoadedState()
        development.resetLoadedState()
    }
}
