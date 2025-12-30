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
            self.error = .fetchFailed(underlying: error)
            logger.error("Failed to load payment schedules", error: error)
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
            self.error = .fetchFailed(underlying: error)
            logger.error("Failed to load payment plan summaries", error: error)
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
            self.error = .fetchFailed(underlying: error)
            logger.error("Failed to load payment plan summary for expense: \(expenseId)", error: error)
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
                    logger.error("Expense payment status notification failed after create", error: error)
                    await loadPaymentSchedules()
                    self.error = .updateFailed(underlying: error)
                }
            }
        } catch {
            self.error = .createFailed(underlying: error)
            logger.error("Error adding payment schedule", error: error)
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
                    logger.error("Expense payment status notification failed after update; rolling back payment schedule", error: error)
                    do {
                        _ = try await repository.updatePaymentSchedule(previousSchedule)
                        paymentSchedules[index] = previousSchedule
                    } catch {
                        logger.error("Failed to rollback payment schedule after notifier failure", error: error)
                        await loadPaymentSchedules()
                    }
                    self.error = .updateFailed(underlying: error)
                }
            }
        } catch {
            paymentSchedules[index] = previousSchedule
            self.error = .updateFailed(underlying: error)
            logger.error("Error updating payment schedule", error: error)
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
                    logger.error("Expense payment status notification failed after delete; restoring schedule", error: error)
                    do {
                        let restored = try await repository.createPaymentSchedule(removed)
                        paymentSchedules.insert(restored, at: min(index, paymentSchedules.count))
                    } catch {
                        logger.error("Failed to restore schedule after notifier failure", error: error)
                        await loadPaymentSchedules()
                    }
                    self.error = .deleteFailed(underlying: error)
                }
            }
        } catch {
            paymentSchedules.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
            logger.error("Error deleting payment schedule, rolled back", error: error)
        }
    }

    /// Delete a payment schedule (convenience method)
    func deletePayment(_ schedule: PaymentSchedule) async {
        await deletePayment(id: schedule.id)
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

    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        paymentSchedules = []
    }
}
