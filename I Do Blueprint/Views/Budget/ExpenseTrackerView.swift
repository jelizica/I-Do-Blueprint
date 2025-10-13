import SwiftUI

struct ExpenseTrackerView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var showAddExpenseSheet = false
    @State private var showEditExpenseSheet = false
    @State private var selectedExpense: Expense?
    @State private var searchText = ""
    @State private var selectedFilterStatus: PaymentStatus? = nil
    @State private var selectedCategoryFilter: UUID?
    @State private var showDeleteAlert = false
    @State private var expenseToDelete: Expense?
    @State private var isLoadingExpenses = false
    @State private var showBenchmarks = false
    @State private var viewMode: ViewMode = .cards

    private let logger = AppLogger.ui

    enum ViewMode {
        case cards, list

        var icon: String {
            switch self {
            case .cards: "rectangle.grid.2x2"
            case .list: "list.bullet"
            }
        }

        var title: String {
            switch self {
            case .cards: "Card View"
            case .list: "List View"
            }
        }
    }

    let filterOptions = ["all", "pending", "paid"]

    var filteredExpenses: [Expense] {
        var results = budgetStore.expenses

        // Apply search filter
        if !searchText.isEmpty {
            results = results.filter { expense in
                expense.expenseName.localizedCaseInsensitiveContains(searchText) ||
                    (expense.notes ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply status filter
        if let filterStatus = selectedFilterStatus {
            results = results.filter { expense in
                expense.paymentStatus == filterStatus
            }
        }

        // Apply category filter
        if let categoryId = selectedCategoryFilter {
            results = results.filter { $0.budgetCategoryId == categoryId }
        }

        return results.sorted { $0.expenseDate > $1.expenseDate }
    }

    // Calculate category benchmarks
    var categoryBenchmarks: [(category: BudgetCategory, spent: Double, percentage: Double, status: BenchmarkStatus)] {
        budgetStore.categories.compactMap { category in
            let categoryExpenses = budgetStore.expensesForCategory(category.id)
            let spent = categoryExpenses.reduce(0) { $0 + $1.amount }
            let budgeted = category.allocatedAmount
            let percentage = budgeted > 0 ? (spent / budgeted) * 100 : 0

            let status: BenchmarkStatus = if percentage > 100 {
                .over
            } else if percentage > 50 {
                .onTrack
            } else {
                .under
            }

            return (category, spent, percentage, status)
        }
    }

    enum BenchmarkStatus {
        case under, onTrack, over

        var color: Color {
            switch self {
            case .under: .blue
            case .onTrack: .green
            case .over: .red
            }
        }

        var icon: String {
            switch self {
            case .under: "arrow.down.circle.fill"
            case .onTrack: "checkmark.circle.fill"
            case .over: "exclamationmark.circle.fill"
            }
        }

        var label: String {
            switch self {
            case .under: "Under Budget"
            case .onTrack: "On Track"
            case .over: "Over Budget"
            }
        }
    }

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header with stats
                headerSection

                // Filters
                filtersSection

                // Expense List
                expenseListSection

                // Category Benchmarks (collapsible)
                if showBenchmarks {
                    categoryBenchmarksSection
                }
            }
            .padding()
        }
        .onAppear {
            loadExpenses()
        }
        .sheet(isPresented: $showAddExpenseSheet) {
            ExpenseTrackerAddView()
                .environmentObject(budgetStore)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseTrackerEditView(expense: expense)
                .environmentObject(budgetStore)
        }
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                expenseToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    deleteExpense(expense)
                }
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Expense Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { showAddExpenseSheet = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Expense")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }

            // Stats Cards
            HStack(spacing: 16) {
                ExpenseStatCard(
                    title: "Total Spent",
                    value: String(format: "$%.2f", budgetStore.totalExpensesAmount),
                    icon: "dollarsign.circle.fill",
                    color: .blue)

                ExpenseStatCard(
                    title: "Pending",
                    value: String(format: "$%.2f", budgetStore.pendingExpensesAmount),
                    icon: "clock.fill",
                    color: .orange)

                ExpenseStatCard(
                    title: "Paid",
                    value: String(format: "$%.2f", budgetStore.paidExpensesAmount),
                    icon: "checkmark.circle.fill",
                    color: .green)

                ExpenseStatCard(
                    title: "Total Expenses",
                    value: "\(budgetStore.expenses.count)",
                    icon: "doc.text.fill",
                    color: .purple)
            }
        }
    }

    private var filtersSection: some View {
        HStack(spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search expenses...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 300)

            // Status Filter
            Picker("Status", selection: $selectedFilterStatus) {
                Text("All Status").tag(nil as PaymentStatus?)
                Text("Pending").tag(PaymentStatus.pending as PaymentStatus?)
                Text("Paid").tag(PaymentStatus.paid as PaymentStatus?)
                Text("Partial").tag(PaymentStatus.partial as PaymentStatus?)
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 150)

            // Category Filter
            Picker("Category", selection: $selectedCategoryFilter) {
                Text("All Categories").tag(nil as UUID?)
                ForEach(budgetStore.categories) { category in
                    Text(category.categoryName).tag(category.id as UUID?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 200)

            Spacer()

            // View Mode Toggle
            HStack(spacing: 0) {
                ForEach([ViewMode.cards, ViewMode.list], id: \.self) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewMode = mode
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 12, weight: .medium))
                            Text(mode == .cards ? "Cards" : "List")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewMode == mode ? Color.blue : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(viewMode == mode ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)

            // Toggle Benchmarks
            Button(action: { withAnimation { showBenchmarks.toggle() } }) {
                HStack {
                    Image(systemName: showBenchmarks ? "chevron.up" : "chevron.down")
                    Text("Benchmarks")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var expenseListSection: some View {
        ScrollView {
            if filteredExpenses.isEmpty {
                emptyStateView
            } else {
                if viewMode == .cards {
                    expenseCardsView
                } else {
                    expenseListView
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            Group {
                if isLoadingExpenses {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            })
    }

    private var expenseCardsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(filteredExpenses) { expense in
                ExpenseCardView(expense: expense) {
                    selectedExpense = expense
                } onDelete: {
                    expenseToDelete = expense
                    showDeleteAlert = true
                }
            }
        }
        .padding()
    }

    private var expenseListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredExpenses) { expense in
                ExpenseTrackerRowView(expense: expense) {
                    selectedExpense = expense
                } onDelete: {
                    expenseToDelete = expense
                    showDeleteAlert = true
                }
            }
        }
        .padding()
    }

    private var categoryBenchmarksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Performance vs Budget")
                .font(.headline)
                .fontWeight(.semibold)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(categoryBenchmarks, id: \.category.id) { benchmark in
                        CategoryBenchmarkRow(
                            category: benchmark.category,
                            spent: benchmark.spent,
                            percentage: benchmark.percentage,
                            status: benchmark.status)
                    }
                }
            }
            .frame(maxHeight: 300)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No expenses found")
                .font(.headline)
                .foregroundColor(.secondary)

            if !searchText.isEmpty || selectedFilterStatus != nil || selectedCategoryFilter != nil {
                Text("Try adjusting your filters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Button(action: { showAddExpenseSheet = true }) {
                    Label("Add Your First Expense", systemImage: "plus")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
        .padding()
    }

    // MARK: - Helper Methods

    private func loadExpenses() {
        Task {
            isLoadingExpenses = true
            defer { isLoadingExpenses = false }

            do {
                try await budgetStore.loadExpenses()
            } catch {
                logger.error("Failed to load expenses", error: error)
            }
        }
    }

    private func deleteExpense(_ expense: Expense) {
        Task {
            do {
                try await budgetStore.deleteExpense(id: expense.id)
                expenseToDelete = nil
            } catch {
                logger.error("Failed to delete expense", error: error)
            }
        }
    }
}

