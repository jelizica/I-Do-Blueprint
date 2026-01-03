//
//  GuestDetailContactSection.swift
//  I Do Blueprint
//
//  Contact information section for guest detail modal
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
                    iconColor: SemanticColors.errorLight,
                    label: "Email",
                    value: email
                )
            }
            
            // Phone
            if let phone = guest.phone {
                GuestDetailContactRow(
                    icon: "phone.fill",
                    iconColor: SemanticColors.errorLight,
                    label: "Phone",
                    value: phone
                )
            }
            
            // Plus One
            if guest.plusOneAllowed {
                GuestDetailContactRow(
                    icon: "person.2.fill",
                    iconColor: SemanticColors.errorLight,
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
            // Icon
            Circle()
                .fill(iconColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColors.error)
                )
            
            // Label and Value
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SemanticColors.textPrimary)
            }
            
            Spacer()
        }
    }
}
