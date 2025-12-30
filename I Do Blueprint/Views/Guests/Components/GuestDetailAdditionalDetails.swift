//
//  GuestDetailAdditionalDetails.swift
//  I Do Blueprint
//
//  Additional details section for guest detail modal
//

import SwiftUI

struct GuestDetailAdditionalDetails: View {
    let guest: Guest
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Additional Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: Spacing.sm) {
                if let contactMethod = guest.preferredContactMethod {
                    DetailItem(label: "Preferred Contact", value: contactMethod.rawValue.capitalized)
                }
                
                if let invitationNum = guest.invitationNumber {
                    DetailItem(label: "Invitation #", value: invitationNum)
                }
                
                if guest.giftReceived {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "gift.fill")
                            .foregroundColor(AppColors.success)
                        Text("Gift Received")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Detail Item Component

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}
