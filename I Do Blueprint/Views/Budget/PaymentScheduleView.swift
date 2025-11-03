import SwiftUI

struct PaymentScheduleView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2

    // Filter states
    @State private var selectedFilterOption: PaymentFilterOption = .all

    // Dialog states
    @State private var showingAddPayment = false

    var filteredPayments: [PaymentSchedule] {
        let filtered = budgetStore.paymentSchedules.filter { payment in
            switch selectedFilterOption {
            case .all:
                return true
            case .upcoming:
                return payment.paymentDate > Date() && !payment.paid
            case .overdue:
                return payment.paymentDate < Date() && !payment.paid
            case .thisWeek:
                let calendar = Calendar.current
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
                return payment.paymentDate >= startOfWeek && payment.paymentDate <= endOfWeek
            case .thisMonth:
                let calendar = Calendar.current
                let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
                let endOfMonth = calendar.dateInterval(of: .month, for: Date())?.end ?? Date()
                return payment.paymentDate >= startOfMonth && payment.paymentDate <= endOfMonth
            case .paid:
                return payment.paid
            }
        }
        return filtered.sorted { $0.paymentDate < $1.paymentDate }
    }

    var upcomingPaymentsTotal: Double {
        filteredPayments.filter { !$0.paid && $0.paymentDate > Date() }.reduce(0) { $0 + $1.paymentAmount }
    }

    var overduePaymentsTotal: Double {
        filteredPayments.filter { !$0.paid && $0.paymentDate < Date() }.reduce(0) { $0 + $1.paymentAmount }
    }

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Payment Schedule")
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showingAddPayment) {
                    addPaymentSheet
                }
        }
        .task {
            await budgetStore.loadBudgetData(force: true)
        }
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            paymentListView
        }
    }

    private var headerView: some View {
        VStack(spacing: 0) {
            PaymentSummaryHeaderView(
                totalUpcoming: upcomingPaymentsTotal,
                totalOverdue: overduePaymentsTotal,
                scheduleCount: filteredPayments.count)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

            filterView
        }
    }

    private var filterView: some View {
        VStack(spacing: 12) {
            Picker("Filter", selection: $selectedFilterOption) {
                ForEach(PaymentFilterOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.bottom)
        .background(Color(NSColor.controlBackgroundColor))
    }

    @ViewBuilder
    private var paymentListView: some View {
        if filteredPayments.isEmpty {
            ContentUnavailableView(
                "No Payment Schedules",
                systemImage: "calendar.circle",
                description: Text("Add payment schedules to track upcoming payments and deadlines"))
        } else {
            List {
                ForEach(groupedPayments, id: \.key) { group in
                    Section(group.key) {
                        ForEach(group.value, id: \.id) { payment in
                            PaymentScheduleRowView(
                                payment: payment,
                                expense: getExpenseForPayment(payment),
                                onUpdate: { updatedPayment in
                                    Task {
                                        await budgetStore.updatePaymentSchedule(updatedPayment)
                                    }
                                },
                                onDelete: { paymentToDelete in
                                    Task {
                                        await budgetStore.deletePaymentSchedule(id: paymentToDelete.id)
                                    }
                                },
                                getVendorName: { vendorId in
                                    // First try to get vendor name from the payment's expense
                                    if let expense = getExpenseForPayment(payment) {
                                        return expense.vendorName
                                    }
                                    // Fall back to payment's vendor field
                                    return payment.vendor.isEmpty ? nil : payment.vendor
                                }
                            )
                            .id(payment.id)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: {
                showingAddPayment = true
            }) {
                Label("Add Payment", systemImage: "plus")
            }
        }

        ToolbarItem(placement: .secondaryAction) {
            Button(action: {
                Task {
                    await budgetStore.refreshBudgetData()
                }
            }) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }

    private var addPaymentSheet: some View {
        AddPaymentScheduleView(
            expenses: budgetStore.expenses.filter { $0.paymentStatus != .paid },
            existingPaymentSchedules: budgetStore.paymentSchedules,
            onSave: { newPaymentSchedule in
                Task {
                    await budgetStore.addPaymentSchedule(newPaymentSchedule)
                }
            },
            getVendorName: { vendorId in
                // Look up vendor name from vendors list using vendor_id
                guard let vendorId = vendorId else { return nil }

                // Access vendors from VendorStoreV2 through AppStores
                let vendors = AppStores.shared.vendor.vendors
                return vendors.first(where: { $0.id == vendorId })?.vendorName
            }
        )
        #if os(macOS)
        .frame(minWidth: 1000, maxWidth: 1200, minHeight: 600, maxHeight: 650)
        #endif
    }

    private var groupedPayments: [(key: String, value: [PaymentSchedule])] {
        let grouped = Dictionary(grouping: filteredPayments) { payment in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: payment.paymentDate)
        }
        return grouped.sorted { first, second in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"

            guard let firstDate = formatter.date(from: first.key),
                  let secondDate = formatter.date(from: second.key) else {
                return first.key < second.key
            }

            return firstDate < secondDate
        }
    }

    private func getExpenseForPayment(_ payment: PaymentSchedule) -> Expense? {
        budgetStore.expenses.first { $0.id == payment.expenseId }
    }
}

// MARK: - Supporting Views

struct PaymentSummaryHeaderView: View {
    let totalUpcoming: Double
    let totalOverdue: Double
    let scheduleCount: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                PaymentOverviewCard(
                    title: "Upcoming Payments",
                    value: NumberFormatter.currency.string(from: NSNumber(value: totalUpcoming)) ?? "$0",
                    subtitle: "Due soon",
                    icon: "calendar",
                    color: AppColors.Budget.pending)

                PaymentOverviewCard(
                    title: "Overdue Payments",
                    value: NumberFormatter.currency.string(from: NSNumber(value: totalOverdue)) ?? "$0",
                    subtitle: "Past due",
                    icon: "exclamationmark.triangle.fill",
                    color: AppColors.Budget.overBudget)

                PaymentOverviewCard(
                    title: "Total Schedules",
                    value: "\(scheduleCount)",
                    subtitle: "Active schedules",
                    icon: "list.number",
                    color: AppColors.Budget.allocated)
            }
        }
    }
}

struct PaymentScheduleRowView: View {
    let payment: PaymentSchedule
    let expense: Expense?
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?

    @State private var showingEditModal = false

    var body: some View {
        Button(action: {
            showingEditModal = true
        }) {
            HStack(spacing: 16) {
                // Payment status indicator
                Circle()
                    .fill(payment.paid ? AppColors.Budget.income : AppColors.Budget.pending)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(expense?.expenseName ?? "Unknown Expense")
                            .font(.headline)
                            .fontWeight(.medium)

                        Spacer()

                        Text(NumberFormatter.currency.string(from: NSNumber(value: payment.paymentAmount)) ?? "$0")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(payment.paid ? AppColors.Budget.income : .primary)
                    }

                    Text(payment.notes ?? "No description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Due: \(formatDate(payment.paymentDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(payment.paid ? "Paid" : "Pending")
                            .font(.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(payment.paid ? AppColors.Budget.income.opacity(0.2) : AppColors.Budget.pending.opacity(0.2))
                            .foregroundColor(payment.paid ? AppColors.Budget.income : AppColors.Budget.pending)
                            .clipShape(Capsule())
                    }
                }

                // Quick action buttons
                HStack(spacing: 8) {
                    Button(action: {
                        var updatedPayment = payment
                        updatedPayment.paid.toggle()
                        updatedPayment.updatedAt = Date()
                        onUpdate(updatedPayment)
                    }) {
                        Image(systemName: payment.paid ? "checkmark.square.fill" : "square")
                            .foregroundColor(payment.paid ? AppColors.Budget.income : .secondary)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditModal) {
            PaymentEditModal(
                payment: payment,
                expense: expense,
                getVendorName: getVendorName,
                onUpdate: onUpdate,
                onDelete: {
                    onDelete(payment)
                })
        }
    }
}

struct PaymentOverviewCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
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
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Filter Options

enum PaymentFilterOption: String, CaseIterable {
    case all = "all"
    case upcoming = "upcoming"
    case overdue = "overdue"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case paid = "paid"

    var displayName: String {
        switch self {
        case .all: "All"
        case .upcoming: "Upcoming"
        case .overdue: "Overdue"
        case .thisWeek: "This Week"
        case .thisMonth: "This Month"
        case .paid: "Paid"
        }
    }
}

// MARK: - Helper Functions

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

#Preview {
    PaymentScheduleView()
}
