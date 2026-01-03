//
//  BudgetDashboardHubView.swift
//  I Do Blueprint
//
//  Created by Qodo Gen on 1/1/26.
//  Central hub for budget navigation with toolbar dropdown
//

import SwiftUI

struct BudgetDashboardHubView: View {
    @State private var currentPage: BudgetPage = .hub
    @EnvironmentObject var budgetStore: BudgetStoreV2

    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
            let availableWidth = geometry.size.width - (horizontalPadding * 2)

            ZStack {
                // Background
                Color(NSColor.windowBackgroundColor)
                    .ignoresSafeArea()

                if currentPage == .hub {
                    // Hub page with its own ScrollView
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Standardized header (persists across ALL pages)
                            BudgetManagementHeader(
                                windowSize: windowSize,
                                currentPage: $currentPage
                            )

                            // Dashboard hub content
                            VStack(spacing: Spacing.xl) {
                                // Dashboard stats summary
                                budgetStatsSummary(windowSize: windowSize)
                                    .frame(width: availableWidth)

                                // 3 Group Cards
                                groupCardsGrid(windowSize: windowSize)
                                    .frame(width: availableWidth)

                                // Quick Access section (optimized layout)
                                if windowSize != .compact {
                                    quickAccessSection(windowSize: windowSize)
                                        .frame(width: availableWidth)
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
                    }
                } else {
                    // Child pages render their own content (they have their own ScrollView/GeometryReader)
                    VStack(spacing: 0) {
                        // Budget Builder, Budget Overview, Expense Tracker, Payment Schedule, and Expense Categories have their own unified headers, other pages use standard header
                        if currentPage != .budgetBuilder && currentPage != .budgetOverview && currentPage != .expenseTracker && currentPage != .paymentSchedule && currentPage != .expenseCategories {
                            BudgetManagementHeader(
                                windowSize: windowSize,
                                currentPage: $currentPage
                            )
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
                        }
                        
                        // Child page content fills remaining space
                        // Pass currentPage binding to all child views for navigation
                        currentPage.view(currentPage: $currentPage)
                    }
                }
            }
        }
        .task {
            await budgetStore.loadBudgetData()
        }
    }

    // MARK: - Budget Stats Summary

    @ViewBuilder
    private func budgetStatsSummary(windowSize: WindowSize) -> some View {
        VStack(spacing: Spacing.lg) {
            // Stats Grid
            StatsGridView(
                stats: [
                    StatItem(
                        icon: "dollarsign.circle.fill",
                        label: "Total Budget",
                        value: NumberFormatter.currencyShort.string(from: NSNumber(value: budgetStore.actualTotalBudget)) ?? "$0",
                        color: AppColors.Budget.allocated
                    ),
                    StatItem(
                        icon: "creditcard.fill",
                        label: "Total Spent",
                        value: NumberFormatter.currencyShort.string(from: NSNumber(value: budgetStore.totalSpent)) ?? "$0",
                        color: budgetStore.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.underBudget
                    ),
                    StatItem(
                        icon: "banknote.fill",
                        label: "Remaining",
                        value: NumberFormatter.currencyShort.string(from: NSNumber(value: budgetStore.remainingBudget)) ?? "$0",
                        color: budgetStore.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.pending
                    )
                ],
                columns: windowSize == .compact ? 2 : 3
            )

            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Budget Progress")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(budgetStore.percentageSpent))% spent")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressBar(
                    value: min(budgetStore.percentageSpent / 100, 1.0),
                    color: budgetStore.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.allocated,
                    height: 8
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Group Cards Grid

    @ViewBuilder
    private func groupCardsGrid(windowSize: WindowSize) -> some View {
        let columns: [GridItem] = {
            if windowSize == .compact {
                return [GridItem(.flexible())]
            } else {
                return [GridItem(.flexible()), GridItem(.flexible())]
            }
        }()

        LazyVGrid(columns: columns, spacing: Spacing.lg) {
            ForEach(BudgetGroup.allCases) { group in
                BudgetGroupCard(group: group) {
                    currentPage = group.defaultPage
                }
            }
        }
    }

    // MARK: - Quick Access Section

    @ViewBuilder
    private func quickAccessSection(windowSize: WindowSize) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Access")
                .font(.headline)

            // Horizontal grid layout (2x2 for regular, 4 columns for large)
            let columns: [GridItem] = {
                if windowSize == .large {
                    return Array(repeating: GridItem(.flexible()), count: 4)
                } else {
                    return Array(repeating: GridItem(.flexible()), count: 2)
                }
            }()

            LazyVGrid(columns: columns, spacing: Spacing.md) {
                QuickAccessCard(page: .budgetOverview) {
                    currentPage = .budgetOverview
                }
                QuickAccessCard(page: .expenseTracker) {
                    currentPage = .expenseTracker
                }
                QuickAccessCard(page: .paymentSchedule) {
                    currentPage = .paymentSchedule
                }
                QuickAccessCard(page: .analytics) {
                    currentPage = .analytics
                }
            }
        }
    }

}

// MARK: - Supporting Views

struct BudgetGroupCard: View {
    let group: BudgetGroup
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: group.icon)
                        .font(.system(size: 32))
                        .foregroundColor(group.color)

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(group.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(group.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Text("\(group.pages.count) pages")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, Spacing.xxs)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(group.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(group.rawValue) section")
        .accessibilityHint("Navigate to \(group.description)")
    }
}

struct QuickAccessCard: View {
    let page: BudgetPage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: page.icon)
                        .font(.system(size: 20))
                        .foregroundColor(page.group?.color ?? AppColors.Budget.allocated)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(page.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(page.rawValue)
    }
}

// MARK: - Preview

#Preview {
    BudgetDashboardHubView()
        .environmentObject(BudgetStoreV2())
        .frame(width: 1000, height: 800)
}
