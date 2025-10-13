import SwiftUI

struct PaymentManagementView: View {
    @StateObject private var budgetStore = BudgetStoreV2()
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

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

// MARK: - Payment Summary Cards

struct PaymentSummaryCards: View {
    let payments: [PaymentScheduleItem]

    private var summaryData: PaymentSummaryData {
        let totalAmount = payments.reduce(0) { $0 + $1.amount }
        let paidAmount = payments.filter(\.isPaid).reduce(0) { $0 + $1.amount }
        let pendingAmount = payments.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }

        let overduePayments = payments.filter { !$0.isPaid && $0.dueDate < Date() }
        let overdueAmount = overduePayments.reduce(0) { $0 + $1.amount }

        let thisMonthPayments = payments.filter { payment in
            Calendar.current.isDate(payment.dueDate, equalTo: Date(), toGranularity: .month)
        }
        let thisMonthAmount = thisMonthPayments.reduce(0) { $0 + $1.amount }

        return PaymentSummaryData(
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            pendingAmount: pendingAmount,
            overdueAmount: overdueAmount,
            overdueCount: overduePayments.count,
            thisMonthAmount: thisMonthAmount,
            thisMonthCount: thisMonthPayments.count)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                PaymentManagementSummaryCard(
                    title: "Total Payments",
                    amount: summaryData.totalAmount,
                    subtitle: "\(payments.count) payments",
                    color: .blue,
                    icon: "calendar.badge.clock")

                PaymentManagementSummaryCard(
                    title: "Paid",
                    amount: summaryData.paidAmount,
                    subtitle: "completed",
                    color: .green,
                    icon: "checkmark.circle.fill")

                PaymentManagementSummaryCard(
                    title: "Pending",
                    amount: summaryData.pendingAmount,
                    subtitle: "outstanding",
                    color: .orange,
                    icon: "clock.fill")

                if summaryData.overdueAmount > 0 {
                    PaymentManagementSummaryCard(
                        title: "Overdue",
                        amount: summaryData.overdueAmount,
                        subtitle: "\(summaryData.overdueCount) payments",
                        color: .red,
                        icon: "exclamationmark.triangle.fill")
                }

