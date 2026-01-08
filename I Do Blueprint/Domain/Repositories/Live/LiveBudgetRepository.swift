// swiftlint:disable file_length
import Foundation
import Supabase

/// Production implementation of BudgetRepositoryProtocol
/// Uses Supabase client for all data operations with automatic caching
// swiftlint:disable type_body_length
actor LiveBudgetRepository: BudgetRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository
    private let sessionManager = SessionManager.shared

    // In-flight request de-duplication
    private var inFlightSummary: Task<BudgetSummary?, Error>?
    private var inFlightCategories: Task<[BudgetCategory], Error>?
    private var inFlightExpenses: [UUID: Task<[Expense], Error>] = [:]

    // Domain Services
    private lazy var allocationService = BudgetAllocationService(repository: self)
    private lazy var aggregationService = BudgetAggregationService(repository: self)
    
    // Internal Data Sources
    private var categoryDataSource: BudgetCategoryDataSource?
    private var expenseDataSource: ExpenseDataSource?
    private var paymentScheduleDataSource: PaymentScheduleDataSource?
    private var giftsAndOwedDataSource: GiftsAndOwedDataSource?
    private var affordabilityDataSource: AffordabilityDataSource?
    private var budgetDevelopmentDataSource: BudgetDevelopmentDataSource?

    init(supabase: SupabaseClient? = nil) {
        self.supabase = supabase
    }

    // Convenience initializer using SupabaseManager singleton
    init() {
        supabase = SupabaseManager.shared.client
    }

    private let cacheStrategy = BudgetCacheStrategy()

    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }

    private func getTenantId() async throws -> UUID {
        try await TenantContextProvider.shared.requireTenantId()
    }
    
    /// Lazily initializes the category data source
    private func getCategoryDataSource() async throws -> BudgetCategoryDataSource {
        if let dataSource = categoryDataSource {
            return dataSource
        }
        let client = try getClient()
        let dataSource = BudgetCategoryDataSource(supabase: client)
        categoryDataSource = dataSource
        return dataSource
    }
    
    /// Lazily initializes the expense data source
    private func getExpenseDataSource() async throws -> ExpenseDataSource {
        if let dataSource = expenseDataSource {
            return dataSource
        }
        let client = try getClient()
        let dataSource = ExpenseDataSource(supabase: client)
        expenseDataSource = dataSource
        return dataSource
    }

    /// Lazily initializes the payment schedule data source
    private func getPaymentScheduleDataSource() async throws -> PaymentScheduleDataSource {
        if let dataSource = paymentScheduleDataSource {
            return dataSource
        }
        let client = try getClient()
        let dataSource = PaymentScheduleDataSource(supabase: client)
        paymentScheduleDataSource = dataSource
        return dataSource
    }

    /// Lazily initializes the gifts and owed data source
    private func getGiftsAndOwedDataSource() async throws -> GiftsAndOwedDataSource {
        if let dataSource = giftsAndOwedDataSource {
            return dataSource
        }
        let client = try getClient()
        let dataSource = GiftsAndOwedDataSource(supabase: client)
        giftsAndOwedDataSource = dataSource
        return dataSource
    }

    /// Lazily initializes the affordability data source
    private func getAffordabilityDataSource() async throws -> AffordabilityDataSource {
        if let dataSource = affordabilityDataSource {
            return dataSource
        }
        let client = try getClient()
        let dataSource = AffordabilityDataSource(supabase: client)
        affordabilityDataSource = dataSource
        return dataSource
    }

    /// Lazily initializes the budget development data source
    private func getBudgetDevelopmentDataSource() async throws -> BudgetDevelopmentDataSource {
        if let dataSource = budgetDevelopmentDataSource {
            return dataSource
        }
        let client = try getClient()
        let dataSource = BudgetDevelopmentDataSource(supabase: client)
        budgetDevelopmentDataSource = dataSource
        return dataSource
    }

    /// Ensures a valid auth session exists before making authenticated requests
    /// This is critical for POST/PUT/DELETE operations that require JWT tokens
    private func ensureValidSession() async throws {
        let client = try getClient()
        do {
            let session = try await client.auth.session
            logger.debug("✅ Valid session confirmed: user=\(session.user.id)")
        } catch {
            logger.error("❌ No valid auth session available", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    // MARK: - Budget Summary

    func fetchBudgetSummary() async throws -> BudgetSummary? {
        let cacheKey = "budget_summary"

        // ✅ Check cache first (5 min TTL)
        if let cached: BudgetSummary = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            logger.info("Cache hit: budget summary")
            return cached
        }

        // Coalesce in-flight request (singleton scope)
        if let task = inFlightSummary {
            return try await task.value
        }

        let task = Task<BudgetSummary?, Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            self.logger.info("Cache miss: fetching budget summary from database")
            let client = try await self.getClient()
            let startTime = Date()
            let response: [BudgetSummary] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_settings")
                    .select()
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value
            }
            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchBudgetSummary", duration: duration)
            self.logger.info("Fetched budget summary in \(String(format: "%.2f", duration))s")
            let summary = response.first
            if let summary { await RepositoryCache.shared.set(cacheKey, value: summary, ttl: 300) }
            return summary
        }

        inFlightSummary = task
        do {
            let result = try await task.value
            inFlightSummary = nil
            return result
        } catch {
            inFlightSummary = nil
            logger.error("Budget summary fetch failed", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchBudgetSummary",
                "repository": "LiveBudgetRepository"
            ])
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Category Budget Metrics

    func fetchCategoryBudgetMetrics() async throws -> [CategoryBudgetMetrics] {
        let tenantId = try await getTenantId()
        let cacheKey = CacheConfiguration.KeyPrefix.categoryMetrics(tenantId)

        // Check cache first (60 second TTL - these are calculated values)
        if let cached: [CategoryBudgetMetrics] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: category budget metrics (\(cached.count) items)")
            return cached
        }

        logger.info("Cache miss: fetching category budget metrics via RPC")
        let client = try getClient()
        let startTime = Date()

        let metrics: [CategoryBudgetMetrics] = try await RepositoryNetwork.withRetry {
            try await client
                .rpc("get_category_budget_metrics", params: ["p_couple_id": tenantId])
                .execute()
                .value
        }

        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("fetchCategoryBudgetMetrics", duration: duration)
        logger.info("Fetched \(metrics.count) category budget metrics in \(String(format: "%.2f", duration))s")

        // Cache result
        await RepositoryCache.shared.set(cacheKey, value: metrics, ttl: 60)
        return metrics
    }

    // MARK: - Categories (Delegated to BudgetCategoryDataSource)

    func fetchCategories() async throws -> [BudgetCategory] {
        let dataSource = try await getCategoryDataSource()
        return try await dataSource.fetchCategories()
    }

    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        let dataSource = try await getCategoryDataSource()
        return try await dataSource.createCategory(category)
    }

    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        let dataSource = try await getCategoryDataSource()
        return try await dataSource.updateCategory(category)
    }

    func deleteCategory(id: UUID) async throws {
        let dataSource = try await getCategoryDataSource()
        try await dataSource.deleteCategory(id: id)
    }

    func checkCategoryDependencies(id: UUID) async throws -> CategoryDependencies {
        let tenantId = try await getTenantId()
        let dataSource = try await getCategoryDataSource()
        return try await dataSource.checkCategoryDependencies(id: id, tenantId: tenantId)
    }

    func batchDeleteCategories(ids: [UUID]) async throws -> BatchDeleteResult {
        let dataSource = try await getCategoryDataSource()
        return try await dataSource.batchDeleteCategories(ids: ids)
    }

    // MARK: - Expenses (Delegated to ExpenseDataSource)

    func fetchExpenses() async throws -> [Expense] {
        let tenantId = try await getTenantId()
        let dataSource = try await getExpenseDataSource()
        return try await dataSource.fetchExpenses(tenantId: tenantId)
    }

    func createExpense(_ expense: Expense) async throws -> Expense {
        let tenantId = try await getTenantId()
        let dataSource = try await getExpenseDataSource()
        return try await dataSource.createExpense(expense, tenantId: tenantId)
    }

    func updateExpense(_ expense: Expense) async throws -> Expense {
        let tenantId = try await getTenantId()
        let dataSource = try await getExpenseDataSource()
        
        // Fetch previous state for potential rollback if recalculation fails
        let previousExpense = try await dataSource.fetchPreviousExpense(id: expense.id)
        
        // Update the expense
        let result = try await dataSource.updateExpense(expense, tenantId: tenantId)
        
        // Recalculate proportional allocations if expense amount changed
        // If recalculation fails, attempt rollback to previous state
        do {
            try await allocationService.recalculateExpenseAllocationsForAllScenarios(
                expenseId: expense.id,
                newAmount: expense.amount
            )
        } catch {
            // Attempt to restore previous expense if available
            if let previous = previousExpense {
                do {
                    try await dataSource.rollbackExpense(previous)
                    logger.info("Rolled back expense update after allocation recalculation failure for expense: \(expense.id)")
                } catch {
                    logger.error("Failed to rollback expense after allocation recalculation failure", error: error)
                }
            }
            throw error
        }
        
        return result
    }

    func deleteExpense(id: UUID) async throws {
        let tenantId = try await getTenantId()
        let dataSource = try await getExpenseDataSource()
        try await dataSource.deleteExpense(id: id, tenantId: tenantId)
    }

    func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense] {
        let dataSource = try await getExpenseDataSource()
        return try await dataSource.fetchExpensesByVendor(vendorId: vendorId)
    }

    // MARK: - Payment Schedules (Delegated to PaymentScheduleDataSource)

    func fetchPaymentSchedules() async throws -> [PaymentSchedule] {
        let tenantId = try await getTenantId()
        let dataSource = try await getPaymentScheduleDataSource()
        return try await dataSource.fetchPaymentSchedules(tenantId: tenantId)
    }

    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        let dataSource = try await getPaymentScheduleDataSource()
        return try await dataSource.createPaymentSchedule(schedule)
    }

    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        let dataSource = try await getPaymentScheduleDataSource()
        return try await dataSource.updatePaymentSchedule(schedule)
    }

    func deletePaymentSchedule(id: Int64) async throws {
        let dataSource = try await getPaymentScheduleDataSource()
        try await dataSource.deletePaymentSchedule(id: id)
    }

    func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule] {
        let dataSource = try await getPaymentScheduleDataSource()
        return try await dataSource.fetchPaymentSchedulesByVendor(vendorId: vendorId)
    }

    // MARK: - Payment Plan Summaries

    func fetchPaymentPlanSummaries() async throws -> [PaymentPlanSummary] {
        let tenantId = try await getTenantId()
        let cacheKey = "payment_plan_summaries_\(tenantId.uuidString)"
        
        if let cached: [PaymentPlanSummary] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: payment plan summaries (\(cached.count) items)")
            return cached
        }
        
        let client = try getClient()
        let startTime = Date()
        
        do {
            let summaries: [PaymentPlanSummary] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("payment_plan_summaries")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .order("vendor", ascending: true)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(summaries.count) payment plan summaries in \(String(format: "%.2f", duration))s")
            
            await RepositoryCache.shared.set(cacheKey, value: summaries, ttl: 60)
            return summaries
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment plan summaries fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    func fetchPaymentPlanSummary(expenseId: UUID) async throws -> PaymentPlanSummary? {
        let tenantId = try await getTenantId()
        let cacheKey = "payment_plan_summary_\(expenseId.uuidString)"
        
        if let cached: PaymentPlanSummary = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: payment plan summary for expense \(expenseId)")
            return cached
        }
        
        let client = try getClient()
        let startTime = Date()
        
        do {
            let summaries: [PaymentPlanSummary] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("payment_plan_summaries")
                    .select()
                    .eq("expense_id", value: expenseId)
                    .eq("couple_id", value: tenantId)
                    .limit(1)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            let summary = summaries.first
            
            if let summary {
                logger.info("Fetched payment plan summary for expense \(expenseId) in \(String(format: "%.2f", duration))s")
                await RepositoryCache.shared.set(cacheKey, value: summary, ttl: 60)
            } else {
                logger.info("No payment plan summary found for expense \(expenseId)")
            }
            
            return summary
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment plan summary fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Gifts and Owed (Delegated to GiftsAndOwedDataSource)

    func fetchGiftsAndOwed() async throws -> [GiftOrOwed] {
        let tenantId = try await getTenantId()
        let dataSource = try await getGiftsAndOwedDataSource()
        return try await dataSource.fetchGiftsAndOwed(tenantId: tenantId)
    }

    func createGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        let dataSource = try await getGiftsAndOwedDataSource()
        return try await dataSource.createGiftOrOwed(gift)
    }

    func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        let dataSource = try await getGiftsAndOwedDataSource()
        return try await dataSource.updateGiftOrOwed(gift)
    }

    func deleteGiftOrOwed(id: UUID) async throws {
        let dataSource = try await getGiftsAndOwedDataSource()
        try await dataSource.deleteGiftOrOwed(id: id)
    }

    // MARK: - Gift Received Operations (Delegated to GiftsAndOwedDataSource)

    func fetchGiftsReceived() async throws -> [GiftReceived] {
        let dataSource = try await getGiftsAndOwedDataSource()
        return try await dataSource.fetchGiftsReceived()
    }

    func createGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        let dataSource = try await getGiftsAndOwedDataSource()
        return try await dataSource.createGiftReceived(gift)
    }

    func updateGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        let dataSource = try await getGiftsAndOwedDataSource()
        return try await dataSource.updateGiftReceived(gift)
    }

    func deleteGiftReceived(id: UUID) async throws {
        let dataSource = try await getGiftsAndOwedDataSource()
        try await dataSource.deleteGiftReceived(id: id)
    }

    // MARK: - Money Owed Operations (Delegated to GiftsAndOwedDataSource)

    func fetchMoneyOwed() async throws -> [MoneyOwed] {
        let dataSource = try await getGiftsAndOwedDataSource()
        return try await dataSource.fetchMoneyOwed()
    }

    func createMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        let dataSource = try await getGiftsAndOwedDataSource()
        return try await dataSource.createMoneyOwed(money)
    }

    func updateMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        let dataSource = try await getGiftsAndOwedDataSource()
        return try await dataSource.updateMoneyOwed(money)
    }

    func deleteMoneyOwed(id: UUID) async throws {
        let dataSource = try await getGiftsAndOwedDataSource()
        try await dataSource.deleteMoneyOwed(id: id)
    }

    // MARK: - Affordability Scenarios (Delegated to AffordabilityDataSource)

    func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario] {
        let tenantId = try await getTenantId()
        let dataSource = try await getAffordabilityDataSource()
        return try await dataSource.fetchAffordabilityScenarios(tenantId: tenantId)
    }

    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario {
        let dataSource = try await getAffordabilityDataSource()
        return try await dataSource.saveAffordabilityScenario(scenario)
    }

    func deleteAffordabilityScenario(id: UUID) async throws {
        let tenantId = try await getTenantId()
        let dataSource = try await getAffordabilityDataSource()
        try await dataSource.deleteAffordabilityScenario(id: id, tenantId: tenantId)
    }

    // MARK: - Affordability Contributions (Delegated to AffordabilityDataSource)

    func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem] {
        let dataSource = try await getAffordabilityDataSource()
        return try await dataSource.fetchAffordabilityContributions(scenarioId: scenarioId)
    }

    func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem {
        let dataSource = try await getAffordabilityDataSource()
        return try await dataSource.saveAffordabilityContribution(contribution)
    }

    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws {
        let dataSource = try await getAffordabilityDataSource()
        try await dataSource.deleteAffordabilityContribution(id: id, scenarioId: scenarioId)
    }

    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async throws {
        let dataSource = try await getAffordabilityDataSource()
        try await dataSource.linkGiftsToScenario(giftIds: giftIds, scenarioId: scenarioId)
    }

    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async throws {
        let dataSource = try await getAffordabilityDataSource()
        try await dataSource.unlinkGiftFromScenario(giftId: giftId, scenarioId: scenarioId)
    }

    // MARK: - Budget Development (Delegated to BudgetDevelopmentDataSource)

    func fetchBudgetDevelopmentScenarios() async throws -> [SavedScenario] {
        let tenantId = try await getTenantId()
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.fetchBudgetDevelopmentScenarios(tenantId: tenantId)
    }

    func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem] {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
    }

    func fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async throws -> [BudgetOverviewItem] {
        let cacheKey = "budget_overview_items_\(scenarioId)"

        if let cached: [BudgetOverviewItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            #if DEBUG
            logger.debug("Cache hit: budget_overview_items (\(cached.count) items)")
            #endif
            return cached
        }

        // Delegate aggregation to domain service
        let overviewItems = try await aggregationService.fetchBudgetOverview(scenarioId: scenarioId)

        await RepositoryCache.shared.set(cacheKey, value: overviewItems)
        #if DEBUG
        logger.debug("Cached \(overviewItems.count) budget overview items")
        #endif
        return overviewItems
    }

    func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.createBudgetDevelopmentScenario(scenario)
    }

    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.updateBudgetDevelopmentScenario(scenario)
    }

    func deleteBudgetDevelopmentScenario(id: String) async throws {
        let tenantId = try await getTenantId()
        let dataSource = try await getBudgetDevelopmentDataSource()
        try await dataSource.deleteBudgetDevelopmentScenario(id: id, tenantId: tenantId)
    }

    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.createBudgetDevelopmentItem(item)
    }

    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        let dataSource = try await getBudgetDevelopmentDataSource()
        let (updated, previous) = try await dataSource.updateBudgetDevelopmentItem(item)
        
        // If this item belongs to a scenario, perform recalculation. If it fails,
        // attempt to restore the previous item so we don't leave inconsistent state.
        if let scenarioId = item.scenarioId {
            do {
                try await allocationService.recalculateAllocations(budgetItemId: item.id, scenarioId: scenarioId)
                
                // Only invalidate caches after successful recalculation
                await dataSource.invalidateCachesAfterUpdate(item)
            } catch {
                if let previous = previous {
                    do {
                        try await dataSource.rollbackBudgetDevelopmentItem(previous)
                        logger.info("Rolled back budget development item update after recalculation failure: \(item.id)")
                    } catch {
                        logger.error("Failed to rollback budget development item after recalculation failure", error: error)
                    }
                }
                throw error
            }
        } else {
            // No scenario associated, still remove the global cache key
            await dataSource.invalidateCachesAfterUpdate(item)
        }
        
        return updated
    }

    func deleteBudgetDevelopmentItem(id: String) async throws {
        let dataSource = try await getBudgetDevelopmentDataSource()
        _ = try await dataSource.deleteBudgetDevelopmentItem(id: id)
    }

    // MARK: - Tax Rates

    func fetchTaxRates() async throws -> [TaxInfo] {
    do {
    let cacheKey = "tax_rates"

    if let cached: [TaxInfo] = await RepositoryCache.shared.get(cacheKey, maxAge: 3600) {
    return cached
    }

    let client = try getClient()
    let startTime = Date()

    let rates: [TaxInfo] = try await RepositoryNetwork.withRetry {
    try await client
    .from("tax_rates")
    .select()
    .order("region", ascending: true)
    .execute()
    .value
    }

    let duration = Date().timeIntervalSince(startTime)

    // Only log if slow
    if duration > 1.0 {
    logger.info("Slow tax rates fetch: \(String(format: "%.2f", duration))s for \(rates.count) items")
    }

    await RepositoryCache.shared.set(cacheKey, value: rates)

    return rates
    } catch {
    logger.error("Failed to fetch tax rates", error: error)
    throw BudgetError.fetchFailed(underlying: error)
    }
    }

    func createTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
    do {
    let client = try getClient()
    let startTime = Date()

    let created: TaxInfo = try await RepositoryNetwork.withRetry {
    try await client
    .from("tax_rates")
    .insert(taxInfo)
    .select()
    .single()
    .execute()
    .value
    }

    let duration = Date().timeIntervalSince(startTime)

    // Log important mutation
    logger.info("Created tax rate for region: \(created.region)")

    await RepositoryCache.shared.remove("tax_rates")

    return created
    } catch {
    logger.error("Failed to create tax rate", error: error)
    throw BudgetError.createFailed(underlying: error)
    }
    }

    func updateTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
    do {
    let client = try getClient()
    let startTime = Date()

    let result: TaxInfo = try await RepositoryNetwork.withRetry {
    try await client
    .from("tax_rates")
    .update(taxInfo)
    .eq("id", value: String(taxInfo.id))
    .select()
    .single()
    .execute()
    .value
    }

    let duration = Date().timeIntervalSince(startTime)

    // Log important mutation
    logger.info("Updated tax rate for region: \(result.region)")

    await RepositoryCache.shared.remove("tax_rates")

    return result
    } catch {
    logger.error("Failed to update tax rate", error: error)
    throw BudgetError.updateFailed(underlying: error)
    }
    }

    func deleteTaxRate(id: Int64) async throws {
    do {
    let client = try getClient()
    let startTime = Date()

    try await RepositoryNetwork.withRetry {
    try await client
    .from("tax_rates")
    .delete()
    .eq("id", value: String(id))
    .execute()
    }

    let duration = Date().timeIntervalSince(startTime)

    // Log important mutation
    logger.info("Deleted tax rate: \(id)")

    await RepositoryCache.shared.remove("tax_rates")
    } catch {
    logger.error("Failed to delete tax rate", error: error)
    throw BudgetError.deleteFailed(underlying: error)
    }
    }

    // MARK: - Wedding Events

    func fetchWeddingEvents() async throws -> [WeddingEvent] {
    do {
    // Get tenant ID for cache key
    let tenantId = try await getTenantId()
    let cacheKey = "wedding_events_\(tenantId.uuidString)"

    if let cached: [WeddingEvent] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
    return cached
    }

    let client = try getClient()
    let startTime = Date()

    let events: [WeddingEvent] = try await RepositoryNetwork.withRetry {
    try await client
    .from("wedding_events")
    .select()
    .eq("couple_id", value: tenantId)
    .order("event_date", ascending: true)
    .execute()
    .value
    }

    let duration = Date().timeIntervalSince(startTime)

    // Only log if slow
    if duration > 1.0 {
    logger.info("Slow wedding events fetch: \(String(format: "%.2f", duration))s for \(events.count) items")
    }

    await RepositoryCache.shared.set(cacheKey, value: events)

    return events
    } catch {
    logger.error("Failed to fetch wedding events", error: error)
    throw BudgetError.fetchFailed(underlying: error)
    }
    }
    
    func createWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()
            
            let created: WeddingEvent = try await RepositoryNetwork.withRetry {
                try await client
                    .from("wedding_events")
                    .insert(event)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Log important mutation
            logger.info("Created wedding event: \(created.eventName)")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("wedding_events_\(tenantId.uuidString)")
            
            return created
        } catch {
            logger.error("Failed to create wedding event", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    func updateWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()
            
            // Create new event with updated timestamp
            let updatedEvent = WeddingEvent(
                id: event.id,
                eventName: event.eventName,
                eventType: event.eventType,
                eventDate: event.eventDate,
                startTime: event.startTime,
                endTime: event.endTime,
                venueId: event.venueId,
                venueName: event.venueName,
                address: event.address,
                city: event.city,
                state: event.state,
                zipCode: event.zipCode,
                guestCount: event.guestCount,
                budgetAllocated: event.budgetAllocated,
                notes: event.notes,
                isConfirmed: event.isConfirmed,
                description: event.description,
                eventOrder: event.eventOrder,
                isMainEvent: event.isMainEvent,
                venueLocation: event.venueLocation,
                eventTime: event.eventTime,
                coupleId: event.coupleId,
                createdAt: event.createdAt,
                updatedAt: Date()
            )
            
            let result: WeddingEvent = try await RepositoryNetwork.withRetry {
                try await client
                    .from("wedding_events")
                    .update(updatedEvent)
                    .eq("id", value: updatedEvent.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Log important mutation
            logger.info("Updated wedding event: \(result.eventName)")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("wedding_events_\(tenantId.uuidString)")
            
            return result
        } catch {
            logger.error("Failed to update wedding event", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    func deleteWeddingEvent(id: String) async throws {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()
            
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("wedding_events")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Log important mutation
            logger.info("Deleted wedding event: \(id)")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("wedding_events_\(tenantId.uuidString)")
        } catch {
            logger.error("Failed to delete wedding event", error: error)
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Expense Allocations (Delegated to BudgetDevelopmentDataSource)

    func fetchExpenseAllocations(scenarioId: String, budgetItemId: String) async throws -> [ExpenseAllocation] {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.fetchExpenseAllocations(scenarioId: scenarioId, budgetItemId: budgetItemId)
    }

    func fetchExpenseAllocationsForScenario(scenarioId: String) async throws -> [ExpenseAllocation] {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.fetchExpenseAllocationsForScenario(scenarioId: scenarioId)
    }

    func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws -> ExpenseAllocation {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.createExpenseAllocation(allocation)
    }

    func fetchAllocationsForExpense(expenseId: UUID, scenarioId: String) async throws -> [ExpenseAllocation] {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.fetchAllocationsForExpense(expenseId: expenseId, scenarioId: scenarioId)
    }

    func fetchAllocationsForExpenseAllScenarios(expenseId: UUID) async throws -> [ExpenseAllocation] {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.fetchAllocationsForExpenseAllScenarios(expenseId: expenseId)
    }

    func replaceAllocations(expenseId: UUID, scenarioId: String, with newAllocations: [ExpenseAllocation]) async throws {
        let dataSource = try await getBudgetDevelopmentDataSource()
        try await dataSource.replaceAllocations(expenseId: expenseId, scenarioId: scenarioId, with: newAllocations)
    }

    func linkGiftToBudgetItem(giftId: UUID, budgetItemId: String) async throws {
        let dataSource = try await getBudgetDevelopmentDataSource()
        try await dataSource.linkGiftToBudgetItem(giftId: giftId, budgetItemId: budgetItemId)
    }

    // MARK: - Composite Saves (Scenario + Items) (Delegated to BudgetDevelopmentDataSource)

    func saveBudgetScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int) {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.saveBudgetScenarioWithItems(scenario, items: items)
    }

    // MARK: - Primary Budget Scenario (Delegated to BudgetDevelopmentDataSource)

    func fetchPrimaryBudgetScenario() async throws -> BudgetDevelopmentScenario? {
        let tenantId = try await getTenantId()
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.fetchPrimaryBudgetScenario(tenantId: tenantId)
    }

    // MARK: - Folder Operations (Delegated to BudgetDevelopmentDataSource)

    func createFolder(name: String, scenarioId: String, parentFolderId: String?, displayOrder: Int) async throws -> BudgetItem {
        let tenantId = try await getTenantId()
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.createFolder(name: name, scenarioId: scenarioId, parentFolderId: parentFolderId, displayOrder: displayOrder, tenantId: tenantId)
    }

    func moveItemToFolder(itemId: String, targetFolderId: String?, displayOrder: Int) async throws {
        let dataSource = try await getBudgetDevelopmentDataSource()
        try await dataSource.moveItemToFolder(itemId: itemId, targetFolderId: targetFolderId, displayOrder: displayOrder)
    }

    func updateDisplayOrder(items: [(itemId: String, displayOrder: Int)]) async throws {
        let dataSource = try await getBudgetDevelopmentDataSource()
        try await dataSource.updateDisplayOrder(items: items)
    }

    func toggleFolderExpansion(folderId: String, isExpanded: Bool) async throws {
        let dataSource = try await getBudgetDevelopmentDataSource()
        try await dataSource.toggleFolderExpansion(folderId: folderId, isExpanded: isExpanded)
    }

    func fetchBudgetItemsHierarchical(scenarioId: String) async throws -> [BudgetItem] {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.fetchBudgetItemsHierarchical(scenarioId: scenarioId)
    }

    func calculateFolderTotals(folderId: String) async throws -> FolderTotals {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.calculateFolderTotals(folderId: folderId)
    }

    func canMoveItem(itemId: String, toFolder targetFolderId: String?) async throws -> Bool {
        let dataSource = try await getBudgetDevelopmentDataSource()
        return try await dataSource.canMoveItem(itemId: itemId, toFolder: targetFolderId)
    }

    func deleteFolder(folderId: String, deleteContents: Bool) async throws {
        let dataSource = try await getBudgetDevelopmentDataSource()
        try await dataSource.deleteFolder(folderId: folderId, deleteContents: deleteContents)
    }
}
