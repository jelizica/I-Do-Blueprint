//
//  ExpenseDetailComponents.swift
//  I Do Blueprint
//
//  Expense detail view components for budget category detail view
//

import AppKit
import SwiftUI

// MARK: - Expense Detail View

struct ExpenseDetailView: View {
    let expense: Expense

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expense Details")
                            .font(.title)
                            .fontWeight(.bold)

                        HStack {
                            Text(NumberFormatter.currency.string(from: NSNumber(value: expense.amount)) ?? "$0")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(AppColors.Budget.allocated)

                            Spacer()

                            PaymentStatusBadge(status: expense.paymentStatusEnum)
                        }
                    }
                    .padding()
                    .background(AppColors.Budget.allocated.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Divider()

                    // Basic Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Information")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ExpenseDetailRow(label: "Expense Name", value: expense.expenseName)

                        if let vendor = expense.vendorName, !vendor.isEmpty {
                            ExpenseDetailRow(label: "Vendor", value: vendor)
                        }

                        ExpenseDetailRow(label: "Date", value: expense.expenseDate, formatter: .date)

                        ExpenseDetailRow(label: "Category", value: expense.categoryId.uuidString)

                        ExpenseDetailRow(label: "Payment Method", value: expense.paymentMethod?.capitalized ?? "N/A")
                    }

                    Divider()

                    // Payment Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Payment Details")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ExpenseDetailRow(label: "Total Amount", value: expense.amount, formatter: .currency)

                        ExpenseDetailRow(label: "Amount Paid", value: expense.paidAmount, formatter: .currency)

                        ExpenseDetailRow(
                            label: "Remaining",
                            value: expense.remainingAmount,
                            formatter: .currency,
                            valueColor: expense.remainingAmount > 0
                                ? AppColors.Budget.overBudget
                                : AppColors.Budget.income
                        )

                        if let dueDate = expense.dueDate {
                            ExpenseDetailRow(label: "Due Date", value: dueDate, formatter: .date)

                            if expense.isOverdue {
                                let daysOverdue = Calendar.current.dateComponents([.day], from: dueDate, to: Date()).day ?? 0
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(AppColors.Budget.overBudget)
                                    Text("\(daysOverdue) day\(daysOverdue == 1 ? "" : "s") overdue")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.Budget.overBudget)
                                        .fontWeight(.semibold)
                                }
                            }
                        }

                        if let approvedAt = expense.approvedAt {
                            ExpenseDetailRow(label: "Approved Date", value: approvedAt, formatter: .date)
                        }
                    }

                    // Notes
                    if let notes = expense.notes, !notes.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text(notes)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }

                    // Receipt
                    if let receiptUrl = expense.receiptUrl, !receiptUrl.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Receipt")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Button(action: {
                                if let url = URL(string: receiptUrl) {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(.title2)
                                        .foregroundColor(AppColors.Budget.allocated)

                                    Text("View Receipt")
                                        .font(.headline)

                                    Spacer()

                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(AppColors.Budget.allocated)
                                }
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Metadata
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metadata")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ExpenseDetailRow(label: "Created", value: expense.createdAt, formatter: .dateTime)
                        ExpenseDetailRow(label: "Last Updated", value: expense.updatedAt, formatter: .dateTime)
                    }
                }
                .padding()
            }
            .navigationTitle("Expense Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Expense Detail Row

struct ExpenseDetailRow: View {
    let label: String
    let value: Any
    var formatter: ExpenseDetailFormatter = .text
    var valueColor: Color = .primary

    enum ExpenseDetailFormatter {
        case text
        case currency
        case date
        case dateTime
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(formattedValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)

            Spacer()
        }
    }

    private var formattedValue: String {
        switch formatter {
        case .text:
            return "\(value)"
        case .currency:
            if let amount = value as? Double {
                return NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0"
            }
            return "\(value)"
        case .date:
            if let date = value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: date)
            }
            return "\(value)"
        case .dateTime:
            if let date = value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            return "\(value)"
        }
    }
}