                PaymentManagementSummaryCard(
                    title: "This Month",
                    amount: summaryData.thisMonthAmount,
                    subtitle: "\(summaryData.thisMonthCount) due",
                    color: .purple,
                    icon: "calendar.circle.fill")
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct PaymentManagementSummaryCard: View {
    let title: String
    let amount: Double
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

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
        .frame(width: 120)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Payment Row

struct PaymentRowView: View {
    let payment: PaymentScheduleItem
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    @State private var showingDetails = false

    private var statusColor: Color {
        if payment.isPaid {
            .green
        } else if payment.dueDate < Date() {
            .red
        } else {
            .orange
        }
    }

    private var statusIcon: String {
        if payment.isPaid {
            "checkmark.circle.fill"
        } else if payment.dueDate < Date() {
            "exclamationmark.triangle.fill"
        } else {
            "clock.fill"
        }
    }

    private var statusText: String {
        if payment.isPaid {
            return "Paid"
        } else if payment.dueDate < Date() {
            let daysPast = Calendar.current.dateComponents([.day], from: payment.dueDate, to: Date()).day ?? 0
            return "\(daysPast) days overdue"
        } else {
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: payment.dueDate).day ?? 0
            return "Due in \(daysUntil) days"
        }
    }

    var body: some View {
        Button(action: { showingDetails = true }) {
            HStack(spacing: 12) {
                // Selection checkbox
                Button(action: { onSelectionChanged(!isSelected) }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)

                // Status indicator
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title3)

                // Payment details
                VStack(alignment: .leading, spacing: 4) {
                    Text(payment.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack {
                        Text(payment.vendorName)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(payment.dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(statusColor)
                        .fontWeight(.medium)
                }

                Spacer()

                // Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NumberFormatter.currency.string(from: NSNumber(value: payment.amount)) ?? "$0")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if payment.isRecurring {
                        Text("Recurring")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetails) {
            PaymentDetailView(payment: payment)
        }
    }
}

// MARK: - Payment Detail View

struct PaymentDetailView: View {
    let payment: PaymentScheduleItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(payment.description)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(NumberFormatter.currency.string(from: NSNumber(value: payment.amount)) ?? "$0")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    // Payment details
                    VStack(alignment: .leading, spacing: 16) {
                        PaymentDetailRow(label: "Vendor", value: payment.vendorName)
                        PaymentDetailRow(
                            label: "Due Date",
                            value: payment.dueDate.formatted(date: .abbreviated, time: .omitted))
                        PaymentDetailRow(label: "Status", value: payment.isPaid ? "Paid" : "Pending")

                        if payment.isRecurring {
                            PaymentDetailRow(label: "Recurring", value: "Yes")
                        }

                        if let paymentMethod = payment.paymentMethod {
                            PaymentDetailRow(label: "Payment Method", value: paymentMethod.capitalized)
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        if !payment.isPaid {
                            Button("Mark as Paid") {
                                // Mark as paid
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }

                        Button("Edit Payment") {
                            // Edit payment
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Payment Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Payment View

struct AddPaymentView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var amount = ""
    @State private var vendorName = ""
    @State private var dueDate = Date()
    @State private var paymentMethod = "credit_card"
    @State private var isRecurring = false
    @State private var recurringInterval = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    TextField("Description", text: $description)

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("$0.00", text: $amount)
                            .multilineTextAlignment(.trailing)
                    }

                    TextField("Vendor", text: $vendorName)

                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }

                Section("Payment Options") {
                    Picker("Payment Method", selection: $paymentMethod) {
                        Text("Credit Card").tag("credit_card")
                        Text("Bank Transfer").tag("bank_transfer")
                        Text("Check").tag("check")
                        Text("Cash").tag("cash")
                    }

                    Toggle("Recurring Payment", isOn: $isRecurring)

                    if isRecurring {
                        Stepper("Every \(recurringInterval) month(s)", value: $recurringInterval, in: 1 ... 12)
                    }
                }
            }
            .navigationTitle("Add Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        savePayment()
                    }
                    .disabled(description.isEmpty || amount.isEmpty || vendorName.isEmpty)
                }
            }
        }
    }

    private func savePayment() {
        guard let amountValue = Double(amount), !description.isEmpty, !vendorName.isEmpty else { return }

        // Create PaymentSchedule directly instead of PaymentScheduleItem
        let payment = PaymentSchedule(
            id: Int64.random(in: 1 ... Int64.max),
            coupleId: UUID(), // TODO: Get from auth context
            vendor: vendorName,
            paymentDate: dueDate,
            paymentAmount: amountValue,
            notes: description,
            paid: false,
            autoRenew: isRecurring,
            reminderEnabled: true,
            isDeposit: false,
            isRetainer: false,
            createdAt: Date())

        Task {
            await budgetStore.addPayment(payment)
            dismiss()
        }
    }
}

// MARK: - Bulk Actions View

struct BulkActionsView: View {
    let selectedPayments: Set<String>
    let payments: [PaymentScheduleItem]
    let budgetStore: BudgetStoreV2
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var selectedPaymentItems: [PaymentScheduleItem] {
        payments.filter { selectedPayments.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("\(selectedPayments.count) payments selected")
                    .font(.headline)

                VStack(spacing: 16) {
                    BulkActionButton(
                        title: "Mark as Paid",
                        description: "Mark all selected payments as paid",
                        icon: "checkmark.circle.fill",
                        color: .green) {
                        markAsPaid()
                    }

                    BulkActionButton(
                        title: "Update Due Date",
                        description: "Change the due date for all selected payments",
                        icon: "calendar",
                        color: .blue) {
                        // Update due date
                    }

                    BulkActionButton(
                        title: "Delete Payments",
                        description: "Remove all selected payments",
                        icon: "trash.fill",
                        color: .red) {
                        deletePayments()
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Bulk Actions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func markAsPaid() {
        Task {
            for payment in selectedPaymentItems {
                // Find the original PaymentSchedule and update it
                if let schedule = budgetStore.paymentSchedules.first(where: { String($0.id) == payment.id }) {
                    var updatedSchedule = schedule
                    updatedSchedule.paid = true
                    await budgetStore.updatePayment(updatedSchedule)
                }
            }
            onComplete()
            dismiss()
        }
    }

    private func deletePayments() {
        Task {
            for payment in selectedPaymentItems {
                // Find the original PaymentSchedule and delete it
                if let schedule = budgetStore.paymentSchedules.first(where: { String($0.id) == payment.id }) {
                    await budgetStore.deletePayment(schedule)
                }
            }
            onComplete()
            dismiss()
        }
    }
}

struct BulkActionButton: View {
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
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Types

enum PaymentFilter {
    case all, pending, paid, overdue, thisMonth

    var displayName: String {
        switch self {
        case .all: "All"
        case .pending: "Pending"
        case .paid: "Paid"
        case .overdue: "Overdue"
        case .thisMonth: "This Month"
        }
    }
}

enum PaymentSortOption: String, CaseIterable {
    case dueDate
    case amount
    case vendor
    case status

    var displayName: String {
        switch self {
        case .dueDate: "Due Date"
        case .amount: "Amount"
        case .vendor: "Vendor"
        case .status: "Status"
        }
    }
}

struct PaymentSummaryData {
    let totalAmount: Double
    let paidAmount: Double
    let pendingAmount: Double
    let overdueAmount: Double
    let overdueCount: Int
    let thisMonthAmount: Double
    let thisMonthCount: Int
}

struct PaymentScheduleItem {
    let id: String
    let description: String
    let amount: Double
    let vendorName: String
    let dueDate: Date
    var isPaid: Bool
    let isRecurring: Bool
    let paymentMethod: String?

    init(
        id: String,
        description: String,
        amount: Double,
        vendorName: String,
        dueDate: Date,
        isPaid: Bool,
        isRecurring: Bool = false,
        paymentMethod: String? = nil) {
        self.id = id
        self.description = description
        self.amount = amount
        self.vendorName = vendorName
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.isRecurring = isRecurring
        self.paymentMethod = paymentMethod
    }
}

struct PaymentDetailRow: View {
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
