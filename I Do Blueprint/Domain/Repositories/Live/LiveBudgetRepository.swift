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

    // MARK: - Categories

    func fetchCategories() async throws -> [BudgetCategory] {
    do {
    let cacheKey = "budget_categories"

    // Check cache first (1 min TTL for fresher data)
    if let cached: [BudgetCategory] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
    return cached
    }

    // Coalesce in-flight request (singleton scope)
    if let task = inFlightCategories {
        return try await task.value
    }

    let task = Task<[BudgetCategory], Error> { [weak self] in
        guard let self = self else { throw CancellationError() }
        let client = try await self.getClient()
        let startTime = Date()
        let categories: [BudgetCategory] = try await RepositoryNetwork.withRetry {
            try await client
                .from("budget_categories")
                .select()
                .order("priority_level", ascending: true)
                .execute()
                .value
        }
        let duration = Date().timeIntervalSince(startTime)
        if duration > 1.0 {
            self.logger.info("Slow category fetch: \(String(format: "%.2f", duration))s for \(categories.count) items")
        }
        await RepositoryCache.shared.set(cacheKey, value: categories)
        return categories
    }
    inFlightCategories = task
    do {
        let result = try await task.value
        inFlightCategories = nil
        return result
    } catch {
        inFlightCategories = nil
        logger.error("Failed to fetch categories", error: error)
        await SentryService.shared.captureError(error, context: [
            "operation": "fetchCategories",
            "repository": "LiveBudgetRepository"
        ])
        throw BudgetError.fetchFailed(underlying: error)
    }
    }
    }

    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        do {
            let client = try getClient()
            
            // Verify auth session exists before making authenticated request
            let session = try await client.auth.session
            logger.info("✅ Auth session exists: user=\(session.user.id)")
            
            let startTime = Date()

            // Supabase client automatically includes JWT in Authorization header
            let created: BudgetCategory = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_categories")
                    .insert(category)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Created category: \(created.categoryName)")

            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .categoryCreated)

            return created
        } catch {
            logger.error("Failed to create category", error: error)
await SentryService.shared.captureError(error, context: [
                "operation": "createCategory",
                "repository": "LiveBudgetRepository"
            ])
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        do {
            let client = try getClient()
            let startTime = Date()

            var updated = category
            updated.updatedAt = Date()

            let result: BudgetCategory = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_categories")
                    .update(updated)
                    .eq("id", value: category.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Updated category: \(result.categoryName)")

            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .categoryUpdated)

            return result
        } catch {
            logger.error("Failed to update category", error: error)
await SentryService.shared.captureError(error, context: [
                "operation": "updateCategory",
                "repository": "LiveBudgetRepository",
                "categoryId": category.id.uuidString
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func deleteCategory(id: UUID) async throws {
        do {
            let client = try getClient()
            let startTime = Date()

            _ = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_categories")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted category: \(id)")

            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .categoryDeleted)
        } catch {
            logger.error("Failed to delete category", error: error)
await SentryService.shared.captureError(error, context: [
                "operation": "deleteCategory",
                "repository": "LiveBudgetRepository",
                "categoryId": id.uuidString
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    func checkCategoryDependencies(id: UUID) async throws -> CategoryDependencies {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            // Fetch the category first to get its name
            let categories: [BudgetCategory] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_categories")
                    .select()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .limit(1)
                    .execute()
                    .value
            }

            guard let category = categories.first else {
                throw BudgetError.fetchFailed(underlying: NSError(
                    domain: "LiveBudgetRepository",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Category not found"]
                ))
            }

            // Fetch expenses linked to this category
            let expenses: [Expense] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .select()
                    .eq("budget_category_id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }

            // Fetch subcategories
            let subcategories: [BudgetCategory] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_categories")
                    .select()
                    .eq("parent_category_id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }

            // Fetch tasks linked to this category
            struct TaskBasic: Codable {
                let id: UUID
            }
            let tasks: [TaskBasic] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("wedding_tasks")
                    .select("id")
                    .eq("budget_category_id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }

            // Fetch vendors linked to this category
            struct VendorBasic: Codable {
                let id: Int64
            }
            let vendors: [VendorBasic] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_information")
                    .select("id")
                    .eq("budget_category_id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }

            // Fetch budget development items using this category name
            // Use two separate safe queries to avoid string interpolation injection
            struct BudgetItemBasic: Codable {
                let id: String
                let category: String?
                let subcategory: String?
            }
            
            // Query 1: Items where category matches
            let categoryItems: [BudgetItemBasic] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_items")
                    .select("id, category, subcategory")
                    .eq("category", value: category.categoryName)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }
            
            // Query 2: Items where subcategory matches
            let subcategoryItems: [BudgetItemBasic] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_items")
                    .select("id, category, subcategory")
                    .eq("subcategory", value: category.categoryName)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }
            
            // Merge results and deduplicate by id
            let allItems = categoryItems + subcategoryItems
            let uniqueItemsDict = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
            let budgetItems = Array(uniqueItemsDict.values)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Checked dependencies for category '\(category.categoryName)' in \(String(format: "%.2f", duration))s")

            return CategoryDependencies(
                categoryId: id,
                categoryName: category.categoryName,
                expenseCount: expenses.count,
                budgetItemCount: budgetItems.count,
                subcategoryCount: subcategories.count,
                taskCount: tasks.count,
                vendorCount: vendors.count
            )
        } catch {
            logger.error("Failed to check category dependencies", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "checkCategoryDependencies",
                "repository": "LiveBudgetRepository",
                "categoryId": id.uuidString
            ])
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    func batchDeleteCategories(ids: [UUID]) async throws -> BatchDeleteResult {
        var succeeded: [UUID] = []
        var failed: [(UUID, BatchDeleteResult.SendableErrorWrapper)] = []

        for id in ids {
            do {
                try await deleteCategory(id: id)
                succeeded.append(id)
            } catch {
                failed.append((id, BatchDeleteResult.SendableErrorWrapper(error)))
                logger.warning("Failed to delete category \(id) in batch: \(error.localizedDescription)")
            }
        }

        logger.info("Batch delete completed: \(succeeded.count) succeeded, \(failed.count) failed")

        return BatchDeleteResult(succeeded: succeeded, failed: failed)
    }

    // MARK: - Expenses

    func fetchExpenses() async throws -> [Expense] {
        // Get tenant ID for cache key
        let tenantId = try await getTenantId()
        let cacheKey = "expenses_\(tenantId.uuidString)"

        // Check cache first (30 sec TTL for very fresh data)
        if let cached: [Expense] = await RepositoryCache.shared.get(cacheKey, maxAge: 30) {
            return cached
        }

        // Coalesce in-flight requests per-tenant
        if let task = inFlightExpenses[tenantId] {
            return try await task.value
        }

        let task = Task<[Expense], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            let client = try await self.getClient()
            let startTime = Date()
            do {
                // Fetch expenses without join first
                let expenses: [Expense] = try await RepositoryNetwork.withRetry {
                    try await client
                        .from("expenses")
                        .select()
                        .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                        .order("created_at", ascending: false)
                        .execute()
                        .value
                }

                // Get unique vendor IDs
                let vendorIds = expenses.compactMap { $0.vendorId }

                // If there are vendor IDs, fetch vendor names in a separate query
                if !vendorIds.isEmpty {
                    struct VendorBasic: Codable {
                        let id: Int64
                        let vendorName: String

                        enum CodingKeys: String, CodingKey {
                            case id = "id"
                            case vendorName = "vendor_name"
                        }
                    }

                    let vendors: [VendorBasic] = try await RepositoryNetwork.withRetry {
                        try await client
                            .from("vendor_information")
                            .select("id, vendor_name")
                            .in("id", values: vendorIds.map { String($0) })
                            .execute()
                            .value
                    }

                    // Create a lookup dictionary
                    let vendorDict = Dictionary(uniqueKeysWithValues: vendors.map { ($0.id, $0.vendorName) })

                    // Map expenses with vendor names
                    let expensesWithVendors = expenses.map { expense in
                        Expense(
                            id: expense.id,
                            coupleId: expense.coupleId,
                            budgetCategoryId: expense.budgetCategoryId,
                            vendorId: expense.vendorId,
                            vendorName: expense.vendorId.flatMap { vendorDict[$0] },
                            expenseName: expense.expenseName,
                            amount: expense.amount,
                            expenseDate: expense.expenseDate,
                            paymentMethod: expense.paymentMethod,
                            paymentStatus: expense.paymentStatus,
                            receiptUrl: expense.receiptUrl,
                            invoiceNumber: expense.invoiceNumber,
                            notes: expense.notes,
                            approvalStatus: expense.approvalStatus,
                            approvedBy: expense.approvedBy,
                            approvedAt: expense.approvedAt,
                            invoiceDocumentUrl: expense.invoiceDocumentUrl,
                            isTestData: expense.isTestData,
                            createdAt: expense.createdAt,
                            updatedAt: expense.updatedAt
                        )
                    }

                    let duration = Date().timeIntervalSince(startTime)
                    if duration > 1.0 {
                        self.logger.info("Slow expense fetch: \(String(format: "%.2f", duration))s for \(expensesWithVendors.count) items")
                    }
                    await RepositoryCache.shared.set(cacheKey, value: expensesWithVendors)
                    return expensesWithVendors
                }

                let duration = Date().timeIntervalSince(startTime)
                if duration > 1.0 {
                    self.logger.info("Slow expense fetch: \(String(format: "%.2f", duration))s for \(expenses.count) items")
                }
                await RepositoryCache.shared.set(cacheKey, value: expenses)
                return expenses
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                self.logger.error("Expenses fetch failed after \(String(format: "%.2f", duration))s", error: error)
                throw error
            }
        }

        inFlightExpenses[tenantId] = task
        defer { inFlightExpenses[tenantId] = nil }
        return try await task.value
    }

    func createExpense(_ expense: Expense) async throws -> Expense {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let created: Expense = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .insert(expense)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Created expense: \(created.expenseName)")

            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .expenseCreated(tenantId: tenantId))

            return created
        } catch {
            logger.error("Failed to create expense", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateExpense(_ expense: Expense) async throws -> Expense {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            // Create update struct without vendorName (it's a computed field from join, not a real column)
            struct ExpenseUpdate: Codable {
                let budgetCategoryId: UUID
                let vendorId: Int64?
                let expenseName: String
                let amount: Double
                let expenseDate: Date
                let paymentMethod: String?
                let paymentStatus: PaymentStatus
                let receiptUrl: String?
                let invoiceNumber: String?
                let notes: String?
                let approvalStatus: String?
                let approvedBy: String?
                let approvedAt: Date?
                let invoiceDocumentUrl: String?
                let updatedAt: Date

                enum CodingKeys: String, CodingKey {
                    case budgetCategoryId = "budget_category_id"
                    case vendorId = "vendor_id"
                    case expenseName = "expense_name"
                    case amount = "amount"
                    case expenseDate = "expense_date"
                    case paymentMethod = "payment_method"
                    case paymentStatus = "payment_status"
                    case receiptUrl = "receipt_url"
                    case invoiceNumber = "invoice_number"
                    case notes = "notes"
                    case approvalStatus = "approval_status"
                    case approvedBy = "approved_by"
                    case approvedAt = "approved_at"
                    case invoiceDocumentUrl = "invoice_document_url"
                    case updatedAt = "updated_at"
                }
            }

            let updateData = ExpenseUpdate(
                budgetCategoryId: expense.budgetCategoryId,
                vendorId: expense.vendorId,
                expenseName: expense.expenseName,
                amount: expense.amount,
                expenseDate: expense.expenseDate,
                paymentMethod: expense.paymentMethod,
                paymentStatus: expense.paymentStatus,
                receiptUrl: expense.receiptUrl,
                invoiceNumber: expense.invoiceNumber,
                notes: expense.notes,
                approvalStatus: expense.approvalStatus,
                approvedBy: expense.approvedBy,
                approvedAt: expense.approvedAt,
                invoiceDocumentUrl: expense.invoiceDocumentUrl,
                updatedAt: Date()
            )

            // Fetch previous state so we can attempt a compensating rollback if recalculation fails
            let previousExpenses: [Expense] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .select()
                    .eq("id", value: expense.id)
                    .limit(1)
                    .execute()
                    .value
            }
            let previousExpense = previousExpenses.first

            let result: Expense = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .update(updateData)
                    .eq("id", value: expense.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Updated expense: \(result.expenseName)")

            // Recalculate proportional allocations if expense amount changed. If recalculation fails,
            // attempt to roll back the expense update to previous state so we don't leave inconsistent DB state.
            do {
                try await allocationService.recalculateExpenseAllocationsForAllScenarios(expenseId: expense.id, newAmount: expense.amount)

                // Invalidate caches via strategy only after successful recalculation
                await cacheStrategy.invalidate(for: .expenseUpdated(tenantId: tenantId))
            } catch {
                // Attempt to restore previous expense if available
                if let previous = previousExpense {
                    do {
                        try await RepositoryNetwork.withRetry {
                            try await client
                                .from("expenses")
                                .update(previous)
                                .eq("id", value: expense.id)
                                .execute()
                        }
                        logger.info("Rolled back expense update after allocation recalculation failure for expense: \(expense.id)")
                    } catch {
                        logger.error("Failed to rollback expense after allocation recalculation failure", error: error)
                    }
                }
                throw error
            }

            return result
        } catch {
            logger.error("Failed to update expense", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func deleteExpense(id: UUID) async throws {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted expense: \(id)")

            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .expenseDeleted(tenantId: tenantId))
        } catch {
            logger.error("Failed to delete expense", error: error)
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense] {
        let cacheKey = "expenses_vendor_\(vendorId)"

        // Check cache first (30 sec TTL for very fresh data)
        if let cached: [Expense] = await RepositoryCache.shared.get(cacheKey, maxAge: 30) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
            let expenses: [Expense] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .select()
                    .eq("vendor_id", value: String(vendorId))
                    .order("expense_date", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow vendor expenses fetch: \(String(format: "%.2f", duration))s for \(expenses.count) items")
            }

            await RepositoryCache.shared.set(cacheKey, value: expenses)

            return expenses
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Vendor expenses fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Payment Schedules

    func fetchPaymentSchedules() async throws -> [PaymentSchedule] {
        do {
            // Get tenant ID for cache key
            let tenantId = try await getTenantId()
            let cacheKey = "payment_schedules_\(tenantId.uuidString)"

            if let cached: [PaymentSchedule] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
                return cached
            }

            let client = try getClient()
            let startTime = Date()

            let schedules: [PaymentSchedule] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("payment_plans")
                    .select()
                    .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                    .order("payment_date", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow payment schedules fetch: \(String(format: "%.2f", duration))s for \(schedules.count) items")
            }

            await RepositoryCache.shared.set(cacheKey, value: schedules)

            return schedules
        } catch {
            logger.error("Failed to fetch payment schedules", error: error)
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        do {
            let client = try getClient()
            let startTime = Date()

            // Create a codable struct for insertion that excludes the id field
            struct PaymentScheduleInsert: Codable {
                let coupleId: UUID
                let vendor: String?
                let paymentDate: Date
                let paymentAmount: Double
                let notes: String?
                let vendorType: String?
                let paid: Bool
                let paymentType: String?
                let customAmount: Double?
                let billingFrequency: String?
                let autoRenew: Bool
                let startDate: Date?
                let reminderEnabled: Bool
                let reminderDaysBefore: Int?
                let priorityLevel: String?
                let expenseId: UUID?
                let vendorId: Int64?
                let isDeposit: Bool
                let isRetainer: Bool
                let paymentOrder: Int?
                let totalPaymentCount: Int?
                let paymentPlanType: String?
                let paymentPlanId: UUID?  // ✅ Added payment_plan_id
                let createdAt: Date
                let updatedAt: Date?

                enum CodingKeys: String, CodingKey {
                case coupleId = "couple_id"
                case vendor = "vendor"
                case paymentDate = "payment_date"
                case paymentAmount = "payment_amount"
                case notes = "notes"
                case vendorType = "vendor_type"
                case paid = "paid"
                case paymentType = "payment_type"
                case customAmount = "custom_amount"
                case billingFrequency = "billing_frequency"
                    case autoRenew = "auto_renew"
                    case startDate = "start_date"
                    case reminderEnabled = "reminder_enabled"
                    case reminderDaysBefore = "reminder_days_before"
                    case priorityLevel = "priority_level"
                    case expenseId = "expense_id"
                    case vendorId = "vendor_id"
                    case isDeposit = "is_deposit"
                    case isRetainer = "is_retainer"
                    case paymentOrder = "payment_order"
                    case totalPaymentCount = "total_payment_count"
                    case paymentPlanType = "payment_plan_type"
                    case paymentPlanId = "payment_plan_id"  // ✅ Added payment_plan_id
                    case createdAt = "created_at"
                    case updatedAt = "updated_at"
                }
            }

            let insertData = PaymentScheduleInsert(
                coupleId: schedule.coupleId,
                vendor: schedule.vendor,
                paymentDate: schedule.paymentDate,
                paymentAmount: schedule.paymentAmount,
                notes: schedule.notes,
                vendorType: schedule.vendorType,
                paid: schedule.paid,
                paymentType: schedule.paymentType,
                customAmount: schedule.customAmount,
                billingFrequency: schedule.billingFrequency,
                autoRenew: schedule.autoRenew,
                startDate: schedule.startDate,
                reminderEnabled: schedule.reminderEnabled,
                reminderDaysBefore: schedule.reminderDaysBefore,
                priorityLevel: schedule.priorityLevel,
                expenseId: schedule.expenseId,
                vendorId: schedule.vendorId,
                isDeposit: schedule.isDeposit,
                isRetainer: schedule.isRetainer,
                paymentOrder: schedule.paymentOrder,
                totalPaymentCount: schedule.totalPaymentCount,
                paymentPlanType: schedule.paymentPlanType,
                paymentPlanId: schedule.paymentPlanId,  // ✅ Include payment_plan_id
                createdAt: schedule.createdAt,
                updatedAt: schedule.updatedAt
            )

            let created: PaymentSchedule = try await RepositoryNetwork.withRetry {
                try await client
                    .from("payment_plans")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Created payment schedule for vendor: \(created.vendor)")

            await RepositoryCache.shared.remove("payment_schedules")

            return created
        } catch {
            logger.error("Failed to create payment schedule", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        do {
            let client = try getClient()
            let startTime = Date()

            // Create update struct with only the fields that should be updated
            // This prevents sending invalid values for constrained fields
            struct PaymentScheduleUpdate: Codable {
                let vendor: String
                let paymentDate: Date
                let paymentAmount: Double
                let notes: String?
                let vendorType: String?
                let paid: Bool
                let paymentType: String?  // Must be: 'individual', 'monthly', 'interval', 'cyclical', 'deposit', 'retainer', or null
                let customAmount: Double?
                let billingFrequency: String?  // Must be: 'monthly', 'quarterly', 'yearly', or null
                let autoRenew: Bool
                let startDate: Date?
                let reminderEnabled: Bool
                let reminderDaysBefore: Int?
                let priorityLevel: String?  // Must be: 'high', 'medium', 'low', or null
                let expenseId: UUID?
                let vendorId: Int64?
                let isDeposit: Bool
                let isRetainer: Bool
                let paymentOrder: Int?
                let totalPaymentCount: Int?
                let paymentPlanType: String?
                let updatedAt: Date

                enum CodingKeys: String, CodingKey {
                    case vendor = "vendor"
                    case paymentDate = "payment_date"
                    case paymentAmount = "payment_amount"
                    case notes = "notes"
                    case vendorType = "vendor_type"
                    case paid = "paid"
                    case paymentType = "payment_type"
                    case customAmount = "custom_amount"
                    case billingFrequency = "billing_frequency"
                    case autoRenew = "auto_renew"
                    case startDate = "start_date"
                    case reminderEnabled = "reminder_enabled"
                    case reminderDaysBefore = "reminder_days_before"
                    case priorityLevel = "priority_level"
                    case expenseId = "expense_id"
                    case vendorId = "vendor_id"
                    case isDeposit = "is_deposit"
                    case isRetainer = "is_retainer"
                    case paymentOrder = "payment_order"
                    case totalPaymentCount = "total_payment_count"
                    case paymentPlanType = "payment_plan_type"
                    case updatedAt = "updated_at"
                }
            }

            // Validate and normalize paymentType to ensure it matches the check constraint
            // Valid types: 'individual', 'monthly', 'interval', 'cyclical', 'deposit', 'retainer'
            let validPaymentType: String?
            if let type = schedule.paymentType {
                let normalized = type.lowercased()
                if ["individual", "monthly", "interval", "cyclical", "deposit", "retainer"].contains(normalized) {
                    validPaymentType = normalized
                } else {
                    logger.warning("Invalid payment_type '\(type)' - setting to null. Valid types: individual, monthly, interval, cyclical, deposit, retainer")
                    validPaymentType = nil
                }
            } else {
                validPaymentType = nil
            }

            // Validate and normalize billingFrequency
            let validBillingFrequency: String?
            if let freq = schedule.billingFrequency {
                let normalized = freq.lowercased()
                if ["monthly", "quarterly", "yearly"].contains(normalized) {
                    validBillingFrequency = normalized
                } else {
                    logger.warning("Invalid billing_frequency '\(freq)' - setting to 'monthly'")
                    validBillingFrequency = "monthly"
                }
            } else {
                validBillingFrequency = "monthly"  // Default value from schema
            }

            // Validate and normalize priorityLevel
            let validPriorityLevel: String?
            if let priority = schedule.priorityLevel {
                let normalized = priority.lowercased()
                if ["high", "medium", "low"].contains(normalized) {
                    validPriorityLevel = normalized
                } else {
                    logger.warning("Invalid priority_level '\(priority)' - setting to null")
                    validPriorityLevel = nil
                }
            } else {
                validPriorityLevel = nil
            }

            let updateData = PaymentScheduleUpdate(
                vendor: schedule.vendor,
                paymentDate: schedule.paymentDate,
                paymentAmount: schedule.paymentAmount,
                notes: schedule.notes,
                vendorType: schedule.vendorType,
                paid: schedule.paid,
                paymentType: validPaymentType,
                customAmount: schedule.customAmount,
                billingFrequency: validBillingFrequency,
                autoRenew: schedule.autoRenew,
                startDate: schedule.startDate,
                reminderEnabled: schedule.reminderEnabled,
                reminderDaysBefore: schedule.reminderDaysBefore,
                priorityLevel: validPriorityLevel,
                expenseId: schedule.expenseId,
                vendorId: schedule.vendorId,
                isDeposit: schedule.isDeposit,
                isRetainer: schedule.isRetainer,
                paymentOrder: schedule.paymentOrder,
                totalPaymentCount: schedule.totalPaymentCount,
                paymentPlanType: schedule.paymentPlanType,
                updatedAt: Date()
            )

            let result: PaymentSchedule = try await RepositoryNetwork.withRetry {
                try await client
                    .from("payment_plans")
                    .update(updateData)
                    .eq("id", value: String(schedule.id))
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Updated payment schedule: \(result.id)")

            await RepositoryCache.shared.remove("payment_schedules")

            return result
        } catch {
            logger.error("Failed to update payment schedule: \(error.localizedDescription)", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func deletePaymentSchedule(id: Int64) async throws {
        do {
            let client = try getClient()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("payment_plans")
                    .delete()
                    .eq("id", value: String(id))
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted payment schedule: \(id)")

            await RepositoryCache.shared.remove("payment_schedules")
        } catch {
            logger.error("Failed to delete payment schedule", error: error)
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule] {
        let cacheKey = "payment_schedules_vendor_\(vendorId)"

        if let cached: [PaymentSchedule] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
            let schedules: [PaymentSchedule] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("payment_plans")
                    .select()
                    .eq("vendor_id", value: String(vendorId))
                    .order("payment_date", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow vendor payment schedules fetch: \(String(format: "%.2f", duration))s for \(schedules.count) items")
            }

            await RepositoryCache.shared.set(cacheKey, value: schedules)

            return schedules
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Vendor payment schedules fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
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

    // MARK: - Gifts and Owed

    func fetchGiftsAndOwed() async throws -> [GiftOrOwed] {
        // Get tenant ID for cache key
        let tenantId = try await getTenantId()
        let cacheKey = "gifts_and_owed_\(tenantId.uuidString)"

        if let cached: [GiftOrOwed] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
            let items: [GiftOrOwed] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("gifts_and_owed")
                    .select()
                    .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow gifts/owed fetch: \(String(format: "%.2f", duration))s for \(items.count) items")
            }

            await RepositoryCache.shared.set(cacheKey, value: items)

            return items
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gifts/owed fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        do {
            let client = try getClient()
            let startTime = Date()

            let created: GiftOrOwed = try await RepositoryNetwork.withRetry {
                try await client
                    .from("gifts_and_owed")
                    .insert(gift)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Created gift/owed: \(created.title)")

            // Invalidate cache
            await RepositoryCache.shared.remove("gifts_and_owed")
            if let scenarioId = gift.scenarioId {
                await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId)")
            }

            return created
        } catch {
            logger.error("Failed to create gift/owed", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        do {
            let client = try getClient()
            let startTime = Date()

            // Create updated gift object with new timestamp
            var updated = gift
            updated.updatedAt = Date()

            let result: GiftOrOwed = try await RepositoryNetwork.withRetry {
                try await client
                    .from("gifts_and_owed")
                    .update(updated)
                    .eq("id", value: gift.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Updated gift/owed: \(result.title)")

            // Invalidate cache
            await RepositoryCache.shared.remove("gifts_and_owed")
            if let scenarioId = gift.scenarioId {
                await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId)")
            }

            return result
        } catch {
            logger.error("Failed to update gift/owed", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func deleteGiftOrOwed(id: UUID) async throws {
        do {
            let client = try getClient()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("gifts_and_owed")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted gift/owed: \(id)")

            // Invalidate cache
            await RepositoryCache.shared.remove("gifts_and_owed")
        } catch {
            logger.error("Failed to delete gift/owed", error: error)
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Gift Received Operations

    func fetchGiftsReceived() async throws -> [GiftReceived] {
        let cacheKey = "gifts_received"

        if let cached: [GiftReceived] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
            let gifts: [GiftReceived] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("gift_received")
                    .select()
                    .order("date_received", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow gifts received fetch: \(String(format: "%.2f", duration))s for \(gifts.count) items")
            }

            await RepositoryCache.shared.set(cacheKey, value: gifts)

            return gifts
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gifts received fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        do {
            let client = try getClient()
            let startTime = Date()

            let created: GiftReceived = try await RepositoryNetwork.withRetry {
                try await client
                    .from("gift_received")
                    .insert(gift)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Created gift received from: \(created.fromPerson)")

            // Invalidate cache
            await RepositoryCache.shared.remove("gifts_received")

            return created
        } catch {
            logger.error("Failed to create gift received", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        do {
            let client = try getClient()
            let startTime = Date()

            // Create updated gift object with new timestamp
            var updated = gift
            updated.updatedAt = Date()

            let result: GiftReceived = try await RepositoryNetwork.withRetry {
                try await client
                    .from("gift_received")
                    .update(updated)
                    .eq("id", value: gift.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Updated gift received from: \(result.fromPerson)")

            // Invalidate cache
            await RepositoryCache.shared.remove("gifts_received")

            return result
        } catch {
            logger.error("Failed to update gift received", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func deleteGiftReceived(id: UUID) async throws {
        do {
            let client = try getClient()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("gift_received")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted gift received: \(id)")

            // Invalidate cache
            await RepositoryCache.shared.remove("gifts_received")
        } catch {
            logger.error("Failed to delete gift received", error: error)
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Money Owed Operations

    func fetchMoneyOwed() async throws -> [MoneyOwed] {
        let cacheKey = "money_owed"

        if let cached: [MoneyOwed] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
            let items: [MoneyOwed] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("money_owed")
                    .select()
                    .order("is_paid", ascending: true)
                    .order("due_date", ascending: true, nullsFirst: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow money owed fetch: \(String(format: "%.2f", duration))s for \(items.count) items")
            }

            await RepositoryCache.shared.set(cacheKey, value: items)

            return items
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Money owed fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        do {
            let client = try getClient()
            let startTime = Date()

            let created: MoneyOwed = try await RepositoryNetwork.withRetry {
                try await client
                    .from("money_owed")
                    .insert(money)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Created money owed to: \(created.toPerson)")

            // Invalidate cache
            await RepositoryCache.shared.remove("money_owed")

            return created
        } catch {
            logger.error("Failed to create money owed", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        do {
            let client = try getClient()
            let startTime = Date()

            // Create updated money object with new timestamp
            var updated = money
            updated.updatedAt = Date()

            let result: MoneyOwed = try await RepositoryNetwork.withRetry {
                try await client
                    .from("money_owed")
                    .update(updated)
                    .eq("id", value: money.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Updated money owed to: \(result.toPerson)")

            // Invalidate cache
            await RepositoryCache.shared.remove("money_owed")

            return result
        } catch {
            logger.error("Failed to update money owed", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func deleteMoneyOwed(id: UUID) async throws {
        do {
            let client = try getClient()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("money_owed")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted money owed: \(id)")

            // Invalidate cache
            await RepositoryCache.shared.remove("money_owed")
        } catch {
            logger.error("Failed to delete money owed", error: error)
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Affordability Scenarios

    func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario] {
        // Get tenant ID for cache key
        let tenantId = try await getTenantId()
        let cacheKey = "affordability_scenarios_\(tenantId.uuidString)"

        if let cached: [AffordabilityScenario] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
            let scenarios: [AffordabilityScenario] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("affordability_scenarios")
                    .select()
                    .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow affordability scenarios fetch: \(String(format: "%.2f", duration))s for \(scenarios.count) items")
            }

            await RepositoryCache.shared.set(cacheKey, value: scenarios)

            return scenarios
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Affordability scenarios fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario {
        do {
            let client = try getClient()
            let startTime = Date()

            let saved: AffordabilityScenario = try await RepositoryNetwork.withRetry {
                try await client
                    .from("affordability_scenarios")
                    .upsert(scenario)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Saved affordability scenario: \(saved.scenarioName)")

            await RepositoryCache.shared.remove("affordability_scenarios")

            return saved
        } catch {
            logger.error("Failed to save affordability scenario", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func deleteAffordabilityScenario(id: UUID) async throws {
        do {
            let client = try getClient()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("affordability_scenarios")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Deleted affordability scenario: \(id)")

            await RepositoryCache.shared.remove("affordability_scenarios")
        } catch {
            logger.error("Failed to delete affordability scenario", error: error)
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Affordability Contributions

    func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem] {
        let cacheKey = "affordability_contributions_\(scenarioId)"

        if let cached: [ContributionItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            #if DEBUG
            logger.debug("Cache hit: affordability_contributions for scenario \(scenarioId) - \(cached.count) items")
            #endif
            return cached
        }

        let client = try getClient()

        #if DEBUG
        logger.debug("Fetching affordability contributions for scenario \(scenarioId)...")
        logger.debug("Cache miss - fetching fresh data from database")
        #endif

        // Fetch direct contributions from affordability_gifts_contributions
        let directContributions: [ContributionItem]
        do {
            directContributions = try await client
                .from("affordability_gifts_contributions")
                .select()
                .eq("scenario_id", value: scenarioId)
                .order("contribution_date", ascending: false)
                .execute()
                .value
            #if DEBUG
            logger.debug("Fetched \(directContributions.count) direct contributions")
            #endif
        } catch {
            logger.error("Error fetching direct contributions", error: error)
            throw error
        }

        // Fetch linked gifts from gifts_and_owed
        let linkedGifts: [GiftOrOwed]
        do {
            linkedGifts = try await client
                .from("gifts_and_owed")
                .select()
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value
            #if DEBUG
            logger.debug("Fetched \(linkedGifts.count) linked gifts")
            for gift in linkedGifts {
                logger.debug("Gift ID: \(gift.id), Title: \(gift.title), From: \(gift.fromPerson ?? "N/A")")
            }
            #endif
        } catch {
            logger.error("Error fetching linked gifts", error: error)
            throw error
        }

        #if DEBUG
        logger.debug("Found \(directContributions.count) direct contributions and \(linkedGifts.count) linked gifts")
        #endif

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

        await RepositoryCache.shared.set(cacheKey, value: contributions)
        #if DEBUG
        logger.debug("Cached \(contributions.count) contributions")
        #endif

        return contributions
    }

    func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem {
        let client = try getClient()
        let saved: ContributionItem = try await client
            .from("affordability_gifts_contributions")
            .upsert(contribution)
            .select()
            .single()
            .execute()
            .value

        await RepositoryCache.shared.remove("affordability_contributions_\(contribution.scenarioId)")

        // Log important mutation
        logger.info("Saved contribution from: \(saved.contributorName)")

        return saved
    }

    func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws {
        let client = try getClient()
        try await client
            .from("affordability_gifts_contributions")
            .delete()
            .eq("id", value: id)
            .execute()

        await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId)")

        // Log important mutation
        logger.info("Deleted contribution: \(id)")
    }

    func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async throws {
        let client = try getClient()
        for giftId in giftIds {
            try await client
                .from("gifts_and_owed")
                .update(["scenario_id": scenarioId])
                .eq("id", value: giftId)
                .execute()
        }

        await RepositoryCache.shared.remove("gifts_and_owed")
        await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId)")

        // Log important mutation
        logger.info("Linked \(giftIds.count) gifts to scenario \(scenarioId)")
    }

    func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async throws {
        let client = try getClient()
        let response = try await client
            .from("gifts_and_owed")
            .update(["scenario_id": AnyJSON.null])
            .eq("id", value: giftId)
            .select()
            .execute()

        // Verify the update worked by checking response status
        let affectedRows = (try? JSONDecoder().decode([GiftOrOwed].self, from: response.data).count) ?? 0

        if affectedRows == 0 {
            logger.warning("No rows updated - gift may not exist or already unlinked")
        } else {
            // Log important mutation
            logger.info("Unlinked gift \(giftId) from scenario \(scenarioId)")
        }

        await RepositoryCache.shared.remove("gifts_and_owed")
        await RepositoryCache.shared.remove("affordability_contributions_\(scenarioId)")
    }

    // MARK: - Budget Development

    func fetchBudgetDevelopmentScenarios() async throws -> [SavedScenario] {
    // Get tenant ID for cache key
    let tenantId = try await getTenantId()
    let cacheKey = "budget_dev_scenarios_\(tenantId.uuidString)"

    if let cached: [SavedScenario] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
    return cached
    }

    let client = try getClient()
    let scenarios: [SavedScenario] = try await client
    .from("budget_development_scenarios")
    .select()
    .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
    .order("created_at", ascending: false)
    .execute()
    .value

    await RepositoryCache.shared.set(cacheKey, value: scenarios)

    return scenarios
    }

    func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem] {
        let cacheKey = scenarioId.map { "budget_dev_items_\($0)" } ?? "budget_dev_items_all"

        if let cached: [BudgetItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let client = try getClient()
        var query = client.from("budget_development_items").select()

        if let scenarioId {
            query = query.eq("scenario_id", value: scenarioId)
        }

        let items: [BudgetItem] = try await query
            .order("created_at", ascending: false)
            .execute()
            .value

        await RepositoryCache.shared.set(cacheKey, value: items)

        return items
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
        do {
            let client = try getClient()
            let created: SavedScenario = try await client
                .from("budget_development_scenarios")
                .insert(scenario)
                .select()
                .single()
                .execute()
                .value

            await RepositoryCache.shared.remove("budget_dev_scenarios")

            // Log important mutation
            logger.info("Created budget development scenario: \(created.scenarioName)")

            return created
        } catch {
            logger.error("Failed to create budget development scenario", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        do {
            let client = try getClient()
            
            logger.debug("Updating scenario: \(scenario.id), isPrimary: \(scenario.isPrimary), coupleId: \(scenario.coupleId)")
            
            let result: SavedScenario = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_scenarios")
                    .update(scenario)
                    .eq("id", value: scenario.id)
                    .eq("couple_id", value: scenario.coupleId)  // ✅ Use scenario's coupleId for proper filtering
                    .select()
                    .single()
                    .execute()
                    .value
            }

            await RepositoryCache.shared.remove("budget_dev_scenarios_\(scenario.coupleId.uuidString)")
            await RepositoryCache.shared.remove("primary_budget_scenario_\(scenario.coupleId.uuidString)")

            // Log important mutation
            logger.info("Updated budget development scenario: \(result.scenarioName), isPrimary: \(result.isPrimary)")

            return result
        } catch {
            logger.error("Failed to update budget development scenario: \(error.localizedDescription)", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        do {
            let client = try getClient()
            let created: BudgetItem = try await client
                .from("budget_development_items")
                .insert(item)
                .select()
                .single()
                .execute()
                .value

            if let scenarioId = item.scenarioId {
                await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            }
            await RepositoryCache.shared.remove("budget_dev_items_all")

            // Log important mutation
            logger.info("Created budget development item: \(created.itemName)")

            return created
        } catch {
            logger.error("Failed to create budget development item", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        do {
            let client = try getClient()
            // Read previous state for potential rollback if recalculation fails
            let previousItems: [BudgetItem] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: item.id)
                    .limit(1)
                    .execute()
                    .value
            }
            let previousItem = previousItems.first

            let result: BudgetItem = try await client
                .from("budget_development_items")
                .update(item)
                .eq("id", value: item.id)
                .select()
                .single()
                .execute()
                .value

            // If this item belongs to a scenario, perform recalculation. If it fails,
            // attempt to restore the previous item so we don't leave inconsistent state.
            if let scenarioId = item.scenarioId {
                do {
                    try await allocationService.recalculateAllocations(budgetItemId: item.id, scenarioId: scenarioId)

                    // Only invalidate caches after successful recalculation
                    await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
                    await RepositoryCache.shared.remove("budget_dev_items_all")
                } catch {
                    if let previous = previousItem {
                        do {
                            try await RepositoryNetwork.withRetry {
                                try await client
                                    .from("budget_development_items")
                                    .update(previous)
                                    .eq("id", value: item.id)
                                    .execute()
                            }
                            logger.info("Rolled back budget development item update after recalculation failure: \(item.id)")
                        } catch {
                            logger.error("Failed to rollback budget development item after recalculation failure", error: error)
                        }
                    }
                    throw error
                }
            } else {
                // No scenario associated, still remove the global cache key
                await RepositoryCache.shared.remove("budget_dev_items_all")
            }

            // Log important mutation
            logger.info("Updated budget development item: \(result.itemName)")

            return result
        } catch {
            logger.error("Failed to update budget development item", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }



    func deleteBudgetDevelopmentItem(id: String) async throws {
        do {
            let client = try getClient()
            
            // Fetch the item first to get its scenarioId for proper cache invalidation
            let items: [BudgetItem] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: id)
                    .limit(1)
                    .execute()
                    .value
            }
            let scenarioId = items.first?.scenarioId
            
            try await client
                .from("budget_development_items")
                .delete()
                .eq("id", value: id)
                .execute()

            // Invalidate scenario-specific cache if we know the scenario
            if let scenarioId = scenarioId {
                await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            }
            // Always invalidate global cache
            await RepositoryCache.shared.remove("budget_dev_items_all")

            // Log important mutation
            logger.info("Deleted budget development item: \(id)")
        } catch {
            logger.error("Failed to delete budget development item", error: error)
            throw BudgetError.deleteFailed(underlying: error)
        }
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

    // MARK: - Expense Allocations

    func fetchExpenseAllocations(scenarioId: String, budgetItemId: String) async throws -> [ExpenseAllocation] {
        do {
            let client = try getClient()
            let startTime = Date()

            let allocations: [ExpenseAllocation] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expense_budget_allocations")
                    .select()
                    .eq("scenario_id", value: scenarioId)
                    .eq("budget_item_id", value: budgetItemId)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            if duration > 1.0 {
                logger.info("Slow expense allocations fetch: \(String(format: "%.2f", duration))s for \(allocations.count) items")
            }

            return allocations
        } catch {
            logger.error("Failed to fetch expense allocations", error: error)
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    func fetchExpenseAllocationsForScenario(scenarioId: String) async throws -> [ExpenseAllocation] {
        do {
            let client = try getClient()
            let startTime = Date()

            let allocations: [ExpenseAllocation] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expense_budget_allocations")
                    .select()
                    .eq("scenario_id", value: scenarioId)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            if duration > 1.0 {
                logger.info("Slow expense allocations fetch (scenario): \(String(format: "%.2f", duration))s for \(allocations.count) items")
            }

            return allocations
        } catch {
            logger.error("Failed to fetch expense allocations for scenario", error: error)
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws -> ExpenseAllocation {
        let client = try getClient()
        let startTime = Date()

        do {
            let created: ExpenseAllocation = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expense_budget_allocations")
                    .insert(allocation)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created expense allocation: \(created.expenseId) -> \(created.budgetItemId) in \(String(format: "%.2f", duration))s")
            await RepositoryCache.shared.remove("budget_overview_items_\(allocation.scenarioId)")
            return created
        } catch {
            logger.error("Failed to create expense allocation", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func fetchAllocationsForExpense(expenseId: UUID, scenarioId: String) async throws -> [ExpenseAllocation] {
        let client = try getClient()
        let allocations: [ExpenseAllocation] = try await RepositoryNetwork.withRetry {
            try await client
                .from("expense_budget_allocations")
                .select()
                .eq("expense_id", value: expenseId.uuidString)
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value
        }
        return allocations
    }

    func fetchAllocationsForExpenseAllScenarios(expenseId: UUID) async throws -> [ExpenseAllocation] {
        let client = try getClient()
        let allocations: [ExpenseAllocation] = try await RepositoryNetwork.withRetry {
            try await client
                .from("expense_budget_allocations")
                .select()
                .eq("expense_id", value: expenseId.uuidString)
                .execute()
                .value
        }
        return allocations
    }

    func replaceAllocations(expenseId: UUID, scenarioId: String, with newAllocations: [ExpenseAllocation]) async throws {
        let client = try getClient()
        // Fetch backup of existing allocations so we can restore on failure
        let existing: [ExpenseAllocation] = try await RepositoryNetwork.withRetry {
            try await client
                .from("expense_budget_allocations")
                .select()
                .eq("expense_id", value: expenseId.uuidString)
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value
        }

        // Delete existing
        try await RepositoryNetwork.withRetry {
            try await client
                .from("expense_budget_allocations")
                .delete()
                .eq("expense_id", value: expenseId.uuidString)
                .eq("scenario_id", value: scenarioId)
                .execute()
        }

        // Insert new set
        if !newAllocations.isEmpty {
            do {
                try await RepositoryNetwork.withRetry {
                    try await client
                        .from("expense_budget_allocations")
                        .insert(newAllocations)
                        .execute()
                }
            } catch {
                // Attempt to restore previous allocations
                if !existing.isEmpty {
                    do {
                        try await RepositoryNetwork.withRetry {
                            try await client
                                .from("expense_budget_allocations")
                                .insert(existing)
                                .execute()
                        }
                        logger.info("Restored previous allocations after insert failure for expense: \(expenseId)")
                    } catch {
                        logger.error("Failed to restore allocations after insert failure", error: error)
                    }
                }
                throw error
            }
        }

        // Only invalidate cache after successful replace
        await RepositoryCache.shared.remove("budget_overview_items_\(scenarioId)")
    }

    func linkGiftToBudgetItem(giftId: UUID, budgetItemId: String) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_items")
                    .update(["linked_gift_owed_id": giftId.uuidString])
                    .eq("id", value: budgetItemId)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)

            // Log important mutation
            logger.info("Linked gift \(giftId) to budget item \(budgetItemId)")

            // Invalidate related caches
            await RepositoryCache.shared.remove("gifts_and_owed")
            // Invalidate budget development items cache for all scenarios
            // (we don't know which scenario this item belongs to)
            let stats = await RepositoryCache.shared.stats()
            for key in stats.keys where key.hasPrefix("budget_development_items_") {
                await RepositoryCache.shared.remove(key)
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gift linking failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Composite Saves (Scenario + Items)

    func saveBudgetScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int) {
        struct Params: Encodable {
            let p_scenario: SavedScenario
            let p_items: [BudgetItem]
        }
        struct ResultRow: Decodable {
            let scenario_id: String
            let inserted_items: Int
        }
        let client = try getClient()
        let startTime = Date()
        let params = Params(p_scenario: scenario, p_items: items)
        let results: [ResultRow] = try await RepositoryNetwork.withRetry {
            try await client
                .rpc("save_budget_scenario_with_items", params: params)
                .execute()
                .value
        }
        guard let first = results.first,
              !first.scenario_id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let errorInfo = [NSLocalizedDescriptionKey: "RPC returned no or empty scenario_id"]
            let error = NSError(domain: "LiveBudgetRepository", code: -1, userInfo: errorInfo)
            throw BudgetError.updateFailed(underlying: error)
        }

        // Resolve tenant id explicitly so errors propagate (don't silently use empty string)
        let tenantId = try await getTenantId().uuidString

        // Invalidate caches
        await RepositoryCache.shared.remove("budget_dev_scenarios_\(tenantId)")
        await RepositoryCache.shared.remove("budget_dev_items_\(first.scenario_id)")
        await RepositoryCache.shared.remove("budget_dev_items_all")
        await RepositoryCache.shared.remove("primary_budget_scenario_\(tenantId)")
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Saved scenario + items via RPC in \(String(format: "%.2f", duration))s (items=\(first.inserted_items))")
        return (first.scenario_id, first.inserted_items)
    }

    // MARK: - Primary Budget Scenario

    func fetchPrimaryBudgetScenario() async throws -> BudgetDevelopmentScenario? {
    let client = try getClient()
    let startTime = Date()
    let tenantId = try await getTenantId()

    // Check cache first (tenant-specific key to prevent cross-couple data leakage)
    let cacheKey = "primary_budget_scenario_\(tenantId.uuidString)"
    if let cached: BudgetDevelopmentScenario = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
    logger.info("Cache hit: primary budget scenario")
    return cached
    }

    do {
    // Query with explicit couple_id filter (don't rely solely on RLS for cache correctness)
    let scenarios: [BudgetDevelopmentScenario] = try await RepositoryNetwork.withRetry {
    try await client
    .from("budget_development_scenarios")
    .select()
    .eq("couple_id", value: tenantId)
    .eq("is_primary", value: true)
    .limit(1)
    .execute()
    .value
    }

    let scenario = scenarios.first
    let duration = Date().timeIntervalSince(startTime)

    if let scenario = scenario {
    logger.info("Fetched primary budget scenario: \(scenario.scenarioName) ($\(scenario.totalWithTax)) in \(String(format: "%.2f", duration))s")

    // Cache the result (5 minute TTL) with tenant-specific key
    await RepositoryCache.shared.set(cacheKey, value: scenario, ttl: 300)
            } else {
                logger.info("No primary budget scenario found in \(String(format: "%.2f", duration))s")
            }

            return scenario
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Primary budget scenario fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Folder Operations

    func createFolder(name: String, scenarioId: String, parentFolderId: String?, displayOrder: Int) async throws -> BudgetItem {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            
            let folder = BudgetItem.createFolder(
                name: name,
                scenarioId: scenarioId,
                parentFolderId: parentFolderId,
                displayOrder: displayOrder,
                coupleId: tenantId
            )
            
            let created: BudgetItem = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_items")
                    .insert(folder)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            logger.info("Created folder: \(name)")
            await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            await RepositoryCache.shared.remove("budget_dev_items_all")
            
            return created
        } catch {
            logger.error("Failed to create folder", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }

    func moveItemToFolder(itemId: String, targetFolderId: String?, displayOrder: Int) async throws {
        do {
            let client = try getClient()
            
            struct MoveUpdate: Codable {
                let parentFolderId: String?
                let displayOrder: Int
                let updatedAt: Date
                
                enum CodingKeys: String, CodingKey {
                    case parentFolderId = "parent_folder_id"
                    case displayOrder = "display_order"
                    case updatedAt = "updated_at"
                }
            }
            
            let update = MoveUpdate(
                parentFolderId: targetFolderId,
                displayOrder: displayOrder,
                updatedAt: Date()
            )
            
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_items")
                    .update(update)
                    .eq("id", value: itemId)
                    .execute()
            }
            
            logger.info("Moved item \(itemId) to folder \(targetFolderId ?? "root")")
            await RepositoryCache.shared.remove("budget_dev_items_all")
        } catch {
            logger.error("Failed to move item to folder", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func updateDisplayOrder(items: [(itemId: String, displayOrder: Int)]) async throws {
        // Define struct outside loop to avoid repeated allocations
        struct OrderUpdate: Codable {
            let id: String
            let displayOrder: Int
            let updatedAt: Date

            enum CodingKeys: String, CodingKey {
                case id = "id"
                case displayOrder = "display_order"
                case updatedAt = "updated_at"
            }
        }
        
        do {
            let client = try getClient()
            let now = Date()
            
            // Collect all updates into a single array for batch operation
            let updates = items.map { (itemId, order) in
                OrderUpdate(id: itemId, displayOrder: order, updatedAt: now)
            }
            
            // Perform single batch upsert instead of N separate updates
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_items")
                    .upsert(updates)
                    .execute()
            }

            logger.info("Updated display order for \(items.count) items in single batch operation")
            await RepositoryCache.shared.remove("budget_dev_items_all")
        } catch {
            logger.error("Failed to update display order", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }



    func toggleFolderExpansion(folderId: String, isExpanded: Bool) async throws {
        do {
            let client = try getClient()
            
            struct ExpansionUpdate: Codable {
                let isExpanded: Bool
                let updatedAt: Date
                
                enum CodingKeys: String, CodingKey {
                    case isExpanded = "is_expanded"
                    case updatedAt = "updated_at"
                }
            }
            
            let update = ExpansionUpdate(isExpanded: isExpanded, updatedAt: Date())
            
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_development_items")
                    .update(update)
                    .eq("id", value: folderId)
                    .execute()
            }
            
            logger.info("Toggled folder \(folderId) expansion to \(isExpanded)")
        } catch {
            logger.error("Failed to toggle folder expansion", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    func fetchBudgetItemsHierarchical(scenarioId: String) async throws -> [BudgetItem] {
        let cacheKey = "budget_items_hierarchical_\(scenarioId)"
        
        if let cached: [BudgetItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        let client = try getClient()
        
        let items: [BudgetItem] = try await RepositoryNetwork.withRetry {
            try await client
                .from("budget_development_items")
                .select()
                .eq("scenario_id", value: scenarioId)
                .order("display_order", ascending: true)
                .execute()
                .value
        }
        
        await RepositoryCache.shared.set(cacheKey, value: items)
        logger.info("Fetched \(items.count) hierarchical items for scenario \(scenarioId)")
        
        return items
    }

    func calculateFolderTotals(folderId: String) async throws -> FolderTotals {
    // Fetch the folder first to get its scenarioId
    let client = try getClient()
    let folders: [BudgetItem] = try await RepositoryNetwork.withRetry {
    try await client
    .from("budget_development_items")
    .select()
    .eq("id", value: folderId)
    .eq("is_folder", value: true)
    .limit(1)
    .execute()
    .value
    }
    
    guard let folder = folders.first, let scenarioId = folder.scenarioId else {
    throw BudgetError.fetchFailed(underlying: NSError(
    domain: "LiveBudgetRepository",
    code: -1,
    userInfo: [NSLocalizedDescriptionKey: "Folder not found or missing scenarioId"]
    ))
    }
    
    // Now fetch all items for the correct scenario
    let items = try await fetchBudgetItemsHierarchical(scenarioId: scenarioId)
    
    func getAllDescendants(of folderId: String) -> [BudgetItem] {
    var result: [BudgetItem] = []
    var queue = [folderId]
    
    while !queue.isEmpty {
    let currentId = queue.removeFirst()
    let children = items.filter { $0.parentFolderId == currentId && !$0.isFolder }
    result.append(contentsOf: children)
    
    let childFolders = items.filter { $0.parentFolderId == currentId && $0.isFolder }
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
    // Can't move to itself
    if itemId == targetFolderId { return false }
    
    // If moving to root, always allowed
    guard let targetFolderId = targetFolderId else { return true }
    
    // Fetch the item first to get its scenarioId
    let client = try getClient()
    let itemsToMove: [BudgetItem] = try await RepositoryNetwork.withRetry {
    try await client
    .from("budget_development_items")
    .select()
    .eq("id", value: itemId)
    .limit(1)
    .execute()
    .value
    }
    
    guard let item = itemsToMove.first, let scenarioId = item.scenarioId else {
    throw BudgetError.fetchFailed(underlying: NSError(
    domain: "LiveBudgetRepository",
    code: -1,
    userInfo: [NSLocalizedDescriptionKey: "Item not found or missing scenarioId"]
    ))
    }
    
    // Fetch all items for the correct scenario
    let items = try await fetchBudgetItemsHierarchical(scenarioId: scenarioId)
        
        // Check if target is a folder
        guard let targetFolder = items.first(where: { $0.id == targetFolderId }),
              targetFolder.isFolder else {
            return false
        }
        
        // Check depth limit (max 3 levels)
        func getDepth(of itemId: String) -> Int {
            var depth = 0
            var currentId: String? = itemId
            
            while let id = currentId,
                  let item = items.first(where: { $0.id == id }),
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
            
            guard let item = items.first(where: { $0.id == id }) else { break }
            currentId = item.parentFolderId
        }
        
        return true
    }

    func deleteFolder(folderId: String, deleteContents: Bool) async throws {
    do {
    let client = try getClient()
    
    // Fetch the folder first to get its scenarioId (needed for both branches)
    let folders: [BudgetItem] = try await RepositoryNetwork.withRetry {
    try await client
    .from("budget_development_items")
    .select()
    .eq("id", value: folderId)
    .eq("is_folder", value: true)
    .limit(1)
    .execute()
    .value
    }
    
    guard let folder = folders.first, let scenarioId = folder.scenarioId else {
    throw BudgetError.deleteFailed(underlying: NSError(
    domain: "LiveBudgetRepository",
    code: -1,
    userInfo: [NSLocalizedDescriptionKey: "Folder not found or missing scenarioId"]
    ))
    }
    
    if deleteContents {
    // Delete folder and all descendant items recursively
    // First, fetch all items in the scenario to build the hierarchy
    let items = try await fetchBudgetItemsHierarchical(scenarioId: scenarioId)
    
    // Recursively collect all descendant IDs (folders and items)
    func getAllDescendantIds(of parentId: String) -> [String] {
    var result: [String] = []
    let directChildren = items.filter { $0.parentFolderId == parentId }
    
    for child in directChildren {
    result.append(child.id)
    // If child is a folder, recursively get its descendants
    if child.isFolder {
    result.append(contentsOf: getAllDescendantIds(of: child.id))
    }
    }
    
    return result
    }
    
    let descendantIds = getAllDescendantIds(of: folderId)
    
    // Delete all descendants first (if any)
    if !descendantIds.isEmpty {
    try await RepositoryNetwork.withRetry {
    try await client
    .from("budget_development_items")
    .delete()
    .in("id", values: descendantIds)
    .execute()
    }
    logger.info("Deleted \(descendantIds.count) descendant items from folder \(folderId)")
    }
    
    // Then delete the folder itself
    try await RepositoryNetwork.withRetry {
    try await client
    .from("budget_development_items")
    .delete()
    .eq("id", value: folderId)
    .execute()
    }
    
    logger.info("Deleted folder \(folderId) and all contents")
    } else {
    // Move contents to parent, then delete folder
    let items = try await fetchBudgetItemsHierarchical(scenarioId: scenarioId)
    
    let children = items.filter { $0.parentFolderId == folderId }
    
    // Move children to folder's parent
    for child in children {
    try await moveItemToFolder(itemId: child.id, targetFolderId: folder.parentFolderId, displayOrder: child.displayOrder)
    }
    
    // Delete the folder
    try await RepositoryNetwork.withRetry {
    try await client
    .from("budget_development_items")
    .delete()
    .eq("id", value: folderId)
    .execute()
    }
    
    logger.info("Deleted folder \(folderId), moved \(children.count) items to parent")
    }
    
    // Invalidate caches with scenarioId
    await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
    await RepositoryCache.shared.remove("budget_dev_items_all")
    } catch {
    logger.error("Failed to delete folder", error: error)
    throw BudgetError.deleteFailed(underlying: error)
    }
    }
}
