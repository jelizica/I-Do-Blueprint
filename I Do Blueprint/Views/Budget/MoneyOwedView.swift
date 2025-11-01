import SwiftUI

struct MoneyOwedView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var searchText = ""
    @State private var selectedPriority: OwedPriority?
    @State private var statusFilter: StatusFilter = .all
    @State private var sortOrder: SortOrder = .dueDateAscending
    @State private var showingNewOwedForm = false
    @State private var selectedOwed: MoneyOwed?

    var body: some View {
        VStack(spacing: 0) {
            // Summary section
            MoneyOwedSummarySection(
                totalOwed: totalOwed,
                outstandingAmount: outstandingAmount,
                overdueAmount: overdueAmount,
                pendingCount: pendingCount,
                paidCount: paidCount,
                overdueCount: overdueCount
            )

            // Filters and sorting
            MoneyOwedFiltersSection(
                statusFilter: $statusFilter,
                selectedPriority: $selectedPriority,
                sortOrder: $sortOrder
            )

            // Priority breakdown chart
            MoneyOwedChartsSection(
                priorityData: priorityData,
                upcomingDueDates: upcomingDueDates
            )

            // Owed list
            owedListSection
        }
        .searchable(text: $searchText, prompt: "Search owed money...")
        .sheet(isPresented: $showingNewOwedForm) {
            AddGiftOrOwedModal { newGift in
                Task {
                    await budgetStore.gifts.addGiftOrOwed(newGift)
                }
            }
        }
        .sheet(item: $selectedOwed) { owed in
            OwedDetailView(owed: owed)
                .environmentObject(budgetStore)
        }
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
                                .padding(.leading, Spacing.huge)
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
        budgetStore.moneyOwed.filter { owed in
            guard let dueDate = owed.dueDate else { return false }
            return !owed.isPaid && dueDate < Date()
        }
        .reduce(0) { $0 + $1.amount }
    }

    private var pendingCount: Int {
        budgetStore.moneyOwed.filter { !$0.isPaid }.count
    }

    private var paidCount: Int {
        budgetStore.moneyOwed.filter(\.isPaid).count
    }

    private var overdueCount: Int {
        budgetStore.moneyOwed.filter { owed in
            guard let dueDate = owed.dueDate else { return false }
            return !owed.isPaid && dueDate < Date()
        }.count
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
            owed = owed.filter { item in
                guard let dueDate = item.dueDate else { return false }
                return !item.isPaid && dueDate < Date()
            }
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

#Preview {
    MoneyOwedView()
        .environmentObject(BudgetStoreV2())
}
