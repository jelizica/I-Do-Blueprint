import AppKit
import SwiftUI

struct BudgetCategoryDetailView: View {
    let category: BudgetCategory
    let expenses: [Expense]
    let onUpdateCategory: (BudgetCategory) -> Void
    let onAddExpense: (Expense) -> Void
    let onUpdateExpense: (Expense) -> Void

    @State private var isEditing = false
    @State private var editedCategory: BudgetCategory
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var showingExpenseDetail = false
    @State private var showingEditExpense = false
    @State private var expenseFilterOption: ExpenseFilterOption = .all
    @State private var searchText = ""

    init(
        category: BudgetCategory,
        expenses: [Expense],
        onUpdateCategory: @escaping (BudgetCategory) -> Void,
        onAddExpense: @escaping (Expense) -> Void,
        onUpdateExpense: @escaping (Expense) -> Void) {
        self.category = category
        self.expenses = expenses
        self.onUpdateCategory = onUpdateCategory
        self.onAddExpense = onAddExpense
        self.onUpdateExpense = onUpdateExpense
        _editedCategory = State(initialValue: category)
    }

    var filteredExpenses: [Expense] {
        let filtered = expenses.filter { expense in
            let matchesSearch = searchText.isEmpty || expense.expenseName.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool = switch expenseFilterOption {
            case .all:
                true
            case .pending:
                expense.paymentStatus == .pending
            case .partial:
                expense.paymentStatus == .partial
            case .paid:
                expense.paymentStatus == .paid
            case .overdue:
                expense.isOverdue
            case .dueToday:
                expense.isDueToday
            case .dueSoon:
                expense.isDueSoon
            }

            return matchesSearch && matchesFilter
        }
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category header
                CategoryHeaderView(category: category)

                // Category stats and progress
                CategoryStatsView(category: category, expenses: expenses)

                // Expense management section
                VStack(spacing: 16) {
                    // Section header with controls
                    HStack {
                        Text("Expenses")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Spacer()

                        Button(action: {
                            showingAddExpense = true
                        }) {
                            Label("Add Expense", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                        }
                    }

                    // Search and filter controls
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search expenses...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Picker("Filter", selection: $expenseFilterOption) {
                                ForEach(ExpenseFilterOption.allCases, id: \.self) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            Spacer()
                        }
                    }

                    // Expenses list
                    if filteredExpenses.isEmpty {
                        ContentUnavailableView(
                            "No Expenses Found",
                            systemImage: "doc.text",
                            description: Text(searchText
                                .isEmpty ? "Add your first expense to this category" :
                                "Try adjusting your search or filters"))
                            .frame(minHeight: 200)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredExpenses) { expense in
                                ExpenseRowView(
                                    expense: expense,
                                    onUpdate: onUpdateExpense,
                                    onViewDetails: { expense in
                                        selectedExpense = expense
                                        showingExpenseDetail = true
                                    },
                                    onEdit: { expense in
                                        selectedExpense = expense
                                        showingEditExpense = true
                                    })
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle(category.categoryName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    HStack {
                        Button("Cancel") {
                            editedCategory = category
                            isEditing = false
                        }
                        Button("Save") {
                            onUpdateCategory(editedCategory)
                            isEditing = false
                        }
                        .fontWeight(.semibold)
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(
                categories: [category],
                preselectedCategory: category) { newExpense in
                onAddExpense(newExpense)
            }
            #if os(macOS)
            .frame(minWidth: 600, maxWidth: 700, minHeight: 500, maxHeight: 650)
            #endif
        }
        .sheet(isPresented: $showingExpenseDetail) {
            if let expense = selectedExpense {
                ExpenseDetailView(expense: expense)
            }
        }
        .sheet(isPresented: $showingEditExpense) {
            if let expense = selectedExpense {
                ExpenseTrackerEditView(expense: expense)
                    .environmentObject(BudgetStoreV2())
            }
        }
    }
}

// MARK: - Supporting Views

struct CategoryHeaderView: View {
    let category: BudgetCategory

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Category color
                Circle()
                    .fill(Color(hex: category.color) ?? .blue)
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.categoryName)
                        .font(.title)
                        .fontWeight(.bold)

                    if let description = category.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(NumberFormatter.currency.string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    Text("Budget Allocated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Priority and status badges
            HStack {
                PriorityBadge(priority: category.priority)

                if category.isEssential {
                    StatusBadge(text: "Essential", color: .green)
                }

                if category.isOverBudget {
                    StatusBadge(text: "Over Budget", color: .red)
                }

                Spacer()

                Text("Updated \(formatDate(category.updatedAt ?? category.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CategoryStatsView: View {
    let category: BudgetCategory
    let expenses: [Expense]

    private var expenseStats: (total: Int, pending: Int, paid: Int, overdue: Int) {
        let total = expenses.count
        let pending = expenses.filter { $0.paymentStatus == .pending }.count
        let paid = expenses.filter { $0.paymentStatus == .paid }.count
        let overdue = expenses.filter(\.isOverdue).count
        return (total, pending, paid, overdue)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Budget progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Budget Progress")
                        .font(.headline)

                    Spacer()

                    Text("\(Int(category.percentageSpent))% spent")
                        .font(.subheadline)
                        .foregroundColor(category.isOverBudget ? .red : .secondary)
                }

                ProgressView(value: min(category.percentageSpent / 100, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: category.isOverBudget ? .red : .blue))
                    .scaleEffect(x: 1, y: 3, anchor: .center)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(NumberFormatter.currency.string(from: NSNumber(value: category.spentAmount)) ?? "$0")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(category.isOverBudget ? .red : .primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(NumberFormatter.currency.string(from: NSNumber(value: category.remainingAmount)) ?? "$0")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(category.remainingAmount >= 0 ? .green : .red)
                    }
                }
            }

            Divider()

            // Expense stats
            HStack(spacing: 20) {
                StatItem(
                    title: "Total Expenses",
                    value: "\(expenseStats.total)",
                    icon: "doc.text.fill",
                    color: .blue)

                StatItem(
                    title: "Pending",
                    value: "\(expenseStats.pending)",
                    icon: "clock.fill",
                    color: .orange)

                StatItem(
                    title: "Paid",
                    value: "\(expenseStats.paid)",
                    icon: "checkmark.circle.fill",
                    color: .green)

                if expenseStats.overdue > 0 {
                    StatItem(
                        title: "Overdue",
                        value: "\(expenseStats.overdue)",
                        icon: "exclamationmark.triangle.fill",
                        color: .red)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let onUpdate: (Expense) -> Void
    let onViewDetails: (Expense) -> Void
    let onEdit: (Expense) -> Void

    @State private var showingPaymentSheet = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.expenseName)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(NumberFormatter.currency.string(from: NSNumber(value: expense.amount)) ?? "$0")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if expense.paidAmount > 0 {
                            Text(
                                "Paid: \(NumberFormatter.currency.string(from: NSNumber(value: expense.paidAmount)) ?? "$0")")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                HStack {
                    PaymentStatusBadge(status: expense.paymentStatusEnum)

                    if expense.isOverdue {
                        StatusBadge(text: "Overdue", color: .red)
                    } else if expense.isDueToday {
                        StatusBadge(text: "Due Today", color: .orange)
                    } else if expense.isDueSoon {
                        StatusBadge(text: "Due Soon", color: .yellow)
                    }

                    Spacer()

                    if let dueDate = expense.dueDate {
                        Text("Due: \(formatDate(dueDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let notes = expense.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            VStack(spacing: 8) {
                if expense.paymentStatus != .paid {
                    Button(action: {
                        showingPaymentSheet = true
                    }) {
                        Image(systemName: "dollarsign.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Menu {
                    Button("View Details") {
                        onViewDetails(expense)
                    }

                    Button("Edit Expense") {
                        onEdit(expense)
                    }

                    if expense.receiptUrl != nil {
                        Button("View Receipt") {
                            if let urlString = expense.receiptUrl,
                               let url = URL(string: urlString) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }

                    Divider()

                    if expense.paymentStatus != .paid {
                        Button("Mark as Paid") {
                            var updatedExpense = expense
                            updatedExpense.paymentStatus = .paid
                            updatedExpense.approvedAt = Date()
                            onUpdate(updatedExpense)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .contentShape(Rectangle())
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentRecordView(expense: expense) { updatedExpense in
                onUpdate(updatedExpense)
            }
            #if os(macOS)
            .frame(minWidth: 400, maxWidth: 500, minHeight: 300, maxHeight: 400)
            #endif
        }
    }
}

struct PaymentStatusBadge: View {
    let status: PaymentStatus

    var body: some View {
        StatusBadge(text: status.displayName, color: statusColor)
    }

    private var statusColor: Color {
        switch status {
        case .pending: .orange
        case .partial: .blue
        case .paid: .green
        case .overdue: .red
        case .cancelled: .gray
        case .refunded: .purple
        }
    }
}

struct PriorityBadge: View {
    let priority: BudgetPriority

    var body: some View {
        StatusBadge(text: priority.displayName, color: priorityColor)
    }

    private var priorityColor: Color {
        switch priority {
        case .high: .red
        case .medium: .orange
        case .low: .blue
        }
    }
}

// MARK: - Helper Functions

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

#Preview {
    BudgetCategoryDetailView(
        category: BudgetCategory(
            id: UUID(),
            coupleId: UUID(),
            categoryName: "Venue",
            parentCategoryId: nil,
            allocatedAmount: 15000,
            spentAmount: 12000,
            typicalPercentage: 35.0,
            priorityLevel: 1,
            isEssential: true,
            notes: nil,
            forecastedAmount: 15000,
            confidenceLevel: 0.9,
            lockedAllocation: false,
            description: "Wedding venue and related costs",
            createdAt: Date(),
            updatedAt: Date()),
        expenses: [],
        onUpdateCategory: { _ in },
        onAddExpense: { _ in },
        onUpdateExpense: { _ in })
}

// MARK: - Expense Detail View

struct ExpenseDetailView: View {
    let expense: Expense

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expense Details")
                            .font(.title)
                            .fontWeight(.bold)

                        HStack {
                            Text(NumberFormatter.currency.string(from: NSNumber(value: expense.amount)) ?? "$0")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.blue)

                            Spacer()

                            PaymentStatusBadge(status: expense.paymentStatusEnum)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Divider()

                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Information")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ExpenseDetailRow(label: "Expense Name", value: expense.expenseName)

                        if let vendor = expense.vendorName, !vendor.isEmpty {
                            ExpenseDetailRow(label: "Vendor", value: vendor)
                        }

                        ExpenseDetailRow(label: "Date", value: expense.expenseDate, formatter: .date)

                        ExpenseDetailRow(label: "Category", value: expense.categoryId.uuidString)

                        ExpenseDetailRow(label: "Payment Method", value: expense.paymentMethod?.capitalized ?? "N/A")
                    }

                    Divider()

                    // Payment Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Details")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ExpenseDetailRow(label: "Total Amount", value: expense.amount, formatter: .currency)

                        ExpenseDetailRow(label: "Amount Paid", value: expense.paidAmount, formatter: .currency)

                        ExpenseDetailRow(label: "Remaining", value: expense.remainingAmount, formatter: .currency, valueColor: expense.remainingAmount > 0 ? .red : .green)

                        if let dueDate = expense.dueDate {
                            ExpenseDetailRow(label: "Due Date", value: dueDate, formatter: .date)

                            if expense.isOverdue {
                                let daysOverdue = Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("\(daysOverdue) day\(daysOverdue == 1 ? "" : "s") overdue")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                        .fontWeight(.semibold)
                                }
                            }
                        }

                        if let approvedAt = expense.approvedAt {
                            ExpenseDetailRow(label: "Approved Date", value: approvedAt, formatter: .date)
                        }
                    }

                    // Notes
                    if let notes = expense.notes, !notes.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text(notes)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }

                    // Receipt
                    if let receiptUrl = expense.receiptUrl, !receiptUrl.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Receipt")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Button(action: {
                                if let url = URL(string: receiptUrl) {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)

                                    Text("View Receipt")
                                        .font(.headline)

                                    Spacer()

                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Metadata
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metadata")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ExpenseDetailRow(label: "Created", value: expense.createdAt, formatter: .dateTime)
                        ExpenseDetailRow(label: "Last Updated", value: expense.updatedAt, formatter: .dateTime)
                    }
                }
                .padding()
            }
            .navigationTitle("Expense Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExpenseDetailRow: View {
    let label: String
    let value: Any
    var formatter: ExpenseDetailFormatter = .text
    var valueColor: Color = .primary

    enum ExpenseDetailFormatter {
        case text
        case currency
        case date
        case dateTime
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(formattedValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)

            Spacer()
        }
    }

    private var formattedValue: String {
        switch formatter {
        case .text:
            return "\(value)"
        case .currency:
            if let amount = value as? Double {
                return NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0"
            }
            return "\(value)"
        case .date:
            if let date = value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            }
            return "\(value)"
        case .dateTime:
            if let date = value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            return "\(value)"
        }
    }
}
