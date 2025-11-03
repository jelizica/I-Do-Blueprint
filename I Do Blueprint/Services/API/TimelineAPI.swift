//
//  TimelineAPI.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Foundation
import Supabase

class TimelineAPI {
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

    // MARK: - Fetch Timeline Items

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
        struct PaymentRow: Codable {
            let id: Int
            let vendor: String?
            let paymentDate: String?
            let paymentAmount: Double?
            let paid: Bool?
            let notes: String?
            let vendorType: String?
            let coupleId: String?
            let createdAt: String?

            enum CodingKeys: String, CodingKey {
                case id = "id"
                case vendor = "vendor"
                case notes = "notes"
                case paymentDate = "payment_date"
                case paymentAmount = "payment_amount"
                case paid = "paid"
                case vendorType = "vendor_type"
                case coupleId = "couple_id"
                case createdAt = "created_at"
            }
        }

        do {
            let client = try getClient()
            let rows: [PaymentRow] = try await RepositoryNetwork.withRetry {
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

            let items = rows.compactMap { row -> TimelineItem? in
                // Skip if missing required fields
                guard let paymentDateString = row.paymentDate,
                      let date = dateFromString(paymentDateString),
                      let amount = row.paymentAmount else {
                    return nil
                }

                // Use a default couple_id if not present
                let coupleId = row.coupleId.flatMap { UUID(uuidString: $0) } ?? UUID()
                let createdAt = row.createdAt.flatMap { iso8601DateFromString($0) } ?? Date()

                let title = "\(row.vendor ?? "Payment") - $\(String(format: "%.2f", amount))"
                logger.debug("Payment: \(title) on \(paymentDateString)")

                return TimelineItem(
                    id: UUID(),
                    coupleId: coupleId,
                    title: title,
                    description: row.notes,
                    itemType: .payment,
                    itemDate: date,
                    endDate: nil,
                    completed: row.paid ?? false,
                    relatedId: String(row.id),
                    createdAt: createdAt,
                    updatedAt: createdAt,
                    task: nil,
                    milestone: nil,
                    vendor: nil,
                    payment: nil
                )
            }

            logger.debug("Converted \(items.count) payment items")
            return items
        } catch {
            logger.error("Error fetching payments", error: error)
            throw error
        }

    }

    // Helper functions for date parsing
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func iso8601DateFromString(_ dateString: String) -> Date? {
        // Try ISO8601DateFormatter first
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Fallback to DateFormatter for Postgres timestamp format
        let postgresFormatter = DateFormatter()
        postgresFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
        if let date = postgresFormatter.date(from: dateString) {
            return date
        }

        // Another fallback without fractional seconds
        postgresFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        return postgresFormatter.date(from: dateString)
    }

