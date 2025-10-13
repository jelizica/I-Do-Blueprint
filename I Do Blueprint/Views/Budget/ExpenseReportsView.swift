import Charts
import SwiftUI

struct ExpenseReportsView: View {
    @StateObject private var budgetStore = BudgetStoreV2()
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
                    headerSection

                    // Filters
                    filtersSection

                    // Statistics Cards
                    statisticsSection

                    // Tabs
                    TabView(selection: $selectedTab) {
                        overviewTab
                            .tag(ReportTab.overview)

                        chartsTab
                            .tag(ReportTab.charts)

                        tableTab
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
                .task {
                    await budgetStore.loadBudgetData()
                }
                .sheet(isPresented: $showingExportOptions) {
                    ExportOptionsView(expenses: budgetStore.expenses, categories: budgetStore.categories)
                }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Expense Reports")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Manage and analyze your wedding budget expenses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { showingExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                }

                Button(action: { Task { await budgetStore.refreshBudgetData() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
            }
        }
    }

    private var filtersSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.blue)
                Text("Filters")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search expenses...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                }

                // Filter pickers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Category", selection: $filters.category) {
                            ForEach(categoryOptions, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vendor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Vendor", selection: $filters.vendor) {
                            ForEach(vendorOptions, id: \.self) { vendor in
                                Text(vendor).tag(vendor)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Payment Status", selection: $filters.paymentStatus) {
                            ForEach(PaymentStatusOption.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date Range")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Date Range", selection: $filters.dateRange) {
                            ForEach(DateRange.allCases, id: \.self) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
        .padding()
        .background(Color(.quaternarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statisticsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatisticCard(
                title: "Total Expenses",
                value: statistics.totalExpenses.formatted(.currency(code: "USD")),
                subtitle: "\(statistics.transactionCount) transactions",
                color: .blue,
                icon: "receipt.fill")

            StatisticCard(
                title: "Average Transaction",
                value: statistics.averageAmount.formatted(.currency(code: "USD")),
                subtitle: "per expense",
                color: .green,
                icon: "chart.line.uptrend.xyaxis")

            StatisticCard(
                title: "Top Category",
                value: statistics.topCategory.name,
                subtitle: statistics.topCategory.amount.formatted(.currency(code: "USD")),
                color: .orange,
                icon: "tag.fill")

            StatisticCard(
                title: "Payment Status",
                value: "\(statistics.statusCounts.paid) Paid",
                subtitle: "\(statistics.statusCounts.pending) Pending",
                color: .purple,
                icon: "checkmark.circle.fill")
        }
    }

    private var overviewTab: some View {
        VStack(spacing: 20) {
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                Text("Overview").tag(ReportTab.overview)
                Text("Charts").tag(ReportTab.charts)
                Text("Table").tag(ReportTab.table)
            }
            .pickerStyle(.segmented)

            VStack(spacing: 16) {
                // Category Pie Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Expenses by Category")
                        .font(.headline)

                    Chart(statistics.categoryData, id: \.name) { data in
                        SectorMark(
                            angle: .value("Amount", data.amount),
                            innerRadius: .ratio(0.4),
                            angularInset: 2)
                            .foregroundStyle(Color(hex: data.color) ?? .blue)
                            .opacity(0.8)
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Monthly Trend
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Spending Trend")
                        .font(.headline)

                    Chart(statistics.monthlyData, id: \.month) { data in
                        LineMark(
                            x: .value("Month", data.month, unit: .month),
                            y: .value("Amount", data.amount))
                            .foregroundStyle(.blue)
                            .symbol(.circle)

                        AreaMark(
                            x: .value("Month", data.month, unit: .month),
                            y: .value("Amount", data.amount))
                            .foregroundStyle(.blue.opacity(0.3))
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var chartsTab: some View {
        VStack(spacing: 20) {
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                Text("Overview").tag(ReportTab.overview)
                Text("Charts").tag(ReportTab.charts)
                Text("Table").tag(ReportTab.table)
            }
            .pickerStyle(.segmented)

            VStack(spacing: 16) {
                // Top Vendors Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Vendors by Spending")
                        .font(.headline)

                    Chart(statistics.vendorData.prefix(10), id: \.name) { data in
                        BarMark(
                            x: .value("Amount", data.amount),
                            y: .value("Vendor", data.name))
                            .foregroundStyle(.orange)
                    }
                    .frame(height: 300)
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Payment Status Distribution
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Status Distribution")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ForEach(PaymentStatus.allCases, id: \.self) { status in
                            let count = statistics.statusCounts.count(for: status)
                            let percentage = statistics.transactionCount > 0 ?
                                Double(count) / Double(statistics.transactionCount) * 100 : 0

                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.blue)

                                Text(status.displayName)
                                    .font(.subheadline)

                                Spacer()

                                Text("\(count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                ProgressView(value: percentage / 100)
                                    .frame(width: 60)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var tableTab: some View {
        VStack(spacing: 20) {
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                Text("Overview").tag(ReportTab.overview)
                Text("Charts").tag(ReportTab.charts)
                Text("Table").tag(ReportTab.table)
            }
            .pickerStyle(.segmented)

            VStack(spacing: 16) {
                // Table Header
                HStack {
                    Text("Expense Details")
                        .font(.headline)

                    Spacer()

                    Text(
                        "Showing \((currentPage - 1) * itemsPerPage + 1) to \(min(currentPage * itemsPerPage, filteredExpenses.count)) of \(filteredExpenses.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Table
                VStack(spacing: 0) {
                    // Header Row
                    HStack {
                        sortableHeader("Date", key: .date)
                        sortableHeader("Description", key: .description)
                        sortableHeader("Category", key: .category)
                        sortableHeader("Vendor", key: .vendor)
                        sortableHeader("Amount", key: .amount)
                        Text("Status")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 80)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemFill))

                    Divider()

                    // Data Rows
                    LazyVStack(spacing: 0) {
                        ForEach(paginatedExpenses, id: \.id) { expense in
                            HStack {
                                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .frame(width: 80, alignment: .leading)

                                Text(expense.description)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(expense.category)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(.quaternarySystemFill))
                                    .clipShape(Capsule())
                                    .frame(width: 100)

                                Text(expense.vendor)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(width: 100, alignment: .leading)

                                Text(expense.amount.formatted(.currency(code: "USD")))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(width: 80, alignment: .trailing)

                                PaymentStatusBadge(status: expense.paymentStatus)
                                    .frame(width: 80)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)

                            if expense.id != paginatedExpenses.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .background(Color(.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Pagination
                if totalPages > 1 {
                    paginationControls
                }
            }
        }
    }

    private func sortableHeader(_ title: String, key: SortKey) -> some View {
        Button(action: {
            if sortConfig.key == key {
                sortConfig.direction = sortConfig.direction == .asc ? .desc : .asc
            } else {
                sortConfig.key = key
                sortConfig.direction = .asc
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Image(systemName: sortConfig.key == key ?
                    (sortConfig.direction == .asc ? "chevron.up" : "chevron.down") :
                    "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundColor(sortConfig.key == key ? .blue : .secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var paginationControls: some View {
        HStack {
            Button("Previous") {
                currentPage = max(currentPage - 1, 1)
            }
            .disabled(currentPage == 1)

            Spacer()

            HStack(spacing: 8) {
                ForEach(1 ... min(totalPages, 5), id: \.self) { page in
                    Button("\(page)") {
                        currentPage = page
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(page == currentPage)
                }
            }

            Spacer()

            Button("Next") {
                currentPage = min(currentPage + 1, totalPages)
            }
            .disabled(currentPage == totalPages)
        }
        .padding()
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

// MARK: - Supporting Views

struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// PaymentStatusBadge is defined in BudgetCategoryDetailView.swift

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let expenses: [Expense]
    let categories: [BudgetCategory]

    @State private var isExporting = false
    @State private var exportError: Error?
    private let exportService = BudgetExportService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export Options")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 16) {
                    ExportOptionButton(
                        title: "Export as PDF",
                        description: "Generate a formatted PDF report",
                        icon: "doc.fill",
                        color: .red) {
                        Task {
                            isExporting = true
                            do {
                                let fileURL = try await exportService.exportExpenses(
                                    expenses: expenses,
                                    categories: categories,
                                    format: .pdf
                                )
                                dismiss()
                                await MainActor.run {
                                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                                }
                            } catch {
                                exportError = error
                                AppLogger.ui.error("PDF export failed", error: error)
                            }
                            isExporting = false
                        }
                    }

                    ExportOptionButton(
                        title: "Export as CSV",
                        description: "Export raw data for spreadsheet analysis",
                        icon: "tablecells.fill",
                        color: .green) {
                        Task {
                            isExporting = true
                            do {
                                let fileURL = try await exportService.exportExpenses(
                                    expenses: expenses,
                                    categories: categories,
                                    format: .csv
                                )
                                dismiss()
                                await MainActor.run {
                                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                                }
                            } catch {
                                exportError = error
                                AppLogger.ui.error("CSV export failed", error: error)
                            }
                            isExporting = false
                        }
                    }

                    ExportOptionButton(
                        title: "Share Report",
                        description: "Share via email or messaging",
                        icon: "square.and.arrow.up.fill",
                        color: .blue) {
                        Task {
                            isExporting = true
                            do {
                                let fileURL = try await exportService.exportExpenses(
                                    expenses: expenses,
                                    categories: categories,
                                    format: .pdf
                                )
                                dismiss()
                                await MainActor.run {
                                    exportService.showShareSheet(for: fileURL)
                                }
                            } catch {
                                exportError = error
                                AppLogger.ui.error("Share failed", error: error)
                            }
                            isExporting = false
                        }
                    }
                }
                .disabled(isExporting)

                Spacer()
            }
            .padding()
            .navigationTitle("Export Report")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct ExportOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.quaternarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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

// Using existing PaymentStatus enum from Budget.swift

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
        case .partial: 0 // Add partial status support
        case .refunded: 0 // Add refunded status support
        }
    }
}

// MARK: - Extensions

// Color.init(hex:) extension is defined in BudgetOverviewView.swift

#Preview {
    ExpenseReportsView()
}
