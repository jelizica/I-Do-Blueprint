//
//  VendorDetailOverviewTabV2.swift
//  I Do Blueprint
//
//  Enhanced overview tab with export settings, quick info cards, contact & business details
//  Matches design screen 1 layout with 2x2 grid for Quick Info and side-by-side Contact/Business
//

import SwiftUI

struct VendorDetailOverviewTabV2: View {
    let vendor: Vendor
    @ObservedObject var vendorStore: VendorStoreV2
    let budgetCategories: [BudgetCategory]

    @State private var includeInExport: Bool

    init(vendor: Vendor, vendorStore: VendorStoreV2, budgetCategories: [BudgetCategory] = []) {
        self.vendor = vendor
        self.vendorStore = vendorStore
        self.budgetCategories = budgetCategories
        self._includeInExport = State(initialValue: vendor.includeInExport)
    }
    
    // MARK: - Category Helpers
    
    /// Get the budget category for this vendor
    private var vendorCategory: BudgetCategory? {
        guard let categoryId = vendor.budgetCategoryId else { return nil }
        return budgetCategories.first { $0.id == categoryId }
    }
    
    /// Get the parent category if vendor's category is a subcategory
    private var parentCategory: BudgetCategory? {
        guard let category = vendorCategory,
              let parentId = category.parentCategoryId else { return nil }
        return budgetCategories.first { $0.id == parentId }
    }
    
    /// Get formatted category display string (Parent > Child or just Category)
    private var categoryDisplayString: String? {
        guard let category = vendorCategory else { return nil }
        
        if let parent = parentCategory {
            return "\(parent.categoryName) > \(category.categoryName)"
        }
        return category.categoryName
    }
    
