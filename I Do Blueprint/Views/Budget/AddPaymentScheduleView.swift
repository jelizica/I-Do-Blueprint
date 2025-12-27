import Foundation
import SwiftUI

// MARK: - Main Add Payment Schedule View

struct AddPaymentScheduleView: View {
    let expenses: [Expense]
    let existingPaymentSchedules: [PaymentSchedule]
    let onSave: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var formData = PaymentFormData()
    @State private var schedule: [PaymentScheduleItem] = []
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @FocusState private var focusedField: FocusedField?

    enum FocusedField: Hashable {
        case partialAmount
        case individualAmount
        case monthlyAmount
        case intervalAmount
        case cyclicalAmount(Int)
        case notes
    }

    private var selectedExpense: Expense? {
        expenses.first { $0.id == formData.selectedExpenseId }
    }

    /// Calculate total already paid for the selected expense from existing payment schedules
    private var alreadyPaidForExpense: Double {
        guard let expenseId = formData.selectedExpenseId else { return 0 }

        return existingPaymentSchedules
            .filter { $0.expenseId == expenseId && $0.paid }
            .reduce(0) { $0 + $1.paymentAmount }
    }

    /// Calculate remaining unpaid amount for the selected expense
    private var remainingUnpaidAmount: Double {
        guard let expense = selectedExpense else { return 0 }
        return max(0, expense.amount - alreadyPaidForExpense)
    }

    private var totalScheduleAmount: Double {
        schedule.reduce(0) { $0 + $1.amount }
    }

    private var amountDifference: Double {
        totalScheduleAmount - formData.totalAmount
    }

    var body: some View {
        mainNavigationView
            .frame(minWidth: 900, minHeight: 600)
            .onAppear(perform: handleOnAppear)
            .onChange(of: formData.selectedExpenseId, perform: updateExpenseAndSchedule)
            .onChange(of: formData.usePartialAmount, perform: updateScheduleOnly)
            .onChange(of: formData.partialAmount, perform: updateScheduleOnly)
            .onChange(of: formData.paymentType, perform: updateScheduleOnly)
            .onChange(of: formData.totalAmount, perform: updateScheduleOnly)
            .onChange(of: formData.individualAmount, perform: updateScheduleOnly)
            .onChange(of: formData.monthlyAmount, perform: updateScheduleOnly)
            .onChange(of: formData.intervalAmount, perform: updateScheduleOnly)
            .onChange(of: formData.intervalMonths, perform: updateScheduleOnly)
            .onChange(of: formData.cyclicalPayments, perform: updateScheduleOnly)
            .alert(
                "Validation Error",
                isPresented: $showingValidationAlert,
                actions: alertActions,
                message: alertMessage)
    }

