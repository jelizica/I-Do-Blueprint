//
//  IndividualPaymentActionsV1.swift
//  I Do Blueprint
//
//  Action buttons for individual payment detail view
//  Handles paid/unpaid state button styling
//

import SwiftUI

struct IndividualPaymentActionsV1: View {
    let payment: PaymentSchedule
    let onMarkPaid: () -> Void
    let onRecordPayment: () -> Void
    let onViewReceipt: () -> Void
    let onEdit: () -> Void
    let onPlan: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Record Payment - Primary action when unpaid (allows partial payments)
            if !payment.paid {
                recordPaymentButton
            }

            // Mark as Paid - Secondary option when unpaid, or status display when paid
            markPaidButton

            // View Receipt - Enabled when paid
            viewReceiptButton

            // Edit and Plan - Side by side
            HStack(spacing: Spacing.sm) {
                secondaryButton(
                    title: "Edit",
                    icon: "pencil",
                    action: onEdit
                )

                secondaryButton(
                    title: "Plan",
                    icon: "calendar",
                    action: onPlan
                )
            }
        }
        .frame(minWidth: 200)
    }

    // MARK: - Record Payment Button

    private var recordPaymentButton: some View {
        Button(action: onRecordPayment) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.body)
                Text("Record Payment")
                    .font(Typography.bodyRegular.weight(.medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(AppColors.Budget.allocated)
            )
            .shadow(
                color: AppColors.Budget.allocated.opacity(0.3),
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mark as Paid Button

    @ViewBuilder
    private var markPaidButton: some View {
        if payment.paid {
            // Paid state - green disabled button
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                Text("Paid")
                    .font(Typography.bodyRegular.weight(.medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(SemanticColors.success)
            )
        } else {
            // Unpaid state - primary action button
            Button(action: onMarkPaid) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle")
                        .font(.body)
                    Text("Mark as Paid")
                        .font(Typography.bodyRegular.weight(.medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(AppColors.Budget.allocated)
                )
                .shadow(
                    color: AppColors.Budget.allocated.opacity(0.3),
                    radius: 8,
                    y: 4
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - View Receipt Button

    @ViewBuilder
    private var viewReceiptButton: some View {
        if payment.paid {
            // Enabled state with highlight ring
            Button(action: onViewReceipt) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "doc.text")
                        .font(.body)
                    Text("View Receipt")
                        .font(Typography.bodyRegular.weight(.medium))
                }
                .foregroundColor(SemanticColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(AppColors.Budget.allocated.opacity(0.3), lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        } else {
            // Disabled state
            HStack(spacing: Spacing.sm) {
                Image(systemName: "doc.text")
                    .font(.body)
                Text("View Receipt")
                    .font(Typography.bodyRegular.weight(.medium))
            }
            .foregroundColor(SemanticColors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
    }

    // MARK: - Secondary Button

    private func secondaryButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(Typography.bodyRegular.weight(.medium))
            }
            .foregroundColor(SemanticColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
