//
//  GuestStatsSection.swift
//  I Do Blueprint
//
//  Statistics cards section for guest management
//

import SwiftUI

struct GuestStatsSection: View {
    let windowSize: WindowSize
    let totalGuestsCount: Int
    let weeklyChange: Int
    let acceptanceRate: Double
    let attendingCount: Int
    let pendingCount: Int
    let declinedCount: Int

    var body: some View {
        if windowSize == .compact {
            // Compact: 2-2-1 asymmetric grid
            VStack(spacing: Spacing.lg) {
                // Row 1: Total Guests + Acceptance Rate
                HStack(spacing: Spacing.lg) {
                    GuestManagementStatCard(
                        title: "Total Guests",
                        value: "\(totalGuestsCount)",
                        subtitle: weeklyChange > 0 ? "+\(weeklyChange) this week" : nil,
                        subtitleColor: SemanticColors.success,
                        icon: "person.3.fill"
                    )

                    GuestManagementStatCard(
                        title: "Acceptance Rate",
                        value: "\(Int(acceptanceRate * 100))%",
                        subtitle: nil,
                        subtitleColor: SemanticColors.success,
                        icon: "checkmark.circle.fill"
                    )
                }

                // Row 2: Attending + Pending
                HStack(spacing: Spacing.lg) {
                    GuestManagementStatCard(
                        title: "Attending",
                        value: "\(attendingCount)",
                        subtitle: "Confirmed & Attending",
                        subtitleColor: SemanticColors.success,
                        icon: "checkmark.circle.fill"
                    )

                    GuestManagementStatCard(
                        title: "Pending",
                        value: "\(pendingCount)",
                        subtitle: "All other statuses",
                        subtitleColor: SemanticColors.warning,
                        icon: "clock.fill"
                    )
                }

                // Row 3: Declined (full width)
                GuestManagementStatCard(
                    title: "Declined",
                    value: "\(declinedCount)",
                    subtitle: "Declined & No Response",
                    subtitleColor: SemanticColors.error,
                    icon: "xmark.circle.fill"
                )
            }
        } else {
            // Regular/Large: Original 2-row layout
            VStack(spacing: Spacing.lg) {
                // Main Stats Row
                HStack(spacing: Spacing.lg) {
                    GuestManagementStatCard(
                        title: "Total Guests",
                        value: "\(totalGuestsCount)",
                        subtitle: weeklyChange > 0 ? "+\(weeklyChange) this week" : nil,
                        subtitleColor: SemanticColors.success,
                        icon: "person.3.fill"
                    )

                    GuestManagementStatCard(
                        title: "Acceptance Rate",
                        value: "\(Int(acceptanceRate * 100))%",
                        subtitle: nil,
                        subtitleColor: SemanticColors.success,
                        icon: "checkmark.circle.fill"
                    )
                }

                // Sub-sections Row
                HStack(spacing: Spacing.lg) {
                    GuestManagementStatCard(
                        title: "Attending",
                        value: "\(attendingCount)",
                        subtitle: "Confirmed & Attending",
                        subtitleColor: SemanticColors.success,
                        icon: "checkmark.circle.fill"
                    )

                    GuestManagementStatCard(
                        title: "Pending",
                        value: "\(pendingCount)",
                        subtitle: "All other statuses",
                        subtitleColor: SemanticColors.warning,
                        icon: "clock.fill"
                    )

                    GuestManagementStatCard(
                        title: "Declined",
                        value: "\(declinedCount)",
                        subtitle: "Declined & No Response",
                        subtitleColor: SemanticColors.error,
                        icon: "xmark.circle.fill"
                    )
                }
            }
        }
    }
}

/// Guest management stat card with glassmorphism styling
/// Uses glassPanel() modifier and NativeIconBadge for consistent V7 design
struct GuestManagementStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let subtitleColor: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text(value)
                        .font(Typography.displayMedium)
                        .foregroundColor(SemanticColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundColor(subtitleColor)
                    }
                }

                Spacer()

                NativeIconBadge(
                    systemName: icon,
                    color: SemanticColors.primaryAction,
                    size: 40
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel()
    }
}
