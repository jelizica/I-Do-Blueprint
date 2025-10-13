import SwiftUI

struct ExpenseLinkingView: View {
    @Binding var isPresented: Bool
    let budgetItem: BudgetOverviewItem
    let activeScenario: SavedScenario?
    let onSuccess: () -> Void

    @EnvironmentObject var budgetStore: BudgetStoreV2

    // State for expenses
    @State private var expenses: [Expense] = []
    @State private var filteredExpenses: [Expense] = []
    @State private var selectedExpenses: Set<UUID> = []
    @State private var linkedExpenseIds: Set<UUID> = []

    // Search and filter state
    @State private var searchText = ""
    @State private var hideLinkedExpenses = false

    // Loading and error state
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var linkingProgress: (current: Int, total: Int)?

    // Vendor information cache
    @State private var vendorCache: [Int64: Vendor] = [:]
    @State private var categoryCache: [UUID: BudgetCategory] = [:]

    private let logger = AppLogger.ui

    private var availableExpenses: [Expense] {
        filteredExpenses.filter { !linkedExpenseIds.contains($0.id) }
    }

    private var selectedExpensesList: [Expense] {
        expenses.filter { selectedExpenses.contains($0.id) }
    }

    private var totalAllocationAmount: Double {
        selectedExpensesList.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection

                if let error = errorMessage {
                    errorView(error)
                }

                if isLoading {
                    ProgressView("Loading expenses...")
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            searchSection
                            filterSection

                            if !selectedExpenses.isEmpty {
                                selectionSummary
                            }

                            expensesList

                            if !selectedExpenses.isEmpty {
                                allocationPreview
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                footerSection
            }
            .frame(width: 700, height: 600)
            .navigationTitle("Link Expenses to \(budgetItem.itemName)")
        }
        .onAppear {
            logger.debug("ExpenseLinkingView appeared - budgetItem: \(budgetItem.itemName), ID: \(budgetItem.id), activeScenario: \(activeScenario?.scenarioName ?? "nil")")
            Task {
                await loadExpenses()
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select expenses to allocate to this budget item")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let scenario = activeScenario {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Active Scenario: \(scenario.scenarioName)")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Active scenario not available - expense linking disabled")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search expenses by name, vendor, or category...", text: $searchText)
                .textFieldStyle(.plain)
                .onChange(of: searchText) {
                    filterExpenses()
                }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var filterSection: some View {
        HStack {
            Toggle("Hide already linked expenses", isOn: $hideLinkedExpenses)
                .onChange(of: hideLinkedExpenses) {
                    filterExpenses()
                }

            Spacer()

            if !expenses.isEmpty {
                Text("\(linkedExpenseIds.count) of \(expenses.count) expenses already linked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var selectionSummary: some View {
        HStack {
            Button(action: toggleSelectAll) {
                HStack(spacing: 4) {
                    Image(systemName: selectedExpenses.count == availableExpenses.count ?
                        "checkmark.square.fill" : "square")
                    Text("Select All (\(availableExpenses.count) available)")
                        .font(.subheadline)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(selectedExpenses.count) selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !linkedExpenseIds.isEmpty {
                Text("• \(linkedExpenseIds.count) already linked")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var expensesList: some View {
        VStack(spacing: 8) {
            if filteredExpenses.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredExpenses) { expense in
                    expenseRow(expense)
                }
            }
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        let isLinked = linkedExpenseIds.contains(expense.id)
        let isSelected = selectedExpenses.contains(expense.id)

        return HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                if !isLinked {
                    toggleExpenseSelection(expense)
                }
            }) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isLinked ? .gray : (isSelected ? .accentColor : .secondary))
            }
            .buttonStyle(.plain)
            .disabled(isLinked)

            // Expense details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.expenseName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isLinked ? .secondary : .primary)

                    if isLinked {
                        Label("Already Linked", systemImage: "link")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // Payment status badge
                    paymentStatusBadge(expense.paymentStatus)
                }

                HStack(spacing: 16) {
                    // Amount
                    Label(formatCurrency(expense.amount), systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.green)

                    // Date
                    Label(formatDate(expense.expenseDate), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Vendor
                    if let vendorId = expense.vendorId,
                       let vendor = vendorCache[vendorId] {
                        Label(vendor.vendorName, systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Category
                    if let category = categoryCache[expense.budgetCategoryId] {
                        Label(category.categoryName, systemImage: "tag")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) :
                    (isLinked ? Color.gray.opacity(0.05) : Color(NSColor.controlBackgroundColor)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)))
        .opacity(isLinked ? 0.6 : 1.0)
    }

    private func paymentStatusBadge(_ status: PaymentStatus) -> some View {
        let config = paymentStatusConfig(status)
        return HStack(spacing: 4) {
            Image(systemName: config.icon)
                .font(.caption2)
            Text(config.label)
                .font(.caption)
        }
        .foregroundColor(config.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(config.color.opacity(0.1))
        .clipShape(Capsule())
    }

    private func paymentStatusConfig(_ status: PaymentStatus) -> (label: String, icon: String, color: Color) {
        switch status {
        case .paid:
            ("Paid", "checkmark.circle.fill", .green)
        case .pending:
            ("Pending", "clock.fill", .orange)
        case .partial:
            ("Partial", "clock.fill", .yellow)
        case .overdue:
            ("Overdue", "exclamationmark.circle.fill", .red)
        case .cancelled:
            ("Cancelled", "xmark.circle.fill", .gray)
        case .refunded:
            ("Refunded", "arrow.uturn.backward.circle.fill", .blue)
        }
    }

    private var allocationPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allocation Method")
                .font(.headline)

            // Proportional allocation info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                    Text("Proportional allocation (automatic)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text("Expenses will be allocated proportionally based on budget amounts within the scenario.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // How it works
            VStack(alignment: .leading, spacing: 4) {
                Text("How proportional allocation works:")
                    .font(.caption)
                    .fontWeight(.medium)

                Text("• If only this budget item is linked, it receives 100% allocation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("• Multiple linked items split proportionally based on budget amounts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("• Over-budget allocations are allowed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Allocation Preview")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    Text("Budget Item: \(budgetItem.itemName)")
                        .font(.caption)
                    Spacer()
                    Text("Remaining: \(formatCurrency(budgetItem.budgeted - budgetItem.spent))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Text("Selected Expenses (\(selectedExpenses.count)):")
                    .font(.caption)
                    .fontWeight(.medium)

                ForEach(selectedExpensesList) { expense in
                    HStack {
                        Text(expense.expenseName)
                            .font(.caption)
                        Spacer()
                        Text(formatCurrency(expense.amount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HStack {
                    Text("Estimated Total Allocation:")
                        .font(.caption)
                        .fontWeight(.bold)
                    Spacer()
                    Text(formatCurrency(totalAllocationAmount))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                if totalAllocationAmount > (budgetItem.budgeted - budgetItem.spent) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(
                            "Exceeds remaining budget by \(formatCurrency(totalAllocationAmount - (budgetItem.budgeted - budgetItem.spent)))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)

            Text("No expenses found")
                .font(.headline)

            Text("Try adjusting your search terms or add new expenses")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
            Spacer()
            Button("Dismiss") {
                errorMessage = nil
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding()
    }

    private var footerSection: some View {
        HStack {
            if let progress = linkingProgress {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Linking expenses...")
                        .font(.caption)
                    ProgressView(value: Double(progress.current), total: Double(progress.total))
                        .progressViewStyle(.linear)
                    Text("\(progress.current) of \(progress.total)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 200)
            }

            Spacer()

            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.plain)

            Button(action: linkExpenses) {
                if isSubmitting {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(linkingProgress != nil ?
                            "Linking \(linkingProgress!.current) of \(linkingProgress!.total)..." :
                            "Linking...")
                    }
                } else if activeScenario == nil {
                    Text("Active Scenario Required")
                } else {
                    Text(selectedExpenses.count == 1 ?
                        "Link Expense" :
                        "Link \(selectedExpenses.count) Expenses")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedExpenses.isEmpty || isSubmitting || activeScenario == nil)
        }
        .padding()
    }

    // MARK: - Actions

    private func loadExpenses() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all expenses
            let allExpenses = try await SupabaseManager.shared.fetchExpenses()

            // Fetch vendors for expense display
            let vendors = try await SupabaseManager.shared.fetchVendors()
            vendorCache = Dictionary(uniqueKeysWithValues: vendors.map { ($0.id, $0) })

            // Fetch categories for expense display
            let categories = try await SupabaseManager.shared.fetchBudgetCategories()
            categoryCache = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

            // Fetch linked expense allocations for current scenario and budget item
            if let scenario = activeScenario {
                let allocations = try await SupabaseManager.shared.fetchExpenseAllocations(
                    scenarioId: scenario.id,
                    budgetItemId: budgetItem.id)
                linkedExpenseIds = Set(allocations.map { UUID(uuidString: $0.expenseId) }.compactMap { $0 })
            }

            await MainActor.run {
                expenses = allExpenses
                filterExpenses()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load expenses: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func filterExpenses() {
        var filtered = expenses

        // Apply search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { expense in
                expense.expenseName.lowercased().contains(searchLower) ||
                    (vendorCache[expense.vendorId ?? -1]?.vendorName.lowercased().contains(searchLower) ?? false) ||
                    (categoryCache[expense.budgetCategoryId]?.categoryName.lowercased().contains(searchLower) ?? false)
            }
        }

        // Hide linked expenses if requested
        if hideLinkedExpenses {
            filtered = filtered.filter { !linkedExpenseIds.contains($0.id) }
        }

        filteredExpenses = filtered
    }

    private func toggleExpenseSelection(_ expense: Expense) {
        if selectedExpenses.contains(expense.id) {
            selectedExpenses.remove(expense.id)
            logger.debug("Removed expense from selection: \(expense.expenseName). Total selected: \(selectedExpenses.count)")
        } else {
            selectedExpenses.insert(expense.id)
            logger.debug("Added expense to selection: \(expense.expenseName). Total selected: \(selectedExpenses.count)")
        }
    }

    private func toggleSelectAll() {
        let available = availableExpenses
        if selectedExpenses.count == available.count {
            // Deselect all
            selectedExpenses.removeAll()
        } else {
            // Select all available
            selectedExpenses = Set(available.map(\.id))
        }
    }

    private func linkExpenses() {
        logger.debug("LinkExpenses called - selectedExpenses: \(selectedExpenses.count), activeScenario: \(activeScenario?.scenarioName ?? "nil"), budgetItem: \(budgetItem.itemName)")

        guard let scenario = activeScenario,
              !selectedExpenses.isEmpty else {
            logger.warning("Guard failed - scenario exists: \(activeScenario != nil), has selected expenses: \(!selectedExpenses.isEmpty)")
            return
        }

        logger.debug("Starting expense linking process for \(selectedExpenses.count) expenses")
        isSubmitting = true
        errorMessage = nil
        linkingProgress = (current: 0, total: selectedExpenses.count)

        Task {
            logger.debug("Task started - processing \(selectedExpenses.count) expenses")
            var successCount = 0
            var failedExpenses: [(expense: Expense, error: String)] = []

            for (index, expenseId) in selectedExpenses.enumerated() {
                logger.debug("Processing expense \(index + 1)/\(selectedExpenses.count) - ID: \(expenseId)")
                guard let expense = expenses.first(where: { $0.id == expenseId }) else {
                    logger.warning("Could not find expense with ID: \(expenseId)")
                    continue
                }

                do {
                    // Create expense allocation
                    let allocation = ExpenseAllocation(
                        id: UUID().uuidString,
                        expenseId: expense.id.uuidString,
                        budgetItemId: budgetItem.id,
                        allocatedAmount: expense.amount, // Will be recalculated server-side for proportional
                        percentage: nil,
                        notes: "Linked via Budget Overview Dashboard",
                        createdAt: Date(),
                        updatedAt: nil,
                        coupleId: scenario.coupleId,
                        scenarioId: scenario.id,
                        isTestData: false)

                    logger.debug("Creating allocation: \(allocation.expenseId) -> \(allocation.budgetItemId)")
                    try await SupabaseManager.shared.createExpenseAllocation(allocation)
                    logger.info("Successfully created allocation for expense: \(expense.expenseName)")
                    successCount += 1

                    await MainActor.run {
                        linkingProgress = (current: index + 1, total: selectedExpenses.count)
                    }
                } catch {
                    logger.error("Failed to create allocation for expense \(expense.expenseName)", error: error)
                    failedExpenses.append((expense, error.localizedDescription))
                    await MainActor.run {
                        linkingProgress = (current: index + 1, total: selectedExpenses.count)
                    }
                }
            }

            logger.debug("Processing complete - Success: \(successCount), Failed: \(failedExpenses.count)")

            await MainActor.run {
                if failedExpenses.isEmpty {
                    logger.info("All \(successCount) expenses linked successfully!")
                    // All successful
                    onSuccess()
                    isPresented = false
                } else if successCount == 0 {
                    logger.error("All expenses failed to link")
                    // All failed
                    errorMessage = "Failed to link all expenses: \(failedExpenses.map(\.error).joined(separator: ", "))"
                } else {
                    logger.warning("Mixed results - \(successCount) success, \(failedExpenses.count) failed")
                    // Mixed results
                    errorMessage = "Linked \(successCount) expenses. Failed: \(failedExpenses.map { "\($0.expense.expenseName) - \($0.error)" }.joined(separator: ", "))"
                    onSuccess() // Still refresh parent to show partial success
                }

                isSubmitting = false
                linkingProgress = nil
            }
        }
    }

    // MARK: - Formatters

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
