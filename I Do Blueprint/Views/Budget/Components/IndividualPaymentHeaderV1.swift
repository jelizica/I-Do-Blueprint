//
//  IndividualPaymentHeaderV1.swift
//  I Do Blueprint
//
//  Header components for individual payment detail view
//  Status badge and amount display components
//

import SwiftUI

// MARK: - Status Badge

struct IndividualPaymentStatusBadgeV1: View {
    let isPaid: Bool
    let date: Date
    let timezone: TimeZone

    private var statusColor: Color {
        isPaid ? SemanticColors.success : SemanticColors.statusPending
    }

    private var statusText: String {
        isPaid ? "Paid" : "Upcoming"
    }

    private var dateText: String {
        let formatted = DateFormatting.formatDate(date, format: "MMM dd, yyyy", timezone: timezone)
        return isPaid ? "Paid \(formatted)" : "Due \(formatted)"
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status pill
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )

            // Date label
            Text(dateText)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }
}

// MARK: - Amount Display

struct IndividualPaymentAmountV1: View {
    let amount: Double
    let isPaid: Bool
    let date: Date
    let timezone: TimeZone

    private var amountLabel: String {
        isPaid ? "AMOUNT PAID" : "AMOUNT DUE"
    }

    private var subtext: String {
        let formatted = DateFormatting.formatDate(date, format: "MMM dd, yyyy", timezone: timezone)
        return isPaid ? "Payment processed on \(formatted)" : "Scheduled for \(formatted)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(amountLabel)
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(1.5)

            Text(formatCurrency(amount))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            SemanticColors.textPrimary,
                            SemanticColors.textPrimary.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(subtext)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Stats Grid

struct IndividualPaymentStatsGridV1: View {
    let originalAmount: Double
    let remainingBalance: Double
    var paymentMethod: String = "Not specified"

    var body: some View {
        HStack(spacing: Spacing.xxl) {
            statItem(
                label: "Original Amount",
                value: formatCurrency(originalAmount)
            )

            statItem(
                label: "Remaining Balance",
                value: formatCurrency(remainingBalance)
            )

            statItem(
                label: "Payment Method",
                value: paymentMethod,
                icon: "creditcard"
            )

            Spacer()
        }
    }

    private func statItem(
        label: String,
        value: String,
        icon: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label.uppercased())
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textTertiary)
                .tracking(0.5)

            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(SemanticColors.textTertiary)
                }

                Text(value)
                    .font(Typography.bodyRegular.weight(.medium))
                    .foregroundColor(SemanticColors.textPrimary)
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
