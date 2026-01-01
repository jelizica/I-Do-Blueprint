//
//  BudgetDashboardHubView.swift
//  I Do Blueprint
//
//  Created by Qodo Gen on 1/1/26.
//  Central hub for budget navigation with toolbar dropdown
//

import SwiftUI

struct BudgetDashboardHubView: View {
    @State private var currentPage: BudgetPage = .dashboard
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

                // Content based on current page
                if currentPage == .dashboard {
                    // Dashboard hub content
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Dashboard header with stats
                            budgetDashboardSummary(windowSize: windowSize)
                                .frame(width: availableWidth)

                            // 4 Group Cards (2x2 grid or adaptive)
                            groupCardsGrid(windowSize: windowSize)
                                .frame(width: availableWidth)

                            // Quick Access section (hidden in compact)
                            if windowSize != .compact {
                                quickAccessSection
                                    .frame(width: availableWidth)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, Spacing.lg)
                    }
                } else {
                    // Show the selected page's view
                    currentPage.view
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                budgetPageDropdown
            }
        }
        .task {
            await budgetStore.loadBudgetData()
        }
    }

    // MARK: - Dashboard Summary

    @ViewBuilder
    private func budgetDashboardSummary(windowSize: WindowSize) -> some View {
        VStack(spacing: Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget Dashboard")
                        .font(Typography.displaySmall)

                    if windowSize != .compact {
                        Text("Your wedding budget at a glance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: {
                    Task {
                        await budgetStore.refresh()
                    }
                }) {
                    if windowSize == .compact {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .frame(width: windowSize == .compact ? 44 : nil, height: 44)
                .buttonStyle(.bordered)
                .help(windowSize == .compact ? "Refresh" : "")
            }

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

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Access")
                .font(.headline)
                .padding(.horizontal, Spacing.sm)

            VStack(spacing: Spacing.xs) {
                QuickAccessRow(page: .expenseTracker) {
                    currentPage = .expenseTracker
                }
                QuickAccessRow(page: .paymentSchedule) {
                    currentPage = .paymentSchedule
                }
                QuickAccessRow(page: .analytics) {
                    currentPage = .analytics
                }
            }
            .padding(Spacing.sm)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    // MARK: - Toolbar Dropdown

    private var budgetPageDropdown: some View {
        Menu {
            // Overview Group
            Section("Overview") {
                ForEach(BudgetGroup.overview.pages) { page in
                    Button {
                        currentPage = page
                    } label: {
                        Label(page.rawValue, systemImage: page.icon)
                        if currentPage == page {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            // Expenses Group
            Section("Expenses") {
                ForEach(BudgetGroup.expenses.pages) { page in
                    Button {
                        currentPage = page
                    } label: {
                        Label(page.rawValue, systemImage: page.icon)
                        if currentPage == page {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            // Payments Group
            Section("Payments") {
                ForEach(BudgetGroup.payments.pages) { page in
                    Button {
                        currentPage = page
                    } label: {
                        Label(page.rawValue, systemImage: page.icon)
                        if currentPage == page {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            // Gifts & Owed Group
            Section("Gifts & Owed") {
                ForEach(BudgetGroup.giftsOwed.pages) { page in
                    Button {
                        currentPage = page
                    } label: {
                        Label(page.rawValue, systemImage: page.icon)
                        if currentPage == page {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text("Budget: \(currentPage.rawValue)")
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
        .menuStyle(.borderlessButton)
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

struct QuickAccessRow: View {
    let page: BudgetPage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: page.icon)
                    .font(.system(size: 16))
                    .foregroundColor(page.group.color)
                    .frame(width: 24)

                Text(page.rawValue)
                    .font(.subheadline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
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
