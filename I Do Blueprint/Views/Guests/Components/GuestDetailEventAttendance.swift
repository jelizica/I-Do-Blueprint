//
//  GuestDetailEventAttendance.swift
//  I Do Blueprint
//
//  Event attendance section for guest detail modal
//  Dynamically shows events based on what events exist in the database
//  Grayed out/disabled when guest is not attending (RSVP status != attending/confirmed)
//

import SwiftUI

struct GuestDetailEventAttendance: View {
    let guest: Guest
    let weddingEvents: [WeddingEvent]
    
    /// Whether the guest is attending (RSVP status is attending or confirmed)
    private var isGuestAttending: Bool {
        guest.isAttending
    }
    
    /// Filter events to only show attendable events (rehearsal, ceremony, reception)
    /// Excludes "other" type events like "Pre-Wedding Expenses"
    private var attendableEvents: [WeddingEvent] {
        weddingEvents.filter { event in
            let eventType = event.eventType.lowercased()
            return eventType == "rehearsal" || eventType == "ceremony" || eventType == "reception"
        }.sorted { event1, event2 in
            // Sort by event date, then by event order
            if event1.eventDate != event2.eventDate {
                return event1.eventDate < event2.eventDate
            }
            return (event1.eventOrder ?? 0) < (event2.eventOrder ?? 0)
        }
    }
    
    /// Check if a specific event type exists
    private var hasRehearsalEvent: Bool {
        attendableEvents.contains { $0.eventType.lowercased() == "rehearsal" }
    }
    
    private var hasCeremonyEvent: Bool {
        attendableEvents.contains { $0.eventType.lowercased() == "ceremony" }
    }
    
    private var hasReceptionEvent: Bool {
        attendableEvents.contains { $0.eventType.lowercased() == "reception" }
    }
    
    /// Get the display name for an event type
    private func displayName(for event: WeddingEvent) -> String {
        // Use the event name from the database, or fall back to a formatted type
        if !event.eventName.isEmpty {
            return event.eventName
        }
        
        switch event.eventType.lowercased() {
        case "rehearsal":
            return "Welcome Dinner"
        case "ceremony":
            return "Ceremony"
        case "reception":
            return "Reception"
        default:
            return event.eventType.capitalized
        }
    }
    
    /// Get the guest's attendance status for a specific event type
    private func isAttendingEvent(_ event: WeddingEvent) -> Bool {
        switch event.eventType.lowercased() {
        case "rehearsal":
            return guest.attendingRehearsal
        case "ceremony":
            return guest.attendingCeremony
        case "reception":
            return guest.attendingReception
        default:
            // Check attending_other_events array for custom events
            return guest.attendingOtherEvents?.contains(event.id) ?? false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Event Attendance")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isGuestAttending ? AppColors.textPrimary : AppColors.textTertiary)
            
            if attendableEvents.isEmpty {
                // No events configured
                Text("No events have been set up yet")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
                    .italic()
            } else if isGuestAttending {
                // Show attendance details when guest is attending
                HStack(spacing: Spacing.xl) {
                    ForEach(attendableEvents) { event in
                        AttendanceItem(
                            label: displayName(for: event),
                            isAttending: isAttendingEvent(event)
                        )
                    }
                }
            } else {
                // Show disabled state when guest is not attending
                HStack(spacing: Spacing.xl) {
                    ForEach(attendableEvents) { event in
                        DisabledAttendanceItem(label: displayName(for: event))
                    }
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

#Preview("Attending Guest - All Events") {
    let events = [
        WeddingEvent(
            id: "1",
            eventName: "Welcome Dinner",
            eventType: "rehearsal",
            eventDate: Date(),
            coupleId: "test"
        ),
        WeddingEvent(
            id: "2",
            eventName: "Wedding Ceremony",
            eventType: "ceremony",
            eventDate: Date(),
            coupleId: "test"
        ),
        WeddingEvent(
            id: "3",
            eventName: "Wedding Reception",
            eventType: "reception",
            eventDate: Date(),
            coupleId: "test"
        )
    ]
    
    return GuestDetailEventAttendance(
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
        ),
        weddingEvents: events
    )
    .padding()
}

#Preview("Attending Guest - Ceremony Only") {
    let events = [
        WeddingEvent(
            id: "1",
            eventName: "Wedding Ceremony",
            eventType: "ceremony",
            eventDate: Date(),
            coupleId: "test"
        )
    ]
    
    return GuestDetailEventAttendance(
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
            attendingReception: false,
            attendingRehearsal: false,
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
        ),
        weddingEvents: events
    )
    .padding()
}

#Preview("Pending Guest") {
    let events = [
        WeddingEvent(
            id: "1",
            eventName: "Welcome Dinner",
            eventType: "rehearsal",
            eventDate: Date(),
            coupleId: "test"
        ),
        WeddingEvent(
            id: "2",
            eventName: "Wedding Ceremony",
            eventType: "ceremony",
            eventDate: Date(),
            coupleId: "test"
        )
    ]
    
    return GuestDetailEventAttendance(
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
        ),
        weddingEvents: events
    )
    .padding()
}

#Preview("No Events Configured") {
    GuestDetailEventAttendance(
        guest: Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "Test",
            lastName: "User",
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
        ),
        weddingEvents: []
    )
    .padding()
}
