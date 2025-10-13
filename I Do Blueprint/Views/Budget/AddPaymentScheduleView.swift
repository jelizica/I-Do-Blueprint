import Combine
import Foundation
import SwiftUI

// MARK: - Payment Form Models

enum PaymentType: String, CaseIterable {
    case individual
    case monthly = "simple-recurring"
    case interval = "interval-recurring"
    case cyclical = "cyclical-recurring"

    var displayName: String {
        switch self {
        case .individual: "Individual"
        case .monthly: "Monthly"
        case .interval: "Interval"
        case .cyclical: "Cyclical"
        }
    }

    var databaseValue: String {
        switch self {
        case .individual: "single"
        case .monthly: "monthly"
        case .interval: "custom"
        case .cyclical: "custom"
        }
    }

    var icon: String {
        switch self {
        case .individual: "1.circle.fill"
        case .monthly: "calendar.circle.fill"
        case .interval: "timer.circle.fill"
        case .cyclical: "repeat.circle.fill"
        }
    }
}

struct CyclicalPayment: Identifiable, Equatable {
    let id = UUID()
    var amount: Double = 0
    var order: Int
}

class PaymentFormData: ObservableObject {
    @Published var paymentType: PaymentType = .individual
    @Published var selectedExpenseId: UUID?
    @Published var totalAmount: Double = 0
    @Published var startDate = Date()

    // Deposit settings
    @Published var hasDeposit = false
    @Published var usePercentage = true
    @Published var depositAmount: Double = 0
    @Published var depositPercentage: Double = 20
    @Published var isDepositRetainer = false

    // Individual payment settings
    @Published var individualAmount: Double = 0
    @Published var isIndividualDeposit = false
    @Published var isIndividualRetainer = false

    // Monthly recurring settings
    @Published var monthlyAmount: Double = 0
    @Published var isFirstMonthlyDeposit = false
    @Published var isFirstMonthlyRetainer = false

    // Interval recurring settings
    @Published var intervalAmount: Double = 0
    @Published var intervalMonths: Int = 1
    @Published var isFirstIntervalDeposit = false
    @Published var isFirstIntervalRetainer = false

    // Cyclical recurring settings
    @Published var cyclicalPayments: [CyclicalPayment] = [CyclicalPayment(order: 1)]
    @Published var isFirstCyclicalDeposit = false
    @Published var isFirstCyclicalRetainer = false

    @Published var notes: String = ""
    @Published var enableReminders = true

    var isValid: Bool {
        guard selectedExpenseId != nil, totalAmount > 0 else { return false }

        switch paymentType {
        case .individual:
            return individualAmount > 0
        case .monthly:
            return monthlyAmount > 0
        case .interval:
            return intervalAmount > 0 && intervalMonths > 0
        case .cyclical:
            return cyclicalPayments.contains { $0.amount > 0 }
        }
    }

    var actualDepositAmount: Double {
        guard hasDeposit else { return 0 }
        return usePercentage ? (totalAmount * depositPercentage / 100) : depositAmount
    }
}

// MARK: - Payment Schedule Calculator

