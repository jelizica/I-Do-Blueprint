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

// Dependency for expense status recalculation/notification
private protocol PaymentScheduleChangeNotifying: Sendable {
    func notifyPaymentScheduleChanged(expenseId: UUID) async throws
}

private enum PaymentScheduleChangeNotifierKey: DependencyKey {
    // Default live implementation uses AppStores to update payment status
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
        // Use AppStores to update the expense payment status
        // This must be called on MainActor since BudgetStoreV2 is @MainActor
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

            // Reload all payment schedules to ensure we have the latest data
            await loadPaymentSchedules()
            
            // Update expense payment status if linked to an expense
            if let expenseId = created.expenseId {
                do {
                    try await notifier.notifyPaymentScheduleChanged(expenseId: expenseId)
                } catch {
                    // Notification failed: log and propagate as create failure by rolling back local append
                    logger.error("Expense payment status notification failed after create", error: error)
                    // Reload schedules from source of truth to avoid inconsistent state
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

        // Optimistic update - update UI immediately
        let previousSchedule = paymentSchedules[index]
        paymentSchedules[index] = schedule

        do {
            // Save to database via repository
            let updated = try await repository.updatePaymentSchedule(schedule)
            paymentSchedules[index] = updated
            logger.info("Updated payment schedule in database")
            
            // Update expense payment status if linked to an expense
            if let expenseId = updated.expenseId {
                do {
                    try await notifier.notifyPaymentScheduleChanged(expenseId: expenseId)
                } catch {
                    // Compensating rollback: revert schedule to previous state both locally and remotely
                    logger.error("Expense payment status notification failed after update; rolling back payment schedule", error: error)
                    // Attempt to revert remotely to previousSchedule
                    do {
                        _ = try await repository.updatePaymentSchedule(previousSchedule)
                        paymentSchedules[index] = previousSchedule
                    } catch {
                        // If rollback fails, reload from source of truth
                        logger.error("Failed to rollback payment schedule after notifier failure", error: error)
                        await loadPaymentSchedules()
                    }
                    self.error = .updateFailed(underlying: error)
                }
            }
        } catch {
            // Rollback on error
            paymentSchedules[index] = previousSchedule
            self.error = .updateFailed(underlying: error)
            logger.error("Error updating payment schedule", error: error)
        }
    }

    /// Delete a payment schedule
    func deletePayment(id: Int64) async {
        // Optimistic delete
        guard let index = paymentSchedules.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = paymentSchedules.remove(at: index)
        let expenseId = removed.expenseId // Store before deletion

        do {
            try await repository.deletePaymentSchedule(id: id)
            logger.info("Deleted payment schedule")
            
            // Update expense payment status if it was linked to an expense
            if let expenseId = expenseId {
                do {
                    try await notifier.notifyPaymentScheduleChanged(expenseId: expenseId)
                } catch {
                    // Compensating action: attempt to restore deleted schedule if notification fails
                    logger.error("Expense payment status notification failed after delete; restoring schedule", error: error)
                    // Try to recreate the schedule to maintain consistency
                    do {
                        let restored = try await repository.createPaymentSchedule(removed)
                        paymentSchedules.insert(restored, at: min(index, paymentSchedules.count))
                    } catch {
                        logger.error("Failed to restore schedule after notifier failure", error: error)
                        // As last resort, reload all schedules
                        await loadPaymentSchedules()
                    }
                    self.error = .deleteFailed(underlying: error)
                }
            }
        } catch {
            // Rollback on error
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
    /// - Parameter groupBy: Strategy for grouping payments (default: by expense)
    /// - Returns: Array of payment plan summaries grouped according to strategy
    func fetchPaymentPlanSummaries(
        groupBy strategy: PaymentPlanGroupingStrategy = .byExpense,
        expenses: [Expense] = []
    ) async throws -> [PaymentPlanSummary] {
        switch strategy {
        case .byPlanId:
            return try await fetchPaymentPlanSummariesByPlanId()
        case .byExpense:
            return await fetchPaymentPlanSummariesByExpense()
        case .byVendor:
            return await fetchPaymentPlanSummariesByVendor()
        }
    }
    
    /// Fetch hierarchical payment plan groups (for vendor/expense grouping)
    /// - Parameters:
    ///   - groupBy: Strategy for grouping payments
    ///   - expenses: Array of expenses for name lookup
    /// - Returns: Array of hierarchical groups containing multiple plans
    func fetchPaymentPlanGroups(
        groupBy strategy: PaymentPlanGroupingStrategy,
        expenses: [Expense]
    ) async throws -> [PaymentPlanGroup] {
        switch strategy {
        case .byPlanId:
            // For "By Plan ID", no grouping needed - return empty array
            return []
        case .byExpense:
            return await fetchPaymentPlanGroupsByExpense(expenses: expenses)
        case .byVendor:
            return await fetchPaymentPlanGroupsByVendor()
        }
    }
    
    // MARK: - Payment Plan Grouping Methods
    
    /// Group payments by their original payment_plan_id (original behavior)
    private func fetchPaymentPlanSummariesByPlanId() async throws -> [PaymentPlanSummary] {
        // Call existing database view or query for backward compatibility
        return try await repository.fetchPaymentPlanSummaries()
    }
    
    /// Group all payments for the same expense together
    private func fetchPaymentPlanSummariesByExpense() async -> [PaymentPlanSummary] {
        // Group by expense_id
        let groupedByExpense = Dictionary(grouping: paymentSchedules) { payment in
            payment.expenseId
        }
        
        var summaries: [PaymentPlanSummary] = []
        
        for (expenseId, paymentsGroup) in groupedByExpense {
            guard let expenseId = expenseId else { continue }
            
            // Sort payments by date
            let sortedPayments = paymentsGroup.sorted { $0.paymentDate < $1.paymentDate }
            guard let firstPayment = sortedPayments.first else { continue }
            
            // Create summary using expense_id as the plan ID for grouping
            let summary = createPaymentPlanSummary(
                from: sortedPayments,
                planId: expenseId,
                expenseId: expenseId
            )
            
            summaries.append(summary)
        }
        
        // Sort by next payment date (soonest first), then by vendor name
        return summaries.sorted { lhs, rhs in
            if let lhsNext = lhs.nextPaymentDate, let rhsNext = rhs.nextPaymentDate {
                return lhsNext < rhsNext
            } else if lhs.nextPaymentDate != nil {
                return true
            } else if rhs.nextPaymentDate != nil {
                return false
            } else {
                return lhs.vendor < rhs.vendor
            }
        }
    }
    
    /// Group all payments for the same vendor together
    private func fetchPaymentPlanSummariesByVendor() async -> [PaymentPlanSummary] {
        // Group by vendor_id
        let groupedByVendor = Dictionary(grouping: paymentSchedules) { payment in
            payment.vendorId
        }
        
        var summaries: [PaymentPlanSummary] = []
        
        for (vendorId, paymentsGroup) in groupedByVendor {
            guard let vendorId = vendorId else { continue }
            
            // Sort payments by date
            let sortedPayments = paymentsGroup.sorted { $0.paymentDate < $1.paymentDate }
            guard let firstPayment = sortedPayments.first else { continue }
            
            // Use first expense_id or generate a synthetic ID
            let syntheticPlanId = firstPayment.expenseId ?? UUID()
            
            // Create summary
            let summary = createPaymentPlanSummary(
                from: sortedPayments,
                planId: syntheticPlanId,
                expenseId: syntheticPlanId
            )
            
            summaries.append(summary)
        }
        
        // Sort by vendor name
        return summaries.sorted { $0.vendor < $1.vendor }
    }
    
    // MARK: - Hierarchical Grouping Methods
    
    /// Group payments hierarchically by expense
    /// Returns groups where each expense contains multiple payment plans
    private func fetchPaymentPlanGroupsByExpense(expenses: [Expense]) async -> [PaymentPlanGroup] {
        // First group by expense_id
        let groupedByExpense = Dictionary(grouping: paymentSchedules) { $0.expenseId }
        
        var groups: [PaymentPlanGroup] = []
        
        for (expenseId, expensePayments) in groupedByExpense {
            guard let expenseId = expenseId else { continue }
            
            // Within each expense, group by payment_plan_id
            let groupedByPlan = Dictionary(grouping: expensePayments) { $0.paymentPlanId }
            
            // Create a PaymentPlanSummary for each plan within this expense
            var plansForExpense: [PaymentPlanSummary] = []
            
            for (planId, planPayments) in groupedByPlan {
                guard let planId = planId else { continue }
                
                let sortedPayments = planPayments.sorted { $0.paymentDate < $1.paymentDate }
                guard sortedPayments.first != nil else { continue }
                
                // Calculate aggregates for this specific plan
                let summary = createPaymentPlanSummary(
                    from: sortedPayments,
                    planId: planId,
                    expenseId: expenseId
                )
                
                plansForExpense.append(summary)
            }
            
            // Sort plans by next payment date
            plansForExpense.sort { lhs, rhs in
                if let lhsNext = lhs.nextPaymentDate, let rhsNext = rhs.nextPaymentDate {
                    return lhsNext < rhsNext
                } else if lhs.nextPaymentDate != nil {
                    return true
                } else if rhs.nextPaymentDate != nil {
                    return false
                } else {
                    return lhs.firstPaymentDate < rhs.firstPaymentDate
                }
            }
            
            // Get expense name from first payment
            guard let firstPayment = expensePayments.first else { continue }
            let expenseName = expenses.first(where: { $0.id == expenseId })?.expenseName ?? firstPayment.vendor
            
            // Create group
            let group = PaymentPlanGroup(
                id: expenseId,
                groupName: expenseName,
                groupType: .expense(expenseId: expenseId),
                plans: plansForExpense
            )
            
            groups.append(group)
        }
        
        // Sort groups by name
        return groups.sorted { $0.groupName < $1.groupName }
    }
    
    /// Group payments hierarchically by vendor
    /// Returns groups where each vendor contains multiple payment plans
    private func fetchPaymentPlanGroupsByVendor() async -> [PaymentPlanGroup] {
        // First group by vendor_id
        let groupedByVendor = Dictionary(grouping: paymentSchedules) { $0.vendorId }
        
        var groups: [PaymentPlanGroup] = []
        
        for (vendorId, vendorPayments) in groupedByVendor {
            guard let vendorId = vendorId else { continue }
            
            // Within each vendor, group by payment_plan_id
            let groupedByPlan = Dictionary(grouping: vendorPayments) { $0.paymentPlanId }
            
            // Create a PaymentPlanSummary for each plan within this vendor
            var plansForVendor: [PaymentPlanSummary] = []
            
            for (planId, planPayments) in groupedByPlan {
                guard let planId = planId else { continue }
                
                let sortedPayments = planPayments.sorted { $0.paymentDate < $1.paymentDate }
                guard let firstPayment = sortedPayments.first else { continue }
                
                // Use expense_id from first payment, or generate synthetic ID
                let expenseId = firstPayment.expenseId ?? UUID()
                
                // Calculate aggregates for this specific plan
                let summary = createPaymentPlanSummary(
                    from: sortedPayments,
                    planId: planId,
                    expenseId: expenseId
                )
                
                plansForVendor.append(summary)
            }
            
            // Sort plans by next payment date
            plansForVendor.sort { lhs, rhs in
                if let lhsNext = lhs.nextPaymentDate, let rhsNext = rhs.nextPaymentDate {
                    return lhsNext < rhsNext
                } else if lhs.nextPaymentDate != nil {
                    return true
                } else if rhs.nextPaymentDate != nil {
                    return false
                } else {
                    return lhs.firstPaymentDate < rhs.firstPaymentDate
                }
            }
            
            // Get vendor name from first payment
            guard let firstPayment = vendorPayments.first else { continue }
            let vendorName = firstPayment.vendor
            
            // Create group
            let group = PaymentPlanGroup(
                id: UUID(), // Generate unique ID for vendor group
                groupName: vendorName,
                groupType: .vendor(vendorId: vendorId),
                plans: plansForVendor
            )
            
            groups.append(group)
        }
        
        // Sort groups by name
        return groups.sorted { $0.groupName < $1.groupName }
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to create a PaymentPlanSummary from a list of payments
    private func createPaymentPlanSummary(
        from payments: [PaymentSchedule],
        planId: UUID,
        expenseId: UUID
    ) -> PaymentPlanSummary {
        let totalAmount = payments.reduce(0) { $0 + $1.paymentAmount }
        let amountPaid = payments.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
        let amountRemaining = totalAmount - amountPaid
        let percentPaid = totalAmount > 0 ? (amountPaid / totalAmount) * 100 : 0
        
        let paymentsCompleted = Int64(payments.filter { $0.paid }.count)
        let paymentsRemaining = Int64(payments.count) - paymentsCompleted
        
        let allPaid = payments.allSatisfy { $0.paid }
        let anyPaid = payments.contains { $0.paid }
        
        let deposits = payments.filter { $0.isDeposit }
        let depositAmount = deposits.reduce(0) { $0 + $1.paymentAmount }
        let depositCount = Int64(deposits.count)
        
        let nextPayment = payments.first { !$0.paid && $0.paymentDate >= Date() }
        let nextPaymentDate = nextPayment?.paymentDate
        let nextPaymentAmount = nextPayment?.paymentAmount
        
        var daysUntilNextPayment: Int?
        if let nextDate = nextPaymentDate {
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: Date(), to: nextDate).day
            daysUntilNextPayment = days
        }
        
        let overduePayments = payments.filter { !$0.paid && $0.paymentDate < Date() }
        let overdueCount = Int64(overduePayments.count)
        let overdueAmount = overduePayments.reduce(0) { $0 + $1.paymentAmount }
        
        let planStatus: PaymentPlanSummary.PlanStatus
        if allPaid {
            planStatus = .completed
        } else if overdueCount > 0 {
            planStatus = .overdue
        } else if anyPaid {
            planStatus = .inProgress
        } else {
            planStatus = .pending
        }
        
        let planType = determinePlanType(for: payments)
        
        guard let firstPayment = payments.first else {
            fatalError("Cannot create summary from empty payments array")
        }
        
        let notes = payments.compactMap { $0.notes }.filter { !$0.isEmpty }
        let combinedNotes = notes.isEmpty ? nil : notes.joined(separator: " | ")
        
        return PaymentPlanSummary(
            paymentPlanId: planId,
            expenseId: expenseId,
            coupleId: firstPayment.coupleId,
            vendor: firstPayment.vendor,
            vendorId: firstPayment.vendorId ?? 0,
            vendorType: firstPayment.vendorType,
            paymentType: planType.rawValue,
            paymentPlanType: planType.rawValue,
            planTypeDisplay: planType.displayName,
            totalPayments: payments.count,
            firstPaymentDate: firstPayment.paymentDate,
            lastPaymentDate: payments.last!.paymentDate,
            depositDate: deposits.first?.paymentDate,
            totalAmount: totalAmount,
            amountPaid: amountPaid,
            amountRemaining: amountRemaining,
            depositAmount: depositAmount,
            percentPaid: percentPaid,
            actualPaymentCount: Int64(payments.count),
            paymentsCompleted: paymentsCompleted,
            paymentsRemaining: paymentsRemaining,
            depositCount: depositCount,
            allPaid: allPaid,
            anyPaid: anyPaid,
            hasDeposit: !deposits.isEmpty,
            hasRetainer: payments.contains { $0.isRetainer },
            planStatus: planStatus,
            nextPaymentDate: nextPaymentDate,
            nextPaymentAmount: nextPaymentAmount,
            daysUntilNextPayment: daysUntilNextPayment,
            overdueCount: overdueCount,
            overdueAmount: overdueAmount,
            combinedNotes: combinedNotes,
            planCreatedAt: firstPayment.createdAt,
            planUpdatedAt: payments.compactMap { $0.updatedAt ?? $0.createdAt }.max()
        )
    }
    
    /// Determine plan type from payment pattern
    private func determinePlanType(for payments: [PaymentSchedule]) -> PaymentPlanType {
        if payments.count == 1 {
            return .individual
        }
        
        // Check if all payments have same amount (excluding deposits)
        let nonDepositPayments = payments.filter { !$0.isDeposit }
        
        guard !nonDepositPayments.isEmpty else {
            return .installment
        }
        
        let amounts = Set(nonDepositPayments.map { $0.paymentAmount })
        
        if amounts.count == 1 {
            // Check if monthly intervals
            let sortedDates = nonDepositPayments.map { $0.paymentDate }.sorted()
            var isMonthly = true
            
            for i in 1..<sortedDates.count {
                let interval = Calendar.current.dateComponents([.month], from: sortedDates[i-1], to: sortedDates[i]).month ?? 0
                if interval != 1 {
                    isMonthly = false
                    break
                }
            }
            
            return isMonthly ? .simpleRecurring : .intervalRecurring
        } else {
            return .installment
        }
    }

    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        paymentSchedules = []
    }
}
