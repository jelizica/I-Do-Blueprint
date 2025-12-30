//
//  PaymentScheduleRowView.swift
//  I Do Blueprint
//
//  Individual payment schedule row with quick actions
//

import SwiftUI

struct PaymentScheduleRowView: View {
    let payment: PaymentSchedule
    let expense: Expense?
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?

    @State private var showingEditModal = false

    var body: some View {
        Button(action: {
            showingEditModal = true
        }) {
            HStack(spacing: 16) {
                // Payment status indicator
                Circle()
                    .fill(payment.paid ? AppColors.Budget.income : AppColors.Budget.pending)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(expense?.expenseName ?? "Unknown Expense")
                            .font(.headline)
                            .fontWeight(.medium)

                        Spacer()

                        Text(NumberFormatter.currencyShort.string(from: NSNumber(value: payment.paymentAmount)) ?? "$0")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(payment.paid ? AppColors.Budget.income : .primary)
                    }

                    Text(payment.notes ?? "No description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Due: \(formatDateInUserTimezone(payment.paymentDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(payment.paid ? "Paid" : "Pending")
                            .font(.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(payment.paid ? AppColors.Budget.income.opacity(0.2) : AppColors.Budget.pending.opacity(0.2))
                            .foregroundColor(payment.paid ? AppColors.Budget.income : AppColors.Budget.pending)
                            .clipShape(Capsule())
                    }
                }

                // Quick action buttons
                HStack(spacing: 8) {
                    Button(action: {
                        var updatedPayment = payment
                        updatedPayment.paid.toggle()
                        updatedPayment.updatedAt = Date()
                        onUpdate(updatedPayment)
                    }) {
                        Image(systemName: payment.paid ? "checkmark.square.fill" : "square")
                            .foregroundColor(payment.paid ? AppColors.Budget.income : .secondary)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditModal) {
            PaymentEditModal(
                payment: payment,
                expense: expense,
                getVendorName: getVendorName,
                onUpdate: onUpdate,
                onDelete: {
                    onDelete(payment)
                })
        }
    }
}

// MARK: - Helper Functions

private func formatDateInUserTimezone(_ date: Date) -> String {
    // Use user's timezone for date formatting
    let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
    return DateFormatting.formatDateMedium(date, timezone: userTimezone)
}
