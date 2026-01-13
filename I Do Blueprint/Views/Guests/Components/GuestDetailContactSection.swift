//
//  GuestDetailContactSection.swift
//  I Do Blueprint
//
//  Contact information section for guest detail modal
//  Uses glassmorphism styling with wedding-themed colors
//

import SwiftUI

struct GuestDetailContactSection: View {
    let guest: Guest

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Email
            if let email = guest.email {
                GuestDetailContactRow(
                    icon: "envelope.fill",
                    iconColor: AppGradients.weddingPink,
                    label: "Email",
                    value: email
                )
            }

            // Phone
            if let phone = guest.phone {
                GuestDetailContactRow(
                    icon: "phone.fill",
                    iconColor: AppGradients.sageGreen,
                    label: "Phone",
                    value: phone
                )
            }

            // Plus One
            if guest.plusOneAllowed {
                GuestDetailContactRow(
                    icon: "person.2.fill",
                    iconColor: SoftLavender.shade300,
                    label: "Plus One",
                    value: guest.plusOneName ?? "Not specified"
                )
            }
        }
    }
}

// MARK: - Contact Row Component

struct GuestDetailContactRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon with NativeIconBadge style
            NativeIconBadge(
                systemName: icon,
                color: iconColor,
                size: 36
            )

            // Label and Value
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Text(value)
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            Spacer()
        }
    }
}