class PaymentScheduleCalculator {
    static func calculateSchedule(from formData: PaymentFormData) -> [PaymentScheduleItem] {
        var schedule: [PaymentScheduleItem] = []
        var remainingAmount = formData.totalAmount
        _ = formData.selectedExpenseId

        // Add deposit if enabled (for non-individual payments)
        if formData.hasDeposit, formData.paymentType != .individual {
            let depositAmount = formData.actualDepositAmount
            schedule.append(PaymentScheduleItem(
                id: UUID().uuidString,
                description: formData.isDepositRetainer ? "Retainer" : "Deposit",
                amount: depositAmount,
                vendorName: "Selected Vendor",
                dueDate: formData.startDate,
                isPaid: false,
                isRecurring: false))
            remainingAmount -= depositAmount
        }

        // Calculate payment schedule based on type
        switch formData.paymentType {
        case .individual:
            let description = formData
                .isIndividualDeposit ? (formData.isIndividualRetainer ? "Retainer" : "Deposit") : "Payment"
            schedule.append(PaymentScheduleItem(
                id: UUID().uuidString,
                description: description,
                amount: formData.individualAmount,
                vendorName: "Selected Vendor",
                dueDate: formData.startDate,
                isPaid: false,
                isRecurring: false))

        case .monthly:
            var paymentIndex = 0
            let startDate = formData.hasDeposit ? Calendar.current.date(
                byAdding: .month,
                value: 1,
                to: formData.startDate) ?? formData.startDate : formData.startDate

            while remainingAmount > 0.01 {
                let paymentAmount = min(formData.monthlyAmount, remainingAmount)
                let isLast = paymentAmount >= remainingAmount - 0.01
                let paymentDate = Calendar.current
                    .date(byAdding: .month, value: paymentIndex, to: startDate) ?? startDate

                // Determine description for first payment (deposit/retainer)
                var description: String = if paymentIndex == 0,
                                             formData.isFirstMonthlyDeposit || formData.isFirstMonthlyRetainer {
                    formData.isFirstMonthlyRetainer ? "Retainer" : "Deposit"
                } else {
                    isLast ? "Final Payment" : "Monthly Payment #\(paymentIndex + 1)"
                }

                schedule.append(PaymentScheduleItem(
                    id: UUID().uuidString,
                    description: description,
                    amount: paymentAmount,
                    vendorName: "Selected Vendor",
                    dueDate: paymentDate,
                    isPaid: false,
                    isRecurring: true))

                remainingAmount -= paymentAmount
                paymentIndex += 1
                if paymentIndex > 100 { break } // Safety break
            }

        case .interval:
            var paymentIndex = 0
            let startDate = formData.hasDeposit ? Calendar.current.date(
                byAdding: .month,
                value: formData.intervalMonths,
                to: formData.startDate) ?? formData.startDate : formData.startDate

            while remainingAmount > 0.01 {
                let paymentAmount = min(formData.intervalAmount, remainingAmount)
                let isLast = paymentAmount >= remainingAmount - 0.01
                let monthsToAdd = paymentIndex * formData.intervalMonths
                let paymentDate = Calendar.current
                    .date(byAdding: .month, value: monthsToAdd, to: startDate) ?? startDate

                // Determine description for first payment (deposit/retainer)
                var description: String = if paymentIndex == 0,
                                             formData.isFirstIntervalDeposit || formData.isFirstIntervalRetainer {
                    formData.isFirstIntervalRetainer ? "Retainer" : "Deposit"
                } else {
                    isLast ? "Final Payment" : "Interval Payment #\(paymentIndex + 1)"
                }

                schedule.append(PaymentScheduleItem(
                    id: UUID().uuidString,
                    description: description,
                    amount: paymentAmount,
                    vendorName: "Selected Vendor",
                    dueDate: paymentDate,
                    isPaid: false,
                    isRecurring: true))

                remainingAmount -= paymentAmount
                paymentIndex += 1
                if paymentIndex > 100 { break } // Safety break
            }

        case .cyclical:
            let validPayments = formData.cyclicalPayments.filter { $0.amount > 0 }.sorted { $0.order < $1.order }
            guard !validPayments.isEmpty else { return [] }

            var cycleIndex = 0
            var paymentCount = 0
            let startDate = formData.hasDeposit ? Calendar.current.date(
                byAdding: .month,
                value: 1,
                to: formData.startDate) ?? formData.startDate : formData.startDate

            while remainingAmount > 0.01 {
                let cyclicalAmount = validPayments[cycleIndex].amount
                let paymentAmount = min(cyclicalAmount, remainingAmount)
                let isLast = paymentAmount >= remainingAmount - 0.01
                let paymentDate = Calendar.current
                    .date(byAdding: .month, value: paymentCount, to: startDate) ?? startDate

                // Determine description for first payment (deposit/retainer)
                var description: String = if paymentCount == 0,
                                             formData.isFirstCyclicalDeposit || formData.isFirstCyclicalRetainer {
                    formData.isFirstCyclicalRetainer ? "Retainer" : "Deposit"
                } else {
                    isLast ? "Final Payment" : "Cyclical Payment #\(paymentCount + 1)"
                }

                schedule.append(PaymentScheduleItem(
                    id: UUID().uuidString,
                    description: description,
                    amount: paymentAmount,
                    vendorName: "Selected Vendor",
                    dueDate: paymentDate,
                    isPaid: false,
                    isRecurring: true))

                remainingAmount -= paymentAmount
                cycleIndex = (cycleIndex + 1) % validPayments.count
                paymentCount += 1
                if paymentCount > 100 { break } // Safety break
            }
        }

        return schedule.sorted { $0.dueDate < $1.dueDate }
    }
}

// MARK: - Main Add Payment Schedule View

struct AddPaymentScheduleView: View {
    let expenses: [Expense]
    let onSave: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var formData = PaymentFormData()
    @State private var schedule: [PaymentScheduleItem] = []
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @FocusState private var focusedField: FocusedField?

