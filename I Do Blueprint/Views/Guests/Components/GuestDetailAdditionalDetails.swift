//
//  GuestDetailAdditionalDetails.swift
//  I Do Blueprint
//
//  Additional details section for guest detail modal
//  Shows preferred contact method, invitation number, gift status,
//  table/seat assignment, RSVP date, and plus one attending status
//

import SwiftUI

struct GuestDetailAdditionalDetails: View {
    let guest: Guest
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Additional Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg)
            ], alignment: .leading, spacing: Spacing.md) {
                // Preferred Contact Method
                if let contactMethod = guest.preferredContactMethod {
                    DetailItem(label: "Preferred Contact", value: contactMethod.displayName)
                }
                
                // Invitation Number
                if let invitationNum = guest.invitationNumber, !invitationNum.isEmpty {
                    DetailItem(label: "Invitation #", value: invitationNum)
                }
                
                // RSVP Date
                if let rsvpDate = guest.rsvpDate {
                    DetailItem(
                        label: "RSVP Date",
                        value: DateFormatting.formatDateMedium(rsvpDate, timezone: .current)
                    )
                }
                
                // Table Assignment
                if let table = guest.tableAssignment {
                    DetailItem(label: "Table", value: "Table \(table)")
                }
                
                // Seat Number
                if let seat = guest.seatNumber {
                    DetailItem(label: "Seat", value: "Seat \(seat)")
                }
                
                // Plus One Attending (only show if plus one is allowed)
                if guest.plusOneAllowed {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: guest.plusOneAttending ? "person.2.fill" : "person.2")
                            .foregroundColor(guest.plusOneAttending ? AppColors.success : AppColors.textTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Plus One")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                            Text(guest.plusOneAttending ? "Attending" : "Not Attending")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
            }
            
            // Gift Received Status
            if guest.giftReceived {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "gift.fill")
                        .foregroundColor(AppColors.success)
                    Text("Gift Received")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(.top, Spacing.xs)
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

// MARK: - Preview

#Preview {
    GuestDetailAdditionalDetails(
        guest: Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah@example.com",
            phone: nil,
            guestGroupId: nil,
            relationshipToCouple: nil,
            invitedBy: nil,
            rsvpStatus: .attending,
            rsvpDate: Date(),
            plusOneAllowed: true,
            plusOneName: "Michael",
            plusOneAttending: true,
            attendingCeremony: true,
            attendingReception: true,
            attendingRehearsal: true,
            attendingOtherEvents: nil,
            dietaryRestrictions: nil,
            accessibilityNeeds: nil,
            tableAssignment: 5,
            seatNumber: 3,
            preferredContactMethod: .email,
            addressLine1: nil,
            addressLine2: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            country: nil,
            invitationNumber: "INV-2026-042",
            isWeddingParty: false,
            weddingPartyRole: nil,
            preparationNotes: nil,
            coupleId: UUID(),
            mealOption: nil,
            giftReceived: true,
            notes: nil,
            hairDone: false,
            makeupDone: false
        )
    )
    .padding()
    .frame(width: 500)
}
