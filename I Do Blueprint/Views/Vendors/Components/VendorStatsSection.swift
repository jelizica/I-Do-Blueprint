//
//  VendorStatsSection.swift
//  I Do Blueprint
//
//  Statistics cards section for Vendor Management
//

import SwiftUI

struct VendorStatsSection: View {
    let windowSize: WindowSize
    let vendors: [Vendor]
    
    private var activeVendors: [Vendor] {
        vendors.filter { !$0.isArchived }
    }
    
    private var bookedVendors: [Vendor] {
        vendors.filter { $0.isBooked == true && !$0.isArchived }
    }
    
    private var availableVendors: [Vendor] {
        vendors.filter { $0.isBooked != true && !$0.isArchived }
    }
    
    private var archivedVendors: [Vendor] {
        vendors.filter { $0.isArchived }
    }
    
    private var totalQuoted: Double {
        activeVendors.reduce(0) { $0 + ($1.quotedAmount ?? 0) }
    }
    
    var body: some View {
        if windowSize == .compact {
            // Compact: 2-2-1 asymmetric grid
            VStack(spacing: Spacing.lg) {
                // Row 1: Total Vendors + Total Quoted
                HStack(spacing: Spacing.lg) {
                    VendorManagementStatCard(
                        title: "Total Vendors",
                        value: "\(activeVendors.count)",
                        subtitle: nil,
                        subtitleColor: AppColors.success,
                        icon: "building.2.fill"
                    )

                    VendorManagementStatCard(
                        title: "Total Quoted",
                        value: formatCurrency(totalQuoted),
                        subtitle: nil,
                        subtitleColor: AppColors.textSecondary,
                        icon: "dollarsign.circle.fill"
                    )
                }

                // Row 2: Booked + Available
                HStack(spacing: Spacing.lg) {
                    VendorManagementStatCard(
                        title: "Booked",
                        value: "\(bookedVendors.count)",
                        subtitle: "Confirmed vendors",
                        subtitleColor: AppColors.success,
                        icon: "checkmark.seal.fill"
                    )

                    VendorManagementStatCard(
                        title: "Available",
                        value: "\(availableVendors.count)",
                        subtitle: "Still considering",
                        subtitleColor: AppColors.warning,
                        icon: "clock.fill"
                    )
                }

                // Row 3: Archived (full width)
                VendorManagementStatCard(
                    title: "Archived",
                    value: "\(archivedVendors.count)",
                    subtitle: "No longer needed",
                    subtitleColor: AppColors.textSecondary,
                    icon: "archivebox.fill"
                )
            }
        } else {
            // Regular/Large: Original 2-row layout
            VStack(spacing: Spacing.lg) {
                // Main Stats Row
                HStack(spacing: Spacing.lg) {
                    VendorManagementStatCard(
                        title: "Total Vendors",
                        value: "\(activeVendors.count)",
                        subtitle: nil,
                        subtitleColor: AppColors.success,
                        icon: "building.2.fill"
                    )

                    VendorManagementStatCard(
                        title: "Total Quoted",
                        value: formatCurrency(totalQuoted),
                        subtitle: nil,
                        subtitleColor: AppColors.textSecondary,
                        icon: "dollarsign.circle.fill"
                    )
                }

                // Sub-sections Row
                HStack(spacing: Spacing.lg) {
                    VendorManagementStatCard(
                        title: "Booked",
                        value: "\(bookedVendors.count)",
                        subtitle: "Confirmed vendors",
                        subtitleColor: AppColors.success,
                        icon: "checkmark.seal.fill"
                    )

                    VendorManagementStatCard(
                        title: "Available",
                        value: "\(availableVendors.count)",
                        subtitle: "Still considering",
                        subtitleColor: AppColors.warning,
                        icon: "clock.fill"
                    )

                    VendorManagementStatCard(
                        title: "Archived",
                        value: "\(archivedVendors.count)",
                        subtitle: "No longer needed",
                        subtitleColor: AppColors.textSecondary,
                        icon: "archivebox.fill"
                    )
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Stat Card Component

struct VendorManagementStatCard: View {
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
                        .foregroundColor(AppColors.textSecondary)

                    Text(value)
                        .font(Typography.displayMedium)
                        .foregroundColor(AppColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundColor(subtitleColor)
                    }
                }

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary.opacity(0.2))
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
