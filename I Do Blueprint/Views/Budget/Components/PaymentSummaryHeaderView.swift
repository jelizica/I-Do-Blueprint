//
//  PaymentSummaryHeaderView.swift
//  I Do Blueprint
//
//  Payment schedule summary header with overview cards
//

import SwiftUI

struct PaymentSummaryHeaderView: View {
    let totalUpcoming: Double
    let totalOverdue: Double
    let scheduleCount: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                PaymentOverviewCard(
                    title: "Upcoming Payments",
                    value: NumberFormatter.currencyShort.string(from: NSNumber(value: totalUpcoming)) ?? "$0",
                    subtitle: "Due soon",
                    icon: "calendar",
                    color: AppColors.Budget.pending)

                PaymentOverviewCard(
                    title: "Overdue Payments",
                    value: NumberFormatter.currencyShort.string(from: NSNumber(value: totalOverdue)) ?? "$0",
                    subtitle: "Past due",
                    icon: "exclamationmark.triangle.fill",
                    color: AppColors.Budget.overBudget)

                PaymentOverviewCard(
                    title: "Total Schedules",
                    value: "\(scheduleCount)",
                    subtitle: "Active schedules",
                    icon: "list.number",
                    color: AppColors.Budget.allocated)
            }
        }
    }
}
