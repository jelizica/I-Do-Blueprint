//
//  ExpenseRowComponents.swift
//  I Do Blueprint
//
//  Expense row components for budget category detail view
//

import AppKit
import SwiftUI

// MARK: - Expense Row View

struct ExpenseRowView: View {
    let expense: Expense
    let onUpdate: (Expense) -> Void
    let onViewDetails: (Expense) -> Void
    let onEdit: (Expense) -> Void

    @State private var showingPaymentSheet = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.expenseName)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(NumberFormatter.currency.string(from: NSNumber(value: expense.amount)) ?? "$0")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if expense.paidAmount > 0 {
                            Text(
                                "Paid: \(NumberFormatter.currency.string(from: NSNumber(value: expense.paidAmount)) ?? "$0")")
                                .font(.caption)
                                .foregroundColor(AppColors.Budget.income)
                        }
                    }
                }

                HStack {
                    PaymentStatusBadge(status: expense.paymentStatusEnum)

                    if expense.isOverdue {
                        StatusBadge(text: "Overdue", color: AppColors.Budget.overBudget)
                    } else if expense.isDueToday {
                        StatusBadge(text: "Due Today", color: AppColors.Budget.pending)
                    } else if expense.isDueSoon {
                        StatusBadge(text: "Due Soon", color: AppColors.Budget.pending)
                    }

                    Spacer()

                    if let dueDate = expense.dueDate {
                        Text("Due: \(dueDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let notes = expense.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            VStack(spacing: 8) {
                if expense.paymentStatus != .paid {
                    Button(action: {
                        showingPaymentSheet = true
                    }) {
                        Image(systemName: "dollarsign.circle")
                            .font(.title2)
                            .foregroundColor(AppColors.Budget.allocated)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Menu {
                    Button("View Details") {
                        onViewDetails(expense)
                    }

                    Button("Edit Expense") {
                        onEdit(expense)
                    }

                    if expense.receiptUrl != nil {
                        Button("View Receipt") {
                            if let urlString = expense.receiptUrl,
                               let url = URL(string: urlString) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }

                    Divider()

                    if expense.paymentStatus != .paid {
                        Button("Mark as Paid") {
                            var updatedExpense = expense
                            updatedExpense.paymentStatus = .paid
                            updatedExpense.approvedAt = Date()
                            onUpdate(updatedExpense)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .contentShape(Rectangle())
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentRecordView(expense: expense) { updatedExpense in
                onUpdate(updatedExpense)
            }
            #if os(macOS)
            .frame(minWidth: 400, maxWidth: 500, minHeight: 300, maxHeight: 400)
            #endif
        }
    }
}
