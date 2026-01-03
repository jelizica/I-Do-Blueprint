//
//  V3VendorOverviewContent.swift
//  I Do Blueprint
//
//  Overview tab content for V3 vendor detail view
//

import SwiftUI

struct V3VendorOverviewContent: View {
    let vendor: Vendor
    let onEdit: () -> Void
    let onExportToggle: (Bool) async -> Void

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            // Quick Actions Toolbar
            V3VendorQuickActions(vendor: vendor, onEdit: onEdit)

            // Export Flag Toggle Section
            V3VendorExportToggle(vendor: vendor, onToggle: onExportToggle)

            // Quick Info Cards
            quickInfoSection

            // Contact Section
            if vendor.hasContactInfo {
                V3VendorContactCard(vendor: vendor)
            }

            // Business Details
            businessDetailsSection
        }
    }

    // MARK: - Quick Info Section

    private var quickInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            V3SectionHeader(
                title: "Quick Info",
                icon: "info.circle.fill",
                color: SemanticColors.primaryAction
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: Spacing.md
            ) {
                // Category
                if let vendorType = vendor.vendorType, !vendorType.isEmpty {
                    V3QuickInfoCard(
                        icon: "tag.fill",
                        title: "Category",
                        value: vendorType,
                        color: .purple
                    )
                }

                // Quoted Amount
                if let formattedAmount = vendor.formattedQuotedAmount {
                    V3QuickInfoCard(
                        icon: "dollarsign.circle.fill",
                        title: "Quoted Amount",
                        value: formattedAmount,
                        color: SemanticColors.statusSuccess
                    )
                }

                // Status
                V3QuickInfoCard(
                    icon: vendor.isBooked == true ? "checkmark.seal.fill" : "clock.badge.fill",
                    title: "Status",
                    value: vendor.statusDisplayName,
                    color: vendor.statusColor
                )

                // Booked On Date
                if let formattedDate = vendor.formattedBookingDate, vendor.isBooked == true {
                    V3QuickInfoCard(
                        icon: "calendar.badge.checkmark",
                        title: "Booked On",
                        value: formattedDate,
                        color: SemanticColors.primaryAction
                    )
                }
            }
        }
    }

    // MARK: - Business Details Section

    private var businessDetailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            V3SectionHeader(
                title: "Business Details",
                icon: "building.2.circle.fill",
                color: .purple
            )

            VStack(spacing: Spacing.sm) {
                // Business Name
                V3BusinessDetailCard(
                    icon: "building.columns.fill",
                    title: "Business Name",
                    value: vendor.vendorName,
                    color: .purple
                )

                // Service Type
                if let vendorType = vendor.vendorType, !vendorType.isEmpty {
                    V3BusinessDetailCard(
                        icon: "tag.fill",
                        title: "Service Type",
                        value: vendorType,
                        color: SemanticColors.primaryAction
                    )
                }

                // Address (if available)
                if let address = vendor.address, !address.isEmpty {
                    V3BusinessDetailCard(
                        icon: "mappin.circle.fill",
                        title: "Address",
                        value: address,
                        color: SemanticColors.statusPending
                    )
                }
            }
        }
    }
}

// MARK: - Business Detail Card

private struct V3BusinessDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Text(value)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Overview Content") {
    ScrollView {
        V3VendorOverviewContent(
            vendor: .makeTest(),
            onEdit: { },
            onExportToggle: { _ in }
        )
        .padding()
    }
    .background(SemanticColors.backgroundPrimary)
}
