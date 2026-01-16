//
//  PaymentScheduleStore.swift
//  I Do Blueprint
//
//  Extracted from BudgetStoreV2 as part of JES-42
//  Manages payment schedule operations
//

import Combine
import Dependencies
import Foundation
import SwiftUI

// MARK: - Dependency for expense status recalculation/notification

private protocol PaymentScheduleChangeNotifying: Sendable {
    func notifyPaymentScheduleChanged(expenseId: UUID) async throws
}

private enum PaymentScheduleChangeNotifierKey: DependencyKey {
    static let liveValue: any PaymentScheduleChangeNotifying = DefaultPaymentScheduleChangeNotifier()
    static let testValue: any PaymentScheduleChangeNotifying = NoOpPaymentScheduleChangeNotifier()
}

extension DependencyValues {
    fileprivate var paymentScheduleChangeNotifier: any PaymentScheduleChangeNotifying {
        get { self[PaymentScheduleChangeNotifierKey.self] }
        set { self[PaymentScheduleChangeNotifierKey.self] = newValue }
    }
}

/// Default implementation that uses AppStores to update expense payment status
private struct DefaultPaymentScheduleChangeNotifier: PaymentScheduleChangeNotifying {
    private let logger = AppLogger.database

    func notifyPaymentScheduleChanged(expenseId: UUID) async throws {
        await AppStores.shared.budget.updateExpensePaymentStatus(expenseId: expenseId)
        logger.info("Notified budget store to update payment status for expense: \(expenseId)")
    }
}

/// No-op implementation for tests
private struct NoOpPaymentScheduleChangeNotifier: PaymentScheduleChangeNotifying {
    func notifyPaymentScheduleChanged(expenseId: UUID) async throws {
        // No-op for tests
    }
}

// MARK: - PaymentScheduleStore

/// Store for managing payment schedules
/// Handles CRUD operations for payment schedules with optimistic updates
@MainActor
class PaymentScheduleStore: ObservableObject {

    // MARK: - Published State

    @Published private(set) var paymentSchedules: [PaymentSchedule] = []
    @Published private(set) var paymentPlanSummaries: [PaymentPlanSummary] = []
    @Published var showPlanView: Bool = false
    @Published var isLoading = false
    @Published var error: BudgetError?

    // MARK: - Dependencies

    @Dependency(\.budgetRepository) var repository
    @Dependency(\.paymentScheduleChangeNotifier) private var notifier
    private let logger = AppLogger.database
    private let groupingService = PaymentGroupingService()

    // MARK: - Computed Properties

    /// Get pending payment schedules
    var pendingPayments: [PaymentSchedule] {
        paymentSchedules.filter { !$0.paid }
    }

    /// Get paid payment schedules
    var paidPayments: [PaymentSchedule] {
        paymentSchedules.filter { $0.paid }
    }

    /// Total amount of pending payments
    var totalPending: Double {
        pendingPayments.reduce(0) { $0 + $1.paymentAmount }
    }

    /// Total amount of paid payments
    var totalPaid: Double {
        paidPayments.reduce(0) { $0 + $1.paymentAmount }
    }

    /// Total amount of all payments
    var totalAmount: Double {
        paymentSchedules.reduce(0) { $0 + $1.paymentAmount }
    }

    /// Get upcoming payments (not paid and due within 30 days)
    var upcomingPayments: [PaymentSchedule] {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return paymentSchedules.filter { schedule in
            !schedule.paid && schedule.paymentDate <= thirtyDaysFromNow
        }
    }

    // MARK: - Public Methods

    /// Load all payment schedules
    func loadPaymentSchedules() async {
        do {
            paymentSchedules = try await repository.fetchPaymentSchedules()
            logger.info("Loaded \(paymentSchedules.count) payment schedules")
        } catch {
            await handleError(error, operation: "loadPaymentSchedules")
            self.error = .fetchFailed(underlying: error)
        }
    }

    /// Load payment plan summaries
    func loadPaymentPlanSummaries() async {
        isLoading = true
        error = nil
        
        do {
            paymentPlanSummaries = try await repository.fetchPaymentPlanSummaries()
            logger.info("Loaded \(paymentPlanSummaries.count) payment plan summaries")
        } catch {
            await handleError(error, operation: "loadPaymentPlanSummaries")
            self.error = .fetchFailed(underlying: error)
        }
        
        isLoading = false
    }

