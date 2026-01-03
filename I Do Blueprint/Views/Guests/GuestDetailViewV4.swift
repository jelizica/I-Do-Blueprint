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
    @EnvironmentObject private var budgetStore: BudgetStoreV2
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
    
    // MARK: - Size Constants
    
    /// Preferred modal width (clamped between min and max)
    private let minWidth: CGFloat = 400
    private let maxWidth: CGFloat = 700
    
    /// Preferred modal height (clamped between min and max)
    private let minHeight: CGFloat = 350
    private let maxHeight: CGFloat = 850
    
    /// Threshold below which we use compact layout
    private let compactHeightThreshold: CGFloat = 550
    
    /// Buffer for window chrome (title bar, toolbar) that isn't available for content
    private let windowChromeBuffer: CGFloat = 40
    
    /// Calculate dynamic size based on parent window size from coordinator
    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        // Use 60% of parent width and 75% of parent height (minus chrome buffer), clamped to min/max bounds
        // The chrome buffer accounts for title bar (~28pt) + safety margin
        let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
        let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
        
        return CGSize(width: targetWidth, height: targetHeight)
    }
    
    /// Whether to use compact layout (smaller header, everything scrolls)
    private var isCompactMode: Bool {
        dynamicSize.height < compactHeightThreshold
    }
    
    var body: some View {
        Group {
            if let guest = guest {
                // Adaptive layout based on available height
                // Compact mode: header scrolls with content
                // Normal mode: fixed header, scrollable content
                VStack(spacing: 0) {
                    if isCompactMode {
                        // COMPACT MODE: Everything scrolls, smaller header
                        ScrollView {
                            VStack(spacing: 0) {
                                // Compact Header (horizontal, smaller)
                                GuestDetailCompactHeader(
                                    guest: guest,
                                    settings: settings,
                                    onDismiss: { dismiss() }
                                )
                                
                                // Content sections
                                VStack(alignment: .leading, spacing: Spacing.lg) {
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
                                    
                                    // Event Attendance (dynamically based on created events)
                                    GuestDetailEventAttendance(
                                        guest: guest,
                                        weddingEvents: budgetStore.weddingEvents
                                    )
                                    
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
                                .padding(Spacing.lg)
                            }
                        }
                    } else {
                        // NORMAL MODE: Fixed header, scrollable content
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
                                
                                // Event Attendance (dynamically based on created events)
                                GuestDetailEventAttendance(
                                    guest: guest,
                                    weddingEvents: budgetStore.weddingEvents
                                )
                                
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
                    }
                    
                    // Action Buttons - ALWAYS fixed at bottom
                    GuestDetailActionButtons(
                        onEdit: { showingEditSheet = true },
                        onDelete: { showingDeleteAlert = true }
                    )
                }
                // Dynamic frame size based on parent window size
                // This explicit frame tells the sheet how big to be
                .frame(width: dynamicSize.width, height: dynamicSize.height)
                .background(SemanticColors.backgroundSecondary)
                .cornerRadius(CornerRadius.lg)
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
    .environmentObject(BudgetStoreV2())
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
    .environmentObject(BudgetStoreV2())
    .environmentObject(AppCoordinator.shared)
}