// MARK: - Supporting Views

struct ExpenseStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ExpenseTrackerRowView: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var budgetStore: BudgetStoreV2

    private var category: BudgetCategory? {
        budgetStore.categories.first { $0.id == expense.budgetCategoryId }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(expense.paymentStatus == .paid ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.expenseName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    if let vendorId = expense.vendorId {
                        Label("Vendor #\(vendorId)", systemImage: "building")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let category {
                        Label(category.categoryName, systemImage: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label(formatDate(expense.expenseDate), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let notes = expense.notes, !notes.isEmpty {
                        Label("Has notes", systemImage: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if expense.invoiceDocumentUrl != nil {
                        Label("Invoice", systemImage: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Amount and status
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", expense.amount))
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(expense.paymentStatus.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(expense.paymentStatus == .paid ? Color.green.opacity(0.2) : Color.orange
                        .opacity(0.2))
                    .foregroundColor(expense.paymentStatus == .paid ? Color.green : Color.orange)
                    .cornerRadius(4)
            }

            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct CategoryBenchmarkRow: View {
    let category: BudgetCategory
    let spent: Double
    let percentage: Double
    let status: ExpenseTrackerView.BenchmarkStatus

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(category.categoryName)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Image(systemName: status.icon)
                            .foregroundColor(status.color)
                        Text(status.label)
                            .font(.caption)
                            .foregroundColor(status.color)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "$%.2f", spent))
                        .font(.headline)
                    Text(String(format: "of $%.2f", category.allocatedAmount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(status.color)
                        .frame(
                            width: min(CGFloat(percentage / 100) * geometry.size.width, geometry.size.width),
                            height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.1f%% of budget", percentage))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Add Expense View

struct ExpenseTrackerAddView: View {
    private let logger = AppLogger.ui

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2

    @State private var expenseName = ""
    @State private var amount: Double = 0
    @State private var selectedCategoryId: UUID?
    @State private var selectedVendorId: Int64?
    @State private var expenseDate = Date()
    @State private var paymentMethod = "credit_card"
    @State private var paymentStatus: PaymentStatus = .pending
    @State private var notes = ""
    @State private var isSubmitting = false

    let paymentMethods = [
        ("credit_card", "Credit Card"),
        ("debit_card", "Debit Card"),
        ("cash", "Cash"),
        ("check", "Check"),
        ("bank_transfer", "Bank Transfer"),
        ("venmo", "Venmo"),
        ("zelle", "Zelle"),
        ("other", "Other")
    ]

    let paymentStatuses: [(PaymentStatus, String)] = [
        (.pending, "Pending"),
        (.paid, "Paid"),
        (.partial, "Partial")
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Expense Name", text: $expenseName)

                    TextField(
                        "Amount",
                        value: $amount,
                        format: .currency(code: settingsStore.settings.global.currency))

                    DatePicker("Date", selection: $expenseDate, displayedComponents: .date)
                }

                Section("Details") {
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("Select Category").tag(nil as UUID?)
                        ForEach(budgetStore.categories) { category in
                            Text(category.categoryName).tag(category.id as UUID?)
                        }
                    }

                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.0) { method in
                            Text(method.1).tag(method.0)
                        }
                    }

                    Picker("Payment Status", selection: $paymentStatus) {
                        ForEach(paymentStatuses, id: \.0) { status in
                            Text(status.1).tag(status.0)
                        }
                    }
                }

                Section("Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addExpense()
                    }
                    .disabled(expenseName.isEmpty || amount == 0 || selectedCategoryId == nil || isSubmitting)
                }
            }
        }
    }

    private func addExpense() {
        guard let categoryId = selectedCategoryId else { return }

        guard let coupleId = SessionManager.shared.getTenantId() else {
            logger.error("Cannot add expense: No couple selected")
            return
        }

        isSubmitting = true

        Task {
            do {
                let expense = Expense(
                    id: UUID(),
                    coupleId: coupleId,
                    budgetCategoryId: categoryId,
                    vendorId: selectedVendorId,
                    expenseName: expenseName,
                    amount: amount,
                    expenseDate: expenseDate,
                    paymentMethod: paymentMethod,
                    paymentStatus: paymentStatus,
                    receiptUrl: nil,
                    invoiceNumber: nil,
                    notes: notes.isEmpty ? nil : notes,
                    approvalStatus: "pending",
                    approvedBy: nil,
                    approvedAt: nil,
                    invoiceDocumentUrl: nil,
                    isTestData: false,
                    createdAt: Date(),
                    updatedAt: nil)

                _ = try await budgetStore.createExpense(expense)
                dismiss()
            } catch {
                logger.error("Failed to add expense", error: error)
                isSubmitting = false
            }
        }
    }
}

// MARK: - Edit Expense View

struct ExpenseTrackerEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2

    let expense: Expense

    private let logger = AppLogger.ui

    @State private var expenseName: String
    @State private var amount: Double
    @State private var selectedCategoryId: UUID?
    @State private var expenseDate: Date
    @State private var paymentMethod: String
    @State private var paymentStatus: PaymentStatus
    @State private var notes: String
    @State private var isSubmitting = false

    init(expense: Expense) {
        self.expense = expense
        _expenseName = State(initialValue: expense.expenseName)
        _amount = State(initialValue: expense.amount)
        _selectedCategoryId = State(initialValue: expense.budgetCategoryId)
        _expenseDate = State(initialValue: expense.expenseDate)
        _paymentMethod = State(initialValue: expense.paymentMethod ?? "credit_card")
        _paymentStatus = State(initialValue: expense.paymentStatus)
        _notes = State(initialValue: expense.notes ?? "")
    }

    let paymentMethods = [
        ("credit_card", "Credit Card"),
        ("debit_card", "Debit Card"),
        ("cash", "Cash"),
        ("check", "Check"),
        ("bank_transfer", "Bank Transfer"),
        ("venmo", "Venmo"),
        ("zelle", "Zelle"),
        ("other", "Other")
    ]

    let paymentStatuses: [(PaymentStatus, String)] = [
        (.pending, "Pending"),
        (.paid, "Paid"),
        (.partial, "Partial")
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Expense Name", text: $expenseName)

                    TextField(
                        "Amount",
                        value: $amount,
                        format: .currency(code: settingsStore.settings.global.currency))

                    DatePicker("Date", selection: $expenseDate, displayedComponents: .date)
                }

                Section("Details") {
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("Select Category").tag(nil as UUID?)
                        ForEach(budgetStore.categories) { category in
                            Text(category.categoryName).tag(category.id as UUID?)
                        }
                    }

                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.0) { method in
                            Text(method.1).tag(method.0)
                        }
                    }

                    Picker("Payment Status", selection: $paymentStatus) {
                        ForEach(paymentStatuses, id: \.0) { status in
                            Text(status.1).tag(status.0)
                        }
                    }
                }

                Section("Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateExpense()
                    }
                    .disabled(expenseName.isEmpty || amount == 0 || selectedCategoryId == nil || isSubmitting)
                }
            }
        }
    }

    private func updateExpense() {
        guard let categoryId = selectedCategoryId else { return }

        isSubmitting = true

        Task {
            do {
                var updatedExpense = expense
                updatedExpense.expenseName = expenseName
                updatedExpense.amount = amount
                updatedExpense.budgetCategoryId = categoryId
                updatedExpense.expenseDate = expenseDate
                updatedExpense.paymentMethod = paymentMethod
                updatedExpense.paymentStatus = paymentStatus
                updatedExpense.notes = notes.isEmpty ? nil : notes
                updatedExpense.updatedAt = Date()

                _ = try await budgetStore.updateExpense(updatedExpense)
                dismiss()
            } catch {
                logger.error("Failed to update expense", error: error)
                isSubmitting = false
            }
        }
    }
}

