import Charts
import SwiftUI

struct MoneyOwedView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var searchText = ""
    @State private var selectedPriority: OwedPriority?
    @State private var statusFilter: StatusFilter = .all
    @State private var sortOrder: SortOrder = .dueDateAscending
    @State private var showingNewOwedForm = false
    @State private var selectedOwed: MoneyOwed?

    private enum StatusFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case paid = "Paid"
        case overdue = "Overdue"
    }

    private enum SortOrder: String, CaseIterable {
        case dueDateAscending = "Due Date (Earliest)"
        case dueDateDescending = "Due Date (Latest)"
        case amountDescending = "Amount (High to Low)"
        case amountAscending = "Amount (Low to High)"
        case priorityDescending = "Priority (High to Low)"
        case personAscending = "Person (A-Z)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary section
            summarySection

            // Filters and sorting
            filtersSection

            // Priority breakdown chart
            chartSection

            // Owed list
            owedListSection
        }
        .searchable(text: $searchText, prompt: "Search owed money...")
        .sheet(isPresented: $showingNewOwedForm) {
            AddGiftOrOwedModal { newGift in
                Task {
                    await budgetStore.addGiftOrOwed(newGift)
                }
            }
        }
        .sheet(item: $selectedOwed) { owed in
            OwedDetailView(owed: owed)
                .environmentObject(budgetStore)
        }
    }

    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Owed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(totalOwed, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Outstanding")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(outstandingAmount, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Overdue")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(overdueAmount, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }

            // Status breakdown
            HStack(spacing: 20) {
                StatusCard(
                    title: "Pending",
                    count: pendingCount,
                    color: .orange)

                StatusCard(
                    title: "Paid",
                    count: paidCount,
                    color: .green)

                StatusCard(
                    title: "Overdue",
                    count: overdueCount,
                    color: .red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding()
    }

    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StatusFilter.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.rawValue,
                            isSelected: statusFilter == status,
                            action: { statusFilter = status })
                    }
                }
                .padding(.horizontal)
            }

            // Priority filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All Priorities",
                        isSelected: selectedPriority == nil,
                        action: { selectedPriority = nil })

                    ForEach(OwedPriority.allCases, id: \.self) { priority in
                        FilterChip(
                            title: priority.rawValue,
                            isSelected: selectedPriority == priority,
                            action: { selectedPriority = priority })
                    }
                }
                .padding(.horizontal)
            }

            // Sort order
            HStack {
                Text("Sort by:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button(order.rawValue) {
                            sortOrder = order
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOrder.rawValue)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Owed by Priority")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(priorityData, id: \.priority) { data in
                    BarMark(
                        x: .value("Priority", data.priority.rawValue),
                        y: .value("Amount", data.amount))
                        .foregroundStyle(data.color)
                        .cornerRadius(4)
                }
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(amount, specifier: "%.0f")")
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Timeline chart for due dates
            if !upcomingDueDates.isEmpty {
                Text("Upcoming Due Dates")
                    .font(.headline)
                    .padding(.horizontal)

                Chart {
                    ForEach(upcomingDueDates, id: \.date) { data in
                        PointMark(
                            x: .value("Date", data.date),
                            y: .value("Amount", data.amount))
                            .foregroundStyle(data.isOverdue ? .red : .orange)
                            .symbolSize(data.amount * 0.5)
                    }
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var owedListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Money Owed")
                    .font(.headline)
                Spacer()
                Button("Add Owed") {
                    showingNewOwedForm = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()

            if filteredOwed.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    Text("No money owed")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Add amounts you owe to others")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Button("Add Owed") {
                        showingNewOwedForm = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredOwed, id: \.id) { owed in
                        OwedRowView(owed: owed) {
                            selectedOwed = owed
                        }
                        .environmentObject(budgetStore)

                        if owed.id != filteredOwed.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var totalOwed: Double {
        budgetStore.moneyOwed.reduce(0) { $0 + $1.amount }
    }

    private var outstandingAmount: Double {
        budgetStore.moneyOwed.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    private var overdueAmount: Double {
        budgetStore.moneyOwed.filter { !$0.isPaid && $0.dueDate != nil && $0.dueDate! < Date() }
            .reduce(0) { $0 + $1.amount }
    }

    private var pendingCount: Int {
        budgetStore.moneyOwed.filter { !$0.isPaid }.count
    }

    private var paidCount: Int {
        budgetStore.moneyOwed.filter(\.isPaid).count
    }

    private var overdueCount: Int {
        budgetStore.moneyOwed.filter { !$0.isPaid && $0.dueDate != nil && $0.dueDate! < Date() }.count
    }

    private var filteredOwed: [MoneyOwed] {
        var owed = budgetStore.moneyOwed

        // Apply search filter
        if !searchText.isEmpty {
            owed = owed.filter { item in
                item.toPerson.localizedCaseInsensitiveContains(searchText) ||
                    item.reason.localizedCaseInsensitiveContains(searchText) ||
                    (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply status filter
        switch statusFilter {
        case .all:
            break
        case .pending:
            owed = owed.filter { !$0.isPaid }
        case .paid:
            owed = owed.filter(\.isPaid)
        case .overdue:
            owed = owed.filter { !$0.isPaid && $0.dueDate != nil && $0.dueDate! < Date() }
        }

        // Apply priority filter
        if let selectedPriority {
            owed = owed.filter { $0.priority == selectedPriority }
        }

        // Apply sorting
        switch sortOrder {
        case .dueDateAscending:
            owed.sort { a, b in
                guard let dateA = a.dueDate, let dateB = b.dueDate else {
                    return a.dueDate != nil
                }
                return dateA < dateB
            }
        case .dueDateDescending:
            owed.sort { a, b in
                guard let dateA = a.dueDate, let dateB = b.dueDate else {
                    return a.dueDate == nil
                }
                return dateA > dateB
            }
        case .amountDescending:
            owed.sort { $0.amount > $1.amount }
        case .amountAscending:
            owed.sort { $0.amount < $1.amount }
        case .priorityDescending:
            owed.sort { $0.priority.sortOrder > $1.priority.sortOrder }
        case .personAscending:
            owed.sort { $0.toPerson < $1.toPerson }
        }

        return owed
    }

    private var priorityData: [PriorityData] {
        let grouped = Dictionary(grouping: filteredOwed) { $0.priority }

        return OwedPriority.allCases.compactMap { priority in
            let items = grouped[priority] ?? []
            let amount = items.reduce(0) { $0 + $1.amount }
            guard amount > 0 else { return nil }

            return PriorityData(
                priority: priority,
                amount: amount,
                count: items.count,
                color: priority.color)
        }
    }

    private var upcomingDueDates: [DueDateData] {
        let calendar = Calendar.current
        let today = Date()
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today) ?? today

        return budgetStore.moneyOwed
            .filter { !$0.isPaid && $0.dueDate != nil }
            .compactMap { owed -> DueDateData? in
                guard let dueDate = owed.dueDate,
                      dueDate <= nextMonth else { return nil }

                return DueDateData(
                    date: dueDate,
                    amount: owed.amount,
                    isOverdue: dueDate < today)
            }
            .sorted { $0.date < $1.date }
    }
}

struct StatusCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct OwedRowView: View {
    let owed: MoneyOwed
    let onTap: () -> Void
    @EnvironmentObject var budgetStore: BudgetStoreV2

    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            ZStack {
                Circle()
                    .fill(owed.priority.color)
                    .frame(width: 40, height: 40)

                Text(owed.priority.abbreviation)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(owed.toPerson)
                        .font(.system(size: 14, weight: .medium))

                    if isOverdue {
                        Text("OVERDUE")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    if owed.isPaid {
                        Text("PAID")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }

                Text(owed.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let dueDate = owed.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption2)
                        .foregroundStyle(isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(owed.amount, specifier: "%.0f")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)

                Button(action: {
                    togglePaidStatus()
                }) {
                    Image(systemName: owed.isPaid ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(owed.isPaid ? .green : .gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var isOverdue: Bool {
        guard let dueDate = owed.dueDate else { return false }
        return !owed.isPaid && dueDate < Date()
    }

    private func togglePaidStatus() {
        var updatedOwed = owed
        updatedOwed.isPaid.toggle()
        Task {
            await budgetStore.updateMoneyOwed(updatedOwed)
        }
    }
}

struct MoneyOwedDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct OwedDetailView: View {
    let owed: MoneyOwed
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var showingEditForm = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Amount
                HStack {
                    Text("$\(owed.amount, specifier: "%.2f")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)

                    Spacer()

                    Button(action: {
                        var updatedOwed = owed
                        updatedOwed.isPaid.toggle()
                        Task {
                            await budgetStore.updateMoneyOwed(updatedOwed)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: owed.isPaid ? "checkmark.circle.fill" : "circle")
                            Text(owed.isPaid ? "Paid" : "Mark as Paid")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(owed.isPaid ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                // Details
                VStack(alignment: .leading, spacing: 12) {
                    MoneyOwedDetailRow(label: "To", value: owed.toPerson)
                    MoneyOwedDetailRow(label: "Reason", value: owed.reason)
                    MoneyOwedDetailRow(label: "Priority", value: owed.priority.rawValue)

                    if let dueDate = owed.dueDate {
                        MoneyOwedDetailRow(
                            label: "Due Date",
                            value: dueDate.formatted(date: .abbreviated, time: .omitted))
                    }

                    if let notes = owed.notes, !notes.isEmpty {
                        MoneyOwedDetailRow(label: "Notes", value: notes)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Owed Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditForm = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            // Convert MoneyOwed to GiftOrOwed for editing
            if let giftOrOwed = convertToGiftOrOwed(owed: owed) {
                EditGiftOrOwedModal(
                    giftOrOwed: giftOrOwed,
                    onSave: { updatedGift in
                        Task {
                            await budgetStore.updateGiftOrOwed(updatedGift)
                        }
                    },
                    onDelete: { giftToDelete in
                        Task {
                            await budgetStore.deleteGiftOrOwed(id: giftToDelete.id)
                        }
                    })
            }
        }
    }

    private func convertToGiftOrOwed(owed: MoneyOwed) -> GiftOrOwed? {
        GiftOrOwed(
            id: UUID(), // Will be handled by database
            coupleId: UUID(), // TODO: Use actual couple ID
            title: owed.reason,
            amount: owed.amount,
            type: .moneyOwed,
            description: owed.notes,
            fromPerson: owed.toPerson,
            expectedDate: owed.dueDate,
            receivedDate: owed.isPaid ? Date() : nil,
            status: owed.isPaid ? .received : .pending,
            createdAt: Date(),
            updatedAt: nil)
    }
}

// MARK: - Data Models

struct PriorityData {
    let priority: OwedPriority
    let amount: Double
    let count: Int
    let color: Color
}

struct DueDateData {
    let date: Date
    let amount: Double
    let isOverdue: Bool
}

extension OwedPriority {
    var color: Color {
        switch self {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }

    var abbreviation: String {
        switch self {
        case .low: "L"
        case .medium: "M"
        case .high: "H"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: 3
        case .medium: 2
        case .low: 1
        }
    }
}

#Preview {
    MoneyOwedView()
        .environmentObject(BudgetStoreV2())
}
