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
    let themeSettings: ThemeSettings

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

    /// Dynamic gradient based on user's theme settings
    /// Uses custom wedding colors if enabled, otherwise uses theme-based gradient
    private var bannerGradient: LinearGradient {
        AppGradients.dashboardHeader(for: themeSettings)
    }

    var body: some View {
        ZStack {
            // Colorful header gradient (Design System - now dynamic based on settings)
            bannerGradient

            HStack(spacing: Spacing.xxl * 2) {
                // Left side - Wedding info
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(weddingTitle)
                        .font(Typography.displaySmall)
                        .foregroundColor(SemanticColors.textPrimary)

                    if let weddingDate = weddingDate {
                        Text(formatWeddingDate(weddingDate))
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Right side - Emphasized day count
                VStack(spacing: Spacing.xs) {
                    Text("\(daysUntil)")
                        .font(Typography.displayLarge)
                        .foregroundColor(SemanticColors.info)

                    Text("Days Until")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(SemanticColors.backgroundSecondary)
                        .shadow(color: SemanticColors.textPrimary.opacity(Opacity.verySubtle), radius: 12, x: 0, y: 4)
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
