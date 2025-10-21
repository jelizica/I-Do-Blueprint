//
//  PaymentSummaryComponents.swift
//  I Do Blueprint
//
//  Summary card components for payment management
//

import SwiftUI

// MARK: - Payment Summary Cards

struct PaymentSummaryCards: View {
    let payments: [PaymentScheduleItem]

    private var summaryData: PaymentSummaryData {
        let totalAmount = payments.reduce(0) { $0 + $1.amount }
        let paidAmount = payments.filter(\.isPaid).reduce(0) { $0 + $1.amount }
        let pendingAmount = payments.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }

        let overduePayments = payments.filter { !$0.isPaid && $0.dueDate < Date() }
        let overdueAmount = overduePayments.reduce(0) { $0 + $1.amount }

        let thisMonthPayments = payments.filter { payment in
            Calendar.current.isDate(payment.dueDate, equalTo: Date(), toGranularity: .month)
        }
        let thisMonthAmount = thisMonthPayments.reduce(0) { $0 + $1.amount }

        return PaymentSummaryData(
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            pendingAmount: pendingAmount,
            overdueAmount: overdueAmount,
            overdueCount: overduePayments.count,
            thisMonthAmount: thisMonthAmount,
            thisMonthCount: thisMonthPayments.count)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                PaymentManagementSummaryCard(
                    title: "Total Payments",
                    amount: summaryData.totalAmount,
                    subtitle: "\(payments.count) payments",
                    color: AppColors.Budget.allocated,
                    icon: "calendar.badge.clock")

                PaymentManagementSummaryCard(
                    title: "Paid",
                    amount: summaryData.paidAmount,
                    subtitle: "completed",
                    color: AppColors.Budget.income,
                    icon: "checkmark.circle.fill")

                PaymentManagementSummaryCard(
                    title: "Pending",
                    amount: summaryData.pendingAmount,
                    subtitle: "outstanding",
                    color: AppColors.Budget.pending,
                    icon: "clock.fill")

                if summaryData.overdueAmount > 0 {
                    PaymentManagementSummaryCard(
                        title: "Overdue",
                        amount: summaryData.overdueAmount,
                        subtitle: "\(summaryData.overdueCount) payments",
                        color: AppColors.Budget.overBudget,
                        icon: "exclamationmark.triangle.fill")
                }

                PaymentManagementSummaryCard(
                    title: "This Month",
                    amount: summaryData.thisMonthAmount,
                    subtitle: "\(summaryData.thisMonthCount) due",
                    color: .purple,
                    icon: "calendar.circle.fill")
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - Payment Management Summary Card

struct PaymentManagementSummaryCard: View {
    let title: String
    let amount: Double
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 120)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
