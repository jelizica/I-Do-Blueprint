import AppKit
import SwiftUI

struct BudgetOverviewView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var selectedCategory: BudgetCategory?
    @State private var showingAddCategory = false
    @State private var showingAddExpense = false
    @State private var selectedFilterOption: BudgetFilterOption = .all
    @State private var selectedSortOption: BudgetSortOption = .category
    @State private var sortAscending = true
    @State private var searchText = ""

    var filteredAndSortedCategories: [BudgetCategory] {
        let filtered = budgetStore.filteredCategories(by: selectedFilterOption).filter { category in
            searchText.isEmpty || category.categoryName.localizedCaseInsensitiveContains(searchText)
        }
        return budgetStore.sortedCategories(filtered, by: selectedSortOption, ascending: sortAscending)
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Budget summary header
                BudgetSummaryHeaderView(budgetStore: budgetStore, stats: budgetStore.stats)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))

                // Search and filters
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search categories...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Filter and sort controls
                    HStack {
                        // Filter picker
                        Picker("Filter", selection: $selectedFilterOption) {
                            ForEach(BudgetFilterOption.allCases, id: \.self) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer()

                        // Sort controls
                        sortMenu
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Categories list - Using Component Library
                if filteredAndSortedCategories.isEmpty {
                    UnifiedEmptyStateView(
                        config: searchText.isEmpty ?
                            .custom(
                                icon: "dollarsign.circle",
                                title: "No Budget Categories",
                                message: "Add your first budget category to get started",
                                actionTitle: "Add Category",
                                onAction: { showingAddCategory = true }
                            ) :
                            .searchResults(query: searchText)
                    )
                    .padding()
                } else {
                    List(filteredAndSortedCategories, selection: $selectedCategory) { category in
                        NavigationLink(value: category) {
                            BudgetCategoryRowView(category: category, budgetStore: budgetStore)
                        }
                        .tag(category)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Label("Add Category", systemImage: "folder.badge.plus")
                        }

                        Button(action: {
                            showingAddExpense = true
                        }) {
                            Label("Add Expense", systemImage: "plus.circle")
                        }

                        Divider()

                        Button(action: {
                            Task {
                                await budgetStore.refreshBudgetData()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddBudgetCategoryView { newCategory in
                    Task {
                        await budgetStore.addBudgetCategory(newCategory)
                    }
                }
                #if os(macOS)
                .frame(minWidth: 500, maxWidth: 600, minHeight: 400, maxHeight: 500)
                #endif
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(categories: budgetStore.categories) { newExpense in
                    Task {
                        await budgetStore.addExpense(newExpense)
                    }
                }
                #if os(macOS)
                .frame(minWidth: 700, idealWidth: 750, maxWidth: 800, minHeight: 650, idealHeight: 750, maxHeight: 850)
                #endif
            }
        } detail: {
            if let category = selectedCategory {
                BudgetCategoryDetailView(
                    category: category,
                    expenses: budgetStore.expenses.filter { $0.categoryId == category.id },
                    onUpdateCategory: { updatedCategory in
                        Task {
                            await budgetStore.updateBudgetCategory(updatedCategory)
                        }
                    },
                    onAddExpense: { expense in
                        Task {
                            await budgetStore.addExpense(expense)
                        }
                    },
                    onUpdateExpense: { expense in
                        Task {
                            do {
                                _ = try await budgetStore.updateExpense(expense)
                            } catch {
                                AppLogger.ui.error("Failed to update expense", error: error)
                            }
                        }
                    })
                    .id(category.id)
            } else {
                // Using Component Library Empty State
                UnifiedEmptyStateView(
                    config: .custom(
                        icon: "dollarsign.circle.fill",
                        title: "Select a budget category",
                        message: "Choose a category from the sidebar to view details and manage expenses",
                        actionTitle: nil,
                        onAction: nil
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await budgetStore.loadBudgetData()
        }
        .alert("Error", isPresented: Binding(
            get: { budgetStore.error != nil },
            set: { if !$0 { /* Error is read-only, dismiss by retrying */ } }
        )) {
            Button("OK") {
                // Error will be cleared on next successful load
            }
            if budgetStore.error != nil {
                Button("Retry") {
                    Task {
                        await budgetStore.retryLoad()
                    }
                }
            }
        } message: {
            if let error = budgetStore.error {
                Text(error.errorDescription ?? "Unknown error")
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(BudgetSortOption.allCases, id: \.self) { option in
                Button(action: {
                    if selectedSortOption == option {
                        sortAscending.toggle()
                    } else {
                        selectedSortOption = option
                        sortAscending = true
                    }
                }) {
                    HStack {
                        Text(option.displayName)
                        if selectedSortOption == option {
                            Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text("Sort")
                Image(systemName: "arrow.up.arrow.down")
            }
            .foregroundColor(AppColors.Budget.allocated)
        }
    }
}

// MARK: - Supporting Views

struct BudgetSummaryHeaderView: View {
    let budgetStore: BudgetStoreV2
    let stats: BudgetStats

    var body: some View {
        VStack(spacing: 16) {
            // Main budget overview - Using Component Library
            StatsGridView(
                stats: [
                    StatItem(
                        icon: "dollarsign.circle.fill",
                        label: "Total Budget",
                        value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.actualTotalBudget)) ?? "$0",
                        color: AppColors.Budget.allocated
                    ),
                    StatItem(
                        icon: "creditcard.fill",
                        label: "Total Spent",
                        value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.totalSpent)) ?? "$0",
                        color: budgetStore.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.underBudget,
                        trend: .neutral
                    ),
                    StatItem(
                        icon: "banknote.fill",
                        label: "Remaining",
                        value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.remainingBudget)) ?? "$0",
                        color: budgetStore.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.pending
                    )
                ],
                columns: 3
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
            .padding(.top, 8)

            // Quick stats - Using Component Library
            HStack(spacing: 30) {
                CompactSummaryCard(
                    title: "Categories",
                    value: "\(stats.totalCategories)",
                    subtitle: "\(stats.categoriesOverBudget) over budget",
                    icon: "folder.fill",
                    color: stats.categoriesOverBudget > 0 ? AppColors.Budget.overBudget : AppColors.Budget.allocated
                )

                CompactSummaryCard(
                    title: "Expenses",
                    value: "\(stats.totalExpenses)",
                    subtitle: "\(stats.expensesPending) pending",
                    icon: "doc.text.fill",
                    color: stats.expensesOverdue > 0 ? AppColors.Budget.overBudget : AppColors.Budget.income
                )

                if stats.expensesOverdue > 0 {
                    CompactSummaryCard(
                        title: "Overdue",
                        value: "\(stats.expensesOverdue)",
                        subtitle: "Need attention",
                        icon: "exclamationmark.triangle.fill",
                        color: AppColors.Budget.overBudget
                    )
                }
            }
        }
    }
}

// Note: OverviewSummaryCard replaced with StatsGridView from component library
// Note: QuickStatView replaced with CompactSummaryCard from component library

struct BudgetCategoryRowView: View {
    let category: BudgetCategory
    let budgetStore: BudgetStoreV2

    private var enhancedCategory: EnhancedBudgetCategory {
        budgetStore.enhancedCategory(category)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category color indicator
            Circle()
                .fill(Color(hex: category.color) ?? AppColors.Budget.allocated)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.categoryName)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(NumberFormatter.currency
                            .string(from: NSNumber(value: enhancedCategory.projectedSpending)) ?? "$0")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(enhancedCategory.isOverBudget ? AppColors.Budget.overBudget : .primary)

                        Text(
                            "of \(NumberFormatter.currency.string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Progress bar
                ProgressBar(
                    value: min(enhancedCategory.projectedPercentageSpent / 100, 1.0),
                    color: enhancedCategory.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.allocated,
                    height: 6
                )

                HStack {
                    // Priority badge
                    Text(category.priority.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor(category.priority).opacity(0.2))
                        .foregroundColor(priorityColor(category.priority))
                        .clipShape(Capsule())

                    if category.isEssential {
                        Text("Essential")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.Budget.income.opacity(0.2))
                            .foregroundColor(AppColors.Budget.income)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text("\(Int(enhancedCategory.projectedPercentageSpent))% projected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func priorityColor(_ priority: BudgetPriority) -> Color {
        switch priority {
        case .high: AppColors.Budget.overBudget
        case .medium: AppColors.Budget.pending
        case .low: AppColors.Budget.allocated
        }
    }
}

// MARK: - Extensions

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255
            b = CGFloat(rgb & 0x0000FF) / 255
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF00_0000) >> 24) / 255
            g = CGFloat((rgb & 0x00FF_0000) >> 16) / 255
            b = CGFloat((rgb & 0x0000_FF00) >> 8) / 255
            a = CGFloat(rgb & 0x0000_00FF) / 255
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

#Preview {
    BudgetOverviewView()
}
