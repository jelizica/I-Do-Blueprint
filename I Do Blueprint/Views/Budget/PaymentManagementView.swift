import SwiftUI

struct PaymentManagementView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var showingAddPayment = false
    @State private var selectedFilter: PaymentFilter = .all
    @State private var searchText = ""
    @State private var sortBy: PaymentSortOption = .dueDate
    @State private var showingBulkActions = false
    @State private var selectedPayments = Set<String>()

    private var filteredPayments: [PaymentScheduleItem] {
        // Convert PaymentSchedule to PaymentScheduleItem
        let payments = budgetStore.paymentSchedules.map { schedule in
            PaymentScheduleItem(
                id: String(schedule.id),
                description: schedule.notes ?? schedule.vendor,
                amount: schedule.paymentAmount,
                vendorName: schedule.vendor,
                dueDate: schedule.paymentDate,
                isPaid: schedule.paid,
                isRecurring: schedule.billingFrequency != nil,
                paymentMethod: schedule.paymentType)
        }

        // Apply search filter
        let searchFiltered = searchText.isEmpty ? payments : payments.filter { payment in
            payment.description.localizedCaseInsensitiveContains(searchText) ||
                payment.vendorName.localizedCaseInsensitiveContains(searchText)
        }

        // Apply status filter
        let statusFiltered: [PaymentScheduleItem]
        switch selectedFilter {
        case .all:
            statusFiltered = searchFiltered
        case .pending:
            statusFiltered = searchFiltered.filter { !$0.isPaid }
        case .paid:
            statusFiltered = searchFiltered.filter(\.isPaid)
        case .overdue:
            statusFiltered = searchFiltered.filter { payment in
                !payment.isPaid && payment.dueDate < Date()
            }
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            statusFiltered = searchFiltered.filter { payment in
                calendar.isDate(payment.dueDate, equalTo: now, toGranularity: .month)
            }
        }

        // Apply sorting
        return statusFiltered.sorted { lhs, rhs in
            switch sortBy {
            case .dueDate:
                lhs.dueDate < rhs.dueDate
            case .amount:
                lhs.amount > rhs.amount
            case .vendor:
                lhs.vendorName < rhs.vendorName
            case .status:
                !lhs.isPaid && rhs.isPaid
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            headerSection

            // Payment Summary Cards
            PaymentSummaryCards(payments: filteredPayments)

            // Payments List
            if filteredPayments.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Payments" : "No Results",
                    systemImage: searchText.isEmpty ? "calendar.badge.clock" : "magnifyingglass",
                    description: Text(searchText.isEmpty ?
                        "Add your first payment to get started" :
                        "Try adjusting your search or filters"))
            } else {
                List {
                    ForEach(filteredPayments, id: \.id) { payment in
                        PaymentRowView(
                            payment: payment,
                            isSelected: selectedPayments.contains(payment.id),
                            onSelectionChanged: { isSelected in
                                if isSelected {
                                    selectedPayments.insert(payment.id)
                                } else {
                                    selectedPayments.remove(payment.id)
                                }
                            })
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete(perform: deletePayments)
                }
                .listStyle(PlainListStyle())
            }
        }
        .task {
            await budgetStore.loadBudgetData()
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentView(budgetStore: budgetStore)
        }
        .sheet(isPresented: $showingBulkActions) {
            BulkActionsView(
                selectedPayments: selectedPayments,
                payments: filteredPayments,
                budgetStore: budgetStore) {
                selectedPayments.removeAll()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Management")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(filteredPayments.count) payments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    if !selectedPayments.isEmpty {
                        Button("Bulk Actions") {
                            showingBulkActions = true
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Add Payment") {
                        showingAddPayment = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            // Search and filter controls
            HStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search payments...", text: $searchText)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Filter menu
                Menu {
                    Button("All Payments") { selectedFilter = .all }
                    Button("Pending") { selectedFilter = .pending }
                    Button("Paid") { selectedFilter = .paid }
                    Button("Overdue") { selectedFilter = .overdue }
                    Button("This Month") { selectedFilter = .thisMonth }
                } label: {
                    HStack {
                        Text(selectedFilter.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Sort menu
                Menu {
                    Button("Due Date") { sortBy = .dueDate }
                    Button("Amount") { sortBy = .amount }
                    Button("Vendor") { sortBy = .vendor }
                    Button("Status") { sortBy = .status }
                } label: {
                    HStack {
                        Text("Sort")
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Helper Methods

    private func deletePayments(offsets: IndexSet) {
        for index in offsets {
            let payment = filteredPayments[index]
            // Find the original PaymentSchedule
            if let schedule = budgetStore.paymentSchedules.first(where: { String($0.id) == payment.id }) {
                Task {
                    await budgetStore.deletePayment(schedule)
                }
            }
        }
    }
}
