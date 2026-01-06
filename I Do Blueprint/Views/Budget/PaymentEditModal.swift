import SwiftUI

struct PaymentEditModal: View {
    let payment: PaymentSchedule
    let expense: Expense?
    let getVendorName: (Int64?) -> String?
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var editedPayment: PaymentSchedule
    @State private var showingDeleteAlert = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    // MARK: - Proportional Modal Sizing Pattern

    private let minWidth: CGFloat = 500
    private let maxWidth: CGFloat = 700
    private let minHeight: CGFloat = 550
    private let maxHeight: CGFloat = 700
    private let widthProportion: CGFloat = 0.50
    private let heightProportion: CGFloat = 0.75

    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = parentSize.width * widthProportion
        let targetHeight = parentSize.height * heightProportion
        let finalWidth = min(maxWidth, max(minWidth, targetWidth))
        let finalHeight = min(maxHeight, max(minHeight, targetHeight))
        return CGSize(width: finalWidth, height: finalHeight)
    }

    init(
        payment: PaymentSchedule,
        expense: Expense?,
        getVendorName: @escaping (Int64?) -> String?,
        onUpdate: @escaping (PaymentSchedule) -> Void,
        onDelete: @escaping () -> Void) {
        self.payment = payment
        self.expense = expense
        self.getVendorName = getVendorName
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _editedPayment = State(initialValue: payment)
    }

    private var isFormValid: Bool {
        editedPayment.paymentAmount > 0 && !editedPayment.vendor.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Payment Details Header
                    paymentDetailsHeader

                    // Edit Form
                    editForm

                    // Payment Status Section
                    paymentStatusSection

                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Payment Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .alert("Delete Payment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this payment? This action cannot be undone.")
        }
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") {}
        } message: {
            Text(validationMessage)
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
    }

    private var paymentDetailsHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(editedPayment.paid ? Color
                        .green : (editedPayment.paymentDate < Date() ? Color.red : Color.orange))
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense?.expenseName ?? "Payment")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(getVendorName(expense?.vendorId) ?? editedPayment.vendor)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: editedPayment.paymentAmount)) ?? "$0")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(editedPayment.paid ? .green : .primary)

                    Text(paymentStatusText)
                        .font(.caption)
                        .foregroundColor(editedPayment
                            .paid ? .green : (editedPayment.paymentDate < Date() ? .red : .orange))
                }
            }

            if let notes = editedPayment.notes, !notes.isEmpty {
                HStack {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var editForm: some View {
        VStack(spacing: 16) {
            Text("Edit Payment")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Payment Amount
                HStack {
                    Text("Amount")
                        .frame(width: 100, alignment: .leading)
                    TextField(
                        "$0.00",
                        value: $editedPayment.paymentAmount,
                        format: .currency(code: settingsStore.settings.global.currency))
                        .textFieldStyle(.roundedBorder)
                }

                // Payment Date
                HStack {
                    Text("Due Date")
                        .frame(width: 100, alignment: .leading)
                    DatePicker("", selection: $editedPayment.paymentDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                // Payment Type
                if let paymentType = editedPayment.paymentType {
                    HStack {
                        Text("Type")
                            .frame(width: 100, alignment: .leading)
                        Picker("Payment Type", selection: Binding(
                            get: { editedPayment.paymentType ?? "individual" },
                            set: { editedPayment.paymentType = $0 })) {
                            Text("Individual").tag("individual")
                            Text("Monthly").tag("monthly")
                            Text("Interval").tag("interval")
                            Text("Cyclical").tag("cyclical")
                            Text("Deposit").tag("deposit")
                            Text("Retainer").tag("retainer")
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Notes
                HStack(alignment: .top) {
                    Text("Notes")
                        .frame(width: 100, alignment: .leading)
                    TextField("Add notes...", text: Binding(
                        get: { editedPayment.notes ?? "" },
                        set: { editedPayment.notes = $0.isEmpty ? nil : $0 }), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3 ... 6)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var paymentStatusSection: some View {
        VStack(spacing: 16) {
            Text("Payment Status")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(action: {
                    editedPayment.paid.toggle()
                    if editedPayment.paid {
                        editedPayment.updatedAt = Date()
                    }
                }) {
                    HStack {
                        Image(systemName: editedPayment.paid ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(editedPayment.paid ? .green : .secondary)
                            .font(.title2)

                        Text(editedPayment.paid ? "Paid" : "Mark as Paid")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if editedPayment.paid {
                    Text("✓ Payment completed")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Delete Payment") {
                showingDeleteAlert = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
        }
    }

    private var paymentStatusText: String {
        if editedPayment.paid {
            return "Paid"
        } else if editedPayment.paymentDate < Date() {
            let daysPast = Calendar.current.dateComponents([.day], from: editedPayment.paymentDate, to: Date()).day ?? 0
            return "\(daysPast) days overdue"
        } else {
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: editedPayment.paymentDate)
                .day ?? 0
            return "Due in \(daysUntil) days"
        }
    }

    private func saveChanges() {
        guard isFormValid else {
            validationMessage = "Please ensure all required fields are filled correctly."
            showingValidationAlert = true
            return
        }

        var updatedPayment = editedPayment
        updatedPayment.updatedAt = Date()

        onUpdate(updatedPayment)
        dismiss()
    }
}

#Preview {
    let samplePayment = PaymentSchedule(
        id: 1,
        coupleId: UUID(),
        vendor: "Sample Vendor",
        paymentDate: Date(),
        paymentAmount: 1500.0,
        notes: "Sample payment notes",
        vendorType: "Photography",
        paid: false,
        paymentType: "individual",  // ✅ Valid DB constraint value
        customAmount: nil,
        billingFrequency: nil,
        autoRenew: false,
        startDate: nil,
        reminderEnabled: false,
        reminderDaysBefore: 7,
        priorityLevel: "medium",
        expenseId: UUID(),
        vendorId: 1,
        isDeposit: true,
        isRetainer: false,
        paymentOrder: nil,
        totalPaymentCount: nil,
        paymentPlanType: nil,
        createdAt: Date(),
        updatedAt: nil)

    let sampleExpense = Expense(
        id: UUID(),
        coupleId: UUID(),
        budgetCategoryId: UUID(),
        vendorId: 1,
        expenseName: "Wedding Photography",
        amount: 3000.0,
        expenseDate: Date(),
        paymentMethod: "credit_card",
        paymentStatus: .pending,
        notes: "Sample expense",
        approvalStatus: "approved",
        invoiceDocumentUrl: nil,
        isTestData: true,
        createdAt: Date(),
        updatedAt: Date())

    PaymentEditModal(
        payment: samplePayment,
        expense: sampleExpense,
        getVendorName: { _ in "Sample Vendor" },
        onUpdate: { _ in },
        onDelete: {})
}
