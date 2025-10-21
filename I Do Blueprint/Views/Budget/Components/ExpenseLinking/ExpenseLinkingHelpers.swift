//
//  ExpenseLinkingHelpers.swift
//  I Do Blueprint
//
//  Helper functions for expense linking view
//

import SwiftUI

// MARK: - Expense Linking Helpers

extension ExpenseLinkingView {
    
    // MARK: Computed Properties
    
    var availableExpenses: [Expense] {
        filteredExpenses.filter { !linkedExpenseIds.contains($0.id) }
    }
    
    var selectedExpensesList: [Expense] {
        expenses.filter { selectedExpenses.contains($0.id) }
    }
    
    var totalAllocationAmount: Double {
        selectedExpensesList.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: Formatters
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: Payment Status Configuration
    
    func paymentStatusConfig(_ status: PaymentStatus) -> (label: String, icon: String, color: Color) {
        switch status {
        case .paid:
            ("Paid", "checkmark.circle.fill", AppColors.Budget.income)
        case .pending:
            ("Pending", "clock.fill", AppColors.Budget.pending)
        case .partial:
            ("Partial", "clock.fill", .yellow)
        case .overdue:
            ("Overdue", "exclamationmark.circle.fill", AppColors.Budget.overBudget)
        case .cancelled:
            ("Cancelled", "xmark.circle.fill", .gray)
        case .refunded:
            ("Refunded", "arrow.uturn.backward.circle.fill", AppColors.Budget.allocated)
        }
    }
}
