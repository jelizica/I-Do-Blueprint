//
//  GuestDetailViewV4.swift
//  I Do Blueprint
//
//  Modern modal guest detail view with gradient header
//  Displays all guest fields from the database in organized sections
//

import SwiftUI

struct GuestDetailViewV4: View {
    let guestId: UUID
    @ObservedObject var guestStore: GuestStoreV2
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    // Computed property to get the latest guest data from the store
    private var guest: Guest? {
        guestStore.guests.first(where: { $0.id == guestId })
    }
    
    private var settings: CoupleSettings {
        settingsStore.settings
    }
    
    // MARK: - Computed Properties for Section Visibility
    
    private var hasAddress: Bool {
        guard let guest = guest else { return false }
        return guest.addressLine1 != nil || guest.city != nil || guest.state != nil
    }
    
    private var hasAccessibilityNeeds: Bool {
        guard let guest = guest else { return false }
        return guest.accessibilityNeeds != nil && !guest.accessibilityNeeds!.isEmpty
    }
    
    private var isWeddingPartyMember: Bool {
        guard let guest = guest else { return false }
        return guest.isWeddingParty
    }
    
    private var shouldShowAdditionalDetails: Bool {
        guard let guest = guest else { return false }
        return guest.preferredContactMethod != nil ||
               guest.invitationNumber != nil ||
               guest.giftReceived ||
               guest.tableAssignment != nil ||
               guest.seatNumber != nil ||
               guest.rsvpDate != nil ||
               guest.plusOneAllowed
    }
    
    var body: some View {
        Group {
            if let guest = guest {
                ZStack {
                    // Semi-transparent background overlay
                    AppColors.textPrimary.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismiss()
                        }
                    
                    // Main modal content
                    VStack(spacing: 0) {
                        // Gradient Header with Avatar
                        GuestDetailHeader(
                            guest: guest,
                            settings: settings,
                            onDismiss: { dismiss() }
                        )
                        
                        // Content Section
                        ScrollView {
                            VStack(alignment: .leading, spacing: Spacing.xl) {
                                // Contact Information
                                GuestDetailContactSection(guest: guest)
                                
                                // RSVP Status and Meal Choice Row
                                GuestDetailStatusRow(guest: guest)
                                
                                // Dietary Restrictions
                                if let restrictions = guest.dietaryRestrictions, !restrictions.isEmpty {
                                    GuestDetailDietarySection(restrictions: restrictions)
                                }
                                
                                // Accessibility Needs
                                if hasAccessibilityNeeds {
                                    GuestDetailAccessibilitySection(
                                        accessibilityNeeds: guest.accessibilityNeeds!
                                    )
                                }
                                
                                // Event Attendance (grayed out if not attending)
                                GuestDetailEventAttendance(guest: guest)
                                
                                // Wedding Party Section (only for wedding party members)
                                if isWeddingPartyMember {
                                    GuestDetailWeddingPartySection(guest: guest)
                                }
                                
                                // Address Information
                                if hasAddress {
                                    GuestDetailAddressSection(guest: guest)
                                }
                                
                                // Notes
                                if let notes = guest.notes, !notes.isEmpty {
                                    GuestDetailNotesSection(notes: notes)
                                }
                                
                                // Additional Details
                                if shouldShowAdditionalDetails {
                                    Divider()
                                    GuestDetailAdditionalDetails(guest: guest)
                                }
                            }
                            .padding(Spacing.xl)
                        }
                        
                        // Action Buttons
                        GuestDetailActionButtons(
                            onEdit: { showingEditSheet = true },
                            onDelete: { showingDeleteAlert = true }
                        )
                    }
                    .frame(width: 600, height: 750)
                    .background(AppColors.cardBackground)
                    .cornerRadius(CornerRadius.lg)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditGuestSheetV2(guest: guest, guestStore: guestStore) { _ in
                        // Reload will happen automatically through the store
                    }
                }
                .alert("Delete Guest", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        Task {
                            await guestStore.deleteGuest(id: guestId)
                            dismiss()
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete \(guest.fullName)? This action cannot be undone.")
                }
            } else {
                // Guest not found - dismiss modal
                Color.clear
                    .onAppear {
                        dismiss()
                    }
            }
        }
    }
}

// MARK: - Preview

#Preview("Attending Guest with All Details") {
    let testGuest = Guest(
        id: UUID(),
        createdAt: Date(),
        updatedAt: Date(),
        firstName: "Sarah",
        lastName: "Johnson",
        email: "sarah.johnson@email.com",
        phone: "+1 (555) 123-4567",
        guestGroupId: nil,
        relationshipToCouple: "Friend",
        invitedBy: .bride1,
        rsvpStatus: .confirmed,
        rsvpDate: Date(),
        plusOneAllowed: true,
        plusOneName: "Michael Thompson",
        plusOneAttending: true,
        attendingCeremony: true,
        attendingReception: true,
        attendingRehearsal: true,
        attendingOtherEvents: nil,
        dietaryRestrictions: "Vegetarian, Gluten-Free",
        accessibilityNeeds: "Wheelchair accessible seating required",
        tableAssignment: 5,
        seatNumber: 3,
        preferredContactMethod: .email,
        addressLine1: "123 Main Street",
        addressLine2: "Apt 4B",
        city: "Boston",
        state: "MA",
        zipCode: "02101",
        country: "USA",
        invitationNumber: "INV-2026-042",
        isWeddingParty: true,
        weddingPartyRole: "Bridesmaid",
        preparationNotes: "Arriving at 8am for photos",
        coupleId: UUID(),
        mealOption: "Vegetarian",
        giftReceived: true,
        notes: "Sarah requested a seat near the bridal party table.",
        hairDone: true,
        makeupDone: false
    )
    
    let store = GuestStoreV2()
    
    return GuestDetailViewV4(
        guestId: testGuest.id,
        guestStore: store
    )
    .environmentObject(SettingsStoreV2())
    .environmentObject(AppCoordinator.shared)
}

#Preview("Pending Guest") {
    let testGuest = Guest(
        id: UUID(),
        createdAt: Date(),
        updatedAt: Date(),
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@email.com",
        phone: nil,
        guestGroupId: nil,
        relationshipToCouple: "Colleague",
        invitedBy: .bride2,
        rsvpStatus: .pending,
        rsvpDate: nil,
        plusOneAllowed: false,
        plusOneName: nil,
        plusOneAttending: false,
        attendingCeremony: true,
        attendingReception: true,
        attendingRehearsal: false,
        attendingOtherEvents: nil,
        dietaryRestrictions: nil,
        accessibilityNeeds: nil,
        tableAssignment: nil,
        seatNumber: nil,
        preferredContactMethod: .email,
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
    
    let store = GuestStoreV2()
    
    return GuestDetailViewV4(
        guestId: testGuest.id,
        guestStore: store
    )
    .environmentObject(SettingsStoreV2())
    .environmentObject(AppCoordinator.shared)
}
