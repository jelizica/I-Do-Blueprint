import SwiftUI

struct AddExpenseView: View {
    private let logger = AppLogger.ui
    let categories: [BudgetCategory]
    let preselectedCategory: BudgetCategory?
    let onSave: (Expense) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var expenseName = ""
    @State private var amount = ""
    @State private var selectedCategoryId: UUID?
    @State private var selectedVendorId: Int64?
    @State private var selectedPaymentMethod: PaymentMethod = .creditCard
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurringFrequency: RecurringFrequency = .monthly
    @State private var tags: [String] = []
    @State private var currentTag = ""

    // Vendor integration (would be populated from VendorStore)
    @State private var availableVendors: [VendorOption] = []

    init(
        categories: [BudgetCategory],
        preselectedCategory: BudgetCategory? = nil,
        onSave: @escaping (Expense) -> Void) {
        self.categories = categories
        self.preselectedCategory = preselectedCategory
        self.onSave = onSave
        _selectedCategoryId = State(initialValue: preselectedCategory?.id)
    }

    private var isFormValid: Bool {
        !expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            Double(amount) != nil &&
            Double(amount) ?? 0 > 0 &&
            selectedCategoryId != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Expense Name", text: $expenseName)
                        .help("e.g., 'Wedding Venue Deposit', 'Photographer Booking Fee'")

                    TextField("Amount", text: $amount)
                        .overlay(alignment: .leading) {
                            Text("$")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                        }
                        .padding(.leading, 16)

                    Picker("Category", selection: $selectedCategoryId) {
                        Text("Select Category").tag(nil as UUID?)
                        ForEach(categories, id: \.id) { category in
                            HStack {
                                Circle()
                                    .fill(Color(hex: category.color) ?? AppColors.Budget.allocated)
                                    .frame(width: 12, height: 12)
                                Text(category.categoryName)
                            }
                            .tag(category.id as UUID?)
                        }
                    }
                }

                Section("Payment Details") {
                    Picker("Payment Method", selection: $selectedPaymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Has Due Date", isOn: $hasDueDate)

                        if hasDueDate {
                            DatePicker(
                                "Due Date",
                                selection: Binding(
                                    get: { dueDate ?? Date() },
                                    set: { dueDate = $0 }),
                                displayedComponents: .date)
                        }
                    }
                }

                if !availableVendors.isEmpty {
                    Section("Vendor") {
                        Picker("Associated Vendor", selection: $selectedVendorId) {
                            Text("No Vendor").tag(nil as Int64?)
                            ForEach(availableVendors, id: \.id) { vendor in
                                Text(vendor.name).tag(vendor.id as Int64?)
                            }
                        }
                        .help("Link this expense to a specific vendor")
                    }
                }

                Section("Recurring Payment") {
                    Toggle("Recurring Expense", isOn: $isRecurring)

                    if isRecurring {
                        Picker("Frequency", selection: $recurringFrequency) {
                            ForEach(RecurringFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                        }
                    }
                }

                Section("Additional Details") {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3 ... 6)
                        .help("Any additional details about this expense")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            TextField("Add tag", text: $currentTag)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    addTag()
                                }

                            Button("Add") {
                                addTag()
                            }
                            .disabled(currentTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        if !tags.isEmpty {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3),
                                spacing: 4) {
                                ForEach(tags, id: \.self) { tag in
                                    TagView(tag: tag) {
                                        removeTag(tag)
                                    }
                                }
                            }
                        }
                    }
                }

                if let amount = Double(amount), amount > 0, let categoryId = selectedCategoryId {
                    Section("Budget Impact") {
                        if let category = categories.first(where: { $0.id == categoryId }) {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Category Budget")
                                    Spacer()
                                    Text(NumberFormatter.currency
                                        .string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")
                                        .foregroundColor(AppColors.Budget.allocated)
                                }

                                HStack {
                                    Text("Currently Spent")
                                    Spacer()
                                    Text(NumberFormatter.currency
                                        .string(from: NSNumber(value: category.spentAmount)) ?? "$0")
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("After This Expense")
                                    Spacer()
                                    let newTotal = category.spentAmount + amount
                                    Text(NumberFormatter.currency.string(from: NSNumber(value: newTotal)) ?? "$0")
                                        .foregroundColor(newTotal > category.allocatedAmount ? AppColors.Budget.overBudget : AppColors.Budget.underBudget)
                                        .fontWeight(.semibold)
                                }

                                if category.spentAmount + amount > category.allocatedAmount {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(AppColors.Budget.overBudget)
                                        Text("This expense will put the category over budget")
                                            .font(.caption)
                                            .foregroundColor(AppColors.Budget.overBudget)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            loadAvailableVendors()
        }
    }

    private func addTag() {
        let trimmedTag = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty, !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            currentTag = ""
        }
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    private func loadAvailableVendors() {
        // In a real implementation, this would load vendors from VendorStore
        // For now, we'll leave it empty
        availableVendors = []
    }

    private func saveExpense() {
        guard let amount = Double(amount),
              let categoryId = selectedCategoryId else { return }

        let newExpense = Expense(
            id: UUID(),
            coupleId: UUID(), // This should come from current user/couple context
            budgetCategoryId: categoryId,
            vendorId: selectedVendorId,
            expenseName: expenseName.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            expenseDate: hasDueDate ? (dueDate ?? Date()) : Date(),
            paymentMethod: selectedPaymentMethod.rawValue,
            paymentStatus: .pending,
            receiptUrl: nil,
            invoiceNumber: nil,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            approvalStatus: nil,
            approvedBy: nil,
            approvedAt: nil,
            invoiceDocumentUrl: nil,
            isTestData: false,
            createdAt: Date(),
            updatedAt: nil)

        onSave(newExpense)
        dismiss()
    }
}

// MARK: - Supporting Views and Types

struct VendorOption {
    let id: Int64
    let name: String
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColors.Budget.allocated.opacity(0.1))
        .foregroundColor(AppColors.Budget.allocated)
        .clipShape(Capsule())
    }
}

#Preview {
    AddExpenseView(
        categories: [
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Venue",
                parentCategoryId: nil,
                allocatedAmount: 15000,
                spentAmount: 5000,
                typicalPercentage: 35.0,
                priorityLevel: 1,
                isEssential: true,
                notes: nil,
                forecastedAmount: 15000,
                confidenceLevel: 0.9,
                lockedAllocation: false,
                description: "Wedding venue costs",
                createdAt: Date(),
                updatedAt: nil)
        ]) { expense in
            // TODO: Implement action - print("Saved expense: \(expense.expenseName)")
        }
}
