import Foundation
import Supabase

/// Production implementation of BudgetRepositoryProtocol
/// Uses Supabase client for all data operations with automatic caching
actor LiveBudgetRepository: BudgetRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository

    init(supabase: SupabaseClient? = nil) {
        self.supabase = supabase
    }

    // Convenience initializer using SupabaseManager singleton
    init() {
        supabase = SupabaseManager.shared.client
    }
    
    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }

    // MARK: - Budget Summary

    func fetchBudgetSummary() async throws -> BudgetSummary? {
        let cacheKey = "budget_summary"

        // ✅ Check cache first (5 min TTL)
        if let cached: BudgetSummary = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            logger.info("Cache hit: budget summary")
            return cached
        }

        logger.info("Cache miss: fetching budget summary from database")
        let client = try getClient()
        let startTime = Date()

        do {
            // Fetch from Supabase with retry and timeout
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
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("fetchBudgetSummary", duration: duration)
            
            logger.info("Fetched budget summary in \(String(format: "%.2f", duration))s")

            let summary = response.first

            // ✅ Cache the result
            if let summary {
                await RepositoryCache.shared.set(cacheKey, value: summary, ttl: 300)
            }

            return summary
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("fetchBudgetSummary", duration: duration)
            
            logger.error("Budget summary fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Categories

    func fetchCategories() async throws -> [BudgetCategory] {
        let cacheKey = "budget_categories"

        // Check cache first (1 min TTL for fresher data)
        if let cached: [BudgetCategory] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
            let categories: [BudgetCategory] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("budget_categories")
                    .select()
                    .order("priority_level", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            
            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow category fetch: \(String(format: "%.2f", duration))s for \(categories.count) items")
            }

            await RepositoryCache.shared.set(cacheKey, value: categories)

            return categories
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Category fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        let client = try getClient()
        let startTime = Date()

        do {
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

            // Invalidate cache
            await RepositoryCache.shared.remove("budget_categories")
            await RepositoryCache.shared.remove("budget_summary")

            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Category creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        let client = try getClient()
        let startTime = Date()

        var updated = category
        updated.updatedAt = Date()

        do {
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

            // Invalidate cache
            await RepositoryCache.shared.remove("budget_categories")
            await RepositoryCache.shared.remove("budget_summary")

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Category update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteCategory(id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
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

            // Invalidate cache
            await RepositoryCache.shared.remove("budget_categories")
            await RepositoryCache.shared.remove("budget_summary")
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
        if let cached: [Expense] = await RepositoryCache.shared.get(cacheKey, maxAge: 30) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
            // Fetch expenses without join first
            let expenses: [Expense] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .select()
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
                        case id
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
                
                // Only log if slow
                if duration > 1.0 {
                    logger.info("Slow expense fetch: \(String(format: "%.2f", duration))s for \(expensesWithVendors.count) items")
                }
                
                await RepositoryCache.shared.set(cacheKey, value: expensesWithVendors)
                
                return expensesWithVendors
            }

            let duration = Date().timeIntervalSince(startTime)
            
            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow expense fetch: \(String(format: "%.2f", duration))s for \(expenses.count) items")
            }

            await RepositoryCache.shared.set(cacheKey, value: expenses)

            return expenses
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expenses fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createExpense(_ expense: Expense) async throws -> Expense {
        let client = try getClient()
        let startTime = Date()

        do {
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

            // Invalidate cache
            await RepositoryCache.shared.remove("expenses")
            await RepositoryCache.shared.remove("budget_summary")

            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expense creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updateExpense(_ expense: Expense) async throws -> Expense {
        let client = try getClient()
        let startTime = Date()

        var updated = expense
        updated.updatedAt = Date()

        do {
            let result: Expense = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .update(updated)
                    .eq("id", value: expense.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            
            // Log important mutation
            logger.info("Updated expense: \(result.expenseName)")

            // Invalidate cache
            await RepositoryCache.shared.remove("expenses")
            await RepositoryCache.shared.remove("budget_summary")

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expense update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteExpense(id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
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

            // Invalidate cache
            await RepositoryCache.shared.remove("expenses")
            await RepositoryCache.shared.remove("budget_summary")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expense deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Payment Schedules

    func fetchPaymentSchedules() async throws -> [PaymentSchedule] {
        let cacheKey = "payment_schedules"

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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment schedules fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        let client = try getClient()
        let startTime = Date()

        do {
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
                let createdAt: Date
                let updatedAt: Date?
                
                enum CodingKeys: String, CodingKey {
                    case coupleId = "couple_id"
                    case vendor
                    case paymentDate = "payment_date"
                    case paymentAmount = "payment_amount"
                    case notes
                    case vendorType = "vendor_type"
                    case paid
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment schedule creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        let client = try getClient()
        let startTime = Date()

        var updated = schedule
        updated.updatedAt = Date()

        do {
            let result: PaymentSchedule = try await RepositoryNetwork.withRetry {
                try await client
                    .from("payment_plans")
                    .update(updated)
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment schedule update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deletePaymentSchedule(id: Int64) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payment schedule deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Gifts and Owed

    func fetchGiftsAndOwed() async throws -> [GiftOrOwed] {
        let cacheKey = "gifts_and_owed"

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
        let client = try getClient()
        let startTime = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gift/owed creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed {
        let client = try getClient()
        let startTime = Date()

        // Create updated gift object with new timestamp
        var updated = gift
        updated.updatedAt = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gift/owed update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteGiftOrOwed(id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gift/owed deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
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
        let client = try getClient()
        let startTime = Date()
        
        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gift received creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
    
    func updateGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived {
        let client = try getClient()
        let startTime = Date()
        
        // Create updated gift object with new timestamp
        var updated = gift
        updated.updatedAt = Date()
        
        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gift received update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
    
    func deleteGiftReceived(id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()
        
        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gift received deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
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
        let client = try getClient()
        let startTime = Date()
        
        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Money owed creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
    
    func updateMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed {
        let client = try getClient()
        let startTime = Date()
        
        // Create updated money object with new timestamp
        var updated = money
        updated.updatedAt = Date()
        
        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Money owed update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
    
    func deleteMoneyOwed(id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()
        
        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Money owed deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Affordability Scenarios

    func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario] {
        let cacheKey = "affordability_scenarios"

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
        let client = try getClient()
        let startTime = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Affordability scenario save failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteAffordabilityScenario(id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Affordability scenario deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
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
            .eq("id", value: giftId.uuidString.lowercased())
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
        let cacheKey = "budget_dev_scenarios"

        if let cached: [SavedScenario] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            return cached
        }

        let client = try getClient()
        let scenarios: [SavedScenario] = try await client
            .from("budget_development_scenarios")
            .select()
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

        let client = try getClient()

        #if DEBUG
        logger.debug("Fetching budget overview items with spent amounts from Supabase...")
        logger.debug("Using scenario ID: \(scenarioId)")
        #endif

        // Fetch budget items for the scenario
        let items = try await fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        #if DEBUG
        logger.debug("Fetched \(items.count) budget items for scenario")
        #endif

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

        #if DEBUG
        logger.debug("Querying expense_budget_allocations for scenario_id: \(scenarioId)")
        #endif

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
        let query = client
            .from("expense_budget_allocations")
            .select("id, expense_id, budget_item_id, allocated_amount")

        // Apply filter - try both approaches
        #if DEBUG
        logger.debug("Building query with scenario_id filter: \(scenarioId)")
        #endif
        let simpleAllocations: [SimpleAllocation] = try await query
            .eq("scenario_id", value: scenarioId)
            .execute()
            .value

        #if DEBUG
        logger.debug("Fetched \(simpleAllocations.count) allocations for scenario")

        // Debug: Log first few allocations with their amounts
        for allocation in simpleAllocations.prefix(3) {
            logger.debug("  Allocation \(allocation.id): amount=\(allocation.allocatedAmount)")
        }
        #endif

        // If no allocations, return early
        guard !simpleAllocations.isEmpty else {
            #if DEBUG
            logger.debug("No allocations found for scenario \(scenarioId)")
            #endif
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
            await RepositoryCache.shared.set(cacheKey, value: overviewItems)
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

        let expenses: [ExpenseBasic] = try await client
            .from("expenses")
            .select("id, expense_name")
            .in("id", values: expenseIds.map { $0.uuidString })
            .execute()
            .value

        #if DEBUG
        logger.debug("Fetched \(expenses.count) expenses for allocations")
        #endif

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

        #if DEBUG
        logger.debug("Combined \(allocations.count) expense allocations with expense details")
        #endif

        // Group allocations by budget item ID (normalized to lowercase for consistent lookup)
        var allocationsByItem: [String: [ExpenseAllocation]] = [:]
        for allocation in allocations {
            let itemId = allocation.budgetItemId.uuidString.lowercased()
            allocationsByItem[itemId, default: []].append(allocation)
        }

        // Fetch all linked gifts in one query for efficiency
        let linkedGiftIds = items.compactMap { $0.linkedGiftOwedId }
        var giftsById: [String: (id: UUID, title: String, amount: Double)] = [:]
        
        if !linkedGiftIds.isEmpty {
            struct GiftBasic: Codable {
                let id: UUID
                let title: String
                let amount: Double
            }
            
            do {
                let gifts: [GiftBasic] = try await client
                    .from("gifts_and_owed")
                    .select("id, title, amount")
                    .in("id", values: linkedGiftIds)
                    .execute()
                    .value
                
                giftsById = Dictionary(uniqueKeysWithValues: gifts.map { 
                    ($0.id.uuidString.lowercased(), (id: $0.id, title: $0.title, amount: $0.amount))
                })
                
                #if DEBUG
                logger.debug("Fetched \(gifts.count) linked gifts for budget items")
                #endif
            } catch {
                logger.warning("Failed to fetch linked gifts: \(error)")
            }
        }
        
        // Map budget items to overview items with expense and gift data
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

            // Get linked gift if present
            var giftLinks: [GiftLink] = []
            var totalGiftAmount = 0.0
            
            if let linkedGiftId = item.linkedGiftOwedId,
               let gift = giftsById[linkedGiftId.lowercased()] {
                giftLinks.append(GiftLink(
                    id: gift.id.uuidString,
                    title: gift.title,
                    amount: gift.amount
                ))
                totalGiftAmount = gift.amount
            }
            
            // Calculate effective spent (spent minus gifts)
            let effectiveSpent = max(0, totalSpent - totalGiftAmount)

            return BudgetOverviewItem(
                id: item.id,
                itemName: item.itemName,
                category: item.category,
                subcategory: item.subcategory ?? "",
                budgeted: item.vendorEstimateWithTax,
                spent: totalSpent,
                effectiveSpent: effectiveSpent,
                expenses: expenseLinks,
                gifts: giftLinks
            )
        }

        await RepositoryCache.shared.set(cacheKey, value: overviewItems)
        #if DEBUG
        logger.debug("Cached \(overviewItems.count) budget overview items with \(allocations.count) total expense links")

        // Debug: Log items with non-zero spent amounts
        let itemsWithExpenses = overviewItems.filter { $0.spent > 0 }
        logger.debug("Items with expenses: \(itemsWithExpenses.count)")
        for item in itemsWithExpenses.prefix(3) {
            logger.debug("  - \(item.itemName): spent=\(item.spent), expenses=\(item.expenses.count)")
        }
        #endif

        return overviewItems
    }

    func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
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
    }

    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        let client = try getClient()
        let result: SavedScenario = try await client
            .from("budget_development_scenarios")
            .update(scenario)
            .eq("id", value: scenario.id)
            .select()
            .single()
            .execute()
            .value

        await RepositoryCache.shared.remove("budget_dev_scenarios")
        
        // Log important mutation
        logger.info("Updated budget development scenario: \(result.scenarioName)")

        return result
    }

    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
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
    }

    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        let client = try getClient()
        let result: BudgetItem = try await client
            .from("budget_development_items")
            .update(item)
            .eq("id", value: item.id)
            .select()
            .single()
            .execute()
            .value

        if let scenarioId = item.scenarioId {
            await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
        }
        await RepositoryCache.shared.remove("budget_dev_items_all")
        
        // Log important mutation
        logger.info("Updated budget development item: \(result.itemName)")

        return result
    }

    func deleteBudgetDevelopmentItem(id: String) async throws {
        let client = try getClient()
        try await client
            .from("budget_development_items")
            .delete()
            .eq("id", value: id)
            .execute()

        // Invalidate all item caches since we don't know which scenario
        await RepositoryCache.shared.remove("budget_dev_items_all")
        
        // Log important mutation
        logger.info("Deleted budget development item: \(id)")
    }

    // MARK: - Tax Rates

    func fetchTaxRates() async throws -> [TaxInfo] {
        let cacheKey = "tax_rates"

        if let cached: [TaxInfo] = await RepositoryCache.shared.get(cacheKey, maxAge: 3600) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Tax rates fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        let client = try getClient()
        let startTime = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Tax rate creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updateTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo {
        let client = try getClient()
        let startTime = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Tax rate update failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteTaxRate(id: Int64) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Tax rate deletion failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Wedding Events

    func fetchWeddingEvents() async throws -> [WeddingEvent] {
        let cacheKey = "wedding_events"

        if let cached: [WeddingEvent] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        do {
            let events: [WeddingEvent] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("wedding_events")
                    .select()
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
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Wedding events fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
    
    // MARK: - Expense Allocations
    
    func fetchExpenseAllocations(scenarioId: String, budgetItemId: String) async throws -> [ExpenseAllocation] {
        let client = try getClient()
        let startTime = Date()
        
        do {
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
            
            // Only log if slow
            if duration > 1.0 {
                logger.info("Slow expense allocations fetch: \(String(format: "%.2f", duration))s for \(allocations.count) items")
            }
            
            return allocations
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expense allocations fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
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
            
            // Log important mutation
            logger.info("Created expense allocation: \(created.expenseId) -> \(created.budgetItemId)")
            
            // Invalidate related caches
            await RepositoryCache.shared.remove("expenses")
            await RepositoryCache.shared.remove("budget_development_items_\(allocation.scenarioId)")
            
            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expense allocation creation failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
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
}
