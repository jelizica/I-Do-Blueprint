//
//  IndividualPaymentVendorCardV1.swift
//  I Do Blueprint
//
//  Vendor details card for individual payment detail view
//

import SwiftUI

struct IndividualPaymentVendorCardV1: View {
    let vendor: Vendor?
    let vendorName: String
    let expense: Expense?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Text("Vendor Details")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                vendorIcon
            }

            // Vendor Info
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Name and Category
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(vendorName)
                        .font(Typography.bodyRegular.weight(.medium))
                        .foregroundColor(SemanticColors.textPrimary)

                    if let category = vendor?.vendorType {
                        Text(category)
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }

                // Contact Info
                if let vendor = vendor {
                    contactInfoSection(vendor)
                }

                // Service Description
                if let expense = expense, let desc = expense.notes, !desc.isEmpty {
                    serviceDescriptionSection(desc)
                }
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Vendor Icon

    private var vendorIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(SageGreen.shade200.opacity(0.5))
                .frame(width: 40, height: 40)

            Image(systemName: vendorIconName)
                .font(.title3)
                .foregroundColor(SageGreen.shade500)
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SageGreen.shade500.opacity(0.2), lineWidth: 1)
        )
    }

    private var vendorIconName: String {
        guard let category = vendor?.vendorType?.lowercased() else {
            return "storefront"
        }
        switch category {
        case let c where c.contains("jewel"): return "diamond"
        case let c where c.contains("photo"): return "camera"
        case let c where c.contains("flor"): return "leaf"
        case let c where c.contains("cater"): return "fork.knife"
        case let c where c.contains("music"), let c where c.contains("dj"): return "music.note"
        case let c where c.contains("venue"): return "building.2"
        default: return "storefront"
        }
    }

    // MARK: - Contact Info

    private func contactInfoSection(_ vendor: Vendor) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let contact = vendor.contactName {
                contactRow(icon: "person", text: "Contact: \(contact)")
            }

            if let email = vendor.email {
                contactRow(icon: "envelope", text: email)
            }

            if let phone = vendor.phoneNumber {
                contactRow(icon: "phone", text: phone)
            }
        }
    }

    private func contactRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )

            Text(text)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }

    // MARK: - Service Description

    private func serviceDescriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            NativeDividerStyle(opacity: 0.3)

            Text("SERVICE DESCRIPTION")
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(SemanticColors.textTertiary)
                .tracking(0.5)

            Text(description)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(.top, Spacing.md)
    }
}