    /// Load a specific payment plan summary by expense ID
    func loadPaymentPlanSummary(expenseId: UUID) async -> PaymentPlanSummary? {
        do {
            let summary = try await repository.fetchPaymentPlanSummary(expenseId: expenseId)
            if let summary {
                logger.info("Loaded payment plan summary for expense: \(expenseId)")
            } else {
                logger.info("No payment plan summary found for expense: \(expenseId)")
            }
            return summary
        } catch {
            await handleError(error, operation: "loadPaymentPlanSummary", context: [
                "expenseId": expenseId.uuidString
            ])
            self.error = .fetchFailed(underlying: error)
            return nil
        }
    }

    /// Add a new payment schedule
    func addPayment(_ schedule: PaymentSchedule) async {
        isLoading = true
        error = nil

        do {
            let created = try await repository.createPaymentSchedule(schedule)
            paymentSchedules.append(created)
            logger.info("Added payment schedule with ID: \(created.id)")

            await loadPaymentSchedules()
            
            if let expenseId = created.expenseId {
                do {
                    try await notifier.notifyPaymentScheduleChanged(expenseId: expenseId)
                } catch {
                    await handleError(error, operation: "notifyPaymentScheduleChanged", context: [
                        "expenseId": expenseId.uuidString,
                        "action": "create"
                    ])
                    await loadPaymentSchedules()
                    self.error = .updateFailed(underlying: error)
                }
            }
        } catch {
            await handleError(error, operation: "addPayment") { [weak self] in
                await self?.addPayment(schedule)
            }
            self.error = .createFailed(underlying: error)
        }

        isLoading = false
    }

    /// Update an existing payment schedule
    func updatePayment(_ schedule: PaymentSchedule) async {
        guard let index = paymentSchedules.firstIndex(where: { $0.id == schedule.id }) else {
            return
        }

        let previousSchedule = paymentSchedules[index]
        paymentSchedules[index] = schedule

        do {
            let updated = try await repository.updatePaymentSchedule(schedule)
            paymentSchedules[index] = updated
            logger.info("Updated payment schedule in database")
            
            if let expenseId = updated.expenseId {
                do {
                    try await notifier.notifyPaymentScheduleChanged(expenseId: expenseId)
                } catch {
                    await handleError(error, operation: "notifyPaymentScheduleChanged", context: [
                        "expenseId": expenseId.uuidString,
                        "action": "update"
                    ])
                    do {
                        _ = try await repository.updatePaymentSchedule(previousSchedule)
                        paymentSchedules[index] = previousSchedule
                    } catch {
                        await handleError(error, operation: "rollbackPaymentSchedule", context: [
                            "scheduleId": String(schedule.id)
                        ])
                        await loadPaymentSchedules()
                    }
                    self.error = .updateFailed(underlying: error)
                }
            }
        } catch {
            paymentSchedules[index] = previousSchedule
            await handleError(error, operation: "updatePayment", context: [
                "scheduleId": String(schedule.id)
            ]) { [weak self] in
                await self?.updatePayment(schedule)
            }
            self.error = .updateFailed(underlying: error)
        }
    }

    /// Delete a payment schedule
    func deletePayment(id: Int64) async {
        guard let index = paymentSchedules.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = paymentSchedules.remove(at: index)
        let expenseId = removed.expenseId

        do {
            try await repository.deletePaymentSchedule(id: id)
            logger.info("Deleted payment schedule")
            
            if let expenseId = expenseId {
                do {
                    try await notifier.notifyPaymentScheduleChanged(expenseId: expenseId)
                } catch {
                    await handleError(error, operation: "notifyPaymentScheduleChanged", context: [
                        "expenseId": expenseId.uuidString,
                        "action": "delete"
                    ])
                    do {
                        let restored = try await repository.createPaymentSchedule(removed)
                        paymentSchedules.insert(restored, at: min(index, paymentSchedules.count))
                    } catch {
                        await handleError(error, operation: "restorePaymentSchedule", context: [
                            "scheduleId": String(id)
                        ])
                        await loadPaymentSchedules()
                    }
                    self.error = .deleteFailed(underlying: error)
                }
            }
        } catch {
            paymentSchedules.insert(removed, at: index)
            await handleError(error, operation: "deletePayment", context: [
                "scheduleId": String(id)
            ]) { [weak self] in
                await self?.deletePayment(id: id)
            }
            self.error = .deleteFailed(underlying: error)
        }
    }

