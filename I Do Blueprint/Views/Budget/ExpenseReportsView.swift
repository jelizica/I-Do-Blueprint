import Charts
import SwiftUI

struct ExpenseReportsView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var selectedTab: ReportTab = .overview
    @State private var filters = FilterState()
    @State private var sortConfig = SortConfig(key: .date, direction: .desc)
    @State private var currentPage = 1
    @State private var showingExportOptions = false
    @State private var searchText = ""
    @State private var isExporting = false
    @State private var exportError: Error?

    private let itemsPerPage = 10
    private let exportService = BudgetExportService.shared

    // MARK: - Computed Properties

    private var transformedExpenses: [ExpenseItem] {
        budgetStore.expenses.map { expense in
            let category = budgetStore.categories.first { $0.id == expense.budgetCategoryId }
            return ExpenseItem(
                id: expense.id.uuidString,
                date: expense.expenseDate,
                description: expense.expenseName,
                category: category?.categoryName ?? "Uncategorized",
                vendor: expense.vendorName ?? "Unknown Vendor",
                amount: expense.amount,
                paymentStatus: expense.paymentStatus,
                paymentMethod: expense.paymentMethod ?? "Credit Card",
                notes: expense.notes)
        }
    }

    private var filteredExpenses: [ExpenseItem] {
        var filtered = transformedExpenses

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { expense in
                expense.description.localizedCaseInsensitiveContains(searchText) ||
                    expense.vendor.localizedCaseInsensitiveContains(searchText) ||
                    expense.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply category filter
        if filters.category != "All" {
            filtered = filtered.filter { $0.category == filters.category }
        }

        // Apply vendor filter
        if filters.vendor != "All" {
            filtered = filtered.filter { $0.vendor == filters.vendor }
        }

        // Apply payment status filter
        if filters.paymentStatus != "All" {
            filtered = filtered.filter { $0.paymentStatus.rawValue == filters.paymentStatus.lowercased() }
        }

        // Apply date range filter
        if filters.dateRange != .all {
            filtered = filtered.filter { expense in
                filters.dateRange.contains(expense.date)
            }
        }

        // Apply sorting
        filtered.sort { lhs, rhs in
            let ascending = sortConfig.direction == .asc

            switch sortConfig.key {
            case .date:
                return ascending ? lhs.date < rhs.date : lhs.date > rhs.date
            case .description:
                return ascending ? lhs.description < rhs.description : lhs.description > rhs.description
            case .category:
                return ascending ? lhs.category < rhs.category : lhs.category > rhs.category
            case .vendor:
                return ascending ? lhs.vendor < rhs.vendor : lhs.vendor > rhs.vendor
            case .amount:
                return ascending ? lhs.amount < rhs.amount : lhs.amount > rhs.amount
            }
        }

        return filtered
    }

    private var paginatedExpenses: [ExpenseItem] {
        let startIndex = (currentPage - 1) * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, filteredExpenses.count)
        return Array(filteredExpenses[startIndex ..< endIndex])
    }

    private var totalPages: Int {
        max(1, Int(ceil(Double(filteredExpenses.count) / Double(itemsPerPage))))
    }

    private var statistics: ExpenseStatistics {
        calculateStatistics()
    }

    private var categoryOptions: [String] {
        let categories = Array(Set(transformedExpenses.map(\.category))).sorted()
        return ["All"] + categories
    }

    private var vendorOptions: [String] {
        let vendors = Array(Set(transformedExpenses.map(\.vendor))).sorted()
        return ["All"] + vendors
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    ExpenseReportsHeader(
                        onExport: { showingExportOptions = true },
                        onRefresh: { await budgetStore.refreshBudgetData() })

                    // Filters
                    ExpenseReportsFilters(
                        searchText: $searchText,
                        filters: $filters,
                        categoryOptions: categoryOptions,
                        vendorOptions: vendorOptions)

                    // Statistics Cards
                    ExpenseStatisticsCards(statistics: statistics)

                    // Tabs
                    TabView(selection: $selectedTab) {
                        ExpenseReportsOverviewTab(
                            selectedTab: $selectedTab,
                            statistics: statistics)
                            .tag(ReportTab.overview)

                        ExpenseReportsChartsTab(
                            selectedTab: $selectedTab,
                            statistics: statistics)
                            .tag(ReportTab.charts)

                        ExpenseReportsTableTab(
                            selectedTab: $selectedTab,
                            sortConfig: $sortConfig,
                            currentPage: $currentPage,
                            paginatedExpenses: paginatedExpenses,
                            filteredExpensesCount: filteredExpenses.count,
                            itemsPerPage: itemsPerPage,
                            totalPages: totalPages)
                            .tag(ReportTab.table)
                    }
                    #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    #endif
                    .frame(minHeight: 600)
                }
                .padding()
            }
            .navigationTitle("Expense Reports")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
            #endif
                                .sheet(isPresented: $showingExportOptions) {
                    ExpenseExportOptionsView(expenses: budgetStore.expenses, categories: budgetStore.categories)
                }
        }
    }

    // MARK: - Helper Methods

    private func calculateStatistics() -> ExpenseStatistics {
        let totalExpenses = filteredExpenses.reduce(0) { $0 + $1.amount }
        let transactionCount = filteredExpenses.count
        let averageAmount = transactionCount > 0 ? totalExpenses / Double(transactionCount) : 0

        // Category breakdown
        let categoryTotals = Dictionary(grouping: filteredExpenses, by: { $0.category })
            .mapValues { expenses in expenses.reduce(0) { $0 + $1.amount } }

        let categoryData = categoryTotals.map { name, amount in
            let color = budgetStore.categories.first { $0.categoryName == name }?.color ?? "#3B82F6"
            return CategoryData(name: name, amount: amount, color: color)
        }.sorted { $0.amount > $1.amount }

        let topCategory = categoryData.first ?? CategoryData(name: "None", amount: 0, color: "#3B82F6")

        // Vendor breakdown
        let vendorTotals = Dictionary(grouping: filteredExpenses, by: { $0.vendor })
            .mapValues { expenses in expenses.reduce(0) { $0 + $1.amount } }

        let vendorData = vendorTotals.map { name, amount in
            VendorData(name: name, amount: amount)
        }.sorted { $0.amount > $1.amount }

        // Monthly data
        let monthlyTotals = Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        }.mapValues { expenses in
            expenses.reduce(0) { $0 + $1.amount }
        }

        let monthlyData = monthlyTotals.map { date, amount in
            MonthlyData(month: date, amount: amount)
        }.sorted { $0.month < $1.month }

        // Status counts
        let statusCounts = StatusCounts(
            paid: filteredExpenses.filter { $0.paymentStatus == .paid }.count,
            pending: filteredExpenses.filter { $0.paymentStatus == .pending }.count,
            overdue: filteredExpenses.filter { $0.paymentStatus == .overdue }.count,
            cancelled: filteredExpenses.filter { $0.paymentStatus == .cancelled }.count)

        return ExpenseStatistics(
            totalExpenses: totalExpenses,
            transactionCount: transactionCount,
            averageAmount: averageAmount,
            topCategory: topCategory,
            categoryData: categoryData,
            vendorData: vendorData,
            monthlyData: monthlyData,
            statusCounts: statusCounts)
    }
}