    enum FocusedField: Hashable {
        case individualAmount
        case monthlyAmount
        case intervalAmount
        case cyclicalAmount(Int)
        case notes
    }

    private var selectedExpense: Expense? {
        expenses.first { $0.id == formData.selectedExpenseId }
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
        VStack(spacing: 0) {
            previewHeader
            previewContent
        }
        .frame(width: 350)
        .background(Color(NSColor.textBackgroundColor))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading) {
                Text("Payment Plan Setup")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create a payment schedule for your wedding expenses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Expense Selection Section

    private var expenseSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expense Selection")
                .font(.headline)

            if expenses.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.orange)

                    Text("No expenses available")
                        .font(.headline)

                    Text("You need to create budget expenses first before setting up payment plans.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else {
                Picker("Select Expense", selection: $formData.selectedExpenseId) {
                    Text("Choose an expense").tag(nil as UUID?)
                    ForEach(expenses, id: \.id) { expense in
                        HStack {
                            Text(expense.expenseName)
                            Spacer()
                            Text(NumberFormatter.currency.string(from: NSNumber(value: expense.amount)) ?? "$0")
                                .foregroundColor(.secondary)
                        }
                        .tag(expense.id as UUID?)
                    }
                }
                .pickerStyle(.menu)

                if let selectedExpense {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total Amount")
                                .fontWeight(.medium)
                            Spacer()
                            Text(NumberFormatter.currency.string(from: NSNumber(value: selectedExpense.amount)) ?? "$0")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Already Paid")
                            Spacer()
                            Text(NumberFormatter.currency
                                .string(from: NSNumber(value: selectedExpense.paidAmount)) ?? "$0")
                                .foregroundColor(.green)
                        }

                        HStack {
                            Text("Remaining")
                            Spacer()
                            Text(NumberFormatter.currency
                                .string(from: NSNumber(value: selectedExpense.remainingAmount)) ?? "$0")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Payment Type Section

    private var paymentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Type")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(PaymentType.allCases, id: \.self) { type in
                    Button(action: {
                        formData.paymentType = type
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(formData.paymentType == type ? .white : .blue)

                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(formData.paymentType == type ? .white : .primary)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .background(formData.paymentType == type ? Color.blue : Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Deposit Section

    private var depositSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Deposit/Retainer")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: $formData.hasDeposit)
                    .labelsHidden()
            }

            if formData.hasDeposit {
                VStack(spacing: 12) {
                    Picker("Deposit Type", selection: $formData.usePercentage) {
                        Text("Percentage").tag(true)
                        Text("Fixed Amount").tag(false)
                    }
                    .pickerStyle(.segmented)

                    if formData.usePercentage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Deposit Percentage")
                                Spacer()
                                Text("\(Int(formData.depositPercentage))%")
                                    .foregroundColor(.secondary)
                            }

                            Slider(value: $formData.depositPercentage, in: 1 ... 99, step: 1)

                            Text(
                                "Deposit amount: \(NumberFormatter.currency.string(from: NSNumber(value: formData.actualDepositAmount)) ?? "$0")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Deposit Amount")
                            Spacer()
                            TextField("$0.00", value: $formData.depositAmount, format: .currency(code: "USD"))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                        }
                    }

                    Toggle("This deposit is a retainer", isOn: $formData.isDepositRetainer)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Payment Details Section

    private var paymentDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Details")
                .font(.headline)

            VStack(spacing: 12) {
                DatePicker(
                    formData.paymentType == .individual ? "Payment Date" : "Start Date",
                    selection: $formData.startDate,
                    displayedComponents: .date)

                switch formData.paymentType {
                case .individual:
                    individualPaymentDetails
                case .monthly:
                    monthlyPaymentDetails
                case .interval:
                    intervalPaymentDetails
                case .cyclical:
                    cyclicalPaymentDetails
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
    }

    private var individualPaymentDetails: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Payment Amount")
                Spacer()
                TextField("$0.00", value: $formData.individualAmount, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                    .focused($focusedField, equals: .individualAmount)
                    .onSubmit { focusedField = nil }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Type")
                    .font(.subheadline)
                    .fontWeight(.medium)

                VStack(spacing: 4) {
                    Button(action: {
                        formData.isIndividualDeposit = false
                        formData.isIndividualRetainer = false
                    }) {
                        HStack {
                            Image(systemName: (!formData.isIndividualDeposit && !formData.isIndividualRetainer) ?
                                "checkmark.circle.fill" : "circle")
                                .foregroundColor((!formData.isIndividualDeposit && !formData.isIndividualRetainer) ?
                                    .blue : .gray)
                            Text("Regular Payment")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        formData.isIndividualDeposit = true
                        formData.isIndividualRetainer = false
                    }) {
                        HStack {
                            Image(systemName: formData.isIndividualDeposit ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(formData.isIndividualDeposit ? .blue : .gray)
                            Text("Deposit")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        formData.isIndividualDeposit = false
                        formData.isIndividualRetainer = true
                    }) {
                        HStack {
                            Image(systemName: formData.isIndividualRetainer ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(formData.isIndividualRetainer ? .blue : .gray)
                            Text("Retainer")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var monthlyPaymentDetails: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Monthly Payment Amount")
                Spacer()
                TextField("$0.00", value: $formData.monthlyAmount, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                    .focused($focusedField, equals: .monthlyAmount)
                    .onSubmit { focusedField = nil }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("First Payment Type")
                    .font(.subheadline)
                    .fontWeight(.medium)

                VStack(spacing: 4) {
                    Button(action: {
                        formData.isFirstMonthlyDeposit = false
                        formData.isFirstMonthlyRetainer = false
                    }) {
                        HStack {
                            Image(systemName: (!formData.isFirstMonthlyDeposit && !formData.isFirstMonthlyRetainer) ?
                                "checkmark.circle.fill" : "circle")
                                .foregroundColor((!formData.isFirstMonthlyDeposit && !formData.isFirstMonthlyRetainer) ?
                                    .blue : .gray)
                            Text("Regular Payment")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        formData.isFirstMonthlyDeposit = true
                        formData.isFirstMonthlyRetainer = false
                    }) {
                        HStack {
                            Image(systemName: formData.isFirstMonthlyDeposit ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(formData.isFirstMonthlyDeposit ? .blue : .gray)
                            Text("First Payment is a Deposit")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        formData.isFirstMonthlyDeposit = false
                        formData.isFirstMonthlyRetainer = true
                    }) {
                        HStack {
                            Image(systemName: formData.isFirstMonthlyRetainer ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(formData.isFirstMonthlyRetainer ? .blue : .gray)
                            Text("First Payment is a Retainer")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var intervalPaymentDetails: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Payment Amount")
                Spacer()
                TextField("$0.00", value: $formData.intervalAmount, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                    .focused($focusedField, equals: .intervalAmount)
                    .onSubmit { focusedField = nil }
            }

            HStack {
                Text("Interval (Months)")
                Spacer()
                Stepper(value: $formData.intervalMonths, in: 1 ... 12) {
                    Text("\(formData.intervalMonths) month\(formData.intervalMonths == 1 ? "" : "s")")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("First Payment Type")
                    .font(.subheadline)
                    .fontWeight(.medium)

                VStack(spacing: 4) {
                    Button(action: {
                        formData.isFirstIntervalDeposit = false
                        formData.isFirstIntervalRetainer = false
                    }) {
                        HStack {
                            Image(systemName: (!formData.isFirstIntervalDeposit && !formData.isFirstIntervalRetainer) ?
                                "checkmark.circle.fill" : "circle")
                                .foregroundColor((!formData.isFirstIntervalDeposit && !formData
                                        .isFirstIntervalRetainer) ? .blue : .gray)
                            Text("Regular Payment")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        formData.isFirstIntervalDeposit = true
                        formData.isFirstIntervalRetainer = false
                    }) {
                        HStack {
                            Image(systemName: formData.isFirstIntervalDeposit ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(formData.isFirstIntervalDeposit ? .blue : .gray)
                            Text("First Payment is a Deposit")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        formData.isFirstIntervalDeposit = false
                        formData.isFirstIntervalRetainer = true
                    }) {
                        HStack {
                            Image(systemName: formData.isFirstIntervalRetainer ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(formData.isFirstIntervalRetainer ? .blue : .gray)
                            Text("First Payment is a Retainer")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var cyclicalPaymentDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cyclical Payment Pattern")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button("Add Payment") {
                    let nextOrder = (formData.cyclicalPayments.map(\.order).max() ?? 0) + 1
                    formData.cyclicalPayments.append(CyclicalPayment(order: nextOrder))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            ForEach(formData.cyclicalPayments.indices, id: \.self) { index in
                HStack {
                    Text("#\(formData.cyclicalPayments[index].order)")
                        .frame(width: 30)

                    TextField("$0.00", value: $formData.cyclicalPayments[index].amount, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .cyclicalAmount(index))
                        .onSubmit { focusedField = nil }

                    if formData.cyclicalPayments.count > 1 {
                        Button("Remove") {
                            formData.cyclicalPayments.remove(at: index)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            Text("This pattern will repeat until the total amount is paid.")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("First Payment Type")
                    .font(.subheadline)
                    .fontWeight(.medium)

                VStack(spacing: 4) {
                    Button(action: {
                        formData.isFirstCyclicalDeposit = false
                        formData.isFirstCyclicalRetainer = false
                    }) {
                        HStack {
                            Image(systemName: (!formData.isFirstCyclicalDeposit && !formData.isFirstCyclicalRetainer) ?
                                "checkmark.circle.fill" : "circle")
                                .foregroundColor((!formData.isFirstCyclicalDeposit && !formData
                                        .isFirstCyclicalRetainer) ? .blue : .gray)
                            Text("Regular Payment")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        formData.isFirstCyclicalDeposit = true
                        formData.isFirstCyclicalRetainer = false
                    }) {
                        HStack {
                            Image(systemName: formData.isFirstCyclicalDeposit ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(formData.isFirstCyclicalDeposit ? .blue : .gray)
                            Text("First Payment is a Deposit")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        formData.isFirstCyclicalDeposit = false
                        formData.isFirstCyclicalRetainer = true
                    }) {
                        HStack {
                            Image(systemName: formData.isFirstCyclicalRetainer ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(formData.isFirstCyclicalRetainer ? .blue : .gray)
                            Text("First Payment is a Retainer")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Additional Options Section

    private var additionalOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Options")
                .font(.headline)

            VStack(spacing: 12) {
                Toggle("Enable Reminders", isOn: $formData.enableReminders)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Enter any additional notes...", text: $formData.notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3 ... 6)
                        .focused($focusedField, equals: .notes)
                        .onSubmit { focusedField = nil }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Preview Section

    private var previewHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Payment Schedule Preview")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Total Amount:")
                    Spacer()
                    Text(NumberFormatter.currency.string(from: NSNumber(value: formData.totalAmount)) ?? "$0")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Number of Payments:")
                    Spacer()
                    Text("\(schedule.count)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Schedule Total:")
                    Spacer()
                    Text(NumberFormatter.currency.string(from: NSNumber(value: totalScheduleAmount)) ?? "$0")
                        .fontWeight(.semibold)
                        .foregroundColor(abs(amountDifference) > 0.01 ? .red : .primary)
                }

                if abs(amountDifference) > 0.01 {
                    HStack {
                        Text("Difference:")
                        Spacer()
                        Text(NumberFormatter.currency.string(from: NSNumber(value: amountDifference)) ?? "$0")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }

    private var previewContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if schedule.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title)
                            .foregroundColor(.gray)

                        Text("Configure payment details to see schedule")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(Array(schedule.enumerated()), id: \.element.id) { index, item in
                        PaymentScheduleItemRow(item: item, index: index)
                    }
                }
            }
            .padding()
        }
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
        let vendorName = getVendorName(selectedExpense?.vendorId) ?? ""

        // Create all payment schedules from the calculated schedule
        for (index, payment) in schedule.enumerated() {
            let isDeposit = payment.description.contains("Deposit") || payment.description.contains("Retainer")
            let isRetainer = payment.description.contains("Retainer")

            let paymentSchedule = PaymentSchedule(
                id: Int64.min + Int64(index), // Use very negative unique IDs to avoid conflicts
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
                createdAt: Date())

            onSave(paymentSchedule)
        }

        dismiss()
    }
}

// MARK: - Supporting Views

struct PaymentScheduleItemRow: View {
    let item: PaymentScheduleItem
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.description)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(item.dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(NumberFormatter.currency.string(from: NSNumber(value: item.amount)) ?? "$0")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    if item.description.contains("Deposit") || item.description.contains("Retainer") {
                        Text(item.description.contains("Retainer") ? "Retainer" : "Deposit")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }

                    if item.description.contains("Final") {
                        Text("Final")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }

                    if item.isRecurring {
                        Text("Recurring")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(item.description.contains("Deposit") || item.description.contains("Retainer") ? Color.blue
                    .opacity(0.1) :
                    item.description.contains("Final") ? Color.green.opacity(0.1) :
                    Color(NSColor.controlBackgroundColor)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    item.description.contains("Deposit") || item.description.contains("Retainer") ? Color.blue
                        .opacity(0.3) :
                        item.description.contains("Final") ? Color.green.opacity(0.3) :
                        Color.gray.opacity(0.2),
                    lineWidth: 1))
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
        onSave: { _ in },
        getVendorName: { _ in "Sample Vendor" })
}