    private func fetchExpenseTimelineItems() async throws -> [TimelineItem] {
        let startTime = Date()

        struct ExpenseRow: Codable {
            let id: String
            let expenseName: String
            let amount: Double
            let expenseDate: String?
            let paymentStatus: String?
            let notes: String?
            let coupleId: String?
            let createdAt: String?
            let updatedAt: String?

            enum CodingKeys: String, CodingKey {
                case id = "id"
                case expenseName = "expense_name"
                case amount = "amount"
                case expenseDate = "expense_date"
                case paymentStatus = "payment_status"
                case notes = "notes"
                case coupleId = "couple_id"
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }

        do {
            let client = try getClient()
            let rows: [ExpenseRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("expenses")
                    .select()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(rows.count) expense rows in \(String(format: "%.2f", duration))s")

            let items = rows.compactMap { row -> TimelineItem? in
                guard let id = UUID(uuidString: row.id),
                      let expenseDateString = row.expenseDate,
                      let date = dateFromString(expenseDateString) else {
                    return nil
                }

                let coupleId = row.coupleId.flatMap { UUID(uuidString: $0) } ?? UUID()
                let createdAt = row.createdAt.flatMap { iso8601DateFromString($0) } ?? Date()
                let updatedAt = row.updatedAt.flatMap { iso8601DateFromString($0) } ?? Date()

                let title = "\(row.expenseName) - $\(String(format: "%.2f", row.amount))"
                let completed = row.paymentStatus?.lowercased() == "paid"
                logger.debug("Expense: \(title) on \(expenseDateString)")

                return TimelineItem(
                    id: id,
                    coupleId: coupleId,
                    title: title,
                    description: row.notes,
                    itemType: .payment,
                    itemDate: date,
                    endDate: nil,
                    completed: completed,
                    relatedId: row.id,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    task: nil,
                    milestone: nil,
                    vendor: nil,
                    payment: nil
                )
            }

            logger.debug("Converted \(items.count) expense items")
            return items
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Error fetching expenses after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    private func fetchVendorTimelineItems() async throws -> [TimelineItem] {
        let startTime = Date()

        struct VendorRow: Codable {
            let id: Int
            let vendorName: String
            let vendorType: String?
            let isBooked: Bool
            let dateBooked: String?
            let coupleId: String?
            let createdAt: String
            let updatedAt: String

            enum CodingKeys: String, CodingKey {
                case id = "id"
                case vendorName = "vendor_name"
                case vendorType = "vendor_type"
                case isBooked = "is_booked"
                case dateBooked = "date_booked"
                case coupleId = "couple_id"
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }

        do {
            let client = try getClient()
            let rows: [VendorRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("vendor_information")
                    .select()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(rows.count) vendor rows in \(String(format: "%.2f", duration))s")

            let items = rows.compactMap { row -> TimelineItem? in
                // Only include vendors that have a dateBooked
                guard let dateBookedString = row.dateBooked,
                      let dateBooked = iso8601DateFromString(dateBookedString) else {
                    return nil
                }

                let coupleId = row.coupleId.flatMap { UUID(uuidString: $0) } ?? UUID()
                let createdAt = iso8601DateFromString(row.createdAt) ?? Date()
                let updatedAt = iso8601DateFromString(row.updatedAt) ?? Date()

                let title = "Vendor: \(row.vendorName)"
                logger.debug("Vendor: \(title) booked on \(dateBookedString)")

                return TimelineItem(
                    id: UUID(),
                    coupleId: coupleId,
                    title: title,
                    description: row.vendorType,
                    itemType: .vendorEvent,
                    itemDate: dateBooked,
                    endDate: nil,
                    completed: row.isBooked,
                    relatedId: String(row.id),
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    task: nil,
                    milestone: nil,
                    vendor: nil,
                    payment: nil
                )
            }

            logger.debug("Converted \(items.count) vendor items")
            return items
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Error fetching vendors after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    private func fetchGuestTimelineItems() async throws -> [TimelineItem] {
        let startTime = Date()

        struct GuestRow: Codable {
            let id: String
            let firstName: String
            let lastName: String
            let rsvpStatus: String?
            let rsvpDate: String?
            let coupleId: String
            let createdAt: String
            let updatedAt: String

            enum CodingKeys: String, CodingKey {
                case id = "id"
                case firstName = "first_name"
                case lastName = "last_name"
                case rsvpStatus = "rsvp_status"
                case rsvpDate = "rsvp_date"
                case coupleId = "couple_id"
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }

        do {
            let client = try getClient()
            let rows: [GuestRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .select()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(rows.count) guest rows in \(String(format: "%.2f", duration))s")

            let items = rows.compactMap { row -> TimelineItem? in
                // Only include guests who have RSVPed
                guard let rsvpDateString = row.rsvpDate,
                      let rsvpDate = dateFromString(rsvpDateString),
                      let id = UUID(uuidString: row.id),
                      let coupleId = UUID(uuidString: row.coupleId),
                      let createdAt = iso8601DateFromString(row.createdAt),
                      let updatedAt = iso8601DateFromString(row.updatedAt),
                      let rsvpStatus = row.rsvpStatus else {
                    return nil
                }

                let title = "RSVP: \(row.firstName) \(row.lastName)"
                let completed = rsvpStatus.lowercased() == "accepted"
                logger.debug("Guest: \(title) - \(rsvpStatus)")

                return TimelineItem(
                    id: id,
                    coupleId: coupleId,
                    title: title,
                    description: "RSVP Status: \(rsvpStatus)",
                    itemType: .reminder,
                    itemDate: rsvpDate,
                    endDate: nil,
                    completed: completed,
                    relatedId: row.id,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    task: nil,
                    milestone: nil,
                    vendor: nil,
                    payment: nil
                )
            }

            logger.debug("Converted \(items.count) guest items")
            return items
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Error fetching guests after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func fetchTimelineItemById(_ id: UUID) async throws -> TimelineItem {
        let client = try getClient()
        let response: TimelineItem = try await client
            .from("timeline_items")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Create Timeline Item

    func createTimelineItem(_ data: TimelineItemInsertData) async throws -> TimelineItem {
        struct TimelineItemInsert: Encodable {
            let coupleId: String
            let title: String
            let itemType: String
            let itemDate: String
            let completed: Bool
            let relatedId: String?
            let description: String?

            enum CodingKeys: String, CodingKey {
                case coupleId = "couple_id"
                case title = "title"
                case itemType = "item_type"
                case itemDate = "item_date"
                case completed = "completed"
                case relatedId = "related_id"
                case description = "description"
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let insertData = TimelineItemInsert(
            coupleId: data.coupleId.uuidString,
            title: data.title,
            itemType: data.itemType.rawValue,
            itemDate: dateFormatter.string(from: data.itemDate),
            completed: data.completed,
            relatedId: data.relatedId,
            description: data.description)

        let client = try getClient()
        let response: TimelineItem = try await client
            .from("timeline_items")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Update Timeline Item

    func updateTimelineItem(_ id: UUID, data: TimelineItemInsertData) async throws -> TimelineItem {
        struct TimelineItemUpdate: Encodable {
            let title: String
            let itemType: String
            let itemDate: String
            let completed: Bool
            let relatedId: String?
            let description: String?

            enum CodingKeys: String, CodingKey {
                case title = "title"
                case itemType = "item_type"
                case itemDate = "item_date"
                case completed = "completed"
                case relatedId = "related_id"
                case description = "description"
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let updateData = TimelineItemUpdate(
            title: data.title,
            itemType: data.itemType.rawValue,
            itemDate: dateFormatter.string(from: data.itemDate),
            completed: data.completed,
            relatedId: data.relatedId,
            description: data.description)

        let client = try getClient()
        let response: TimelineItem = try await client
            .from("timeline_items")
            .update(updateData)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func updateTimelineItemCompletion(_ id: UUID, completed: Bool) async throws -> TimelineItem {
        let client = try getClient()
        let response: TimelineItem = try await client
            .from("timeline_items")
            .update(["completed": completed])
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Delete Timeline Item

    func deleteTimelineItem(_ id: UUID) async throws {
        let client = try getClient()
        try await client
            .from("timeline_items")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Milestones

    func fetchMilestones() async throws -> [Milestone] {
        let client = try getClient()
        let response: [Milestone] = try await client
            .from("milestones")
            .select()
            .order("milestone_date", ascending: true)
            .execute()
            .value

        return response
    }

    func fetchMilestoneById(_ id: UUID) async throws -> Milestone {
        let client = try getClient()
        let response: Milestone = try await client
            .from("milestones")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return response
    }

    func createMilestone(_ data: MilestoneInsertData) async throws -> Milestone {
        struct MilestoneInsert: Encodable {
            let coupleId: String
            let milestoneName: String
            let milestoneDate: String
            let completed: Bool
            let description: String?
            let color: String?

            enum CodingKeys: String, CodingKey {
                case coupleId = "couple_id"
                case milestoneName = "milestone_name"
                case milestoneDate = "milestone_date"
                case completed = "completed"
                case description = "description"
                case color = "color"
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let insertData = MilestoneInsert(
            coupleId: data.coupleId.uuidString,
            milestoneName: data.milestoneName,
            milestoneDate: dateFormatter.string(from: data.milestoneDate),
            completed: data.completed,
            description: data.description,
            color: data.color)

        let client = try getClient()
        let response: Milestone = try await client
            .from("milestones")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func updateMilestone(_ id: UUID, data: MilestoneInsertData) async throws -> Milestone {
        struct MilestoneUpdate: Encodable {
            let milestoneName: String
            let milestoneDate: String
            let completed: Bool
            let description: String?
            let color: String?

            enum CodingKeys: String, CodingKey {
                case milestoneName = "milestone_name"
                case milestoneDate = "milestone_date"
                case completed = "completed"
                case description = "description"
                case color = "color"
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let updateData = MilestoneUpdate(
            milestoneName: data.milestoneName,
            milestoneDate: dateFormatter.string(from: data.milestoneDate),
            completed: data.completed,
            description: data.description,
            color: data.color)

        let client = try getClient()
        let response: Milestone = try await client
            .from("milestones")
            .update(updateData)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func updateMilestoneCompletion(_ id: UUID, completed: Bool) async throws -> Milestone {
        let client = try getClient()
        let response: Milestone = try await client
            .from("milestones")
            .update(["completed": completed])
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func deleteMilestone(_ id: UUID) async throws {
        let client = try getClient()
        try await client
            .from("milestones")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
