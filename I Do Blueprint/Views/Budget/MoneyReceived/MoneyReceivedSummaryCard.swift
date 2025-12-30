//
//  MoneyReceivedSummaryCard.swift
//  I Do Blueprint
//
//  Summary card displaying total received, gift count, average gift, and thank you status
//

import SwiftUI

struct MoneyReceivedSummaryCard: View {
    let totalReceived: Double
    let giftCount: Int
    let averageGiftAmount: Double
    let thankYouSentCount: Int
    let thankYouPendingCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Primary metrics
            HStack {
                MetricView(
                    title: "Total Received",
                    value: String(format: "$%.0f", totalReceived),
                    color: AppColors.Budget.income,
                    alignment: .leading
                )
                
                Spacer()
                
                MetricView(
                    title: "Gift Count",
                    value: "\(giftCount)",
                    color: .primary,
                    alignment: .center
                )
                
                Spacer()
                
                MetricView(
                    title: "Avg Gift",
                    value: String(format: "$%.0f", averageGiftAmount),
                    color: AppColors.Budget.allocated,
                    alignment: .trailing
                )
            }
            
            // Thank you status
            HStack {
                MetricView(
                    title: "Thank You Sent",
                    value: "\(thankYouSentCount)",
                    color: AppColors.Budget.income,
                    alignment: .leading,
                    fontSize: .title3
                )
                
                Spacer()
                
                MetricView(
                    title: "Pending",
                    value: "\(thankYouPendingCount)",
                    color: AppColors.Budget.pending,
                    alignment: .trailing,
                    fontSize: .title3
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - Supporting Views

private struct MetricView: View {
    let title: String
    let value: String
    let color: Color
    let alignment: HorizontalAlignment
    var fontSize: Font = .title2
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(fontSize)
                .fontWeight(fontSize == .title2 ? .semibold : .medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview {
    MoneyReceivedSummaryCard(
        totalReceived: 5000,
        giftCount: 12,
        averageGiftAmount: 416.67,
        thankYouSentCount: 8,
        thankYouPendingCount: 4
    )
    .frame(width: 600)
}
