//
//  VendorExportFlagSection.swift
//  My Wedding Planning App
//
//  Extracted from VendorDetailViewV2.swift
//

import SwiftUI

struct VendorExportFlagSection: View {
    let vendor: Vendor
    let onToggle: (Bool) -> Void
    @State private var isToggling = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Export Settings",
                icon: "square.and.arrow.up.circle.fill",
                color: AppColors.Vendor.contacted
            )

            HStack(spacing: Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(vendor.includeInExport ? AppColors.Vendor.booked : AppColors.Vendor.notContacted.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill((vendor.includeInExport ? AppColors.Vendor.booked : AppColors.Vendor.notContacted).opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Include in Contact List Export")
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)

                    Text(vendor.includeInExport
                        ? "This vendor will be included when you export contact lists"
                        : "This vendor will not be included in exported contact lists")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                if isToggling {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Toggle("", isOn: Binding(
                        get: { vendor.includeInExport },
                        set: { newValue in
                            isToggling = true
                            onToggle(newValue)
                            // Reset after a delay to allow the update
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isToggling = false
                            }
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(AppColors.cardBackground)
                    .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .strokeBorder(
                        vendor.includeInExport ? AppColors.Vendor.booked.opacity(0.3) : AppColors.border,
                        lineWidth: vendor.includeInExport ? 2 : 1
                    )
            )

            // Helper text
            HStack(spacing: Spacing.xs) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(AppColors.Vendor.contacted)

                Text("Use the Export button in the vendor list to create CSV, PDF, or Google Sheets contact lists")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, Spacing.sm)
        }
    }
}
