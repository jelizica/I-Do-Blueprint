import Charts
import SwiftUI

struct BudgetDashboardView: View {
    @StateObject private var budgetStore = BudgetStoreV2()
    @State private var selectedPeriod: DashboardPeriod = .month
    @State private var showingFilters = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Dashboard Header with Controls
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Budget Dashboard")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Real-time budget monitoring and insights")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: { showingFilters.toggle() }) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.title2)
                            }

                            Button(action: { Task { await budgetStore.refreshBudgetData() } }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                            }
                        }
                    }

                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(DashboardPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Key Metrics Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    DashboardMetricCard(
                        title: "Budget Used",
                        value: "\(Int(budgetStore.budgetUtilization))%",
                        subtitle: "of total budget",
                        color: budgetStore.budgetUtilization > 80 ? .red : .blue,
                        icon: "chart.pie.fill",
                        trend: .stable)

                    DashboardMetricCard(
                        title: "Avg Monthly Spend",
                        value: NumberFormatter.currencyShort
                            .string(from: NSNumber(value: budgetStore.averageMonthlySpend)) ?? "$0",
                        subtitle: "last 3 months",
                        color: .orange,
                        icon: "calendar",
                        trend: .down)

                    DashboardMetricCard(
                        title: "Days to Wedding",
                        value: "\(budgetStore.daysToWedding)",
                        subtitle: "remaining",
                        color: .purple,
                        icon: "heart.fill",
                        trend: .down)

                    DashboardMetricCard(
                        title: "Pending Payments",
                        value: NumberFormatter.currencyShort
                            .string(from: NSNumber(value: budgetStore.pendingPayments)) ?? "$0",
                        subtitle: "due this month",
                        color: .yellow,
                        icon: "clock.fill",
                        trend: .stable)

                    // Note: Vendor data not available in BudgetStore - use VendorStore instead
                    DashboardMetricCard(
                        title: "Vendors",
                        value: "See Vendors",
                        subtitle: "View in Vendors tab",
                        color: .green,
                        icon: "person.3.fill",
                        trend: .stable)

                    DashboardMetricCard(
                        title: "Budget Remaining",
                        value: NumberFormatter.currencyShort
                            .string(from: NSNumber(value: budgetStore.remainingBudget)) ?? "$0",
                        subtitle: "unallocated",
                        color: budgetStore.remainingBudget > 0 ? .green : .red,
                        icon: "dollarsign.circle.fill",
                        trend: .down)
                }

                // Spending Trend Chart
                SpendingTrendDashboardChart(
                    expenses: budgetStore.expenses,
                    period: selectedPeriod)

                // Quick Actions Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.title2)
                        .fontWeight(.semibold)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        QuickActionButton(
                            title: "Add Expense",
                            icon: "plus.circle",
                            color: .blue) {
                            // Add expense action
                        }

                        QuickActionButton(
                            title: "Schedule Payment",
                            icon: "calendar.badge.plus",
                            color: .orange) {
                            // Schedule payment action
                        }

                        QuickActionButton(
                            title: "View Categories",
                            icon: "list.bullet.rectangle",
                            color: .purple) {
                            // View categories action
                        }

                        QuickActionButton(
                            title: "Export Data",
                            icon: "square.and.arrow.up",
                            color: .green) {
                            // Export data action
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Recent Activity
                RecentActivityDashboard(activities: budgetStore.recentActivities)

                // Budget Alerts
                if !budgetStore.budgetAlerts.isEmpty {
                    BudgetAlertsDashboard(alerts: budgetStore.budgetAlerts)
                }
            }
            .padding()
        }
        .task {
            await budgetStore.loadBudgetData()
        }
        .sheet(isPresented: $showingFilters) {
            DashboardFiltersView(budgetStore: budgetStore)
        }
    }
}

// MARK: - Dashboard Components

struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    let trend: TrendDirection

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Spacer()

                Image(systemName: trend.iconName)
                    .foregroundColor(trend.color)
                    .font(.caption)
            }

            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SpendingTrendDashboardChart: View {
    let expenses: [Expense]
    let period: DashboardPeriod

    private var chartData: [SpendingDataPoint] {
        // Group expenses by the selected period
        let calendar = Calendar.current
        let now = Date()

        let dateRange: [Date] = switch period {
        case .week:
            (0 ..< 7).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }
        case .month:
            (0 ..< 30).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }
        case .quarter:
            (0 ..< 90).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }
        }

        return dateRange.reversed().map { date in
            let dayExpenses = expenses.filter { expense in
                calendar.isDate(expense.approvedAt ?? Date(), inSameDayAs: date)
            }
            let totalAmount = dayExpenses.reduce(0) { $0 + $1.amount }

            return SpendingDataPoint(
                date: date,
                amount: totalAmount)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend (\(period.displayName))")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)

            Chart(chartData, id: \.date) { dataPoint in
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", dataPoint.amount))
                    .foregroundStyle(.blue.opacity(0.3))

                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", dataPoint.amount))
                    .foregroundStyle(.blue)
                    .symbol(.circle)
            }
            .frame(height: 200)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentActivityDashboard: View {
    let activities: [BudgetActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.semibold)

            if activities.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("No recent activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(activities.prefix(5), id: \.id) { activity in
                    HStack(spacing: 12) {
                        Image(systemName: activity.type.icon)
                            .foregroundColor(activity.type.color)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.description)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(activity.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let amount = activity.amount {
                            Text(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(activity.type.color)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BudgetAlertsDashboard: View {
    let alerts: [BudgetAlert]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Alerts")
                .font(.title2)
                .fontWeight(.semibold)

            ForEach(alerts.prefix(3), id: \.id) { alert in
                HStack(spacing: 12) {
                    Image(systemName: alert.severity.icon)
                        .foregroundColor(alert.severity.color)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(alert.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(alert.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button("View") {
                        // View alert action
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(alert.severity.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DashboardFiltersView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    // Date range filters
                }

                Section("Categories") {
                    // Category filters
                }

                Section("Vendors") {
                    // Vendor filters
                }
            }
            .navigationTitle("Dashboard Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Apply") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum DashboardPeriod: String, CaseIterable {
    case week
    case month
    case quarter

    var displayName: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .quarter: "Quarter"
        }
    }
}

struct SpendingDataPoint {
    let date: Date
    let amount: Double
}

struct BudgetActivity {
    let id = UUID()
    let type: ActivityType
    let description: String
    let timestamp: Date
    let amount: Double?

    enum ActivityType {
        case expense, payment, category, vendor

        var icon: String {
            switch self {
            case .expense: "receipt"
            case .payment: "creditcard"
            case .category: "folder"
            case .vendor: "person.circle"
            }
        }

        var color: Color {
            switch self {
            case .expense: .red
            case .payment: .green
            case .category: .blue
            case .vendor: .purple
            }
        }
    }
}

struct BudgetAlert {
    let id = UUID()
    let severity: AlertSeverity
    let title: String
    let message: String
    let timestamp: Date

    enum AlertSeverity {
        case info, warning, critical

        var icon: String {
            switch self {
            case .info: "info.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .critical: "exclamationmark.octagon.fill"
            }
        }

        var color: Color {
            switch self {
            case .info: .blue
            case .warning: .orange
            case .critical: .red
            }
        }
    }
}
