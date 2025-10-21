//
//  CategoryBadges.swift
//  I Do Blueprint
//
//  Badge components for budget category detail view
//

import SwiftUI

// MARK: - Payment Status Badge

struct PaymentStatusBadge: View {
    let status: PaymentStatus

    var body: some View {
        StatusBadge(text: status.displayName, color: statusColor)
    }

    private var statusColor: Color {
        switch status {
        case .pending: AppColors.Budget.pending
        case .partial: AppColors.Budget.allocated
        case .paid: AppColors.Budget.income
        case .overdue: AppColors.Budget.overBudget
        case .cancelled: .gray
        case .refunded: .purple
        }
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: BudgetPriority

    var body: some View {
        StatusBadge(text: priority.displayName, color: priorityColor)
    }

    private var priorityColor: Color {
        switch priority {
        case .high: AppColors.Budget.overBudget
        case .medium: AppColors.Budget.pending
        case .low: AppColors.Budget.allocated
        }
    }
}
