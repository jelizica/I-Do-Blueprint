//
//  BudgetSidebarView.swift
//  I Do Blueprint
//
//  Created by Claude on 10/12/25.
//  Simplified sidebar navigation for Budget section with collapsible groups
//

import SwiftUI

// MARK: - Budget Navigation Types

enum BudgetNavigationItem: Hashable, Identifiable {
    // Overview group
    case budgetDashboard
    case analyticsHub
    case accountCashFlow
    case budgetDevelopment
    case calculator

    // Expenses group
    case expenseTracker
    case expenseReports
    case expenseCategories

    // Payments group
    case paymentSchedule

    // Gifts & Owed group
    case moneyTracker
    case moneyReceived
    case moneyOwed

    var id: Self { self }

    var title: String {
        switch self {
        // Overview
        case .budgetDashboard: return "Budget Dashboard"
        case .analyticsHub: return "Analytics Hub"
        case .accountCashFlow: return "Account Cash Flow"
        case .budgetDevelopment: return "Budget Development"
        case .calculator: return "Calculator"

        // Expenses
        case .expenseTracker: return "Expense Tracker"
        case .expenseReports: return "Expense Reports"
        case .expenseCategories: return "Expense Categories"

        // Payments
        case .paymentSchedule: return "Payment Schedule"

        // Gifts & Owed
        case .moneyTracker: return "Money Tracker"
        case .moneyReceived: return "Money Received"
        case .moneyOwed: return "Money Owed"
        }
    }

    var icon: String {
        switch self {
        // Overview
        case .budgetDashboard: return "chart.bar.fill"
        case .analyticsHub: return "chart.xyaxis.line"
        case .accountCashFlow: return "chart.line.uptrend.xyaxis"
        case .budgetDevelopment: return "hammer.fill"
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
}

// NOTE: BudgetGroup enum moved to Domain/Models/Budget/BudgetPage.swift
// This file (BudgetSidebarView) is deprecated and will be removed after migration is complete
// Keeping BudgetNavigationItem temporarily for reference

/*
enum BudgetGroup: String, CaseIterable {
    case overview = "Overview"
    case expenses = "Expenses"
    case payments = "Payments"
    case giftsOwed = "Gifts & Owed"

    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .expenses: return "receipt.fill"
        case .payments: return "calendar.badge.clock"
        case .giftsOwed: return "dollarsign.circle.fill"
        }
    }

    var items: [BudgetNavigationItem] {
        switch self {
        case .overview:
            return [.budgetDashboard, .analyticsHub, .accountCashFlow, .budgetDevelopment, .calculator]
        case .expenses:
            return [.expenseTracker, .expenseReports, .expenseCategories]
        case .payments:
            return [.paymentSchedule]
        case .giftsOwed:
            return [.moneyTracker, .moneyReceived, .moneyOwed]
        }
    }

    var defaultItem: BudgetNavigationItem {
        switch self {
        case .overview: return .budgetDashboard
        case .expenses: return .expenseTracker
        case .payments: return .paymentSchedule
        case .giftsOwed: return .moneyTracker
        }
    }
}
*/

// MARK: - Sidebar View
// DEPRECATED: This view is no longer used. AppCoordinator now routes to BudgetDashboardHubView.
// Will be removed after migration is complete.

/*
struct BudgetSidebarView: View {
    @Binding var selection: BudgetNavigationItem
    @State private var expandedGroups: Set<BudgetGroup> = Set(BudgetGroup.allCases)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Budget")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            // List content
            List(selection: $selection) {
                ForEach(BudgetGroup.allCases, id: \.self) { group in
                    Section {
                        if expandedGroups.contains(group) {
                            ForEach(group.items) { item in
                                Button {
                                    selection = item
                                } label: {
                                    HStack {
                                        Label(item.title, systemImage: item.icon)
                                            .font(.system(size: 13))
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .background(selection == item ? Color.accentColor.opacity(0.15) : Color.clear)
                                .cornerRadius(6)
                                .accessibilityLabel(item.title)
                            }
                        }
                    } header: {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedGroups.contains(group) {
                                    expandedGroups.remove(group)
                                } else {
                                    expandedGroups.insert(group)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: group.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(SemanticColors.primaryAction)

                                Text(group.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(SemanticColors.textPrimary)

                                Spacer()

                                Image(systemName: expandedGroups.contains(group) ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(SemanticColors.textSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(group.rawValue) section")
                        .accessibilityHint(expandedGroups.contains(group) ? "Tap to collapse" : "Tap to expand")
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}

#Preview {
    NavigationSplitView {
        BudgetSidebarView(selection: .constant(.budgetDashboard))
    } detail: {
        Text("Select an item")
    }
}
*/
