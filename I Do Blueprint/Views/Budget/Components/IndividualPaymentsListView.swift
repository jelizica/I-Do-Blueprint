//
//  IndividualPaymentsListView.swift
//  I Do Blueprint
//
//  List view for individual payment schedules grouped by month
//

import SwiftUI

struct IndividualPaymentsListView: View {
    let windowSize: WindowSize
    let filteredPayments: [PaymentSchedule]
    let expenses: [Expense]
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?
    let userTimezone: TimeZone
    
    var body: some View {
        if filteredPayments.isEmpty {
            ContentUnavailableView(
                "No Payment Schedules",
                systemImage: "calendar.circle",
                description: Text("Add payment schedules to track upcoming payments and deadlines"))
        } else {
            List {
                ForEach(groupedPayments, id: \.key) { group in
                    Section(group.key) {
                        ForEach(group.value, id: \.id) { payment in
                            PaymentScheduleRowView(
                                windowSize: windowSize,
                                payment: payment,
                                expense: getExpenseForPayment(payment),
                                onUpdate: onUpdate,
                                onDelete: onDelete,
                                getVendorName: { vendorId in
                                    // First try to get vendor name from the payment's expense
                                    if let expense = getExpenseForPayment(payment) {
                                        return expense.vendorName
                                    }
                                    // Fall back to payment's vendor field
                                    return payment.vendor.isEmpty ? nil : payment.vendor
                                }
                            )
                            .id(payment.id)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Private Helpers
    
    private var groupedPayments: [(key: String, value: [PaymentSchedule])] {
        // Use user's timezone for month grouping
        let grouped = Dictionary(grouping: filteredPayments) { payment in
            DateFormatting.formatDate(payment.paymentDate, format: "MMMM yyyy", timezone: userTimezone)
        }
        return grouped.sorted { first, second in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.timeZone = userTimezone

            guard let firstDate = formatter.date(from: first.key),
                  let secondDate = formatter.date(from: second.key) else {
                return first.key < second.key
            }

            return firstDate < secondDate
        }
    }
    
    private func getExpenseForPayment(_ payment: PaymentSchedule) -> Expense? {
        expenses.first { $0.id == payment.expenseId }
    }
}
