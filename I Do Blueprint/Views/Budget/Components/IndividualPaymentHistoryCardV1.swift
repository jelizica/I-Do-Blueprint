//
//  IndividualPaymentHistoryCardV1.swift
//  I Do Blueprint
//
//  Payment history timeline card for individual payment detail view
//

import SwiftUI

struct IndividualPaymentHistoryCardV1: View {
    let payment: PaymentSchedule
    let timezone: TimeZone

    private var historyItems: [HistoryItem] {
        var items: [HistoryItem] = []

        // Payment completed (if paid)
        if payment.paid {
            let paidDate = payment.updatedAt ?? Date()
            items.append(HistoryItem(
                type: .completed,
                title: "Payment Completed",
                description: "Payment of \(formatCurrency(payment.paymentAmount)) marked as paid.",
                date: paidDate
            ))
        }

        // Reminder sent (if reminder was enabled)
        if payment.reminderEnabled, let daysBefore = payment.reminderDaysBefore {
            let reminderDate = Calendar.current.date(
                byAdding: .day,
                value: -daysBefore,
                to: payment.paymentDate
            ) ?? payment.paymentDate
            items.append(HistoryItem(
                type: .reminder,
                title: "Reminder Sent",
                description: "Automated reminder sent to email.",
                date: reminderDate
            ))
        }

        // Payment created
        items.append(HistoryItem(
            type: .created,
            title: "Payment Created",
            description: "Initial payment schedule created.",
            date: payment.createdAt
        ))

        return items.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Text("Payment History")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                historyIcon
            }

            // Timeline
            timelineView
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - History Icon

    private var historyIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: "clock.arrow.circlepath")
                .font(.title3)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }

    // MARK: - Timeline View

    private var timelineView: some View {
        ZStack(alignment: .leading) {
            // Vertical line
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 2)
                .padding(.leading, 13)
                .padding(.vertical, Spacing.md)

            // Items
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ForEach(historyItems) { item in
                    timelineItem(item)
                }
            }
        }
    }

    private func timelineItem(_ item: HistoryItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Circle indicator
            ZStack {
                Circle()
                    .fill(item.type.backgroundColor)
                    .frame(width: 28, height: 28)

                Image(systemName: item.type.iconName)
                    .font(.caption2)
                    .foregroundColor(item.type.iconColor)
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text(item.title)
                        .font(Typography.caption.weight(.medium))
                        .foregroundColor(SemanticColors.textPrimary)

                    Spacer()

                    Text(formatShortDate(item.date))
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textTertiary)
                }

                Text(item.description)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatShortDate(_ date: Date) -> String {
        DateFormatting.formatDate(date, format: "MMM d", timezone: timezone)
    }
}

// MARK: - History Item Model

private struct HistoryItem: Identifiable {
    let id = UUID()
    let type: HistoryItemType
    let title: String
    let description: String
    let date: Date
}

private enum HistoryItemType {
    case completed
    case reminder
    case created

    var iconName: String {
        switch self {
        case .completed: return "checkmark"
        case .reminder: return "bell"
        case .created: return "plus"
        }
    }

    var iconColor: Color {
        switch self {
        case .completed: return SemanticColors.success
        case .reminder, .created: return SemanticColors.textTertiary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .completed: return SemanticColors.success.opacity(0.15)
        case .reminder, .created: return Color.gray.opacity(0.1)
        }
    }
}