    private var mainNavigationView: some View {
        NavigationStack {
            contentView
                .navigationTitle("Payment Plan Setup")
                .toolbar(content: toolbarContent)
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Create Plan") {
                savePlan()
            }
            .disabled(!formData.isValid || schedule.isEmpty)
        }
    }

    @ViewBuilder
    private func alertActions() -> some View {
        Button("OK") {}
    }

    @ViewBuilder
    private func alertMessage() -> some View {
        Text(validationMessage)
    }

    private func handleOnAppear() {
        updateTotalAmountFromExpense()
        updateSchedule()
    }

    private func updateExpenseAndSchedule(_: UUID?) {
        updateTotalAmountFromExpense()
        updateSchedule()
    }

    private func updateScheduleOnly(_: some Any) {
        updateSchedule()
    }

    private var contentView: some View {
        HStack(spacing: 0) {
            formPanelView
            Divider()
            previewPanelView
        }
        .onTapGesture {
            focusedField = nil
        }
    }

    private var formPanelView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                expenseSelectionSection

                // Show partial amount selector if an expense is selected
                if let expense = selectedExpense {
                    partialAmountSection(expense: expense)
                }

                paymentTypeSection
                paymentDetailsSection
                additionalOptionsSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var previewPanelView: some View {
        PaymentSchedulePreview(
            schedule: schedule,
            totalAmount: formData.effectiveAmount)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        PaymentPlanHeader()
    }

    // MARK: - Expense Selection Section

    private var expenseSelectionSection: some View {
        ExpenseSelector(
            expenses: expenses,
            selectedExpenseId: $formData.selectedExpenseId,
            alreadyPaid: alreadyPaidForExpense,
            remainingAmount: remainingUnpaidAmount)
    }

    // MARK: - Partial Amount Section

    private func partialAmountSection(expense: Expense) -> some View {
        PartialAmountSelector(
            formData: formData,
            expenseAmount: expense.amount,
            remainingUnpaid: remainingUnpaidAmount,
            focusedField: $focusedField)
    }

    // MARK: - Payment Type Section

    private var paymentTypeSection: some View {
        PaymentTypeSelector(selectedType: $formData.paymentType)
    }


    // MARK: - Payment Details Section

    private var paymentDetailsSection: some View {
        PaymentDetailsForm(formData: formData, focusedField: $focusedField)
    }


    // MARK: - Additional Options Section

    private var additionalOptionsSection: some View {
        AdditionalPaymentOptions(
            enableReminders: $formData.enableReminders,
            notes: $formData.notes,
            focusedField: $focusedField)
    }


    // MARK: - Helper Methods

    private func updateTotalAmountFromExpense() {
        if let expense = selectedExpense {
            formData.totalAmount = expense.amount
        }
    }

    private func updateSchedule() {
        schedule = PaymentScheduleCalculator.calculateSchedule(from: formData)
    }

    private func savePlan() {
        guard formData.isValid else {
            validationMessage = "Please fill in all required fields correctly."
            showingValidationAlert = true
            return
        }

        // Validate that payment doesn't exceed remaining unpaid amount
        let effectiveAmount = formData.effectiveAmount

        guard effectiveAmount > 0 else {
            validationMessage = "Please enter a valid payment amount greater than $0."
            showingValidationAlert = true
            return
        }

        guard effectiveAmount <= remainingUnpaidAmount else {
            validationMessage = "Payment amount cannot exceed the remaining unpaid amount of \(NumberFormatter.currency.string(from: NSNumber(value: remainingUnpaidAmount)) ?? "$0").\n\nThis expense has already had \(NumberFormatter.currency.string(from: NSNumber(value: alreadyPaidForExpense)) ?? "$0") paid through existing payment schedules."
            showingValidationAlert = true
            return
        }

        guard !schedule.isEmpty else {
            validationMessage = "No payment schedule calculated. Please check your inputs."
            showingValidationAlert = true
            return
        }

        guard let coupleId = SessionManager.shared.getTenantId() else {
            validationMessage = "No couple selected. Please select your wedding couple to continue."
            showingValidationAlert = true
            return
        }

        let selectedExpense = expenses.first { $0.id == formData.selectedExpenseId }

        // Validate that the expense has a vendor (vendor_id can be 0, which is valid)
        guard let vendorId = selectedExpense?.vendorId else {
            validationMessage = "This expense must have a vendor assigned before creating a payment schedule."
            showingValidationAlert = true
            return
        }

        // Get vendor name from database - must exist
        // Note: vendor_id can be 0, which is a valid ID
        let vendorName = getVendorName(vendorId)

        guard let vendorName = vendorName, !vendorName.isEmpty else {
            validationMessage = "The vendor for this expense does not exist in the database. Please ensure the vendor is properly set up before creating a payment schedule.\n\nVendor ID: \(vendorId)"
            showingValidationAlert = true
            return
        }

        // Generate a single payment_plan_id for all payments in this plan
        let paymentPlanId = UUID()
        
        // Determine the payment plan type based on the schedule
        let planType: String
        if schedule.count == 1 {
            planType = "individual"
        } else {
            switch formData.paymentType {
            case .individual:
                planType = "installment"  // Multiple individual payments = installment plan
            case .monthly:
                planType = "simple-recurring"
            case .interval:
                planType = "interval-recurring"
            case .cyclical:
                planType = "cyclical-recurring"
            }
        }
        
        // Create all payment schedules from the calculated schedule
        for (index, payment) in schedule.enumerated() {
            let isDeposit = payment.description.contains("Deposit") || payment.description.contains("Retainer")
            let isRetainer = payment.description.contains("Retainer")

            let paymentSchedule = PaymentSchedule(
                id: 0, // Let database auto-generate the ID
                coupleId: coupleId,
                vendor: vendorName,
                paymentDate: payment.dueDate,
                paymentAmount: payment.amount,
                notes: payment.description == formData.notes ? formData.notes : payment.description,
                vendorType: "Vendor Type",
                paid: false,
                paymentType: formData.paymentType.databaseValue,
                customAmount: payment.amount,
                billingFrequency: formData.paymentType == .monthly ? "monthly" : nil,
                autoRenew: false,
                startDate: formData.startDate,
                reminderEnabled: formData.enableReminders,
                reminderDaysBefore: 7,
                priorityLevel: "medium",
                expenseId: formData.selectedExpenseId,
                vendorId: selectedExpense?.vendorId,
                isDeposit: isDeposit,
                isRetainer: isRetainer,
                paymentOrder: index + 1,  // 1-based ordering
                totalPaymentCount: schedule.count,
                paymentPlanType: planType,
                paymentPlanId: paymentPlanId,  // ✅ Assign the same plan ID to all payments
                createdAt: Date(),
                updatedAt: nil)

            onSave(paymentSchedule)
        }

        dismiss()
    }
}


// MARK: - Extensions

#Preview {
    AddPaymentScheduleView(
        expenses: [
            Expense(
                id: UUID(),
                coupleId: UUID(),
                budgetCategoryId: UUID(),
                vendorId: 1,
                expenseName: "Demi Karina Custom Bridal - Veil (Jess)",
                amount: 525.00,
                expenseDate: Date(),
                paymentMethod: "credit_card",
                paymentStatus: .pending,
                notes: "Custom veil for ceremony",
                approvalStatus: "approved",
                invoiceDocumentUrl: nil,
                isTestData: true,
                createdAt: Date(),
                updatedAt: Date())
        ],
        existingPaymentSchedules: [],
        onSave: { _ in },
        getVendorName: { _ in "Sample Vendor" })
}
