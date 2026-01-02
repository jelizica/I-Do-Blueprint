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
    // Hub (special case - not in a group)
    case hub = "Dashboard"
    
    // Planning & Analysis Group (5 pages)
    case budgetOverview = "Budget Overview"
    case budgetBuilder = "Budget Builder"
    case analytics = "Analytics Hub"
    case cashFlow = "Account Cash Flow"
    case calculator = "Calculator"

    // Expenses Group (4 pages - includes Payment Schedule)
    case expenseTracker = "Expense Tracker"
    case expenseReports = "Expense Reports"
    case expenseCategories = "Expense Categories"
    case paymentSchedule = "Payment Schedule"

    // Income Group (3 pages - renamed from Gifts & Owed)
    case moneyTracker = "Money Tracker"
    case moneyReceived = "Money Received"
    case moneyOwed = "Money Owed"

    var id: String { rawValue }

    var group: BudgetGroup? {
        switch self {
        case .hub:
            return nil  // Hub is not in a group
        case .budgetOverview, .budgetBuilder, .analytics, .cashFlow, .calculator:
            return .planningAnalysis
        case .expenseTracker, .expenseReports, .expenseCategories, .paymentSchedule:
            return .expenses
        case .moneyTracker, .moneyReceived, .moneyOwed:
            return .income
        }
    }

    var icon: String {
        switch self {
        // Hub
        case .hub: return "square.grid.2x2.fill"
        
        // Planning & Analysis
        case .budgetOverview: return "chart.bar.fill"
        case .budgetBuilder: return "hammer.fill"
        case .analytics: return "chart.xyaxis.line"
        case .cashFlow: return "chart.line.uptrend.xyaxis"
        case .calculator: return "function"

        // Expenses
        case .expenseTracker: return "receipt.fill"
        case .expenseReports: return "chart.bar.doc.horizontal.fill"
        case .expenseCategories: return "folder.fill"
        case .paymentSchedule: return "calendar.badge.clock"

        // Income
        case .moneyTracker: return "dollarsign.circle.fill"
        case .moneyReceived: return "arrow.down.circle.fill"
        case .moneyOwed: return "arrow.up.circle.fill"
        }
    }

    @ViewBuilder
    func view(currentPage: Binding<BudgetPage>) -> some View {
        switch self {
        // Hub
        case .hub:
            EmptyView()  // Hub is handled separately in BudgetDashboardHubView
        
        // Planning & Analysis group
        case .budgetOverview:
            BudgetOverviewDashboardViewV2(currentPage: currentPage)
        case .budgetBuilder:
            BudgetDevelopmentView(currentPage: currentPage)
        case .analytics:
            BudgetAnalyticsView()
        case .cashFlow:
            BudgetCashFlowView()
        case .calculator:
            BudgetCalculatorView()

        // Expenses group
        case .expenseTracker:
            ExpenseTrackerView(currentPage: currentPage)
        case .expenseReports:
            ExpenseReportsView()
        case .expenseCategories:
            ExpenseCategoriesView()
        case .paymentSchedule:
            PaymentScheduleView()

        // Income group
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
    case planningAnalysis = "Planning & Analysis"
    case expenses = "Expenses"
    case income = "Income"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .planningAnalysis: return AppColors.Budget.allocated
        case .expenses: return AppColors.Budget.overBudget
        case .income: return AppColors.Budget.income
        }
    }

    var icon: String {
        switch self {
        case .planningAnalysis: return "chart.bar.fill"
        case .expenses: return "creditcard.fill"
        case .income: return "dollarsign.circle.fill"
        }
    }

    var pages: [BudgetPage] {
        BudgetPage.allCases.filter { $0.group == self }
    }

    var defaultPage: BudgetPage {
        switch self {
        case .planningAnalysis: return .budgetOverview
        case .expenses: return .expenseTracker
        case .income: return .moneyTracker
        }
    }

    var description: String {
        switch self {
        case .planningAnalysis:
            return "Planning and analysis tools"
        case .expenses:
            return "Track spending and payments"
        case .income:
            return "Monitor gifts and money owed"
        }
    }
}
