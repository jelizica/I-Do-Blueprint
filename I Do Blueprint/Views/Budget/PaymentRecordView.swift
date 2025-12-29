import SwiftUI

struct PaymentRecordView: View {
    private let logger = AppLogger.ui
    let expense: Expense
    let onSave: (Expense) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var paymentAmount = ""
    @State private var selectedPaymentMethod: PaymentMethod
    @State private var paymentDate = Date()
    @State private var notes = ""
    @State private var markAsFullyPaid = false

    init(expense: Expense, onSave: @escaping (Expense) -> Void) {
        self.expense = expense
        self.onSave = onSave
        let paymentMethod = PaymentMethod(rawValue: expense.paymentMethod ?? "credit_card") ?? .creditCard
        _selectedPaymentMethod = State(initialValue: paymentMethod)
        _paymentAmount = State(initialValue: String(expense.remainingAmount))
        _markAsFullyPaid = State(initialValue: expense.remainingAmount <= 0.01)
    }

    private var paymentAmountValue: Double {
        Double(paymentAmount) ?? 0
    }

    private var isFormValid: Bool {
        paymentAmountValue > 0 && paymentAmountValue <= expense.remainingAmount + 0.01
    }

    private var newPaidAmount: Double {
        expense.paidAmount + paymentAmountValue
    }

    private var newRemainingAmount: Double {
        expense.amount - newPaidAmount
    }

    private var newPaymentStatus: PaymentStatus {
        if markAsFullyPaid || newRemainingAmount <= 0.01 {
            .paid
        } else if newPaidAmount > 0 {
            .partial
        } else {
            .pending
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Information") {
                    HStack {
                        Text("Expense")
                        Spacer()
                        Text(expense.expenseName)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total Amount")
                        Spacer()
                        Text(NumberFormatter.currencyShort.string(from: NSNumber(value: expense.amount)) ?? "$0")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Already Paid")
                        Spacer()
                        Text(NumberFormatter.currencyShort.string(from: NSNumber(value: expense.paidAmount)) ?? "$0")
                            .foregroundColor(AppColors.Budget.income)
                    }

                    HStack {
                        Text("Remaining")
                        Spacer()
                        Text(NumberFormatter.currencyShort.string(from: NSNumber(value: expense.remainingAmount)) ?? "$0")
                            .foregroundColor(AppColors.Budget.pending)
                            .fontWeight(.semibold)
                    }
                }

                Section("Payment Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Payment Amount")
                                .fontWeight(.medium)
                            Spacer()
                            Toggle("Pay in Full", isOn: $markAsFullyPaid)
                                .labelsHidden()
                        }

                        TextField("Amount", text: $paymentAmount)
                            .overlay(alignment: .leading) {
                                Text("$")
                                    .foregroundColor(.secondary)
                                    .padding(.leading, Spacing.sm)
                            }
                            .padding(.leading, Spacing.lg)
                            .disabled(markAsFullyPaid)
                            .onChange(of: markAsFullyPaid) { _, newValue in
                                if newValue {
                                    paymentAmount = String(expense.remainingAmount)
                                }
                            }
                    }

                    DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)

                    Picker("Payment Method", selection: $selectedPaymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }

                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(2 ... 4)
                        .help("Any additional notes about this payment")
                }

                Section("Payment Summary") {
                    HStack {
                        Text("Payment Amount")
                        Spacer()
                        Text(NumberFormatter.currencyShort.string(from: NSNumber(value: paymentAmountValue)) ?? "$0")
                            .foregroundColor(AppColors.Budget.allocated)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("New Paid Total")
                        Spacer()
                        Text(NumberFormatter.currencyShort.string(from: NSNumber(value: newPaidAmount)) ?? "$0")
                            .foregroundColor(AppColors.Budget.income)
                    }

                    HStack {
                        Text("New Remaining")
                        Spacer()
                        Text(NumberFormatter.currencyShort.string(from: NSNumber(value: max(0, newRemainingAmount))) ?? "$0")
                            .foregroundColor(newRemainingAmount <= 0.01 ? AppColors.Budget.income : AppColors.Budget.pending)
                    }

                    HStack {
                        Text("New Status")
                        Spacer()
                        PaymentStatusBadge(status: newPaymentStatus)
                    }

                    if paymentAmountValue > expense.remainingAmount + 0.01 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.Budget.overBudget)
                            Text("Payment amount exceeds remaining balance")
                                .font(.caption)
                                .foregroundColor(AppColors.Budget.overBudget)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Record Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save Payment") {
                        savePayment()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private func savePayment() {
        var updatedExpense = expense

        // Update payment details
        updatedExpense.paymentStatus = newPaymentStatus
        updatedExpense.paymentMethod = selectedPaymentMethod.rawValue
        updatedExpense.approvedAt = paymentDate
        updatedExpense.updatedAt = Date()

        // Add payment notes to existing notes
        if !notes.isEmpty {
            let paymentNote = "Payment on \(formatDateInUserTimezone(paymentDate)): \(notes)"
            if let existingNotes = updatedExpense.notes {
                updatedExpense.notes = "\(existingNotes)\n\(paymentNote)"
            } else {
                updatedExpense.notes = paymentNote
            }
        }

        onSave(updatedExpense)
        dismiss()
    }
    
    private func formatDateInUserTimezone(_ date: Date) -> String {
        // Use user's timezone for date formatting
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
        return DateFormatting.formatDateShort(date, timezone: userTimezone)
    }
}

#Preview {
    PaymentRecordView(
        expense: Expense(
            id: UUID(),
            coupleId: UUID(),
            budgetCategoryId: UUID(),
            vendorId: nil,
            expenseName: "Wedding Venue Deposit",
            amount: 5000,
            expenseDate: Date(),
            paymentMethod: "credit_card",
            paymentStatus: .partial,
            receiptUrl: nil,
            invoiceNumber: nil,
            notes: nil,
            approvalStatus: nil,
            approvedBy: nil,
            approvedAt: nil,
            invoiceDocumentUrl: nil,
            isTestData: false,
            createdAt: Date(),
            updatedAt: nil)) { expense in
        // TODO: Implement action - print("Updated expense: \(expense.expenseName)")
    }
}
