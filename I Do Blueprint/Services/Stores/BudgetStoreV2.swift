//
//  BudgetStoreV2.swift
//  I Do Blueprint
//
//  New architecture version of BudgetStore using repository pattern
//  - Uses dependency injection for testability
//  - Implements optimistic updates for better UX
//  - Includes automatic rollback on errors
//

import Combine
import Dependencies
import Foundation
import Supabase
import SwiftUI

@MainActor
class BudgetStoreV2: ObservableObject {
    
    // MARK: - Composed Stores
    
    /// Affordability calculator store - manages scenarios and contributions
    let affordability: AffordabilityStore
    
    /// Payment schedule store - manages payment schedules
    let payments: PaymentScheduleStore
    
    /// Gifts store - manages gifts and money owed
    let gifts: GiftsStore
    
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
                mainThreadAccumulated += Date().timeIntervalSince(t1)
                
                // Load data into composed stores (async work not counted toward main-thread)
                await payments.loadPaymentSchedules()
                await gifts.loadGiftsData()
                
                // Load primary budget scenario (may touch main-thread briefly)
                let t2 = Date()
                await loadPrimaryScenario()
                mainThreadAccumulated += Date().timeIntervalSince(t2)
                
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
                logger.error("Error loading budget data", error: error)
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
        }
    }
    
    // MARK: - Refresh Operations
    
    /// Refresh all budget data
    func refresh() async {
        await loadBudgetData(force: true)
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
    
    // MARK: - Payment Aliases for Compatibility (Delegate to PaymentScheduleStore)
    
    func addPayment(_ payment: PaymentSchedule) async {
        await payments.addPayment(payment)
    }
    
    func deletePayment(_ payment: PaymentSchedule) async {
        await payments.deletePayment(payment)
    }
    
    func updatePayment(_ payment: PaymentSchedule) async {
        await payments.updatePayment(payment)
    }
    
    func addPaymentSchedule(_ schedule: PaymentSchedule) async {
        await payments.addPayment(schedule)
    }
    
    func updatePaymentSchedule(_ schedule: PaymentSchedule) async {
        await payments.updatePayment(schedule)
    }
    
    func deletePaymentSchedule(id: Int64) async {
        await payments.deletePayment(id: id)
    }
    
    // MARK: - Affordability Calculator Methods (Delegate to AffordabilityStore)
    
    /// Load affordability scenarios - delegates to AffordabilityStore
    func loadAffordabilityScenarios() async {
        await affordability.loadScenarios()
    }
    
    /// Load affordability contributions - delegates to AffordabilityStore
    func loadAffordabilityContributions(scenarioId: UUID) async {
        await affordability.loadContributions(scenarioId: scenarioId)
    }
    
    /// Save affordability scenario - delegates to AffordabilityStore
    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async {
        await affordability.saveScenario(scenario)
    }
    
    /// Delete affordability scenario - delegates to AffordabilityStore
    func deleteAffordabilityScenario(id: UUID) async {
        await affordability.deleteScenario(id: id)
    }
    
    /// Save affordability contribution - delegates to AffordabilityStore
    func saveAffordabilityContribution(_ contribution: ContributionItem) async {
        await affordability.saveContribution(contribution)
    }
    
    /// Delete affordability contribution - delegates to AffordabilityStore
    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async {
        await affordability.deleteContribution(id: id, scenarioId: scenarioId)
    }
    
    /// Link gifts to scenario - delegates to AffordabilityStore
    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async {
        await affordability.linkGiftsToScenario(giftIds: giftIds, scenarioId: scenarioId)
    }
    
    /// Unlink gift from scenario - delegates to AffordabilityStore
    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async {
        await affordability.unlinkGiftFromScenario(giftId: giftId, scenarioId: scenarioId)
    }
    
    /// Set wedding date - delegates to AffordabilityStore
    func setWeddingDate(_ dateString: String) {
        affordability.setWeddingDate(dateString)
    }
    
    /// Select scenario - delegates to AffordabilityStore
    func selectScenario(_ scenario: AffordabilityScenario) {
        affordability.selectScenario(scenario)
    }
    
    /// Reset editing state - delegates to AffordabilityStore
    func resetEditingState() {
        affordability.resetEditingState()
    }
    
    /// Save changes - delegates to AffordabilityStore
    func saveChanges() async {
        await affordability.saveChanges()
    }
    
    /// Create scenario - delegates to AffordabilityStore
    func createScenario(name: String) async {
        await affordability.createScenario(name: name)
    }
    
    /// Delete scenario - delegates to AffordabilityStore
    func deleteScenario(_ scenario: AffordabilityScenario) async {
        await affordability.deleteScenario(scenario)
    }
    
    /// Add contribution - delegates to AffordabilityStore
    func addContribution(name: String, amount: Double, type: ContributionType, date: Date?) async {
        await affordability.addContribution(name: name, amount: amount, type: type, date: date)
    }
    
    /// Delete contribution - delegates to AffordabilityStore
    func deleteContribution(_ contribution: ContributionItem) async {
        await affordability.deleteContribution(contribution)
    }
    
    /// Load available gifts - delegates to AffordabilityStore
    func loadAvailableGifts() async {
        await affordability.loadAvailableGifts()
    }
    
    /// Link gifts - delegates to AffordabilityStore
    func linkGifts(giftIds: [UUID]) async {
        await affordability.linkGifts(giftIds: giftIds)
    }
    
    /// Update gift - delegates to AffordabilityStore
    func updateGift(_ gift: GiftOrOwed) async {
        await affordability.updateGift(gift)
    }
    
    /// Start editing gift - delegates to AffordabilityStore
    func startEditingGift(contributionId: UUID) async {
        await affordability.startEditingGift(contributionId: contributionId)
    }
    
    /// Mark field changed - delegates to AffordabilityStore
    func markFieldChanged() {
        affordability.markFieldChanged()
    }
    
    /// Load scenarios (alias) - delegates to AffordabilityStore
    func loadScenarios() async {
        await affordability.loadScenarios()
    }
    
    /// Load contributions (alias) - delegates to AffordabilityStore
    func loadContributions() async {
        await affordability.loadContributions()
    }
    
    /// Load payment schedules - delegates to PaymentScheduleStore
    func loadPaymentSchedules() async {
        await payments.loadPaymentSchedules()
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
            logger.error("Failed to load primary scenario", error: error)
            SentryService.shared.captureError(error, context: ["operation": "loadPrimaryScenario"])
        }
    }
    
    // MARK: - State Management
    
    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
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
        
        // Reset composed stores
        payments.resetLoadedState()
        gifts.resetLoadedState()
        affordability.resetLoadedState()
    }
}
