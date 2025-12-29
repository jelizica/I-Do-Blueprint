//
//  PaymentFormComponents.swift
//  I Do Blueprint
//
//  Form components for adding/editing payments
//

import SwiftUI

// MARK: - Add Payment View

struct AddPaymentView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var authContext: AuthContext
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var amount = ""
    @State private var vendorName = ""
    @State private var dueDate = Date()
    @State private var paymentMethod = "credit_card"
    @State private var isRecurring = false
    @State private var recurringInterval = 1
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    TextField("Description", text: $description)

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("$0.00", text: $amount)
                            .multilineTextAlignment(.trailing)
                    }

                    TextField("Vendor", text: $vendorName)

                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }

                Section("Payment Options") {
                    Picker("Payment Method", selection: $paymentMethod) {
                        Text("Credit Card").tag("credit_card")
                        Text("Bank Transfer").tag("bank_transfer")
                        Text("Check").tag("check")
                        Text("Cash").tag("cash")
                    }

                    Toggle("Recurring Payment", isOn: $isRecurring)

                    if isRecurring {
                        Stepper("Every \(recurringInterval) month(s)", value: $recurringInterval, in: 1 ... 12)
                    }
                }
            }
            .navigationTitle("Add Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        savePayment()
                    }
                    .disabled(description.isEmpty || amount.isEmpty || vendorName.isEmpty)
                }
            }
        }
    }

    private func savePayment() {
        guard let amountValue = Double(amount), !description.isEmpty, !vendorName.isEmpty else { return }

        do {
            let coupleId = try authContext.requireCoupleId()

            // Create PaymentSchedule with authenticated couple ID
            let payment = PaymentSchedule(
                id: Int64.random(in: 1 ... Int64.max),
                coupleId: coupleId,
                vendor: vendorName,
                paymentDate: dueDate,
                paymentAmount: amountValue,
                notes: description,
                paid: false,
                autoRenew: isRecurring,
                reminderEnabled: true,
                isDeposit: false,
                isRetainer: false,
                createdAt: Date())

            Task {
                do {
                    try await budgetStore.payments.addPayment(payment)
                    dismiss()
                } catch {
                    AppLogger.ui.error("Failed to add payment", error: error)
                    errorMessage = "Failed to add payment: \(error.localizedDescription)"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
