//
//  ModernGuestStatCard.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Trend?

    enum Trend {
        case positive, neutral, negative
    }

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )

                Spacer()

                if let trend = trend {
                    Image(systemName: trendIcon(for: trend))
                        .font(.caption2)
                        .foregroundColor(trendColor(for: trend))
                }
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text(title)
                .font(.system(size: 9))
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .frame(height: 80)
        .hoverableCard(padding: Spacing.md)
    }

    private func trendIcon(for trend: Trend) -> String {
        switch trend {
        case .positive: return "arrow.up.right"
        case .neutral: return "minus"
        case .negative: return "arrow.down.right"
        }
    }

    private func trendColor(for trend: Trend) -> Color {
        switch trend {
        case .positive: return AppColors.success
        case .neutral: return AppColors.textSecondary
        case .negative: return AppColors.error
        }
    }
}
