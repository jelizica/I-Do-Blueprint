//
//  PaymentDueRow.swift
//  I Do Blueprint
//
//  Extracted from DashboardViewV4.swift
//  Row component displaying a single payment due with vendor name and amount
//

import SwiftUI

struct PaymentDueRow: View {
    let payment: PaymentSchedule
    @ObservedObject var vendorStore: VendorStoreV2
    let userTimezone: TimeZone

    private var vendorName: String {
        guard let vendorId = payment.vendorId else {
            return payment.notes ?? "Payment"
        }

        // Look up vendor name from vendor store
        if let vendor = vendorStore.vendors.first(where: { $0.id == vendorId }) {
            return vendor.vendorName
        }

        return payment.notes ?? "Payment"
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(formatDate(payment.paymentDate))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(vendorName)
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("$\(formatAmount(payment.paymentAmount))")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)

                Text(payment.paid ? "Paid" : "Unpaid")
                    .font(Typography.caption2)
                    .foregroundColor(payment.paid ? SemanticColors.success : SemanticColors.warning)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func formatDate(_ date: Date) -> String {
        // Format in injected timezone
        return DateFormatting.formatDate(date, format: "MMM d", timezone: userTimezone)
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}
