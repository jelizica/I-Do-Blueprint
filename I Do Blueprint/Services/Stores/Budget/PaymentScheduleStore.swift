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

/// Store for managing payment schedules
/// Handles CRUD operations for payment schedules with optimistic updates
@MainActor
class PaymentScheduleStore: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var paymentSchedules: [PaymentSchedule] = []
    @Published var isLoading = false
    @Published var error: BudgetError?
    
    // MARK: - Dependencies
    
    @Dependency(\.budgetRepository) var repository
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
        
        do {
            try await repository.deletePaymentSchedule(id: id)
            logger.info("Deleted payment schedule")
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
    
    // MARK: - State Management
    
    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        paymentSchedules = []
    }
}
