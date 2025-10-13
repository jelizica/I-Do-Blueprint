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
                SummaryCard(
                    title: "Net Flow",
                    value: netFlow,
                    change: monthlyChange,
                    color: netFlow >= 0 ? .green : .red,
                    icon: "arrow.up.arrow.down")

                SummaryCard(
                    title: "Received",
                    value: totalReceived,
                    change: receivedChange,
                    color: .green,
                    icon: "arrow.down.circle.fill")

                SummaryCard(
                    title: "Owed",
                    value: totalOwed,
                    change: owedChange,
                    color: .red,
                    icon: "arrow.up.circle.fill")

                SummaryCard(
                    title: "Pending",
                    value: pendingAmount,
                    change: nil,
                    color: .orange,
                    icon: "clock.fill")
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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
                        .foregroundStyle(.green)
                        .opacity(0.8)

                    BarMark(
                        x: .value("Month", data.month, unit: .month),
                        y: .value("Owed", -data.owed))
                        .foregroundStyle(.red)
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

            LazyVStack(spacing: 0) {
                ForEach(filteredTransactions, id: \.id) { transaction in
                    TransactionRowView(transaction: transaction)
                        .environmentObject(budgetStore)
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
                .filter { $0.dueDate != nil && calendar.isDate($0.dueDate!, equalTo: month, toGranularity: .month) }
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
            let isOverdue = owed.dueDate != nil && owed.dueDate! < Date() && !owed.isPaid
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

struct SummaryCard: View {
    let title: String
    let value: Double
    let change: Double?
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                if let change {
                    Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundColor(change >= 0 ? .green : .red)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("$\(abs(value), specifier: "%.0f")")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding()
        .frame(width: 140, height: 100)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct TransactionRowView: View {
    let transaction: MoneyTransaction
    @EnvironmentObject var budgetStore: BudgetStoreV2

    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            Circle()
                .fill(transaction.type == .received ? Color.green : Color.red)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(transaction.person)
                        .font(.system(size: 14, weight: .medium))

                    if transaction.isOverdue {
                        Text("OVERDUE")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    if transaction.needsThankYou {
                        Text("THANK YOU")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
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
                    .foregroundColor(transaction.type == .received ? .green : .red)

                Text(transaction.status.rawValue)
                    .font(.caption2)
                    .foregroundColor(transaction.status == .complete ? .green : .orange)
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
