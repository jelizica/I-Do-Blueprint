//
//  DocumentRelatedEntitiesService.swift
//  I Do Blueprint
//
//  Fetch related entities (vendors, expenses, payments)
//

import Foundation
import Supabase

/// Service for fetching entities related to documents
class DocumentRelatedEntitiesService {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.api
    
    init(supabase: SupabaseClient? = SupabaseManager.shared.client) {
        self.supabase = supabase
    }
    
    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }
    
    // MARK: - Vendors
    
    func fetchVendors() async throws -> [(id: Int, name: String)] {
        struct VendorResult: Decodable {
            let id: Int64
            let vendorName: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case vendorName = "vendor_name"
            }
        }
        
        let client = try getClient()
        let startTime = Date()
        
        do {
            let vendors: [VendorResult] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_information")
                    .select("id, vendor_name")
                    .order("vendor_name", ascending: true)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(vendors.count) vendors in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchVendors", outcome: .success, duration: duration)
            
            return vendors.map { (id: Int($0.id), name: $0.vendorName) }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Vendors fetch failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchVendors", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    // MARK: - Expenses
    
    func fetchExpenses() async throws -> [(id: UUID, description: String)] {
        struct ExpenseResult: Decodable {
            let id: UUID
            let expenseName: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case expenseName = "expense_name"
            }
        }
        
        let client = try getClient()
        let startTime = Date()
        
        do {
            let expenses: [ExpenseResult] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .select("id, expense_name")
                    .order("expense_name", ascending: true)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(expenses.count) expenses in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchExpenses", outcome: .success, duration: duration)
            
            return expenses.map { (id: $0.id, description: $0.expenseName) }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expenses fetch failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchExpenses", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    // MARK: - Payments
    
    func fetchPayments(forExpenseId expenseId: UUID? = nil) async throws -> [(id: Int64, description: String)] {
        struct PaymentResult: Decodable {
            let id: Int64
            let vendor: String
            let paymentAmount: Double
            let paymentDate: String
            let paid: Bool
            let expenseId: UUID?
            
            enum CodingKeys: String, CodingKey {
                case id
                case vendor
                case paymentAmount = "payment_amount"
                case paymentDate = "payment_date"
                case paid
                case expenseId = "expense_id"
            }
        }
        
        let startTime = Date()
        
        do {
            let client = try getClient()
            var query = client
                .from("payment_plan_details_with_expenses")
                .select("id, vendor, payment_amount, payment_date, paid, expense_id")
            
            if let expenseId {
                query = query.eq("expense_id", value: expenseId)
            }
            
            let payments: [PaymentResult] = try await RepositoryNetwork.withRetry {
                try await query
                    .order("payment_date", ascending: true)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(payments.count) payments in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchPayments", outcome: .success, duration: duration)
            
            return payments.map {
                let formattedAmount = String(format: "$%.2f", $0.paymentAmount)
                let status = $0.paid ? "✓" : "○"
                return (id: $0.id, description: "\($0.vendor) - \(formattedAmount) (\($0.paymentDate)) \(status)")
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payments fetch failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchPayments", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
}
