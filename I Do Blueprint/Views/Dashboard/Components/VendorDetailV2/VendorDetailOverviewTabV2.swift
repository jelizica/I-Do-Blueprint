//
//  VendorDetailOverviewTabV2.swift
//  I Do Blueprint
//
//  Enhanced overview tab with export settings, quick info cards, contact & business details
//

import SwiftUI

struct VendorDetailOverviewTabV2: View {
    let vendor: Vendor
    @ObservedObject var vendorStore: VendorStoreV2

    @State private var includeInExport: Bool

    init(vendor: Vendor, vendorStore: VendorStoreV2) {
        self.vendor = vendor
        self.vendorStore = vendorStore
        self._includeInExport = State(initialValue: vendor.includeInExport)
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Export Settings Card
            exportSettingsCard

            // Quick Info Cards Row
            quickInfoCards

            // Two-column layout for Contact and Business Details
            HStack(alignment: .top, spacing: Spacing.lg) {
                // Contact Information
                contactInformationSection

                // Business Details
                businessDetailsSection
            }
        }
    }

    // MARK: - Export Settings Card

    private var exportSettingsCard: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "square.and.arrow.up.fill")
                .font(.system(size: 20))
                .foregroundColor(SemanticColors.primaryAction)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Export Settings")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Include this vendor in exports and reports")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $includeInExport)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: includeInExport) { _, newValue in
                    updateExportSetting(newValue)
                }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Quick Info Cards

    private var quickInfoCards: some View {
        HStack(spacing: Spacing.md) {
            // Status Card
            VendorQuickInfoCardV2(
                icon: vendor.isBooked == true ? "checkmark.seal.fill" : "clock.fill",
                title: "Status",
                value: vendor.isBooked == true ? "Booked" : "Available",
                color: vendor.isBooked == true ? AppColors.Vendor.booked : AppColors.Vendor.pending
            )

            // Quoted Amount Card
            if let quotedAmount = vendor.quotedAmount {
                VendorQuickInfoCardV2(
                    icon: "dollarsign.circle.fill",
                    title: "Quoted Amount",
                    value: quotedAmount.formatted(.currency(code: "USD")),
                    color: SemanticColors.primaryAction
                )
            }

            // Booking Date Card
            if vendor.isBooked == true, let dateBooked = vendor.dateBooked {
                VendorQuickInfoCardV2(
                    icon: "calendar.badge.checkmark",
                    title: "Booked Date",
                    value: dateBooked.formatted(date: .abbreviated, time: .omitted),
                    color: SemanticColors.success
                )
            }

            // Vendor Type Card
            if let vendorType = vendor.vendorType {
                VendorQuickInfoCardV2(
                    icon: "tag.fill",
                    title: "Category",
                    value: vendorType,
                    color: AppColors.Vendor.contacted
                )
            }
        }
    }

    // MARK: - Contact Information Section

    private var contactInformationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Contact Information",
                icon: "person.circle.fill",
                color: SemanticColors.primaryAction
            )

            VStack(spacing: Spacing.sm) {
                if let contactName = vendor.contactName {
                    ContactInfoRowV2(
                        icon: "person.fill",
                        label: "Contact",
                        value: contactName
                    )
                }

                if let phone = vendor.phoneNumber {
                    ContactInfoRowV2(
                        icon: "phone.fill",
                        label: "Phone",
                        value: phone,
                        isLink: true
                    ) {
                        let cleanPhone = phone.filter { !$0.isWhitespace }
                        if let url = URL(string: "tel:\(cleanPhone)") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                if let email = vendor.email {
                    ContactInfoRowV2(
                        icon: "envelope.fill",
                        label: "Email",
                        value: email,
                        isLink: true
                    ) {
                        if let url = URL(string: "mailto:\(email)") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                if let website = vendor.website {
                    ContactInfoRowV2(
                        icon: "globe",
                        label: "Website",
                        value: website,
                        isLink: true
                    ) {
                        var urlString = website
                        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                            urlString = "https://" + urlString
                        }
                        if let url = URL(string: urlString) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                if !hasContactInfo {
                    VendorEmptyStateViewV2(
                        icon: "person.crop.circle.badge.questionmark",
                        message: "No contact information available"
                    )
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    // MARK: - Business Details Section

    private var businessDetailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Business Details",
                icon: "building.2.fill",
                color: AppColors.Vendor.contacted
            )

            VStack(spacing: Spacing.sm) {
                if let address = vendor.address {
                    ContactInfoRowV2(
                        icon: "mappin.circle.fill",
                        label: "Address",
                        value: address.replacingOccurrences(of: "\n", with: ", ")
                    )
                }

                if let createdAt = vendor.createdAt as Date? {
                    ContactInfoRowV2(
                        icon: "calendar.badge.plus",
                        label: "Added",
                        value: createdAt.formatted(date: .abbreviated, time: .omitted)
                    )
                }

                if let updatedAt = vendor.updatedAt {
                    ContactInfoRowV2(
                        icon: "clock.arrow.circlepath",
                        label: "Updated",
                        value: updatedAt.formatted(date: .abbreviated, time: .omitted)
                    )
                }

                if !hasBusinessDetails {
                    VendorEmptyStateViewV2(
                        icon: "building.2.crop.circle.badge.questionmark",
                        message: "No business details available"
                    )
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    // MARK: - Computed Properties

    private var hasContactInfo: Bool {
        vendor.contactName != nil || vendor.email != nil || vendor.phoneNumber != nil || vendor.website != nil
    }

    private var hasBusinessDetails: Bool {
        vendor.address != nil
    }

    // MARK: - Actions

    private func updateExportSetting(_ newValue: Bool) {
        var updatedVendor = vendor
        updatedVendor.includeInExport = newValue
        Task {
            await vendorStore.updateVendor(updatedVendor)
        }
    }
}

// MARK: - Supporting Views

struct VendorQuickInfoCardV2: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(Opacity.subtle))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }

            VStack(spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Text(value)
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }
}

struct ContactInfoRowV2: View {
    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false
    var action: (() -> Void)? = nil

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(SemanticColors.primaryAction.opacity(Opacity.verySubtle))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.primaryAction)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label)
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
                    .textCase(.uppercase)

                if isLink, let action = action {
                    Button(action: action) {
                        Text(value)
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.primaryAction)
                            .underline(isHovering)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isHovering = hovering
                    }
                } else {
                    Text(value)
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textPrimary)
                }
            }

            Spacer()
        }
    }
}

struct VendorEmptyStateViewV2: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textSecondary)

            Text(message)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
    }
}