// MARK: - Data Models

struct ExpenseItem {
    let id: String
    let date: Date
    let description: String
    let category: String
    let vendor: String
    let amount: Double
    let paymentStatus: PaymentStatus
    let paymentMethod: String
    let notes: String?
}

enum PaymentStatusOption: String, CaseIterable {
    case all = "All"
    case paid
    case pending
    case overdue
    case cancelled

    var displayName: String {
        switch self {
        case .all: "All"
        case .paid: "Paid"
        case .pending: "Pending"
        case .overdue: "Overdue"
        case .cancelled: "Cancelled"
        }
    }
}

struct FilterState {
    var category: String = "All"
    var vendor: String = "All"
    var paymentStatus: String = "All"
    var dateRange: DateRange = .all
}

enum DateRange: String, CaseIterable {
    case all
    case last30
    case last90
    case thisYear

    var displayName: String {
        switch self {
        case .all: "All Time"
        case .last30: "Last 30 Days"
        case .last90: "Last 90 Days"
        case .thisYear: "This Year"
        }
    }

    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .all:
            return true
        case .last30:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return date >= thirtyDaysAgo
        case .last90:
            let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            return date >= ninetyDaysAgo
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

enum SortKey {
    case date, description, category, vendor, amount
}

struct SortConfig {
    var key: SortKey
    var direction: SortDirection
}

enum SortDirection {
    case asc, desc
}

enum ReportTab: String, CaseIterable {
    case overview
    case charts
    case table

    var displayName: String {
        switch self {
        case .overview: "Overview"
        case .charts: "Charts"
        case .table: "Table"
        }
    }
}

struct ExpenseStatistics {
    let totalExpenses: Double
    let transactionCount: Int
    let averageAmount: Double
    let topCategory: CategoryData
    let categoryData: [CategoryData]
    let vendorData: [VendorData]
    let monthlyData: [MonthlyData]
    let statusCounts: StatusCounts
}

struct CategoryData {
    let name: String
    let amount: Double
    let color: String
}

struct VendorData {
    let name: String
    let amount: Double
}

struct MonthlyData {
    let month: Date
    let amount: Double
}

struct StatusCounts {
    let paid: Int
    let pending: Int
    let overdue: Int
    let cancelled: Int

    func count(for status: PaymentStatus) -> Int {
        switch status {
        case .paid: paid
        case .pending: pending
        case .overdue: overdue
        case .cancelled: cancelled
        case .partial: 0
        case .refunded: 0
        }
    }
}
