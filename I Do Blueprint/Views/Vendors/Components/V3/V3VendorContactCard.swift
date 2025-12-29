//
//  V3VendorContactCard.swift
//  I Do Blueprint
//
//  Contact information card for V3 vendor detail view
//

import SwiftUI

struct V3VendorContactCard: View {
    let vendor: Vendor

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            V3SectionHeader(
                title: "Contact",
                icon: "envelope.circle.fill",
                color: AppColors.Vendor.contacted
            )

            VStack(spacing: Spacing.sm) {
                if let contactName = vendor.contactName, !contactName.isEmpty {
                    V3ContactRow(
                        icon: "person.fill",
                        label: "CONTACT PERSON",
                        value: contactName,
                        color: .purple
                    )
                }

                if let email = vendor.email, !email.isEmpty {
                    V3ContactRow(
                        icon: "envelope.fill",
                        label: "EMAIL",
                        value: email,
                        color: AppColors.Vendor.contacted,
                        isLink: true
                    ) {
                        if let url = vendor.emailURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                if let phone = vendor.phoneNumber, !phone.isEmpty {
                    V3ContactRow(
                        icon: "phone.fill",
                        label: "PHONE",
                        value: phone,
                        color: AppColors.Vendor.booked,
                        isLink: true
                    ) {
                        if let url = vendor.phoneURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                if let website = vendor.website, !website.isEmpty {
                    V3ContactRow(
                        icon: "globe",
                        label: "WEBSITE",
                        value: vendor.websiteDisplayString ?? website,
                        color: .cyan,
                        isLink: true
                    ) {
                        if let url = vendor.websiteURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Contact Row

private struct V3ContactRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var isLink: Bool = false
    var action: (() -> Void)? = nil

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon circle
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                )

            // Label and value
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label)
                    .font(Typography.caption2)
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.5)

                if isLink, let action = action {
                    Button(action: action) {
                        Text(value)
                            .font(Typography.bodyRegular)
                            .foregroundColor(isHovering ? AppColors.primary : AppColors.textPrimary)
                            .underline(isHovering)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isHovering = hovering
                    }
                } else {
                    Text(value)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .accessibilityHint(isLink ? "Double tap to open" : "")
    }
}

// MARK: - Preview

#Preview("Contact Card") {
    V3VendorContactCard(
        vendor: .makeTest()
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Contact Card - Minimal") {
    V3VendorContactCard(
        vendor: .makeTest(
            contactName: nil,
            phoneNumber: nil,
            website: nil
        )
    )
    .padding()
    .background(AppColors.background)
}
