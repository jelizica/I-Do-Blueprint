import SwiftUI

/// Sheet view for adding a new expense
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
    @State private var invoiceNumber = ""
    @State private var isSubmitting = false
    @State private var availableVendors: [Vendor] = []
    
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
                    Picker("Category", selection: $selectedCategoryId) {
                        Text("Select Category").tag(nil as UUID?)
                        ForEach(budgetStore.categories) { category in
                            Text(category.categoryName).tag(category.id as UUID?)
                        }
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
                    invoiceNumber: invoiceNumber.isEmpty ? nil : invoiceNumber,
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