// MARK: - Expense Card View

struct ExpenseCardView: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var budgetStore: BudgetStoreV2

    private var category: BudgetCategory? {
        budgetStore.categories.first { $0.id == expense.budgetCategoryId }
    }

    private var statusColor: Color {
        switch expense.paymentStatus {
        case .paid: .green
        case .pending: .orange
        case .partial: .yellow
        case .overdue: .red
        case .cancelled: .gray
        case .refunded: .blue
        }
    }

    private var approvalStatusColor: Color {
        switch (expense.approvalStatus ?? "pending").lowercased() {
        case "approved": .green
        case "pending": .orange
        case "denied": .red
        default: .gray
        }
    }

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with amount and status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "$%.2f", expense.amount))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        HStack(spacing: 8) {
                            // Payment Status Badge
                            Text(expense.paymentStatus.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(statusColor.opacity(0.2))
                                .foregroundColor(statusColor)
                                .clipShape(Capsule())

                            // Approval Status Badge
                            Text((expense.approvalStatus ?? "Pending").capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(approvalStatusColor.opacity(0.2))
                                .foregroundColor(approvalStatusColor)
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    // Menu button
                    Menu {
                        Button("Edit", action: onEdit)
                        Divider()
                        Button("Delete", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .padding(4)
                            .background(Color.black.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Expense Name
                Text(expense.expenseName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Category info
                if let category {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: category.color) ?? .blue)
                            .frame(width: 8, height: 8)
                        Text(category.categoryName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Date and Payment Method
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(expense.expenseDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: paymentMethodIcon(expense.paymentMethod ?? "credit_card"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(paymentMethodDisplayName(expense.paymentMethod ?? "credit_card"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Notes preview (if available)
                if let notes = expense.notes, !notes.isEmpty {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: false)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                // Add hover effect through shadow
            }
        }
    }

    private func paymentMethodIcon(_ method: String) -> String {
        switch method.lowercased() {
        case "credit_card": "creditcard"
        case "debit_card": "creditcard"
        case "cash": "banknote"
        case "check": "doc.text"
        case "bank_transfer": "building.columns"
        case "venmo": "iphone"
        case "paypal": "globe"
        default: "dollarsign.circle"
        }
    }

    private func paymentMethodDisplayName(_ method: String) -> String {
        switch method.lowercased() {
        case "credit_card": "Credit Card"
        case "debit_card": "Debit Card"
        case "cash": "Cash"
        case "check": "Check"
        case "bank_transfer": "Bank Transfer"
        case "venmo": "Venmo"
        case "paypal": "PayPal"
        default: method.capitalized
        }
    }
}

#Preview {
    ExpenseTrackerView()
        .environmentObject(BudgetStoreV2())
        .frame(width: 1200, height: 800)
}