    /// Delete a payment schedule (convenience method)
    func deletePayment(_ schedule: PaymentSchedule) async {
        await deletePayment(id: schedule.id)
    }

    /// Bulk delete multiple payment schedules
    /// - Parameter ids: Array of payment schedule IDs to delete
    /// - Returns: Number of successfully deleted schedules
    func bulkDeletePayments(ids: [Int64]) async -> Int {
        guard !ids.isEmpty else { return 0 }

        // Optimistically remove from local state
        let removedPayments = paymentSchedules.filter { ids.contains($0.id) }
        let expenseIds = Set(removedPayments.compactMap { $0.expenseId })
        paymentSchedules.removeAll { ids.contains($0.id) }

        do {
            let deletedCount = try await repository.batchDeletePaymentSchedules(ids: ids)
            logger.info("Bulk deleted \(deletedCount) payment schedules")

            // Notify expense status changes for all affected expenses
            for expenseId in expenseIds {
                do {
                    try await notifier.notifyPaymentScheduleChanged(expenseId: expenseId)
                } catch {
                    logger.error("Failed to notify payment schedule change for expense: \(expenseId)", error: error)
                }
            }

            return deletedCount
        } catch {
            // Restore removed payments on error
            paymentSchedules.append(contentsOf: removedPayments)
            paymentSchedules.sort { $0.paymentDate < $1.paymentDate }

            await handleError(error, operation: "bulkDeletePayments", context: [
                "count": ids.count
            ]) { [weak self] in
                _ = await self?.bulkDeletePayments(ids: ids)
            }
            self.error = .deleteFailed(underlying: error)
            return 0
        }
    }

    /// Mark a payment as paid
    func markAsPaid(_ schedule: PaymentSchedule) async {
        var updated = schedule
        updated.paid = true
        await updatePayment(updated)
    }

    /// Mark a payment as unpaid
    func markAsUnpaid(_ schedule: PaymentSchedule) async {
        var updated = schedule
        updated.paid = false
        await updatePayment(updated)
    }

    /// Toggle payment status
    func togglePaidStatus(_ schedule: PaymentSchedule) async {
        var updated = schedule
        updated.paid.toggle()
        await updatePayment(updated)
    }

    // MARK: - Compatibility Aliases

    /// Add payment schedule (alias for compatibility)
    func addPaymentSchedule(_ schedule: PaymentSchedule) async {
        await addPayment(schedule)
    }

    /// Update payment schedule (alias for compatibility)
    func updatePaymentSchedule(_ schedule: PaymentSchedule) async {
        await updatePayment(schedule)
    }

    /// Delete payment schedule (alias for compatibility)
    func deletePaymentSchedule(id: Int64) async {
        await deletePayment(id: id)
    }

    // MARK: - Payment Plan Grouping & Summaries
    
    /// Fetch payment plan summaries with grouping strategy
    func fetchPaymentPlanSummaries(
        groupBy strategy: PaymentPlanGroupingStrategy = .byExpense,
        expenses: [Expense] = []
    ) async throws -> [PaymentPlanSummary] {
        switch strategy {
        case .byPlanId:
            return try await repository.fetchPaymentPlanSummaries()
        case .byExpense:
            return await groupingService.groupByExpense(paymentSchedules)
        case .byVendor:
            return await groupingService.groupByVendor(paymentSchedules)
        }
    }
    
    /// Fetch hierarchical payment plan groups
    func fetchPaymentPlanGroups(
        groupBy strategy: PaymentPlanGroupingStrategy,
        expenses: [Expense]
    ) async throws -> [PaymentPlanGroup] {
        switch strategy {
        case .byPlanId:
            return []
        case .byExpense:
            return await groupingService.groupHierarchicallyByExpense(paymentSchedules, expenses: expenses)
        case .byVendor:
            return await groupingService.groupHierarchicallyByVendor(paymentSchedules)
        }
    }

