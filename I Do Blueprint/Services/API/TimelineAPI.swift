//
//  TimelineAPI.swift
//  I Do Blueprint
//
//  Coordinator for timeline data fetching and aggregation
//

import Foundation
import Supabase

/// Coordinator for timeline data fetching and aggregation
/// Delegates to specialized services for data transformation and CRUD operations
class TimelineAPI {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.api
    
    private let timelineItemService: TimelineItemService
    private let milestoneService: MilestoneService
    
    init(supabase: SupabaseClient? = SupabaseManager.shared.client) {
        self.supabase = supabase
        self.timelineItemService = TimelineItemService(supabase: supabase)
        self.milestoneService = MilestoneService(supabase: supabase)
    }
    
    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }
    
    // MARK: - Fetch Timeline Items (Aggregated)
    
    func fetchTimelineItems() async throws -> [TimelineItem] {
        logger.debug("Starting to fetch timeline items from all sources...")
        let startTime = Date()
        
        do {
            // Fetch all data sources in parallel
            async let paymentsTask = fetchPaymentTimelineItems()
            async let vendorsTask = fetchVendorTimelineItems()
            async let guestsTask = fetchGuestTimelineItems()
            
            let (payments, vendors, guests) = try await (paymentsTask, vendorsTask, guestsTask)
            
            logger.debug("Fetched counts - Payments: \(payments.count), Vendors: \(vendors.count), Guests: \(guests.count)")
            
            // Combine all items and sort by date
            var allItems = payments + vendors + guests
            allItems.sort { $0.itemDate < $1.itemDate }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(allItems.count) timeline items in \(String(format: "%.2f", duration))s")
            
            return allItems
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Timeline items fetch failed after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
    
    // MARK: - Fetch from Individual Tables
    
    private func fetchPaymentTimelineItems() async throws -> [TimelineItem] {
        do {
            let client = try getClient()
            let rows: [TimelineDataTransformer.PaymentRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("payment_plans")
                    .select()
                    .execute()
                    .value
            }
            
            logger.debug("Found \(rows.count) payment rows")
            if rows.isEmpty {
                logger.debug("No payments found in database")
            }
            
            return TimelineDataTransformer.transformPayments(rows)
        } catch {
            logger.error("Error fetching payments", error: error)
            throw error
        }
    }
    
    private func fetchExpenseTimelineItems() async throws -> [TimelineItem] {
        let startTime = Date()
        
        do {
            let client = try getClient()
            let rows: [TimelineDataTransformer.ExpenseRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .select()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(rows.count) expense rows in \(String(format: "%.2f", duration))s")
            
            return TimelineDataTransformer.transformExpenses(rows)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Error fetching expenses after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
    
    private func fetchVendorTimelineItems() async throws -> [TimelineItem] {
        let startTime = Date()
        
        do {
            let client = try getClient()
            let rows: [TimelineDataTransformer.VendorRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_information")
                    .select()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(rows.count) vendor rows in \(String(format: "%.2f", duration))s")
            
            return TimelineDataTransformer.transformVendors(rows)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Error fetching vendors after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
    
    private func fetchGuestTimelineItems() async throws -> [TimelineItem] {
        let startTime = Date()
        
        do {
            let client = try getClient()
            let rows: [TimelineDataTransformer.GuestRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .select()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(rows.count) guest rows in \(String(format: "%.2f", duration))s")
            
            return TimelineDataTransformer.transformGuests(rows)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Error fetching guests after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }
    
    // MARK: - Timeline Item CRUD (Delegated)
    
    func fetchTimelineItemById(_ id: UUID) async throws -> TimelineItem {
        try await timelineItemService.fetchTimelineItemById(id)
    }
    
    func createTimelineItem(_ data: TimelineItemInsertData) async throws -> TimelineItem {
        try await timelineItemService.createTimelineItem(data)
    }
    
    func updateTimelineItem(_ id: UUID, data: TimelineItemInsertData) async throws -> TimelineItem {
        try await timelineItemService.updateTimelineItem(id, data: data)
    }
    
    func updateTimelineItemCompletion(_ id: UUID, completed: Bool) async throws -> TimelineItem {
        try await timelineItemService.updateTimelineItemCompletion(id, completed: completed)
    }
    
    func deleteTimelineItem(_ id: UUID) async throws {
        try await timelineItemService.deleteTimelineItem(id)
    }
    
    // MARK: - Milestone CRUD (Delegated)
    
    func fetchMilestones() async throws -> [Milestone] {
        try await milestoneService.fetchMilestones()
    }
    
    func fetchMilestoneById(_ id: UUID) async throws -> Milestone {
        try await milestoneService.fetchMilestoneById(id)
    }
    
    func createMilestone(_ data: MilestoneInsertData) async throws -> Milestone {
        try await milestoneService.createMilestone(data)
    }
    
    func updateMilestone(_ id: UUID, data: MilestoneInsertData) async throws -> Milestone {
        try await milestoneService.updateMilestone(id, data: data)
    }
    
    func updateMilestoneCompletion(_ id: UUID, completed: Bool) async throws -> Milestone {
        try await milestoneService.updateMilestoneCompletion(id, completed: completed)
    }
    
    func deleteMilestone(_ id: UUID) async throws {
        try await milestoneService.deleteMilestone(id)
    }
}
