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

    /// Calculate appropriate text color based on gradient luminance
    /// Returns dark text for light backgrounds, light text for dark backgrounds
    private var adaptiveTextColor: Color {
        // Get the gradient colors
        let color1: Color
        let color2: Color
        
        if themeSettings.useCustomWeddingColors {
            color1 = Color.fromHex(themeSettings.weddingColor1.replacingOccurrences(of: "#", with: ""))
            color2 = Color.fromHex(themeSettings.weddingColor2.replacingOccurrences(of: "#", with: ""))
        } else {
            // Use theme-specific colors
            switch themeSettings.colorScheme {
            case "sage-serenity":
                color1 = Color.fromHex("B8D4C8")
                color2 = Color.fromHex("5A9070")
            case "lavender-dream":
                color1 = Color.fromHex("E6D5F5")
                color2 = Color.fromHex("9B7EBD")
            case "terracotta-warm":
                color1 = Color.fromHex("F4C2A0")
                color2 = Color.fromHex("D17A4F")
            default: // blush-romance
                color1 = Color.fromHex("EAE2FF")
                color2 = Color.fromHex("FFB6C1")
            }
        }
        
        // Calculate average luminance
        let lum1 = color1.luminance
        let lum2 = color2.luminance
        let avgLuminance = (lum1 + lum2) / 2
        
        // Use dark text on light backgrounds (luminance > 0.5), light text on dark backgrounds
        return avgLuminance > 0.5 ? Color(red: 0.2, green: 0.2, blue: 0.25) : .white
    }

    /// Secondary text color with appropriate opacity
    private var adaptiveSecondaryTextColor: Color {
        adaptiveTextColor.opacity(0.85)
    }

    /// Badge background that contrasts with text
    private var adaptiveBadgeBackground: Color {
        adaptiveTextColor == .white ? Color.white.opacity(0.2) : Color.black.opacity(0.08)
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
                        .foregroundColor(adaptiveTextColor)

                    if let weddingDate = weddingDate {
                        Text(formatWeddingDate(weddingDate))
                            .font(Typography.bodyRegular)
                            .foregroundColor(adaptiveSecondaryTextColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Right side - Emphasized day count
                VStack(spacing: Spacing.xs) {
                    Text("\(daysUntil)")
                        .font(Typography.displayLarge)
                        .foregroundColor(adaptiveTextColor)

                    Text("Days Until")
                        .font(Typography.caption)
                        .foregroundColor(adaptiveSecondaryTextColor)
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(adaptiveBadgeBackground)
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
