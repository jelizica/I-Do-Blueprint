import SwiftUI

/// Table tab for expense reports showing detailed expense list with pagination
struct ExpenseReportsTableTab: View {
    @Binding var selectedTab: ReportTab
    @Binding var sortConfig: SortConfig
    @Binding var currentPage: Int

    let paginatedExpenses: [ExpenseItem]
    let filteredExpensesCount: Int
    let itemsPerPage: Int
    let totalPages: Int

    var body: some View {
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
                        "Showing \((currentPage - 1) * itemsPerPage + 1) to \(min(currentPage * itemsPerPage, filteredExpensesCount)) of \(filteredExpensesCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Table
                VStack(spacing: 0) {
                    // Header Row
                    HStack {
                        sortableHeader("Date", key: .date, sortConfig: $sortConfig)
                        sortableHeader("Description", key: .description, sortConfig: $sortConfig)
                        sortableHeader("Category", key: .category, sortConfig: $sortConfig)
                        sortableHeader("Vendor", key: .vendor, sortConfig: $sortConfig)
                        sortableHeader("Amount", key: .amount, sortConfig: $sortConfig)
                        Text("Status")
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 80)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, Spacing.sm)
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
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xxs)
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
                            .padding(.vertical, Spacing.sm)

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
                    ExpenseReportsPagination(
                        currentPage: $currentPage,
                        totalPages: totalPages)
                }
            }
        }
    }

    private func sortableHeader(_ title: String, key: SortKey, sortConfig: Binding<SortConfig>) -> some View {
        Button(action: {
            if sortConfig.wrappedValue.key == key {
                sortConfig.wrappedValue.direction = sortConfig.wrappedValue.direction == .asc ? .desc : .asc
            } else {
                sortConfig.wrappedValue.key = key
                sortConfig.wrappedValue.direction = .asc
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Image(systemName: sortConfig.wrappedValue.key == key ?
                    (sortConfig.wrappedValue.direction == .asc ? "chevron.up" : "chevron.down") :
                    "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundColor(sortConfig.wrappedValue.key == key ? .blue : .secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

struct ExpenseReportsPagination: View {
    @Binding var currentPage: Int
    let totalPages: Int

    var body: some View {
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
}
