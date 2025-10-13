import AppKit
import SwiftUI

struct BudgetOverviewView: View {
    @StateObject private var budgetStore = BudgetStoreV2()
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

                // Categories list
                if filteredAndSortedCategories.isEmpty {
                    ContentUnavailableView(
                        "No Budget Categories",
                        systemImage: "dollarsign.circle",
                        description: Text(searchText
                            .isEmpty ? "Add your first budget category to get started" :
                            "Try adjusting your search or filters"))
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
                .frame(minWidth: 600, maxWidth: 700, minHeight: 500, maxHeight: 650)
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
                VStack(spacing: 20) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Select a budget category")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("Choose a category from the sidebar to view details and manage expenses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await budgetStore.loadBudgetData()
        }
        .alert("Error", isPresented: .constant(budgetStore.error != nil)) {
            Button("OK") {
                budgetStore.error = nil
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
            .foregroundColor(.blue)
        }
    }
}

// MARK: - Supporting Views

struct BudgetSummaryHeaderView: View {
    let budgetStore: BudgetStoreV2
    let stats: BudgetStats

    var body: some View {
        VStack(spacing: 16) {
            // Main budget overview
            HStack(spacing: 20) {
                OverviewSummaryCard(
                    title: "Total Budget",
                    value: NumberFormatter.currency
                        .string(from: NSNumber(value: budgetStore.actualTotalBudget)) ?? "$0",
                    subtitle: nil,
                    color: .blue,
                    icon: "dollarsign.circle.fill")

                OverviewSummaryCard(
                    title: "Total Spent",
                    value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.totalSpent)) ?? "$0",
                    subtitle: String(format: "%.1f%% of budget", budgetStore.percentageSpent),
                    color: budgetStore.isOverBudget ? .red : .green,
                    icon: "creditcard.fill")

                OverviewSummaryCard(
                    title: "Remaining",
                    value: NumberFormatter.currency.string(from: NSNumber(value: budgetStore.remainingBudget)) ?? "$0",
                    subtitle: budgetStore.isOverBudget ? "Over budget" : "Available",
                    color: budgetStore.isOverBudget ? .red : .orange,
                    icon: "banknote.fill")
            }

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

                ProgressView(value: min(budgetStore.percentageSpent / 100, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: budgetStore.isOverBudget ? .red : .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding(.top, 8)

            // Quick stats
            HStack(spacing: 30) {
                QuickStatView(
                    title: "Categories",
                    value: "\(stats.totalCategories)",
                    subtitle: "\(stats.categoriesOverBudget) over budget",
                    icon: "folder.fill",
                    color: stats.categoriesOverBudget > 0 ? .red : .blue)

                QuickStatView(
                    title: "Expenses",
                    value: "\(stats.totalExpenses)",
                    subtitle: "\(stats.expensesPending) pending",
                    icon: "doc.text.fill",
                    color: stats.expensesOverdue > 0 ? .red : .green)

                if stats.expensesOverdue > 0 {
                    QuickStatView(
                        title: "Overdue",
                        value: "\(stats.expensesOverdue)",
                        subtitle: "Need attention",
                        icon: "exclamationmark.triangle.fill",
                        color: .red)
                }
            }
        }
    }
}

struct OverviewSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(minWidth: 140)
    }
}

struct QuickStatView: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

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
                .fill(Color(hex: category.color) ?? .blue)
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
                            .foregroundColor(enhancedCategory.isOverBudget ? .red : .primary)

                        Text(
                            "of \(NumberFormatter.currency.string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Progress bar
                ProgressView(value: min(enhancedCategory.projectedPercentageSpent / 100, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: enhancedCategory.isOverBudget ? .red : .blue))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)

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
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
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
        case .high: .red
        case .medium: .orange
        case .low: .blue
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
