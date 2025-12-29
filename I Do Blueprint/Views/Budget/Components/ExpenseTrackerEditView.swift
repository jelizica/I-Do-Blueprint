import SwiftUI

/// Sheet view for editing an existing expense
struct ExpenseTrackerEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2

    let expense: Expense

    private let logger = AppLogger.ui

    @State private var expenseName: String
    @State private var amount: Double
    @State private var selectedCategoryId: UUID?
    @State private var selectedVendorId: Int64?
    @State private var expenseDate: Date
    @State private var paymentMethod: String
    @State private var paymentStatus: PaymentStatus
    @State private var notes: String
    @State private var invoiceNumber: String
    @State private var isSubmitting = false
    @State private var availableVendors: [Vendor] = []

    init(expense: Expense) {
        self.expense = expense
        _expenseName = State(initialValue: expense.expenseName)
        _amount = State(initialValue: expense.amount)
        _selectedCategoryId = State(initialValue: expense.budgetCategoryId)
        _selectedVendorId = State(initialValue: expense.vendorId)
        _expenseDate = State(initialValue: expense.expenseDate)
        _paymentMethod = State(initialValue: expense.paymentMethod ?? "credit_card")
        _paymentStatus = State(initialValue: expense.paymentStatus)
        _notes = State(initialValue: expense.notes ?? "")
        _invoiceNumber = State(initialValue: expense.invoiceNumber ?? "")
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
        (.overdue, "Overdue"),
        (.cancelled, "Cancelled")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Expense Name", text: $expenseName)
                        .help("Name or description of the expense")

                    TextField(
                        "Amount",
                        value: $amount,
                        format: .currency(code: settingsStore.settings.global.currency))
                        .help("Total amount of the expense")

                    DatePicker("Date", selection: $expenseDate, displayedComponents: .date)
                        .help("Date of the expense")

                    TextField("Invoice Number (Optional)", text: $invoiceNumber)
                        .help("Invoice or reference number")
                }

                Section("Category & Vendor") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HierarchicalCategoryPicker(
                            categories: budgetStore.categoryStore.categories,
                            selectedCategoryId: $selectedCategoryId
                        )
                    }
                    .help("Budget category for this expense")

                    Picker("Vendor (Optional)", selection: $selectedVendorId) {
                        Text("No Vendor").tag(nil as Int64?)
                        ForEach(availableVendors) { vendor in
                            Text(vendor.vendorName).tag(vendor.id as Int64?)
                        }
                    }
                    .help("Link this expense to a vendor")
                }

                Section("Payment Details") {
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
                        .frame(minHeight: 60, maxHeight: 120)
                        .help("Any additional notes or details about this expense")
                }
            }
            .formStyle(.grouped)
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
            .task {
                await loadVendors()
            }
        }
    }

    private func loadVendors() async {
        let vendorStore = AppStores.shared.vendor
        await vendorStore.loadVendors()
        availableVendors = vendorStore.vendors
            .filter { !$0.isArchived }
            .sorted { $0.vendorName < $1.vendorName }
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
                updatedExpense.vendorId = selectedVendorId
                updatedExpense.expenseDate = expenseDate
                updatedExpense.paymentMethod = paymentMethod
                updatedExpense.paymentStatus = paymentStatus
                updatedExpense.invoiceNumber = invoiceNumber.isEmpty ? nil : invoiceNumber
                updatedExpense.notes = notes.isEmpty ? nil : notes
                updatedExpense.updatedAt = Date()

                _ = try await budgetStore.expenseStore.updateExpense(updatedExpense)
                dismiss()
            } catch {
                logger.error("Failed to update expense", error: error)
                isSubmitting = false
            }
        }
    }
}
