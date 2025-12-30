//
//  ExpenseDataSource.swift
//  I Do Blueprint
//
//  Internal data source for expense operations
//  Extracted from LiveBudgetRepository for better maintainability
//

import Foundation
import Supabase

/// Internal data source handling all expense CRUD operations
/// This is not exposed publicly - all access goes through BudgetRepositoryProtocol
actor ExpenseDataSource {
    private let supabase: SupabaseClient
    private nonisolated let logger = AppLogger.repository
    private let cacheStrategy: BudgetCacheStrategy
    
    // In-flight request de-duplication per tenant
    private var inFlightExpenses: [UUID: Task<[Expense], Error>] = [:]
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        self.cacheStrategy = BudgetCacheStrategy()
    }
    
    // MARK: - Fetch Operations
    
    func fetchExpenses(tenantId: UUID) async throws -> [Expense] {
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
            let startTime = Date()
            do {
                // Fetch expenses without join first
                let expenses: [Expense] = try await RepositoryNetwork.withRetry {
                    try await self.supabase
                        .from("expenses")
                        .select()
                        .eq("couple_id", value: tenantId)
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
                        try await self.supabase
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
    
    func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense] {
        let cacheKey = "expenses_vendor_\(vendorId)"
        
        // Check cache first (30 sec TTL for very fresh data)
        if let cached: [Expense] = await RepositoryCache.shared.get(cacheKey, maxAge: 30) {
            return cached
        }
        
        let startTime = Date()
        
        do {
            let expenses: [Expense] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
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
    
    // MARK: - Create Operations
    
    func createExpense(_ expense: Expense, tenantId: UUID) async throws -> Expense {
        do {
            let startTime = Date()
            
            let created: Expense = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("expenses")
                    .insert(expense)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created expense: \(created.expenseName) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .expenseCreated(tenantId: tenantId))
            
            return created
        } catch {
            logger.error("Failed to create expense", error: error)
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    // MARK: - Update Operations
    
    func updateExpense(_ expense: Expense, tenantId: UUID) async throws -> Expense {
        do {
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
            
            let result: Expense = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("expenses")
                    .update(updateData)
                    .eq("id", value: expense.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated expense: \(result.expenseName) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .expenseUpdated(tenantId: tenantId))
            
            return result
        } catch {
            logger.error("Failed to update expense", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Fetches the previous state of an expense for potential rollback
    func fetchPreviousExpense(id: UUID) async throws -> Expense? {
        let expenses: [Expense] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("expenses")
                .select()
                .eq("id", value: id)
                .limit(1)
                .execute()
                .value
        }
        return expenses.first
    }
    
    /// Rolls back an expense to its previous state
    func rollbackExpense(_ expense: Expense) async throws {
        do {
            // Create rollback update excluding computed fields like vendorName
            struct ExpenseRollback: Codable {
                let expenseName: String
                let amount: Double
                let categoryId: UUID?
                let vendorId: Int64?
                let paid: Bool
                let notes: String?
                let expenseDate: Date?
                let updatedAt: Date

                enum CodingKeys: String, CodingKey {
                    case expenseName = "expense_name"
                    case amount
                    case categoryId = "category_id"
                    case vendorId = "vendor_id"
                    case paid
                    case notes
                    case expenseDate = "expense_date"
                    case updatedAt = "updated_at"
                }
            }

            let rollbackData = ExpenseRollback(
                expenseName: expense.expenseName,
                amount: expense.amount,
                categoryId: expense.categoryId,
                vendorId: expense.vendorId,
                paid: expense.paymentStatus == .paid,
                notes: expense.notes,
                expenseDate: expense.expenseDate,
                updatedAt: Date()
            )

            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("expenses")
                    .update(rollbackData)
                    .eq("id", value: expense.id)
                    .execute()
            }
            logger.info("Rolled back expense: \(expense.id)")

            // Invalidate cache after rollback
            await RepositoryCache.shared.remove("expenses_\(expense.coupleId.uuidString)")
        } catch {
            logger.error("Failed to rollback expense", error: error)
            throw error
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteExpense(id: UUID, tenantId: UUID) async throws {
        do {
            let startTime = Date()
            
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("expenses")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted expense: \(id) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .expenseDeleted(tenantId: tenantId))
        } catch {
            logger.error("Failed to delete expense", error: error)
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
}
