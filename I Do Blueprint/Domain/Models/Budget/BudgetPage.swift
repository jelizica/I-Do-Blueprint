//
//  BudgetPage.swift
//  I Do Blueprint
//
//  Created by Qodo Gen on 1/1/26.
//  Centralized navigation state for Budget module
//

import SwiftUI

// MARK: - Budget Page Enum

enum BudgetPage: String, CaseIterable, Identifiable {
    // Overview Group (5 pages)
    case dashboard = "Budget Dashboard"
    case analytics = "Analytics Hub"
    case cashFlow = "Account Cash Flow"
    case development = "Budget Development"
    case calculator = "Calculator"

    // Expenses Group (3 pages)
    case expenseTracker = "Expense Tracker"
    case expenseReports = "Expense Reports"
    case expenseCategories = "Expense Categories"

    // Payments Group (1 page)
    case paymentSchedule = "Payment Schedule"

    // Gifts & Owed Group (3 pages)
    case moneyTracker = "Money Tracker"
    case moneyReceived = "Money Received"
    case moneyOwed = "Money Owed"

    var id: String { rawValue }

    var group: BudgetGroup {
        switch self {
        case .dashboard, .analytics, .cashFlow, .development, .calculator:
            return .overview
        case .expenseTracker, .expenseReports, .expenseCategories:
            return .expenses
        case .paymentSchedule:
            return .payments
        case .moneyTracker, .moneyReceived, .moneyOwed:
            return .giftsOwed
        }
    }

    var icon: String {
        switch self {
        // Overview
        case .dashboard: return "chart.bar.fill"
        case .analytics: return "chart.xyaxis.line"
        case .cashFlow: return "chart.line.uptrend.xyaxis"
        case .development: return "hammer.fill"
        case .calculator: return "function"

        // Expenses
        case .expenseTracker: return "receipt.fill"
        case .expenseReports: return "chart.bar.doc.horizontal.fill"
        case .expenseCategories: return "folder.fill"

        // Payments
        case .paymentSchedule: return "calendar.badge.clock"

        // Gifts & Owed
        case .moneyTracker: return "dollarsign.circle.fill"
        case .moneyReceived: return "arrow.down.circle.fill"
        case .moneyOwed: return "arrow.up.circle.fill"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        // Overview group
        case .dashboard:
            BudgetOverviewDashboardViewV2()
        case .analytics:
            BudgetAnalyticsView()
        case .cashFlow:
            BudgetCashFlowView()
        case .development:
            BudgetDevelopmentView()
        case .calculator:
            BudgetCalculatorView()

        // Expenses group
        case .expenseTracker:
            ExpenseTrackerView()
        case .expenseReports:
            ExpenseReportsView()
        case .expenseCategories:
            ExpenseCategoriesView()

        // Payments group
        case .paymentSchedule:
            PaymentScheduleView()

        // Gifts & Owed group
        case .moneyTracker:
            GiftsAndOwedView()
        case .moneyReceived:
            MoneyReceivedViewV2()
        case .moneyOwed:
            MoneyOwedView()
        }
    }
}

// MARK: - Budget Group Enum

enum BudgetGroup: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case expenses = "Expenses"
    case payments = "Payments"
    case giftsOwed = "Gifts & Owed"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .overview: return AppColors.Budget.allocated
        case .expenses: return AppColors.Budget.overBudget
        case .payments: return AppColors.Budget.income
        case .giftsOwed: return AppColors.Budget.pending
        }
    }

    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .expenses: return "receipt.fill"
        case .payments: return "calendar.badge.clock"
        case .giftsOwed: return "dollarsign.circle.fill"
        }
    }

    var pages: [BudgetPage] {
        BudgetPage.allCases.filter { $0.group == self }
    }

    var defaultPage: BudgetPage {
        switch self {
        case .overview: return .dashboard
        case .expenses: return .expenseTracker
        case .payments: return .paymentSchedule
        case .giftsOwed: return .moneyTracker
        }
    }

    var description: String {
        switch self {
        case .overview:
            return "Dashboard, analytics, and budget planning tools"
        case .expenses:
            return "Track and categorize wedding expenses"
        case .payments:
            return "Manage payment schedules and deadlines"
        case .giftsOwed:
            return "Track gifts received and money owed"
        }
    }
}
