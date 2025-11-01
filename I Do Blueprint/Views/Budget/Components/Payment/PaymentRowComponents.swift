//
//  PaymentRowComponents.swift
//  I Do Blueprint
//
//  Row and detail view components for payment management
//

import SwiftUI

// MARK: - Payment Row View

struct PaymentRowView: View {
    let payment: PaymentScheduleItem
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    @State private var showingDetails = false

    private var statusColor: Color {
        if payment.isPaid {
            AppColors.Budget.income
        } else if payment.dueDate < Date() {
            AppColors.Budget.overBudget
        } else {
            AppColors.Budget.pending
        }
    }

    private var statusIcon: String {
        if payment.isPaid {
            "checkmark.circle.fill"
        } else if payment.dueDate < Date() {
            "exclamationmark.triangle.fill"
        } else {
            "clock.fill"
        }
    }

    private var statusText: String {
        if payment.isPaid {
            return "Paid"
        } else if payment.dueDate < Date() {
            let daysPast = Calendar.current.dateComponents([.day], from: payment.dueDate, to: Date()).day ?? 0
            return "\(daysPast) days overdue"
        } else {
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: payment.dueDate).day ?? 0
            return "Due in \(daysUntil) days"
        }
    }

    var body: some View {
        Button(action: { showingDetails = true }) {
            HStack(spacing: 12) {
                // Selection checkbox
                Button(action: { onSelectionChanged(!isSelected) }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? AppColors.Budget.allocated : .secondary)
                }
                .buttonStyle(.plain)

                // Status indicator
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title3)

                // Payment details
                VStack(alignment: .leading, spacing: 4) {
                    Text(payment.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack {
                        Text(payment.vendorName)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(payment.dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(statusColor)
                        .fontWeight(.medium)
                }

                Spacer()

                // Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(NumberFormatter.currency.string(from: NSNumber(value: payment.amount)) ?? "$0")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if payment.isRecurring {
                        Text("Recurring")
                            .font(.caption2)
                            .foregroundColor(AppColors.Budget.allocated)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(AppColors.Budget.allocated.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetails) {
            PaymentDetailView(payment: payment)
        }
    }
}

// MARK: - Payment Detail View

struct PaymentDetailView: View {
    let payment: PaymentScheduleItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(payment.description)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(NumberFormatter.currency.string(from: NSNumber(value: payment.amount)) ?? "$0")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.Budget.allocated)
                    }

                    // Payment details
                    VStack(alignment: .leading, spacing: 16) {
                        PaymentDetailRow(label: "Vendor", value: payment.vendorName)
                        PaymentDetailRow(
                            label: "Due Date",
                            value: payment.dueDate.formatted(date: .abbreviated, time: .omitted))
                        PaymentDetailRow(label: "Status", value: payment.isPaid ? "Paid" : "Pending")

                        if payment.isRecurring {
                            PaymentDetailRow(label: "Recurring", value: "Yes")
                        }

                        if let paymentMethod = payment.paymentMethod {
                            PaymentDetailRow(label: "Payment Method", value: paymentMethod.capitalized)
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        if !payment.isPaid {
                            Button("Mark as Paid") {
                                // Mark as paid
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }

                        Button("Edit Payment") {
                            // Edit payment
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Payment Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Payment Detail Row

struct PaymentDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
