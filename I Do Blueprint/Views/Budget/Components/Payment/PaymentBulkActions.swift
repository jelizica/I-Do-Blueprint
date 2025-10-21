//
//  PaymentBulkActions.swift
//  I Do Blueprint
//
//  Bulk action components for payment management
//

import SwiftUI

// MARK: - Bulk Actions View

struct BulkActionsView: View {
    let selectedPayments: Set<String>
    let payments: [PaymentScheduleItem]
    let budgetStore: BudgetStoreV2
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var selectedPaymentItems: [PaymentScheduleItem] {
        payments.filter { selectedPayments.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("\(selectedPayments.count) payments selected")
                    .font(.headline)

                VStack(spacing: 16) {
                    BulkActionButton(
                        title: "Mark as Paid",
                        description: "Mark all selected payments as paid",
                        icon: "checkmark.circle.fill",
                        color: AppColors.Budget.income) {
                        markAsPaid()
                    }

                    BulkActionButton(
                        title: "Update Due Date",
                        description: "Change the due date for all selected payments",
                        icon: "calendar",
                        color: AppColors.Budget.allocated) {
                        // Update due date
                    }

                    BulkActionButton(
                        title: "Delete Payments",
                        description: "Remove all selected payments",
                        icon: "trash.fill",
                        color: AppColors.Budget.overBudget) {
                        deletePayments()
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Bulk Actions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func markAsPaid() {
        Task {
            for payment in selectedPaymentItems {
                // Find the original PaymentSchedule and update it
                if let schedule = budgetStore.paymentSchedules.first(where: { String($0.id) == payment.id }) {
                    var updatedSchedule = schedule
                    updatedSchedule.paid = true
                    await budgetStore.updatePayment(updatedSchedule)
                }
            }
            onComplete()
            dismiss()
        }
    }

    private func deletePayments() {
        Task {
            for payment in selectedPaymentItems {
                // Find the original PaymentSchedule and delete it
                if let schedule = budgetStore.paymentSchedules.first(where: { String($0.id) == payment.id }) {
                    await budgetStore.deletePayment(schedule)
                }
            }
            onComplete()
            dismiss()
        }
    }
}

// MARK: - Bulk Action Button

struct BulkActionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
