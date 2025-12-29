//
//  WeddingCountdownCard.swift
//  I Do Blueprint
//
//  Extracted hero countdown card for dashboard
//

import SwiftUI

struct WeddingCountdownCard: View {
    let weddingDate: Date?
    let daysUntil: Int
    let partner1Name: String
    let partner2Name: String
    let userTimezone: TimeZone

    private var weddingTitle: String {
        if !partner1Name.isEmpty && !partner2Name.isEmpty {
            return "\(partner1Name) & \(partner2Name)'s Wedding"
        } else if !partner1Name.isEmpty {
            return "\(partner1Name)'s Wedding"
        } else if !partner2Name.isEmpty {
            return "\(partner2Name)'s Wedding"
        } else {
            return "Our Wedding"
        }
    }

    var body: some View {
        ZStack {
            // Colorful header gradient (Design System)
            AppGradients.dashboardHeader

            HStack(spacing: Spacing.xxl * 2) {
                // Left side - Wedding info
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(weddingTitle)
                        .font(Typography.displaySmall)
                        .foregroundColor(AppColors.textPrimary)

                    if let weddingDate = weddingDate {
                        Text(formatWeddingDate(weddingDate))
                            .font(Typography.bodyRegular)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Right side - Emphasized day count
                VStack(spacing: Spacing.xs) {
                    Text("\(daysUntil)")
                        .font(Typography.displayLarge)
                        .foregroundColor(AppColors.info)

                    Text("Days Until")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.cardBackground)
                        .shadow(color: AppColors.textPrimary.opacity(0.08), radius: 12, x: 0, y: 4)
                )
            }
            .padding(.horizontal, Spacing.xxl * 1.5)
        }
        .frame(height: 180)
        .cornerRadius(12)
        .shadow(color: AppColors.textPrimary.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func formatWeddingDate(_ date: Date) -> String {
        // Use injected timezone for consistent dependency injection
        return DateFormatting.formatDateLong(date, timezone: userTimezone)
    }
}
