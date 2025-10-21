//
//  PaymentsSummaryCard.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct PaymentsSummaryCard: View {
    let metrics: PaymentMetrics
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "creditcard.fill",
            title: "Payments",
            subtitle: "\(metrics.totalPayments) total",
            color: .green,
            isHovered: $isHovered,
            hasAlert: metrics.overduePayments > 0) {
            VStack(spacing: 12) {
                paymentStats
                quickStats
            }
        }
    }

    private var paymentStats: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Paid")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formatCurrency(metrics.paidAmount))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            HStack {
                Text("Unpaid")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formatCurrency(metrics.unpaidAmount))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            if metrics.overdueAmount > 0 {
                HStack {
                    Text("Overdue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatCurrency(metrics.overdueAmount))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05)))
    }

    private var quickStats: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            QuickStat(
                icon: "clock.fill",
                label: "Upcoming",
                value: "\(metrics.upcomingPayments)",
                color: .blue)

            QuickStat(
                icon: "exclamationmark.circle.fill",
                label: "Overdue",
                value: "\(metrics.overduePayments)",
                color: .red)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsStore.settings.global.currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Preview

#Preview {
    PaymentsSummaryCard(
        metrics: PaymentMetrics(
            totalPayments: 15,
            paidPayments: 8,
            unpaidPayments: 7,
            overduePayments: 2,
            upcomingPayments: 5,
            totalAmount: 25000,
            paidAmount: 12000,
            unpaidAmount: 13000,
            overdueAmount: 3000,
            recentPayments: []))
        .environmentObject(SettingsStoreV2())
        .padding()
        .frame(width: 400)
}
