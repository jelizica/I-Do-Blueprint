//
//  BudgetStoreV2+PaymentStatus.swift
//  I Do Blueprint
//
//  Extension for automatic payment status calculation based on payment schedules
//

import Foundation

extension BudgetStoreV2 {
    
    /// Service for calculating payment statuses
    private var paymentStatusService: ExpensePaymentStatusService {
        ExpensePaymentStatusService()
    }
    
    // MARK: - Automatic Payment Status Updates
    
    /// Updates payment statuses for all expenses based on their payment schedules
    /// This should be called after loading data or when payment schedules change
    @MainActor
    func updateAllExpensePaymentStatuses() async {
        guard case .loaded(let budgetData) = loadingState else {
            logger.warning("Cannot update payment statuses: budget data not loaded")
            return
        }
        
        let start = Date()
        let paymentSchedules = payments.paymentSchedules
        var updatedCount = 0
        var expensesToUpdate: [Expense] = []
        
        // Calculate new statuses for all expenses
        for expense in budgetData.expenses {
            let (needsUpdate, newStatus) = paymentStatusService.shouldUpdatePaymentStatus(
                for: expense,
                paymentSchedules: paymentSchedules
            )
            
            if needsUpdate, let status = newStatus {
                var updatedExpense = expense
                updatedExpense.paymentStatus = status
                updatedExpense.updatedAt = Date()
                expensesToUpdate.append(updatedExpense)
                updatedCount += 1
            }
        }
        
        // Update expenses in database
        if !expensesToUpdate.isEmpty {
            var successCount = 0
            var failureCount = 0

            logger.info("Updating payment status for \(expensesToUpdate.count) expenses")
            
            for expense in expensesToUpdate {
                do {
                    _ = try await repository.updateExpense(expense)
                    successCount += 1
                } catch {
                    failureCount += 1
                    logger.error("Failed to update payment status for expense \(expense.id): \(error.localizedDescription)", error: error)
                    
                    // Check if this is a constraint violation error
                    let errorMessage = error.localizedDescription.lowercased()
                    if errorMessage.contains("payment_status_check") || errorMessage.contains("constraint") {
                        logger.warning("Payment status constraint violation - database may need migration to support 'partial' status. Attempted status: \(expense.paymentStatus.rawValue)")
                    }
                    
                    await handleError(error, operation: "updateExpensePaymentStatus", context: [
                        "expenseId": expense.id.uuidString,
                        "attemptedStatus": expense.paymentStatus.rawValue
                    ])
                    
                    // Continue with other expenses instead of failing completely
                    continue
                }
            }
            
            logger.info("Payment status update complete: \(successCount) succeeded, \(failureCount) failed")
            
            // Update local state directly
            if successCount > 0, case .loaded(var data) = loadingState {
                for updatedExpense in expensesToUpdate {
                    if let index = data.expenses.firstIndex(where: { $0.id == updatedExpense.id }) {
                        data.expenses[index] = updatedExpense
                    }
                }
                loadingState = .loaded(data)
            }
            
            let duration = Date().timeIntervalSince(start)
            logger.info("Updated \(successCount) expense payment statuses in \(String(format: "%.2f", duration))s")
        } else {
            logger.debug("No expense payment statuses need updating")
        }
    }
    
    /// Updates payment status for a single expense based on its payment schedules
    /// - Parameter expenseId: The expense ID to update
    @MainActor
    func updateExpensePaymentStatus(expenseId: UUID) async {
        guard case .loaded(let budgetData) = loadingState else {
            logger.warning("Cannot update payment status: budget data not loaded")
            return
        }
        
        guard let expense = budgetData.expenses.first(where: { $0.id == expenseId }) else {
            logger.warning("Expense not found: \(expenseId)")
            return
        }
        
        let paymentSchedules = payments.paymentSchedules
        let (needsUpdate, newStatus) = paymentStatusService.shouldUpdatePaymentStatus(
            for: expense,
            paymentSchedules: paymentSchedules
        )
        
        if needsUpdate, let status = newStatus {
            var updatedExpense = expense
            updatedExpense.paymentStatus = status
            updatedExpense.updatedAt = Date()
            
            do {
                _ = try await repository.updateExpense(updatedExpense)
                logger.info("Updated payment status for expense \(expenseId) to \(status.rawValue)")
                
                // Update local state
                if case .loaded(var data) = loadingState,
                   let index = data.expenses.firstIndex(where: { $0.id == expenseId }) {
                    data.expenses[index] = updatedExpense
                    loadingState = .loaded(data)
                }
            } catch {
                logger.error("Failed to update payment status for expense \(expenseId)", error: error)
                
                await handleError(error, operation: "updateExpensePaymentStatus", context: [
                    "expenseId": expenseId.uuidString,
                    "attemptedStatus": status.rawValue
                ]) { [weak self] in
                    await self?.updateExpensePaymentStatus(expenseId: expenseId)
                }
            }
        }
    }
    
    /// Gets the calculated payment status for an expense without updating it
    /// - Parameter expense: The expense to calculate status for
    /// - Returns: The calculated payment status
    func getCalculatedPaymentStatus(for expense: Expense) -> PaymentStatus {
        let paymentSchedules = payments.paymentSchedules
        return paymentStatusService.calculatePaymentStatus(
            for: expense,
            paymentSchedules: paymentSchedules
        )
    }
    
    /// Gets payment progress information for an expense
    /// - Parameter expense: The expense to analyze
    /// - Returns: Payment progress summary
    func getPaymentProgress(for expense: Expense) -> ExpensePaymentProgress {
        let paymentSchedules = payments.paymentSchedules
        return paymentStatusService.getPaymentProgress(
            for: expense,
            paymentSchedules: paymentSchedules
        )
    }
    
    /// Checks if an expense's payment status is out of sync with its payment schedules
    /// - Parameter expense: The expense to check
    /// - Returns: True if the status needs updating
    func isPaymentStatusOutOfSync(for expense: Expense) -> Bool {
        let paymentSchedules = payments.paymentSchedules
        let (needsUpdate, _) = paymentStatusService.shouldUpdatePaymentStatus(
            for: expense,
            paymentSchedules: paymentSchedules
        )
        return needsUpdate
    }
}