    // MARK: - Bill Total Fetching

    /// Fetches aggregated bill total for an expense from linked bill calculators
    /// - Parameter expenseId: The expense UUID
    /// - Returns: ExpenseBillTotal if bills are linked, nil otherwise
    func fetchBillTotalForExpense(expenseId: UUID) async throws -> ExpenseBillTotal? {
        return try await repository.fetchBillTotalForExpense(expenseId: expenseId)
    }

    // MARK: - Payment Plan Config Operations

    /// Fetches the configuration for a payment plan
    func fetchPaymentPlanConfig(paymentPlanId: UUID) async throws -> PaymentPlanConfig? {
        return try await repository.fetchPaymentPlanConfig(paymentPlanId: paymentPlanId)
    }

    /// Creates a new payment plan configuration
    func createPaymentPlanConfig(_ config: PaymentPlanConfig) async throws -> PaymentPlanConfig {
        return try await repository.createPaymentPlanConfig(config)
    }

    /// Updates an existing payment plan configuration
    func updatePaymentPlanConfig(_ config: PaymentPlanConfig) async throws -> PaymentPlanConfig {
        return try await repository.updatePaymentPlanConfig(config)
    }

    // MARK: - Payment Plan Recalculation

    /// Recalculates unpaid payments when the total amount changes
    /// - Parameters:
    ///   - paymentPlanId: The UUID of the payment plan
    ///   - newTotalAmount: The new total amount
    ///   - strategy: How to redistribute amounts
    /// - Returns: RecalculationResult with preview of changes
    func previewRecalculation(
        paymentPlanId: UUID,
        newTotalAmount: Double,
        strategy: RecalculationStrategy
    ) -> RecalculationResult {
        let planPayments = paymentSchedules.filter { $0.paymentPlanId == paymentPlanId }
        return PaymentPlanRecalculator.preview(
            existingPayments: planPayments,
            newTotalAmount: newTotalAmount,
            strategy: strategy
        )
    }

    /// Applies recalculation and saves updated payments to the database
    /// - Parameters:
    ///   - paymentPlanId: The UUID of the payment plan
    ///   - newTotalAmount: The new total amount
    ///   - strategy: How to redistribute amounts
    /// - Returns: Updated payments after saving
    func applyRecalculation(
        paymentPlanId: UUID,
        newTotalAmount: Double,
        strategy: RecalculationStrategy
    ) async throws -> [PaymentSchedule] {
        let planPayments = paymentSchedules.filter { $0.paymentPlanId == paymentPlanId }
        let result = PaymentPlanRecalculator.recalculate(
            existingPayments: planPayments,
            newTotalAmount: newTotalAmount,
            strategy: strategy
        )

        guard result.isValid else {
            throw BudgetError.updateFailed(underlying: NSError(
                domain: "PaymentScheduleStore",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: result.errorMessage ?? "Recalculation failed"]
            ))
        }

        // Update only the unpaid payments in the database
        let unpaidUpdated = result.payments.filter { !$0.paid }
        for payment in unpaidUpdated {
            _ = try await repository.updatePaymentSchedule(payment)
        }

        // Refresh local state
        await loadPaymentSchedules()

        // Notify listeners of changes if we have an expense ID
        if let expenseId = result.payments.first?.expenseId {
            try? await notifier.notifyPaymentScheduleChanged(expenseId: expenseId)
        }

