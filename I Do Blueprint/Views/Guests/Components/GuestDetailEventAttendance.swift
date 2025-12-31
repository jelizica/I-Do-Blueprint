//
//  GuestDetailEventAttendance.swift
//  I Do Blueprint
//
//  Event attendance section for guest detail modal
//  Shows Welcome Dinner, Ceremony, and Reception attendance
//  Grayed out/disabled when guest is not attending (RSVP status != attending/confirmed)
//

import SwiftUI

struct GuestDetailEventAttendance: View {
    let guest: Guest
    
    /// Whether the guest is attending (RSVP status is attending or confirmed)
    private var isGuestAttending: Bool {
        guest.isAttending
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Event Attendance")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isGuestAttending ? AppColors.textPrimary : AppColors.textTertiary)
            
            if isGuestAttending {
                // Show attendance details when guest is attending
                HStack(spacing: Spacing.xl) {
                    AttendanceItem(
                        label: "Welcome Dinner",
                        isAttending: guest.attendingRehearsal
                    )
                    
                    AttendanceItem(
                        label: "Ceremony",
                        isAttending: guest.attendingCeremony
                    )
                    
                    AttendanceItem(
                        label: "Reception",
                        isAttending: guest.attendingReception
                    )
                }
            } else {
                // Show disabled state when guest is not attending
                HStack(spacing: Spacing.xl) {
                    DisabledAttendanceItem(label: "Welcome Dinner")
                    DisabledAttendanceItem(label: "Ceremony")
                    DisabledAttendanceItem(label: "Reception")
                }
                
                Text("Event attendance will be available once RSVP is confirmed")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
                    .italic()
                    .padding(.top, Spacing.xs)
            }
        }
    }
}

// MARK: - Attendance Item Component

struct AttendanceItem: View {
    let label: String
    let isAttending: Bool
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: isAttending ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(isAttending ? AppColors.success : AppColors.textTertiary)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

// MARK: - Disabled Attendance Item Component

struct DisabledAttendanceItem: View {
    let label: String
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "circle.dashed")
                .foregroundColor(AppColors.textTertiary.opacity(0.5))
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textTertiary.opacity(0.5))
        }
    }
}

// MARK: - Preview

#Preview("Attending Guest") {
    GuestDetailEventAttendance(
        guest: Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "Sarah",
            lastName: "Johnson",
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
            isWeddingParty: false,
            weddingPartyRole: nil,
            preparationNotes: nil,
            coupleId: UUID(),
            mealOption: nil,
            giftReceived: false,
            notes: nil,
            hairDone: false,
            makeupDone: false
        )
    )
    .padding()
}

#Preview("Pending Guest") {
    GuestDetailEventAttendance(
        guest: Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "John",
            lastName: "Doe",
            email: nil,
            phone: nil,
            guestGroupId: nil,
            relationshipToCouple: nil,
            invitedBy: nil,
            rsvpStatus: .pending,
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
            isWeddingParty: false,
            weddingPartyRole: nil,
            preparationNotes: nil,
            coupleId: UUID(),
            mealOption: nil,
            giftReceived: false,
            notes: nil,
            hairDone: false,
            makeupDone: false
        )
    )
    .padding()
}
