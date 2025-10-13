import Foundation
import Supabase

/// Production implementation of BudgetRepositoryProtocol
/// Uses Supabase client for all data operations with automatic caching
actor LiveBudgetRepository: BudgetRepositoryProtocol {
    private let supabase: SupabaseClient
    private let cache: RepositoryCache
    private let logger = AppLogger.repository

    init(supabase: SupabaseClient) {
        self.supabase = supabase
        cache = RepositoryCache()
    }

    // Convenience initializer using SupabaseManager singleton
    init() {
        supabase = SupabaseManager.shared.client
        cache = RepositoryCache()
    }

    // MARK: - Budget Summary

    func fetchBudgetSummary() async throws -> BudgetSummary? {
        let cacheKey = "budget_summary"

        // Check cache first (5 min TTL)
        if let cached: BudgetSummary = await cache.get(cacheKey, maxAge: 300) {
            logger.debug("Cache hit: budget_summary")
            return cached
        }

        logger.debug("Fetching budget summary from Supabase...")
        let startTime = Date()

        do {
            // Fetch from Supabase with retry and timeout
            let response: [BudgetSummary] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("budget_settings")
                    .select()
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Budget summary fetched successfully in \(String(format: "%.2f", duration))s")

            let summary = response.first

            // Cache the result
            if let summary {
                await cache.set(cacheKey, value: summary)
                logger.debug("Cached budget summary")
            }

            return summary
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Budget summary fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [BudgetCategory] {
        let cacheKey = "budget_categories"

        // Check cache first (1 min TTL for fresher data)
        if let cached: [BudgetCategory] = await cache.get(cacheKey, maxAge: 60) {
            logger.debug("Cache hit: budget_categories (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching budget categories from Supabase...")
        let startTime = Date()

        do {
            let categories: [BudgetCategory] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("budget_categories")
                    .select()
                    .order("priority_level", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(categories.count) categories in \(String(format: "%.2f", duration))s")

            await cache.set(cacheKey, value: categories)
            logger.debug("Cached \(categories.count) budget categories")

            return categories
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Category fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        logger.debug("Creating budget category: \(category.categoryName)")
        let startTime = Date()

        do {
            let created: BudgetCategory = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("budget_categories")
                    .insert(category)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created category in \(String(format: "%.2f", duration))s")

            // Invalidate cache
            await cache.remove("budget_categories")
            await cache.remove("budget_summary")
            logger.info("Created category and invalidated cache")

            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Category creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        logger.debug("Updating budget category: \(category.categoryName)")
        let startTime = Date()

        var updated = category
        updated.updatedAt = Date()

        do {
            let result: BudgetCategory = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("budget_categories")
                    .update(updated)
                    .eq("id", value: category.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated category in \(String(format: "%.2f", duration))s")

            // Invalidate cache
            await cache.remove("budget_categories")
            await cache.remove("budget_summary")
            logger.info("Updated category and invalidated cache")

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Category update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteCategory(id: UUID) async throws {
        logger.debug("Deleting budget category: \(id)")
        let startTime = Date()

        do {
            _ = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("budget_categories")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted category in \(String(format: "%.2f", duration))s")

            // Invalidate cache
            await cache.remove("budget_categories")
            await cache.remove("budget_summary")
            logger.info("Deleted category and invalidated cache")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Category deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Expenses

    func fetchExpenses() async throws -> [Expense] {
        let cacheKey = "expenses"

        // Check cache first (30 sec TTL for very fresh data)
        if let cached: [Expense] = await cache.get(cacheKey, maxAge: 30) {
            logger.debug("Cache hit: expenses (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching expenses from Supabase...")
        let startTime = Date()

        do {
            let expenses: [Expense] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("expenses")
                    .select()
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(expenses.count) expenses in \(String(format: "%.2f", duration))s")

            await cache.set(cacheKey, value: expenses)
            logger.debug("Cached \(expenses.count) expenses")

            return expenses
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expenses fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createExpense(_ expense: Expense) async throws -> Expense {
        logger.debug("Creating expense: \(expense.expenseName)")
        let startTime = Date()

        do {
            let created: Expense = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("expenses")
                    .insert(expense)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created expense in \(String(format: "%.2f", duration))s")

            // Invalidate cache
            await cache.remove("expenses")
            await cache.remove("budget_summary")
            logger.info("Created expense and invalidated cache")

            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expense creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updateExpense(_ expense: Expense) async throws -> Expense {
        logger.debug("Updating expense: \(expense.expenseName)")
        let startTime = Date()

        var updated = expense
        updated.updatedAt = Date()

        do {
            let result: Expense = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("expenses")
                    .update(updated)
                    .eq("id", value: expense.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated expense in \(String(format: "%.2f", duration))s")

            // Invalidate cache
            await cache.remove("expenses")
            await cache.remove("budget_summary")
            logger.info("Updated expense and invalidated cache")

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expense update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteExpense(id: UUID) async throws {
        logger.debug("Deleting expense: \(id)")
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("expenses")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted expense in \(String(format: "%.2f", duration))s")

            // Invalidate cache
            await cache.remove("expenses")
            await cache.remove("budget_summary")
            logger.info("Deleted expense and invalidated cache")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expense deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Payment Schedules

    func fetchPaymentSchedules() async throws -> [PaymentSchedule] {
        let cacheKey = "payment_schedules"

        if let cached: [PaymentSchedule] = await cache.get(cacheKey, maxAge: 60) {
            logger.debug("Cache hit: payment_schedules (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching payment schedules from Supabase...")
        let startTime = Date()

        do {
            let schedules: [PaymentSchedule] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("paymentPlans")
                    .select()
                    .order("payment_date", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(schedules.count) payment schedules in \(String(format: "%.2f", duration))s")

            await cache.set(cacheKey, value: schedules)
            logger.debug("Cached \(schedules.count) payment schedules")

            return schedules
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment schedules fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        logger.debug("Creating payment schedule for vendor: \(schedule.vendor)")
        let startTime = Date()

        do {
            let created: PaymentSchedule = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("paymentPlans")
                    .insert(schedule)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created payment schedule in \(String(format: "%.2f", duration))s")

            await cache.remove("payment_schedules")
            logger.info("Created payment schedule and invalidated cache")

            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment schedule creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        logger.debug("Updating payment schedule: \(schedule.id)")
        let startTime = Date()

        var updated = schedule
        updated.updatedAt = Date()

        do {
            let result: PaymentSchedule = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("paymentPlans")
                    .update(updated)
                    .eq("id", value: String(schedule.id))
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated payment schedule in \(String(format: "%.2f", duration))s")

            await cache.remove("payment_schedules")
            logger.info("Updated payment schedule and invalidated cache")

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment schedule update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deletePaymentSchedule(id: Int64) async throws {
        logger.debug("Deleting payment schedule: \(id)")
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("paymentPlans")
                    .delete()
                    .eq("id", value: String(id))
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted payment schedule in \(String(format: "%.2f", duration))s")

            await cache.remove("payment_schedules")
            logger.info("Deleted payment schedule and invalidated cache")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment schedule deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Gifts and Owed

    func fetchGiftsAndOwed() async throws -> [GiftOrOwed] {
        let cacheKey = "gifts_and_owed"

        if let cached: [GiftOrOwed] = await cache.get(cacheKey, maxAge: 60) {
            logger.debug("Cache hit: gifts_and_owed (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching gifts and owed from Supabase...")

        let items: [GiftOrOwed] = try await supabase
            .from("gifts_and_owed")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        await cache.set(cacheKey, value: items)
        logger.debug("Cached \(items.count) gifts/owed items")

        return items
    }

    // MARK: - Affordability Scenarios

    func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario] {
        let cacheKey = "affordability_scenarios"

        if let cached: [AffordabilityScenario] = await cache.get(cacheKey, maxAge: 300) {
            logger.debug("Cache hit: affordability_scenarios (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching affordability scenarios from Supabase...")
        let startTime = Date()

        do {
            let scenarios: [AffordabilityScenario] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("affordability_scenarios")
                    .select()
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(scenarios.count) affordability scenarios in \(String(format: "%.2f", duration))s")

            await cache.set(cacheKey, value: scenarios)
            logger.debug("Cached \(scenarios.count) affordability scenarios")

            return scenarios
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Affordability scenarios fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario {
        logger.debug("Saving affordability scenario: \(scenario.scenarioName)")
        let startTime = Date()

        do {
            let saved: AffordabilityScenario = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("affordability_scenarios")
                    .upsert(scenario)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Saved affordability scenario in \(String(format: "%.2f", duration))s")

            await cache.remove("affordability_scenarios")

            return saved
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Affordability scenario save failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteAffordabilityScenario(id: UUID) async throws {
        logger.debug("Deleting affordability scenario: \(id)")
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("affordability_scenarios")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted affordability scenario in \(String(format: "%.2f", duration))s")

            await cache.remove("affordability_scenarios")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Affordability scenario deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Affordability Contributions

    func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem] {
        let cacheKey = "affordability_contributions_\(scenarioId)"

        if let cached: [ContributionItem] = await cache.get(cacheKey, maxAge: 300) {
            logger.debug("Cache hit: affordability_contributions for scenario \(scenarioId) - \(cached.count) items")
            return cached
        }

        logger.debug("Fetching affordability contributions for scenario \(scenarioId)...")
        logger.debug("Cache miss - fetching fresh data from database")

        // Fetch direct contributions from affordability_gifts_contributions
        let directContributions: [ContributionItem]
        do {
            directContributions = try await supabase
                .from("affordability_gifts_contributions")
                .select()
                .eq("scenario_id", value: scenarioId)
                .order("contribution_date", ascending: false)
                .execute()
                .value
            logger.debug("Fetched \(directContributions.count) direct contributions")
        } catch {
            logger.error("Error fetching direct contributions", error: error)
            throw error
        }

        // Fetch linked gifts from gifts_and_owed
        let linkedGifts: [GiftOrOwed]
        do {
            linkedGifts = try await supabase
                .from("gifts_and_owed")
                .select()
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value
            logger.debug("Fetched \(linkedGifts.count) linked gifts")
            for gift in linkedGifts {
                logger.debug("Gift ID: \(gift.id), Title: \(gift.title), From: \(gift.fromPerson ?? "N/A")")
            }
        } catch {
            logger.error("Error fetching linked gifts", error: error)
            throw error
        }

        logger.debug("Found \(directContributions.count) direct contributions and \(linkedGifts.count) linked gifts")

        // Convert linked gifts to ContributionItems
        let giftContributions = linkedGifts.map { gift in
            ContributionItem(
                id: gift.id,
                scenarioId: scenarioId,
                contributorName: gift.fromPerson ?? gift.title,
                amount: gift.amount,
                contributionDate: gift.receivedDate ?? gift.expectedDate ?? Date(),
                contributionType: gift.type == .giftReceived ? .gift : .external,
                notes: gift.description,
                coupleId: gift.coupleId,
                createdAt: gift.createdAt ?? Date(),
                updatedAt: gift.updatedAt
            )
        }

        // Combine both sources
        let contributions = directContributions + giftContributions

        await cache.set(cacheKey, value: contributions)
        logger.debug("Cached \(contributions.count) contributions")

        return contributions
    }

    func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem {
        logger.debug("Saving contribution: \(contribution.contributorName)")

        let saved: ContributionItem = try await supabase
            .from("affordability_gifts_contributions")
            .upsert(contribution)
            .select()
            .single()
            .execute()
            .value

        await cache.remove("affordability_contributions_\(contribution.scenarioId)")
        logger.info("Saved contribution")

        return saved
    }

    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws {
        logger.debug("Deleting contribution: \(id)")

        try await supabase
            .from("affordability_gifts_contributions")
            .delete()
            .eq("id", value: id)
            .execute()

        await cache.remove("affordability_contributions_\(scenarioId)")
        logger.info("Deleted contribution")
    }

    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async throws {
        logger.debug("Linking \(giftIds.count) gifts to scenario \(scenarioId)")

        for giftId in giftIds {
            try await supabase
                .from("gifts_and_owed")
                .update(["scenario_id": scenarioId])
                .eq("id", value: giftId)
                .execute()
        }

        await cache.remove("gifts_and_owed")
        await cache.remove("affordability_contributions_\(scenarioId)")
        logger.info("Linked gifts to scenario and invalidated caches")
    }

    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async throws {
        logger.debug("Unlinking gift from scenario")

        let response = try await supabase
            .from("gifts_and_owed")
            .update(["scenario_id": AnyJSON.null])
            .eq("id", value: giftId.uuidString.lowercased())
            .select()
            .execute()

        // Verify the update worked by checking response status
        let affectedRows = (try? JSONDecoder().decode([GiftOrOwed].self, from: response.data).count) ?? 0

        if affectedRows == 0 {
            logger.warning("No rows updated - gift may not exist or already unlinked")
        } else {
            logger.repositorySuccess("Unlink gift from scenario", affectedRows: affectedRows)
        }

        await cache.remove("gifts_and_owed")
        await cache.remove("affordability_contributions_\(scenarioId)")
    }

    func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        logger.debug("Updating gift/owed: \(gift.id)")

        // Create updated gift object for encoding
        let updated = GiftOrOwed(
            id: gift.id,
            coupleId: gift.coupleId,
            title: gift.title,
            amount: gift.amount,
            type: gift.type,
            description: gift.description,
            fromPerson: gift.fromPerson,
            expectedDate: gift.expectedDate,
            receivedDate: gift.receivedDate,
            status: gift.status,
            scenarioId: gift.scenarioId,
            createdAt: gift.createdAt,
            updatedAt: Date()
        )

        let response: GiftOrOwed = try await supabase
            .from("gifts_and_owed")
            .update(updated)
            .eq("id", value: gift.id)
            .select()
            .single()
            .execute()
            .value

        await cache.remove("gifts_and_owed")
        if let scenarioId = gift.scenarioId {
            await cache.remove("affordability_contributions_\(scenarioId)")
        }
        logger.info("Updated gift/owed and invalidated caches")

        return response
    }

    // MARK: - Budget Development

    func fetchBudgetDevelopmentScenarios() async throws -> [SavedScenario] {
        let cacheKey = "budget_dev_scenarios"

        if let cached: [SavedScenario] = await cache.get(cacheKey, maxAge: 300) {
            logger.debug("Cache hit: budget_dev_scenarios (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching budget development scenarios from Supabase...")

        let scenarios: [SavedScenario] = try await supabase
            .from("budget_development_scenarios")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        await cache.set(cacheKey, value: scenarios)
        logger.debug("Cached \(scenarios.count) budget development scenarios")

        return scenarios
    }

    func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem] {
        let cacheKey = scenarioId.map { "budget_dev_items_\($0)" } ?? "budget_dev_items_all"

        if let cached: [BudgetItem] = await cache.get(cacheKey, maxAge: 60) {
            logger.debug("Cache hit: budget_dev_items (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching budget development items from Supabase...")

        var query = supabase.from("budget_development_items").select()

        if let scenarioId {
            query = query.eq("scenario_id", value: scenarioId)
        }

        let items: [BudgetItem] = try await query
            .order("created_at", ascending: false)
            .execute()
            .value

        await cache.set(cacheKey, value: items)
        logger.debug("Cached \(items.count) budget development items")

        return items
    }

    func fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async throws -> [BudgetOverviewItem] {
        let cacheKey = "budget_overview_items_\(scenarioId)"

        if let cached: [BudgetOverviewItem] = await cache.get(cacheKey, maxAge: 60) {
            logger.debug("Cache hit: budget_overview_items (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching budget overview items with spent amounts from Supabase...")
        logger.debug("Using scenario ID: \(scenarioId)")

        // Fetch budget items for the scenario
        let items = try await fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        logger.debug("Fetched \(items.count) budget items for scenario")

        // Fetch all expense allocations for this scenario
        struct ExpenseAllocation: Codable {
            let id: UUID
            let expenseId: UUID
            let budgetItemId: UUID
            let allocatedAmount: Double
            let expenses: ExpenseData

            enum CodingKeys: String, CodingKey {
                case id
                case expenseId = "expense_id"
                case budgetItemId = "budget_item_id"
                case allocatedAmount = "allocated_amount"
                case expenses
            }

            struct ExpenseData: Codable {
                let id: UUID
                let expenseName: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case expenseName = "expense_name"
                }
            }
        }

        logger.debug("Querying expense_budget_allocations for scenario_id: \(scenarioId)")

        // Fetch allocations without the join first (workaround for Supabase Swift client inner join issue)
        struct SimpleAllocation: Codable {
            let id: UUID
            let expenseId: UUID
            let budgetItemId: UUID
            let allocatedAmount: Double

            enum CodingKeys: String, CodingKey {
                case id
                case expenseId = "expense_id"
                case budgetItemId = "budget_item_id"
                case allocatedAmount = "allocated_amount"
            }
        }

        // Try filtering using column-based syntax instead of eq()
        let query = supabase
            .from("expense_budget_allocations")
            .select("id, expense_id, budget_item_id, allocated_amount")

        // Apply filter - try both approaches
        logger.debug("Building query with scenario_id filter: \(scenarioId)")
        let simpleAllocations: [SimpleAllocation] = try await query
            .eq("scenario_id", value: scenarioId)
            .execute()
            .value

        logger.debug("Fetched \(simpleAllocations.count) allocations for scenario")

        // Debug: Log first few allocations with their amounts
        for allocation in simpleAllocations.prefix(3) {
            logger.debug("  Allocation \(allocation.id): amount=\(allocation.allocatedAmount)")
        }

        // If no allocations, return early
        guard !simpleAllocations.isEmpty else {
            logger.debug("No allocations found for scenario \(scenarioId)")
            let overviewItems = items.map { item in
                BudgetOverviewItem(
                    id: item.id,
                    itemName: item.itemName,
                    category: item.category,
                    subcategory: item.subcategory ?? "",
                    budgeted: item.vendorEstimateWithTax,
                    spent: 0,
                    effectiveSpent: 0,
                    expenses: [],
                    gifts: []
                )
            }
            await cache.set(cacheKey, value: overviewItems)
            return overviewItems
        }

        // Fetch expense details separately
        let expenseIds = simpleAllocations.map { $0.expenseId }

        struct ExpenseBasic: Codable {
            let id: UUID
            let expenseName: String

            enum CodingKeys: String, CodingKey {
                case id
                case expenseName = "expense_name"
            }
        }

        let expenses: [ExpenseBasic] = try await supabase
            .from("expenses")
            .select("id, expense_name")
            .in("id", values: expenseIds.map { $0.uuidString })
            .execute()
            .value

        logger.debug("Fetched \(expenses.count) expenses for allocations")

        // Map expenses by ID for quick lookup
        let expenseDict = Dictionary(uniqueKeysWithValues: expenses.map { ($0.id, $0.expenseName) })

        // Combine the data
        let allocations = simpleAllocations.compactMap { simple -> ExpenseAllocation? in
            guard let expenseName = expenseDict[simple.expenseId] else {
                logger.warning("No expense found for allocation \(simple.id)")
                return nil
            }

            return ExpenseAllocation(
                id: simple.id,
                expenseId: simple.expenseId,
                budgetItemId: simple.budgetItemId,
                allocatedAmount: simple.allocatedAmount,
                expenses: ExpenseAllocation.ExpenseData(
                    id: simple.expenseId,
                    expenseName: expenseName
                )
            )
        }

        logger.debug("Combined \(allocations.count) expense allocations with expense details")

        // Group allocations by budget item ID (normalized to lowercase for consistent lookup)
        var allocationsByItem: [String: [ExpenseAllocation]] = [:]
        for allocation in allocations {
            let itemId = allocation.budgetItemId.uuidString.lowercased()
            allocationsByItem[itemId, default: []].append(allocation)
        }

        // Map budget items to overview items with expense data
        let overviewItems: [BudgetOverviewItem] = items.map { item in
            let itemAllocations = allocationsByItem[item.id.lowercased()] ?? []

            let expenseLinks = itemAllocations.map { allocation in
                ExpenseLink(
                    id: allocation.expenseId.uuidString,
                    title: allocation.expenses.expenseName,
                    amount: allocation.allocatedAmount
                )
            }

            let totalSpent = itemAllocations.reduce(0.0) { $0 + $1.allocatedAmount }

            // TODO: Fetch and apply gifts to calculate effectiveSpent

            return BudgetOverviewItem(
                id: item.id,
                itemName: item.itemName,
                category: item.category,
                subcategory: item.subcategory ?? "",
                budgeted: item.vendorEstimateWithTax,
                spent: totalSpent,
                effectiveSpent: totalSpent, // For now, same as spent until gifts are implemented
                expenses: expenseLinks,
                gifts: [] // TODO: Fetch linked gifts
            )
        }

        await cache.set(cacheKey, value: overviewItems)
        logger.debug("Cached \(overviewItems.count) budget overview items with \(allocations.count) total expense links")

        // Debug: Log items with non-zero spent amounts
        let itemsWithExpenses = overviewItems.filter { $0.spent > 0 }
        logger.debug("Items with expenses: \(itemsWithExpenses.count)")
        for item in itemsWithExpenses.prefix(3) {
            logger.debug("  - \(item.itemName): spent=\(item.spent), expenses=\(item.expenses.count)")
        }

        return overviewItems
    }

    func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        logger.debug("Creating budget development scenario: \(scenario.scenarioName)")

        let created: SavedScenario = try await supabase
            .from("budget_development_scenarios")
            .insert(scenario)
            .select()
            .single()
            .execute()
            .value

        await cache.remove("budget_dev_scenarios")
        logger.info("Created budget development scenario and invalidated cache")

        return created
    }

    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        logger.debug("Updating budget development scenario: \(scenario.id)")

        let result: SavedScenario = try await supabase
            .from("budget_development_scenarios")
            .update(scenario)
            .eq("id", value: scenario.id)
            .select()
            .single()
            .execute()
            .value

        await cache.remove("budget_dev_scenarios")
        logger.info("Updated budget development scenario and invalidated cache")

        return result
    }

    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        logger.debug("Creating budget development item: \(item.itemName)")

        let created: BudgetItem = try await supabase
            .from("budget_development_items")
            .insert(item)
            .select()
            .single()
            .execute()
            .value

        if let scenarioId = item.scenarioId {
            await cache.remove("budget_dev_items_\(scenarioId)")
        }
        await cache.remove("budget_dev_items_all")
        logger.info("Created budget development item and invalidated cache")

        return created
    }

    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        logger.debug("Updating budget development item: \(item.id)")

        let result: BudgetItem = try await supabase
            .from("budget_development_items")
            .update(item)
            .eq("id", value: item.id)
            .select()
            .single()
            .execute()
            .value

        if let scenarioId = item.scenarioId {
            await cache.remove("budget_dev_items_\(scenarioId)")
        }
        await cache.remove("budget_dev_items_all")
        logger.info("Updated budget development item and invalidated cache")

        return result
    }

    func deleteBudgetDevelopmentItem(id: String) async throws {
        logger.debug("Deleting budget development item: \(id)")

        try await supabase
            .from("budget_development_items")
            .delete()
            .eq("id", value: id)
            .execute()

        // Invalidate all item caches since we don't know which scenario
        await cache.remove("budget_dev_items_all")
        logger.info("Deleted budget development item and invalidated cache")
    }

    // MARK: - Tax Rates

    func fetchTaxRates() async throws -> [TaxInfo] {
        let cacheKey = "tax_rates"

        if let cached: [TaxInfo] = await cache.get(cacheKey, maxAge: 3600) {
            logger.debug("Cache hit: tax_rates (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching tax rates from Supabase...")
        let startTime = Date()

        do {
            let rates: [TaxInfo] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("tax_rates")
                    .select()
                    .order("region", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(rates.count) tax rates in \(String(format: "%.2f", duration))s")

            await cache.set(cacheKey, value: rates)
            logger.debug("Cached \(rates.count) tax rates")

            return rates
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Tax rates fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        logger.debug("Creating tax rate for region: \(taxInfo.region)")
        let startTime = Date()

        do {
            let created: TaxInfo = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("tax_rates")
                    .insert(taxInfo)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created tax rate in \(String(format: "%.2f", duration))s")

            await cache.remove("tax_rates")

            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Tax rate creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updateTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        logger.debug("Updating tax rate: \(taxInfo.id)")
        let startTime = Date()

        do {
            let result: TaxInfo = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("tax_rates")
                    .update(taxInfo)
                    .eq("id", value: String(taxInfo.id))
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated tax rate in \(String(format: "%.2f", duration))s")

            await cache.remove("tax_rates")

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Tax rate update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteTaxRate(id: Int64) async throws {
        logger.debug("Deleting tax rate: \(id)")
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("tax_rates")
                    .delete()
                    .eq("id", value: String(id))
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted tax rate in \(String(format: "%.2f", duration))s")

            await cache.remove("tax_rates")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Tax rate deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Wedding Events

    func fetchWeddingEvents() async throws -> [WeddingEvent] {
        let cacheKey = "wedding_events"

        if let cached: [WeddingEvent] = await cache.get(cacheKey, maxAge: 300) {
            logger.debug("Cache hit: wedding_events (\(cached.count) items)")
            return cached
        }

        logger.debug("Fetching wedding events from Supabase...")
        let startTime = Date()

        do {
            let events: [WeddingEvent] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("wedding_events")
                    .select()
                    .order("event_date", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(events.count) wedding events in \(String(format: "%.2f", duration))s")

            await cache.set(cacheKey, value: events)
            logger.debug("Cached \(events.count) wedding events")

            return events
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Wedding events fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
}
