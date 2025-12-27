//
//  ExpensePaymentStatusService.swift
//  I Do Blueprint
//
//  Service for automatically calculating expense payment status based on associated payment schedules
//

import Foundation

/// Service responsible for calculating the automatic payment status of expenses based on their payment schedules
struct ExpensePaymentStatusService {
    private let logger = AppLogger.database
    
    /// Calculates the appropriate payment status for an expense based on its payment schedules
    ///
    /// Logic:
    /// - **No payment schedules**: Returns `.pending`
    /// - **Has overdue payments**: Returns `.overdue`
    /// - **All payments paid and total equals expense amount**: Returns `.paid`
    /// - **Some payments paid but total < expense amount**: Returns `.partial`
    /// - **No payments paid yet**: Returns `.pending`
    ///
    /// - Parameters:
    ///   - expense: The expense to calculate status for
    ///   - paymentSchedules: All payment schedules associated with this expense
    /// - Returns: The calculated payment status
    func calculatePaymentStatus(
        for expense: Expense,
        paymentSchedules: [PaymentSchedule]
    ) -> PaymentStatus {
        // Filter payment schedules for this specific expense
        let expensePayments = paymentSchedules.filter { $0.expenseId == expense.id }
        
        // If no payment schedules exist, status is pending
        guard !expensePayments.isEmpty else {
            logger.debug("No payment schedules for expense \(expense.id), status: pending")
            return .pending
        }
        
        let today = Date()
        
        // Check for overdue payments (unpaid and past due date)
        let hasOverduePayments = expensePayments.contains { payment in
            !payment.paid && payment.paymentDate < today
        }
        
        if hasOverduePayments {
            logger.debug("Expense \(expense.id) has overdue payments, status: overdue")
            return .overdue
        }
        
        // Calculate total paid amount
        let totalPaid = expensePayments
            .filter { $0.paid }
            .reduce(0.0) { $0 + $1.paymentAmount }
        
        // Check if any payments have been made
        let hasAnyPayments = expensePayments.contains { $0.paid }
        
        // If no payments have been made yet, status is pending
        guard hasAnyPayments else {
            logger.debug("Expense \(expense.id) has no paid payments, status: pending")
            return .pending
        }
        
        // Check payment status with epsilon for floating point comparison
        let epsilon = 0.01
        
        // Check if overpaid (total paid exceeds expense amount beyond epsilon)
        if totalPaid > expense.amount + epsilon {
            logger.info("Expense \(expense.id) overpaid: \(totalPaid) > \(expense.amount) (overage: \(totalPaid - expense.amount)), treating as paid")
            return .paid
        }
        
        // Check if fully paid (total paid equals expense amount within epsilon)
        if abs(totalPaid - expense.amount) < epsilon {
            logger.debug("Expense \(expense.id) fully paid (\(totalPaid) ≈ \(expense.amount)), status: paid")
            return .paid
        }
        
        // If some payments made but less than expense amount, status is partial
        logger.debug("Expense \(expense.id) partially paid (\(totalPaid) < \(expense.amount)), status: partial")
        return .partial
    }
    
    /// Calculates payment status for multiple expenses at once
    ///
    /// - Parameters:
    ///   - expenses: Array of expenses to calculate status for
    ///   - allPaymentSchedules: All payment schedules (will be filtered per expense)
    /// - Returns: Dictionary mapping expense ID to calculated payment status
    func calculatePaymentStatuses(
        for expenses: [Expense],
        allPaymentSchedules: [PaymentSchedule]
    ) -> [UUID: PaymentStatus] {
        var statusMap: [UUID: PaymentStatus] = [:]
        
        for expense in expenses {
            let status = calculatePaymentStatus(
                for: expense,
                paymentSchedules: allPaymentSchedules
            )
            statusMap[expense.id] = status
        }
        
        logger.info("Calculated payment statuses for \(expenses.count) expenses")
        return statusMap
    }
    
    /// Determines if an expense's payment status needs to be updated
    ///
    /// - Parameters:
    ///   - expense: The expense to check
    ///   - paymentSchedules: Payment schedules for this expense
    /// - Returns: Tuple of (needsUpdate: Bool, newStatus: PaymentStatus?)
    func shouldUpdatePaymentStatus(
        for expense: Expense,
        paymentSchedules: [PaymentSchedule]
    ) -> (needsUpdate: Bool, newStatus: PaymentStatus?) {
        let calculatedStatus = calculatePaymentStatus(
            for: expense,
            paymentSchedules: paymentSchedules
        )
        
        let needsUpdate = expense.paymentStatus != calculatedStatus
        
        if needsUpdate {
            logger.info("Expense \(expense.id) status should change from \(expense.paymentStatus.rawValue) to \(calculatedStatus.rawValue)")
        }
        
        return (needsUpdate, needsUpdate ? calculatedStatus : nil)
    }
    
    /// Gets a summary of payment progress for an expense
    ///
    /// - Parameters:
    ///   - expense: The expense to analyze
    ///   - paymentSchedules: Payment schedules for this expense
    /// - Returns: Payment progress summary
    func getPaymentProgress(
        for expense: Expense,
        paymentSchedules: [PaymentSchedule]
    ) -> ExpensePaymentProgress {
        let expensePayments = paymentSchedules.filter { $0.expenseId == expense.id }
        
        let totalScheduled = expensePayments.reduce(0.0) { $0 + $1.paymentAmount }
        let totalPaid = expensePayments.filter { $0.paid }.reduce(0.0) { $0 + $1.paymentAmount }
        let paidCount = expensePayments.filter { $0.paid }.count
        let totalCount = expensePayments.count
        
        let today = Date()
        let overdueCount = expensePayments.filter { !$0.paid && $0.paymentDate < today }.count
        
        return ExpensePaymentProgress(
            expenseAmount: expense.amount,
            totalScheduled: totalScheduled,
            totalPaid: totalPaid,
            paidCount: paidCount,
            totalCount: totalCount,
            overdueCount: overdueCount,
            calculatedStatus: calculatePaymentStatus(for: expense, paymentSchedules: paymentSchedules)
        )
    }
}

/// Summary of payment progress for an expense
struct ExpensePaymentProgress {
    let expenseAmount: Double
    let totalScheduled: Double
    let totalPaid: Double
    let paidCount: Int
    let totalCount: Int
    let overdueCount: Int
    let calculatedStatus: PaymentStatus
    
    /// Remaining amount to be paid (capped at 0 to handle overpayment scenarios)
    var remainingAmount: Double {
        max(0, expenseAmount - totalPaid)
    }
    
    /// Percentage of expense that has been paid (capped between 0 and 100)
    var percentagePaid: Double {
        guard expenseAmount > 0 else { return 0 }
        let percentage = (totalPaid / expenseAmount) * 100
        return min(100, max(0, percentage))
    }
    
    var hasOverduePayments: Bool {
        overdueCount > 0
    }
    
    var isFullyScheduled: Bool {
        abs(totalScheduled - expenseAmount) < 0.01
    }
}
