//
//  PaymentScheduleDataSource.swift
//  I Do Blueprint
//
//  Internal data source for payment schedule operations
//  Extracted from LiveBudgetRepository for better maintainability
//

import Foundation
import Supabase

/// Internal data source handling all payment schedule CRUD operations
/// This is not exposed publicly - all access goes through BudgetRepositoryProtocol
actor PaymentScheduleDataSource {
    private let supabase: SupabaseClient
    private lazy var cacheStrategy: BudgetCacheStrategy = BudgetCacheStrategy()

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    // MARK: - Fetch Operations

    func fetchPaymentSchedules(tenantId: UUID) async throws -> [PaymentSchedule] {
        let cacheKey = "payment_schedules_\(tenantId.uuidString)"

        if let cached: [PaymentSchedule] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let startTime = Date()

        let schedules: [PaymentSchedule] = try await RepositoryNetwork.withRetry {
            try await self.supabase
                .from("payment_plans")
                .select()
                .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                .order("payment_date", ascending: true)
                .execute()
                .value
        }

        _ = Date().timeIntervalSince(startTime)

        await RepositoryCache.shared.set(cacheKey, value: schedules)

        return schedules
    }

    func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule] {
        let cacheKey = "payment_schedules_vendor_\(vendorId)"

        if let cached: [PaymentSchedule] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let startTime = Date()

        let schedules: [PaymentSchedule] = try await RepositoryNetwork.withRetry {
            try await self.supabase
                .from("payment_plans")
                .select()
                .eq("vendor_id", value: String(vendorId))
                .order("payment_date", ascending: true)
                .execute()
                .value
        }

        _ = Date().timeIntervalSince(startTime)

        await RepositoryCache.shared.set(cacheKey, value: schedules)

        return schedules
    }

    // MARK: - Create Operations

    func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        do {
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
                let paymentPlanId: UUID?
                let segmentIndex: Int?  // For async plans: 0-based index of the segment
                let createdAt: Date
                let updatedAt: Date?
                // Partial payment tracking fields
                let originalAmount: Double
                let amountPaid: Double
                let carryoverAmount: Double
                let carryoverFromId: Int64?
                let isCarryover: Bool
                let paymentRecordedAt: Date?

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
                    case paymentPlanId = "payment_plan_id"
                    case segmentIndex = "segment_index"
                    case createdAt = "created_at"
                    case updatedAt = "updated_at"
                    // Partial payment tracking fields
                    case originalAmount = "original_amount"
                    case amountPaid = "amount_paid"
                    case carryoverAmount = "carryover_amount"
                    case carryoverFromId = "carryover_from_id"
                    case isCarryover = "is_carryover"
                    case paymentRecordedAt = "payment_recorded_at"
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
                paymentPlanId: schedule.paymentPlanId,
                segmentIndex: schedule.segmentIndex,
                createdAt: schedule.createdAt,
                updatedAt: schedule.updatedAt,
                // Partial payment tracking fields
                originalAmount: schedule.originalAmount,
                amountPaid: schedule.amountPaid,
                carryoverAmount: schedule.carryoverAmount,
                carryoverFromId: schedule.carryoverFromId,
                isCarryover: schedule.isCarryover,
                paymentRecordedAt: schedule.paymentRecordedAt
            )

            // NOTE: Insert wrapped in retry has small risk of duplicate creation on network timeout
            // This is acceptable as database constraints will prevent true duplicates
            let created: PaymentSchedule = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("payment_plans")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            _ = Date().timeIntervalSince(startTime)

            // Invalidate cache with tenant ID
            await RepositoryCache.shared.remove("payment_schedules_\(schedule.coupleId.uuidString)")

            return created
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "createPaymentSchedule",
                "dataSource": "PaymentScheduleDataSource"
            ])
            throw BudgetError.createFailed(underlying: error)
        }
    }

    // MARK: - Update Operations

    func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule {
        do {
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
                let segmentIndex: Int?
                let updatedAt: Date
                // Partial payment tracking fields
                let originalAmount: Double
                let amountPaid: Double
                let carryoverAmount: Double
                let carryoverFromId: Int64?
                let isCarryover: Bool
                let paymentRecordedAt: Date?

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
                    case segmentIndex = "segment_index"
                    case updatedAt = "updated_at"
                    // Partial payment tracking fields
                    case originalAmount = "original_amount"
                    case amountPaid = "amount_paid"
                    case carryoverAmount = "carryover_amount"
                    case carryoverFromId = "carryover_from_id"
                    case isCarryover = "is_carryover"
                    case paymentRecordedAt = "payment_recorded_at"
                }
            }

            // Validate and normalize paymentType to ensure it matches the check constraint
            // Valid types: 'individual', 'monthly', 'interval', 'cyclical', 'deposit', 'retainer', 'async'
            let validPaymentType: String?
            if let type = schedule.paymentType {
                let normalized = type.lowercased()
                if ["individual", "monthly", "interval", "cyclical", "deposit", "retainer", "async"].contains(normalized) {
                    validPaymentType = normalized
                } else {
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
                segmentIndex: schedule.segmentIndex,
                updatedAt: Date(),
                // Partial payment tracking fields
                originalAmount: schedule.originalAmount,
                amountPaid: schedule.amountPaid,
                carryoverAmount: schedule.carryoverAmount,
                carryoverFromId: schedule.carryoverFromId,
                isCarryover: schedule.isCarryover,
                paymentRecordedAt: schedule.paymentRecordedAt
            )

            let result: PaymentSchedule = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("payment_plans")
                    .update(updateData)
                    .eq("id", value: String(schedule.id))
                    .select()
                    .single()
                    .execute()
                    .value
            }

            _ = Date().timeIntervalSince(startTime)

            // Invalidate cache with tenant ID
            await RepositoryCache.shared.remove("payment_schedules_\(schedule.coupleId.uuidString)")

            return result
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "updatePaymentSchedule",
                "dataSource": "PaymentScheduleDataSource",
                "scheduleId": String(schedule.id)
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    // MARK: - Delete Operations

    func deletePaymentSchedule(id: Int64) async throws {
        do {
            let startTime = Date()

            // Fetch the schedule first to get couple_id for proper cache invalidation
            let schedules: [PaymentSchedule] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("payment_plans")
                    .select()
                    .eq("id", value: String(id))
                    .limit(1)
                    .execute()
                    .value
            }
            let schedule = schedules.first

            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("payment_plans")
                    .delete()
                    .eq("id", value: String(id))
                    .execute()
            }

            _ = Date().timeIntervalSince(startTime)

            // Invalidate cache with tenant ID
            if let schedule = schedule {
                await RepositoryCache.shared.remove("payment_schedules_\(schedule.coupleId.uuidString)")
            }
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "deletePaymentSchedule",
                "dataSource": "PaymentScheduleDataSource",
                "scheduleId": String(id)
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    /// Batch deletes multiple payment schedules
    /// - Parameter ids: Array of payment schedule IDs to delete
    /// - Returns: Number of successfully deleted schedules
    func batchDeletePaymentSchedules(ids: [Int64]) async throws -> Int {
        guard !ids.isEmpty else { return 0 }

        do {
            let startTime = Date()

            // Fetch schedules first to get couple_id for cache invalidation
            let schedules: [PaymentSchedule] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("payment_plans")
                    .select()
                    .in("id", values: ids.map { String($0) })
                    .execute()
                    .value
            }

            // Get unique couple IDs for cache invalidation
            let coupleIds = Set(schedules.map { $0.coupleId })

            // Delete all schedules in a single query
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("payment_plans")
                    .delete()
                    .in("id", values: ids.map { String($0) })
                    .execute()
            }

            _ = Date().timeIntervalSince(startTime)

            // Invalidate cache for all affected tenants
            for coupleId in coupleIds {
                await RepositoryCache.shared.remove("payment_schedules_\(coupleId.uuidString)")
            }

            return schedules.count
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "batchDeletePaymentSchedules",
                "dataSource": "PaymentScheduleDataSource",
                "count": ids.count
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
}