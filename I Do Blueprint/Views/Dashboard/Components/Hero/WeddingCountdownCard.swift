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
    /// Uses theme-specific text shades for cohesive appearance
    private var adaptiveTextColor: Color {
        if themeSettings.useCustomWeddingColors {
            // For custom colors, derive text color from the gradient itself
            let color1 = Color.fromHex(themeSettings.weddingColor1.replacingOccurrences(of: "#", with: ""))
            let color2 = Color.fromHex(themeSettings.weddingColor2.replacingOccurrences(of: "#", with: ""))
            let avgLuminance = (color1.luminance + color2.luminance) / 2
            
            // Use darker shade of the darker gradient color for light backgrounds
            // Use lighter shade of the lighter gradient color for dark backgrounds
            if avgLuminance > 0.5 {
                // Light background - use darkened version of darker color
                return color1.luminance < color2.luminance ? color1.darkened(by: 0.4) : color2.darkened(by: 0.4)
            } else {
                // Dark background - use lightened version of lighter color
                return color1.luminance > color2.luminance ? color1.lightened(by: 0.4) : color2.lightened(by: 0.4)
            }
        } else {
            // Use theme-specific text shades from design system
            switch themeSettings.colorScheme {
            case "sage-serenity":
                return SageGreen.text  // shade800 - WCAG AAA compliant
            case "lavender-dream":
                return SoftLavender.text  // shade800 - WCAG AAA compliant
            case "terracotta-warm":
                return Terracotta.text  // shade800 - WCAG AAA compliant
            default: // blush-romance
                return BlushPink.text  // shade800 - WCAG AAA compliant
            }
        }
    }

    /// Secondary text color with appropriate opacity
    private var adaptiveSecondaryTextColor: Color {
        adaptiveTextColor.opacity(0.85)
    }

    /// Badge background that contrasts with text
    private var adaptiveBadgeBackground: Color {
        if themeSettings.useCustomWeddingColors {
            let color1 = Color.fromHex(themeSettings.weddingColor1.replacingOccurrences(of: "#", with: ""))
            let color2 = Color.fromHex(themeSettings.weddingColor2.replacingOccurrences(of: "#", with: ""))
            let avgLuminance = (color1.luminance + color2.luminance) / 2
            return avgLuminance > 0.5 ? Color.black.opacity(0.08) : Color.white.opacity(0.2)
        } else {
            // Use theme-specific lighter shade for badge background
            switch themeSettings.colorScheme {
            case "sage-serenity":
                return SageGreen.shade100.opacity(0.6)
            case "lavender-dream":
                return SoftLavender.shade100.opacity(0.6)
            case "terracotta-warm":
                return Terracotta.shade100.opacity(0.6)
            default: // blush-romance
                return BlushPink.shade100.opacity(0.6)
            }
        }
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