        return result.payments
    }

    // MARK: - Async Segment Recalculation

    /// Recalculates async payment plans linked to specific bill calculators
    /// Called when bill calculator totals change to update dynamic final segments
    /// - Parameter billCalculatorIds: Array of bill calculator UUIDs that changed
    func recalculateLinkedAsyncPlans(billCalculatorIds: [UUID]) async {
        guard !billCalculatorIds.isEmpty else { return }

        do {
            // Find payment plan configs linked to these bill calculators
            let linkedConfigs = try await repository.fetchPaymentPlanConfigsLinkedToBills(billCalculatorIds: billCalculatorIds)

            // Filter to only async plans
            let asyncConfigs = linkedConfigs.filter { $0.paymentType == .async }

            guard !asyncConfigs.isEmpty else {
                logger.info("No async payment plans linked to changed bill calculators")
                return
            }

            logger.info("Found \(asyncConfigs.count) async payment plans to recalculate")

            // Recalculate each async plan's final dynamic segment
            for config in asyncConfigs {
                do {
                    try await recalculateFinalAsyncSegment(config: config)
                } catch {
                    logger.error("Failed to recalculate async plan \(config.paymentPlanId): \(error)")
                    // Continue with other plans even if one fails
                }
            }

            // Refresh local state after all recalculations
            await loadPaymentSchedules()

        } catch {
            await handleError(error, operation: "recalculateLinkedAsyncPlans", context: [
                "billCalculatorIds": billCalculatorIds.map { $0.uuidString }.joined(separator: ", ")
            ])
        }
    }

    /// Recalculates the final dynamic segment of an async payment plan
    /// - Parameter config: The payment plan configuration
    private func recalculateFinalAsyncSegment(config: PaymentPlanConfig) async throws {
        // Extract async segments from config data
        guard case .async(let segments) = config.configData else {
            logger.warning("Payment plan \(config.paymentPlanId) is not an async plan")
            return
        }

        // Find the final segment with useRemainingBalance: true
        guard let finalSegmentIndex = segments.lastIndex(where: { $0.useRemainingBalance }) else {
            logger.info("No dynamic final segment in async plan \(config.paymentPlanId)")
            return
        }

        let finalSegment = segments[finalSegmentIndex]

        // Fetch the new bill total from linked bill calculators
        guard let billTotal = try await repository.fetchBillTotalForExpense(expenseId: config.expenseId) else {
            logger.warning("No bill total found for expense \(config.expenseId)")
            return
        }

        // Calculate amounts for segments before the final one
        var amountBeforeFinal: Double = 0.0
        for (index, segment) in segments.enumerated() where index < finalSegmentIndex {
            if let targetAmount = segment.targetAmount {
                amountBeforeFinal += targetAmount
            }
        }

        // New target for the final segment (totalAmount includes tax)
        let newFinalTarget = billTotal.totalAmount - amountBeforeFinal

        // Fetch existing payments for this plan
        let planPayments = try await repository.fetchPaymentSchedulesByPlanId(paymentPlanId: config.paymentPlanId)

        // Filter to payments in the final segment
        let finalSegmentPayments = planPayments.filter { $0.segmentIndex == finalSegmentIndex }

        // Get vendor info from first payment or expense
        let vendorName = finalSegmentPayments.first?.vendor ?? "Vendor"
        let vendorId = finalSegmentPayments.first?.vendorId

        // Recalculate the segment
        let result = AsyncSegmentRecalculator.recalculateSegment(
            segmentConfig: finalSegment,
            existingPayments: finalSegmentPayments,
            newTargetAmount: newFinalTarget,
            segmentIndex: finalSegmentIndex,
            coupleId: config.coupleId,
            expenseId: config.expenseId,
            vendorName: vendorName,
            vendorId: vendorId,
            paymentPlanId: config.paymentPlanId
        )

        guard result.isValid else {
            logger.error("Recalculation failed for plan \(config.paymentPlanId): \(result.errorMessage ?? "Unknown error")")
            return
        }

        // Apply the changes

        // 1. Delete excess payments
        for paymentId in result.paymentsToDelete {
            try await repository.deletePaymentSchedule(id: paymentId)
        }

        // 2. Update modified payments
        for payment in result.paymentsToUpdate {
            _ = try await repository.updatePaymentSchedule(payment)
        }

        // 3. Create new payments
        for payment in result.paymentsToCreate {
            _ = try await repository.createPaymentSchedule(payment)
        }

        // 4. Update totalPaymentCount for all remaining payments in the plan
        let newTotalCount = result.paymentsToKeep.count + result.paymentsToUpdate.count + result.paymentsToCreate.count
        let allPlanPayments = try await repository.fetchPaymentSchedulesByPlanId(paymentPlanId: config.paymentPlanId)
        for var payment in allPlanPayments where payment.totalPaymentCount != newTotalCount {
            payment.totalPaymentCount = newTotalCount
            _ = try await repository.updatePaymentSchedule(payment)
        }

        logger.info("Recalculated async plan \(config.paymentPlanId): deleted \(result.paymentsToDelete.count), updated \(result.paymentsToUpdate.count), created \(result.paymentsToCreate.count)")

        // Notify expense status change
        try? await notifier.notifyPaymentScheduleChanged(expenseId: config.expenseId)
    }

    // MARK: - Partial Payment Operations

    /// The partial payment service for handling under/over payments
    private let partialPaymentService = PartialPaymentService()

    /// Records a partial or full payment for a payment schedule
    /// - Parameters:
    ///   - payment: The payment schedule being paid
    ///   - amountPaid: The actual amount being paid
    /// - Returns: The result of the partial payment operation
    @discardableResult
    func recordPartialPayment(
        payment: PaymentSchedule,
        amountPaid: Double
    ) async -> PartialPaymentResult {
        isLoading = true
        error = nil

        // Get all payments in the same plan for overpayment calculations
        let planPayments: [PaymentSchedule]
        if let planId = payment.paymentPlanId {
            planPayments = paymentSchedules.filter { $0.paymentPlanId == planId }
        } else {
            planPayments = [payment]
        }

        // Calculate the result
        let result = await partialPaymentService.recordPayment(
            payment: payment,
            amountPaid: amountPaid,
            allPlanPayments: planPayments
        )

        guard result.isValid else {
            logger.error("Partial payment failed: \(result.errorMessage ?? "Unknown error")")
            isLoading = false
            return result
        }

        do {
            // 1. Update the original payment
            _ = try await repository.updatePaymentSchedule(result.updatedPayment)
            if let index = paymentSchedules.firstIndex(where: { $0.id == result.updatedPayment.id }) {
                paymentSchedules[index] = result.updatedPayment
            }

            // 2. Create carryover payment if needed (underpayment)
            if let carryover = result.carryoverPayment {
                let created = try await repository.createPaymentSchedule(carryover)
                paymentSchedules.append(created)
                logger.info("Created carryover payment with ID: \(created.id)")
            }

            // 3. Update subsequent payments (overpayment adjustments)
            for updatedPayment in result.updatedSubsequentPayments {
                _ = try await repository.updatePaymentSchedule(updatedPayment)
                if let index = paymentSchedules.firstIndex(where: { $0.id == updatedPayment.id }) {
                    paymentSchedules[index] = updatedPayment
                }
            }

            // 4. Delete eliminated payments (overpayment)
            for paymentId in result.paymentsToDelete {
                try await repository.deletePaymentSchedule(id: paymentId)
                paymentSchedules.removeAll { $0.id == paymentId }
                logger.info("Deleted payment \(paymentId) due to overpayment")
            }

            // Notify expense status change
            if let expenseId = payment.expenseId {
                try? await notifier.notifyPaymentScheduleChanged(expenseId: expenseId)
            }

            logger.info("Partial payment recorded: \(result.summary)")

        } catch {
            await handleError(error, operation: "recordPartialPayment", context: [
                "paymentId": String(payment.id),
                "amountPaid": String(amountPaid)
            ]) { [weak self] in
                await self?.recordPartialPayment(payment: payment, amountPaid: amountPaid)
            }
            self.error = .updateFailed(underlying: error)
        }

        isLoading = false
        return result
    }

    /// Preview what a partial payment would do without making changes
    /// - Parameters:
    ///   - payment: The payment schedule being paid
    ///   - amountPaid: The proposed amount to pay
    /// - Returns: Preview of the partial payment result
    func previewPartialPayment(
        payment: PaymentSchedule,
        amountPaid: Double
    ) async -> PartialPaymentResult {
        let planPayments: [PaymentSchedule]
        if let planId = payment.paymentPlanId {
            planPayments = paymentSchedules.filter { $0.paymentPlanId == planId }
        } else {
            planPayments = [payment]
        }

        return await partialPaymentService.previewPartialPayment(
            payment: payment,
            amountPaid: amountPaid,
            allPlanPayments: planPayments
        )
    }

    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        paymentSchedules = []
    }
}
