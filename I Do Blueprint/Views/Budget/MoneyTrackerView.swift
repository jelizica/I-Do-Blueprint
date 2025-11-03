import Charts
import SwiftUI

struct MoneyTrackerView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var searchText = ""
    @State private var selectedFilter: MoneyFilter = .all
    @State private var showingFilterSheet = false

    enum MoneyFilter: String, CaseIterable {
        case all = "All"
        case received = "Received"
        case owed = "Owed"
        case overdue = "Overdue"
        case thankYouPending = "Thank You Pending"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary cards
            summaryCardsSection

            // Search and filter bar
            searchAndFilterSection

            // Money flow chart
            chartSection

            // Transactions list
            transactionsSection
        }
        .searchable(text: $searchText, prompt: "Search transactions...")
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView(selectedFilter: $selectedFilter)
        }
    }

    private var summaryCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Using Component Library - StatsCardView
                StatsCardView(
                    stat: StatItem(
                        icon: "arrow.up.arrow.down",
                        label: "Net Flow",
                        value: String(format: "$%.0f", abs(netFlow)),
                        color: netFlow >= 0 ? AppColors.Budget.income : AppColors.Budget.expense,
                        trend: monthlyChange.map { change in
                            change >= 0 ? .up(String(format: "+%.1f%%", change)) : .down(String(format: "%.1f%%", change))
                        }
                    )
                )
                .frame(width: 140)

                StatsCardView(
                    stat: StatItem(
                        icon: "arrow.down.circle.fill",
                        label: "Received",
                        value: String(format: "$%.0f", totalReceived),
                        color: AppColors.Budget.income,
                        trend: receivedChange.map { change in
                            change >= 0 ? .up(String(format: "+%.1f%%", change)) : .down(String(format: "%.1f%%", change))
                        }
                    )
                )
                .frame(width: 140)

                StatsCardView(
                    stat: StatItem(
                        icon: "arrow.up.circle.fill",
                        label: "Owed",
                        value: String(format: "$%.0f", totalOwed),
                        color: AppColors.Budget.expense,
                        trend: owedChange.map { change in
                            change >= 0 ? .up(String(format: "+%.1f%%", change)) : .down(String(format: "%.1f%%", change))
                        }
                    )
                )
                .frame(width: 140)

                StatsCardView(
                    stat: StatItem(
                        icon: "clock.fill",
                        label: "Pending",
                        value: String(format: "$%.0f", pendingAmount),
                        color: AppColors.Budget.pending
                    )
                )
                .frame(width: 140)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    private var searchAndFilterSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search transactions...", text: $searchText)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            Button(action: {
                showingFilterSheet = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(selectedFilter.rawValue)
                }
                .font(.caption)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(selectedFilter != .all ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(selectedFilter != .all ? .white : .primary)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Money Flow Trend")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(monthlyData, id: \.month) { data in
                    BarMark(
                        x: .value("Month", data.month, unit: .month),
                        y: .value("Received", data.received))
                        .foregroundStyle(AppColors.Budget.income)
                        .opacity(0.8)

                    BarMark(
                        x: .value("Month", data.month, unit: .month),
                        y: .value("Owed", -data.owed))
                        .foregroundStyle(AppColors.Budget.expense)
                        .opacity(0.8)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(abs(amount), specifier: "%.0f")")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                Text("\(filteredTransactions.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            if filteredTransactions.isEmpty {
                // Using Component Library - UnifiedEmptyStateView
                UnifiedEmptyStateView(
                    config: searchText.isEmpty && selectedFilter == .all ?
                        .custom(
                            icon: "dollarsign.circle",
                            title: "No Transactions",
                            message: "Money received and owed will appear here",
                            actionTitle: nil,
                            onAction: nil
                        ) :
                        .searchResults(query: searchText.isEmpty ? selectedFilter.rawValue : searchText)
                )
                .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredTransactions, id: \.id) { transaction in
                        TransactionRowView(transaction: transaction)
                            .environmentObject(budgetStore)
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var totalReceived: Double {
        budgetStore.giftsReceived.reduce(0) { $0 + $1.amount }
    }

    private var totalOwed: Double {
        budgetStore.moneyOwed.reduce(0) { $0 + $1.amount }
    }

    private var netFlow: Double {
        totalReceived - totalOwed
    }

    private var pendingAmount: Double {
        budgetStore.moneyOwed.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    private var monthlyChange: Double? {
        // Calculate month-over-month change
        5.2 // Placeholder
    }

    private var receivedChange: Double? {
        12.3 // Placeholder
    }

    private var owedChange: Double? {
        -8.1 // Placeholder
    }

    private var monthlyData: [MonthlyFlowData] {
        // Generate last 6 months of data
        let calendar = Calendar.current
        let now = Date()

        return (0 ..< 6).compactMap { monthsBack in
            guard let month = calendar.date(byAdding: .month, value: -monthsBack, to: now) else { return nil }

            let received = budgetStore.giftsReceived
                .filter { calendar.isDate($0.dateReceived, equalTo: month, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }

            let owed = budgetStore.moneyOwed
                .filter { item in
                    guard let dueDate = item.dueDate else { return false }
                    return calendar.isDate(dueDate, equalTo: month, toGranularity: .month)
                }
                .reduce(0) { $0 + $1.amount }

            return MonthlyFlowData(month: month, received: received, owed: owed)
        }.reversed()
    }

    private var filteredTransactions: [MoneyTransaction] {
        let allTransactions = createTransactionList()

        var filtered = allTransactions

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.person.localizedCaseInsensitiveContains(searchText) ||
                    transaction.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .received:
            filtered = filtered.filter { $0.type == .received }
        case .owed:
            filtered = filtered.filter { $0.type == .owed }
        case .overdue:
            filtered = filtered.filter(\.isOverdue)
        case .thankYouPending:
            filtered = filtered.filter(\.needsThankYou)
        }

        return filtered.sorted { $0.date > $1.date }
    }

    private func createTransactionList() -> [MoneyTransaction] {
        var transactions: [MoneyTransaction] = []

        // Add gifts received
        for gift in budgetStore.giftsReceived {
            transactions.append(MoneyTransaction(
                id: gift.id.uuidString,
                type: .received,
                person: gift.fromPerson,
                amount: gift.amount,
                date: gift.dateReceived,
                description: gift.giftType.rawValue,
                status: gift.isThankYouSent ? .complete : .pending,
                needsThankYou: !gift.isThankYouSent,
                isOverdue: false))
        }

        // Add money owed
        for owed in budgetStore.moneyOwed {
            let isOverdue: Bool
            if let dueDate = owed.dueDate {
                isOverdue = dueDate < Date() && !owed.isPaid
            } else {
                isOverdue = false
            }

            transactions.append(MoneyTransaction(
                id: owed.id.uuidString,
                type: .owed,
                person: owed.toPerson,
                amount: owed.amount,
                date: owed.dueDate ?? Date(),
                description: owed.reason,
                status: owed.isPaid ? .complete : .pending,
                needsThankYou: false,
                isOverdue: isOverdue))
        }

        return transactions
    }
}

// Note: MoneyTrackerSummaryCard replaced with StatsCardView from component library

struct TransactionRowView: View {
    let transaction: MoneyTransaction
    @EnvironmentObject var budgetStore: BudgetStoreV2

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            Circle()
                .fill(transaction.type == .received ? AppColors.Budget.income : AppColors.Budget.expense)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(transaction.person)
                        .font(.system(size: 14, weight: .medium))

                    if transaction.isOverdue {
                        Text("OVERDUE")
                            .font(.caption2)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(AppColors.Budget.overBudget)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(4)
                    }

                    if transaction.needsThankYou {
                        Text("THANK YOU")
                            .font(.caption2)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(AppColors.Budget.pending)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(4)
                    }
                }

                Text(transaction.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == .received ? "+" : "-")$\(transaction.amount, specifier: "%.0f")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(transaction.type == .received ? AppColors.Budget.income : AppColors.Budget.expense)

                Text(transaction.status.rawValue)
                    .font(.caption2)
                    .foregroundColor(transaction.status == .complete ? AppColors.Budget.income : AppColors.Budget.pending)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .contentShape(Rectangle())
    }
}

struct FilterSheetView: View {
    @Binding var selectedFilter: MoneyTrackerView.MoneyFilter
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(MoneyTrackerView.MoneyFilter.allCases, id: \.self) { filter in
                    HStack {
                        Text(filter.rawValue)
                        Spacer()
                        if selectedFilter == filter {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFilter = filter
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Filter")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Data Models

struct MonthlyFlowData {
    let month: Date
    let received: Double
    let owed: Double
}

struct MoneyTransaction {
    let id: String
    let type: TransactionType
    let person: String
    let amount: Double
    let date: Date
    let description: String
    let status: TransactionStatus
    let needsThankYou: Bool
    let isOverdue: Bool

    enum TransactionType {
        case received, owed
    }

    enum TransactionStatus: String {
        case pending = "Pending"
        case complete = "Complete"
    }
}

#Preview {
    MoneyTrackerView()
        .environmentObject(BudgetStoreV2())
}
