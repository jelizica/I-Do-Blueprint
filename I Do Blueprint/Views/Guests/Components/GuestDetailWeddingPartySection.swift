//
//  GuestDetailWeddingPartySection.swift
//  I Do Blueprint
//
//  Wedding party section for guest detail modal
//  Shows wedding party role, hair/makeup status, and preparation notes
//  Only displayed for wedding party members
//

import SwiftUI

struct GuestDetailWeddingPartySection: View {
    let guest: Guest
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: "crown.fill")
                    .foregroundColor(AppColors.primary)
                Text("Wedding Party")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Wedding Party Role
                if let role = guest.weddingPartyRole, !role.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Role")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        Text(role)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                
                // Hair & Makeup Status
                HStack(spacing: Spacing.xl) {
                    PreparationStatusItem(
                        label: "Hair",
                        icon: "scissors",
                        isDone: guest.hairDone
                    )
                    
                    PreparationStatusItem(
                        label: "Makeup",
                        icon: "paintbrush.fill",
                        isDone: guest.makeupDone
                    )
                }
                
                // Preparation Notes
                if let notes = guest.preparationNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Preparation Notes")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(AppColors.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preparation Status Item

struct PreparationStatusItem: View {
    let label: String
    let icon: String
    let isDone: Bool
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isDone ? AppColors.success : AppColors.textTertiary)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
            
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(isDone ? AppColors.success : AppColors.textTertiary)
        }
    }
}

// MARK: - Preview

#Preview("Wedding Party Member") {
    GuestDetailWeddingPartySection(
        guest: Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "Emily",
            lastName: "Smith",
            email: nil,
            phone: nil,
            guestGroupId: nil,
            relationshipToCouple: nil,
            invitedBy: nil,
            rsvpStatus: .attending,
            rsvpDate: nil,
            plusOneAllowed: false,
            plusOneName: nil,
            plusOneAttending: false,
            attendingCeremony: true,
            attendingReception: true,
            attendingRehearsal: true,
            attendingOtherEvents: nil,
            dietaryRestrictions: nil,
            accessibilityNeeds: nil,
            tableAssignment: nil,
            seatNumber: nil,
            preferredContactMethod: nil,
            addressLine1: nil,
            addressLine2: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            country: nil,
            invitationNumber: nil,
            isWeddingParty: true,
            weddingPartyRole: "Maid of Honor",
            preparationNotes: "Arriving at 8am for photos. Needs help with dress buttons.",
            coupleId: UUID(),
            mealOption: nil,
            giftReceived: false,
            notes: nil,
            hairDone: true,
            makeupDone: false
        )
    )
    .padding()
    .frame(width: 400)
}
