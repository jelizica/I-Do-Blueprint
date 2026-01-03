//
//  VendorDetailOverviewTab.swift
//  I Do Blueprint
//
//  Overview tab content for vendor detail modal
//

import SwiftUI

struct VendorDetailOverviewTab: View {
    let vendor: Vendor
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Quick Info Cards
            if hasQuickInfo {
                quickInfoCards
            }
            
            // Contact Information
            if hasContactInfo {
                contactInformationSection
            }
            
            // Address
            if let address = vendor.address {
                addressSection(address)
            }
        }
    }
    
    // MARK: - Components
    
    private var quickInfoCards: some View {
        HStack(spacing: Spacing.md) {
            if let quotedAmount = vendor.quotedAmount {
                VendorQuickInfoCard(
                    icon: "dollarsign.circle.fill",
                    title: "Quoted Amount",
                    value: quotedAmount.formatted(.currency(code: "USD")),
                    color: AppColors.Vendor.booked
                )
            }
            
            if vendor.isBooked == true, let dateBooked = vendor.dateBooked {
                VendorQuickInfoCard(
                    icon: "calendar.circle.fill",
                    title: "Booked Date",
                    value: dateBooked.formatted(date: .abbreviated, time: .omitted),
                    color: SemanticColors.success
                )
            }
        }
    }
    
    private var contactInformationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Contact Information",
                icon: "person.circle.fill",
                color: SemanticColors.primaryAction
            )
            
            VStack(spacing: Spacing.sm) {
                if let contactName = vendor.contactName {
                    VendorContactRow(icon: "person.fill", label: "Contact", value: contactName)
                }
                
                if let phone = vendor.phoneNumber {
                    VendorContactRow(icon: "phone.fill", label: "Phone", value: phone, isLink: true) {
                        if let url = URL(string: "tel:\(phone.filter { !$0.isWhitespace })") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                
                if let email = vendor.email {
                    VendorContactRow(icon: "envelope.fill", label: "Email", value: email, isLink: true) {
                        if let url = URL(string: "mailto:\(email)") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                
                if let website = vendor.website {
                    VendorContactRow(icon: "globe", label: "Website", value: website, isLink: true) {
                        if let url = URL(string: website) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
    }
    
    private func addressSection(_ address: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Address",
                icon: "mappin.circle.fill",
                color: AppColors.Vendor.contacted
            )
            
            Text(address)
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textPrimary)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SemanticColors.backgroundSecondary)
                .cornerRadius(CornerRadius.md)
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasQuickInfo: Bool {
        vendor.quotedAmount != nil || (vendor.isBooked == true && vendor.dateBooked != nil)
    }
    
    private var hasContactInfo: Bool {
        vendor.contactName != nil || vendor.email != nil || vendor.phoneNumber != nil || vendor.website != nil
    }
}

// MARK: - Supporting Views

struct VendorQuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text(value)
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

struct VendorContactRow: View {
    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 20)
            
            Text(label)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            if isLink, let action = action {
                Button(action: action) {
                    Text(value)
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.primaryAction)
                        .underline()
                }
                .buttonStyle(.plain)
            } else {
                Text(value)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            
            Spacer()
        }
    }
}