    /// Get the color for the category card
    private var categoryColor: Color {
        guard let category = vendorCategory,
              let color = Color(hex: category.color) else {
            return AppColors.Vendor.contacted
        }
        return color
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Export Settings Card
            exportSettingsCard
            
            // Export Info Banner
            exportInfoBanner

            // Quick Info Section Header + 2x2 Grid
            quickInfoSection

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
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 18))
                    .foregroundColor(SemanticColors.primaryAction)
                
                Text("Export Settings")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            
            HStack(spacing: Spacing.md) {
                Toggle(isOn: $includeInExport) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Include in Contact List Export")
                            .font(Typography.bodyRegular)
                            .fontWeight(.medium)
                            .foregroundColor(SemanticColors.textPrimary)
                        
                        Text("This vendor will be included when you export contact lists")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .onChange(of: includeInExport) { _, newValue in
                    updateExportSetting(newValue)
                }
                
                Spacer()

                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .padding(Spacing.md)
            .background(Color.white.opacity(0.6))
            .cornerRadius(CornerRadius.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modalCard(style: .primary, cornerRadius: CornerRadius.lg, padding: Spacing.lg)
    }

    // MARK: - Export Info Banner
    
    private var exportInfoBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.primaryAction)
            
            Text("Use the Export button in the vendor list to create CSV, PDF, or Google Sheets contact lists")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.primaryAction)
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(SemanticColors.primaryAction.opacity(Opacity.verySubtle))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Quick Info Section

    private var quickInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(SemanticColors.primaryAction)
                
                Text("Quick Info")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Spacer()
                
                // Contact Section Header (right side)
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.primaryAction)
                    
                    Text("Contact")
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)
                }
            }
            
            // Two-column layout: Quick Info Grid + Contact Info
            HStack(alignment: .top, spacing: Spacing.lg) {
                // Left: 2x2 Quick Info Grid
                quickInfoGrid
                    .frame(maxWidth: .infinity)
                
                // Right: Contact Information
                contactInfoCard
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Quick Info 2x2 Grid
    
    private var quickInfoGrid: some View {
        VStack(spacing: Spacing.md) {
            // Row 1: Category + Quoted Amount
            HStack(spacing: Spacing.md) {
                // Category Card
                if let categoryDisplay = categoryDisplayString {
                    QuickInfoCardV2(
                        icon: "tag.fill",
                        title: categoryDisplay,
                        subtitle: "CATEGORY",
                        color: categoryColor,
                        backgroundColor: categoryColor.opacity(Opacity.verySubtle)
                    )
                } else if let vendorType = vendor.vendorType {
                    QuickInfoCardV2(
                        icon: "tag.fill",
                        title: vendorType,
                        subtitle: "CATEGORY",
                        color: AppColors.Vendor.contacted,
                        backgroundColor: AppColors.Vendor.contacted.opacity(Opacity.verySubtle)
                    )
                } else {
                    QuickInfoCardV2(
                        icon: "tag.fill",
                        title: "Uncategorized",
                        subtitle: "CATEGORY",
                        color: SemanticColors.textSecondary,
                        backgroundColor: SemanticColors.backgroundSecondary
                    )
                }
                
                // Quoted Amount Card
                if let quotedAmount = vendor.quotedAmount {
                    QuickInfoCardV2(
                        icon: "dollarsign.circle.fill",
                        title: quotedAmount.formatted(.currency(code: "USD")),
                        subtitle: "QUOTED AMOUNT",
                        color: SemanticColors.primaryAction,
                        backgroundColor: SemanticColors.primaryAction.opacity(Opacity.verySubtle)
                    )
                } else {
                    QuickInfoCardV2(
                        icon: "dollarsign.circle.fill",
                        title: "Not quoted",
                        subtitle: "QUOTED AMOUNT",
                        color: SemanticColors.textSecondary,
                        backgroundColor: SemanticColors.backgroundSecondary
                    )
                }
            }
            
            // Row 2: Status + Booked Date
            HStack(spacing: Spacing.md) {
                // Status Card
                QuickInfoCardV2(
                    icon: vendor.isBooked == true ? "checkmark.circle.fill" : "clock.fill",
                    title: vendor.isBooked == true ? "Booked" : "Available",
                    subtitle: "STATUS",
                    color: vendor.isBooked == true ? SemanticColors.success : AppColors.Vendor.pending,
                    backgroundColor: (vendor.isBooked == true ? SemanticColors.success : AppColors.Vendor.pending).opacity(Opacity.verySubtle)
                )
                
                // Booked Date Card
                if vendor.isBooked == true, let dateBooked = vendor.dateBooked {
                    QuickInfoCardV2(
                        icon: "calendar.badge.checkmark",
                        title: dateBooked.formatted(date: .abbreviated, time: .omitted),
                        subtitle: "BOOKED ON",
                        color: SemanticColors.statusError,
                        backgroundColor: SemanticColors.statusError.opacity(Opacity.verySubtle)
                    )
                } else {
                    QuickInfoCardV2(
                        icon: "calendar",
                        title: "Not booked",
                        subtitle: "BOOKED ON",
                        color: SemanticColors.textSecondary,
                        backgroundColor: SemanticColors.backgroundSecondary
                    )
                }
            }
        }
    }
    
    // MARK: - Contact Info Card (Right side of Quick Info)
    
    private var contactInfoCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Contact Person
            if let contactName = vendor.contactName {
                ContactInfoRowCompact(
                    icon: "person.fill",
                    label: "Contact Person",
                    value: contactName
                )
            }
            
            // Email
            if let email = vendor.email {
                ContactInfoRowCompact(
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
            
            // Phone
            if let phone = vendor.phoneNumber {
                ContactInfoRowCompact(
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
            
            // Website
            if let website = vendor.website {
                ContactInfoRowCompact(
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
            
            // Instagram
            if let instagram = vendor.instagramHandle, !instagram.isEmpty {
                ContactInfoRowCompact(
                    icon: "camera.fill",
                    label: "Instagram",
                    value: "@\(instagram.hasPrefix("@") ? String(instagram.dropFirst()) : instagram)",
                    isLink: true
                ) {
                    let handle = instagram.hasPrefix("@") ? String(instagram.dropFirst()) : instagram
                    if let url = URL(string: "https://instagram.com/\(handle)") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            
            if !hasContactInfo {
                HStack {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.textSecondary)

                    Text("No contact information available")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(Spacing.md)
            }
        }
        .padding(Spacing.md)
        .background(contactCardBackground)
    }

    // Dynamic contact card background matching guest modal card style
    private var contactCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.white.opacity(0.85))

            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            SemanticColors.primaryAction.opacity(0.08),
                            SemanticColors.primaryAction.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    LinearGradient(
                        colors: [
                            SemanticColors.primaryAction.opacity(0.25),
                            SemanticColors.primaryAction.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: SemanticColors.primaryAction.opacity(0.08), radius: 6, x: 0, y: 3)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }

    // MARK: - Contact Information Section (Full width, below Quick Info)

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
                
                // Instagram
                if let instagram = vendor.instagramHandle, !instagram.isEmpty {
                    ContactInfoRowV2(
                        icon: "camera.fill",
                        label: "Instagram",
                        value: "@\(instagram.hasPrefix("@") ? String(instagram.dropFirst()) : instagram)",
                        isLink: true
                    ) {
                        let handle = instagram.hasPrefix("@") ? String(instagram.dropFirst()) : instagram
                        if let url = URL(string: "https://instagram.com/\(handle)") {
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
                // Business Name
                ContactInfoRowV2(
                    icon: "building.columns.fill",
                    label: "Business Name",
                    value: vendor.vendorName
                )
                
                // Service Type
                if let vendorType = vendor.vendorType, !vendorType.isEmpty {
                    ContactInfoRowV2(
                        icon: "tag.fill",
                        label: "Service Type",
                        value: vendorType
                    )
                }
                
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

                if !hasBusinessDetails && vendor.vendorType == nil {
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
        vendor.contactName != nil || vendor.email != nil || vendor.phoneNumber != nil || vendor.website != nil || (vendor.instagramHandle != nil && !vendor.instagramHandle!.isEmpty)
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

// MARK: - Quick Info Card V2 (Matches design screen 1)

struct QuickInfoCardV2: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let backgroundColor: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(title)
                .font(Typography.bodyRegular)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textPrimary)
                .lineLimit(1)

            Text(subtitle)
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(dynamicCardBackground)
    }

    // Dynamic card background matching guest modal card style
    private var dynamicCardBackground: some View {
        ZStack {
            // Base fill with strong opacity for visibility
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.white.opacity(0.85))

            // Color gradient overlay using the card's color
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.12),
                            color.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Inner highlight at top edge for 3D effect
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.1), radius: 6, x: 0, y: 3)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Contact Info Row Compact (For right side of Quick Info)

struct ContactInfoRowCompact: View {
    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false
    var action: (() -> Void)? = nil

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.primaryAction)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
                
                if isLink, let action = action {
                    Button(action: action) {
                        Text(value)
                            .font(Typography.bodySmall)
                            .foregroundColor(SemanticColors.primaryAction)
                            .underline(isHovering)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isHovering = hovering
                    }
                } else {
                    Text(value)
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textPrimary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
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

