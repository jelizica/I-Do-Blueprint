//
//  GuestDetailViewV2.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/1/25.
//  Visual profile-style guest detail view inspired by modern resume layouts
//

import SwiftUI

struct GuestDetailViewV2: View {
    let guest: Guest
    var guestStore: GuestStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var showingEditSheet = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Hero Header Section with Edit Button
            HeroHeaderView(guest: guest, onEdit: {
                showingEditSheet = true
            })

            // Tabbed Content
            TabbedDetailView(
                tabs: [
                    DetailTab(title: "Overview", icon: "info.circle"),
                    DetailTab(title: "Contact", icon: "envelope.circle"),
                    DetailTab(title: "Event Details", icon: "calendar.circle"),
                    DetailTab(title: "Preferences", icon: "heart.circle"),
                    DetailTab(title: "Notes", icon: "note.text")
                ],
                selectedTab: $selectedTab
            ) { index in
                ScrollView {
                    VStack(spacing: Spacing.xxxl) {
                        switch index {
                        case 0: GuestOverviewTab(guest: guest, onEdit: { showingEditSheet = true })
                        case 1: GuestContactTab(guest: guest)
                        case 2: GuestEventDetailsTab(guest: guest)
                        case 3: GuestPreferencesTab(guest: guest)
                        case 4: GuestNotesTab(guest: guest)
                        default: EmptyView()
                        }
                    }
                    .padding(Spacing.xxl)
                }
                .background(AppColors.background)
            }
        }
        .background(AppColors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingEditSheet) {
            EditGuestSheetV2(guest: guest, guestStore: guestStore) { _ in
                // Reload will happen automatically through the store
            }
        }
    }
}

#Preview {
    GuestDetailViewV2(
        guest: Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "Emily",
            lastName: "Turner",
            email: "emily.turner@example.com",
            phone: "+1 (555) 123-4567",
            guestGroupId: nil,
            relationshipToCouple: "Friend",
            invitedBy: .bride1,
            rsvpStatus: .attending,
            rsvpDate: Date(),
            plusOneAllowed: true,
            plusOneName: nil,
            plusOneAttending: false,
            attendingCeremony: true,
            attendingReception: true,
            attendingOtherEvents: nil,
            dietaryRestrictions: "Vegetarian, No nuts",
            accessibilityNeeds: nil,
            tableAssignment: 5,
            seatNumber: nil,
            preferredContactMethod: .email,
            addressLine1: "123 Main St",
            addressLine2: "Apt 4B",
            city: "Dubai",
            state: "Dubai",
            zipCode: "00000",
            country: "United Arab Emirates",
            invitationNumber: "001",
            isWeddingParty: true,
            weddingPartyRole: "Bridesmaid",
            preparationNotes: nil,
            coupleId: UUID(),
            mealOption: "Chicken",
            giftReceived: false,
            notes: "Close friend from college. Loves photography and might take some candid shots.",
            hairDone: false,
            makeupDone: false
        ),
        guestStore: GuestStoreV2()
    )
    .environmentObject(SettingsStoreV2())
}

// MARK: - Edit Guest Sheet

struct EditGuestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var guestStore: GuestStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2

    let guest: Guest

    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var rsvpStatus: RSVPStatus
    @State private var invitedBy: InvitedBy?
    @State private var plusOneAllowed: Bool
    @State private var plusOneName: String
    @State private var plusOneAttending: Bool
    @State private var relationshipToCouple: String
    @State private var mealOption: String
    @State private var dietaryRestrictions: String
    @State private var notes: String
    @State private var isSaving = false

    init(guest: Guest) {
        self.guest = guest
        _firstName = State(initialValue: guest.firstName)
        _lastName = State(initialValue: guest.lastName)
        _email = State(initialValue: guest.email ?? "")
        _phone = State(initialValue: guest.phone ?? "")
        _rsvpStatus = State(initialValue: guest.rsvpStatus)
        _invitedBy = State(initialValue: guest.invitedBy)
        _plusOneAllowed = State(initialValue: guest.plusOneAllowed)
        _plusOneName = State(initialValue: guest.plusOneName ?? "")
        _plusOneAttending = State(initialValue: guest.plusOneAttending)
        _relationshipToCouple = State(initialValue: guest.relationshipToCouple ?? "")
        _mealOption = State(initialValue: guest.mealOption ?? "")
        _dietaryRestrictions = State(initialValue: guest.dietaryRestrictions ?? "")
        _notes = State(initialValue: guest.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }

                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                }

                Section("RSVP Status") {
                    Picker("Status", selection: $rsvpStatus) {
                        ForEach(RSVPStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }

                    Picker("Invited By", selection: $invitedBy) {
                        Text("Not Selected").tag(nil as InvitedBy?)
                        ForEach(InvitedBy.allCases, id: \.self) { inviter in
                            Text(inviter.displayName(with: settingsStore.settings)).tag(inviter as InvitedBy?)
                        }
                    }
                }

                Section("Plus One") {
                    Toggle("Plus One Allowed", isOn: $plusOneAllowed)

                    if plusOneAllowed {
                        TextField("Plus One Name", text: $plusOneName)
                        Toggle("Plus One Attending", isOn: $plusOneAttending)
                    }
                }

                Section("Additional Details") {
                    TextField("Relationship to Couple", text: $relationshipToCouple)
                    TextField("Meal Option", text: $mealOption)
                    TextField("Dietary Restrictions", text: $dietaryRestrictions)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.visible)
            .navigationTitle("Edit Guest")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveGuest()
                        }
                    }
                    .disabled(isSaving || firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func saveGuest() async {
        isSaving = true
        defer { isSaving = false }

        var updatedGuest = guest
        updatedGuest.firstName = firstName
        updatedGuest.lastName = lastName
        updatedGuest.email = email.isEmpty ? nil : email
        updatedGuest.phone = phone.isEmpty ? nil : phone
        updatedGuest.rsvpStatus = rsvpStatus
        updatedGuest.invitedBy = invitedBy
        updatedGuest.plusOneAllowed = plusOneAllowed
        updatedGuest.plusOneName = plusOneName.isEmpty ? nil : plusOneName
        updatedGuest.plusOneAttending = plusOneAttending
        updatedGuest.relationshipToCouple = relationshipToCouple.isEmpty ? nil : relationshipToCouple
        updatedGuest.mealOption = mealOption.isEmpty ? nil : mealOption
        updatedGuest.dietaryRestrictions = dietaryRestrictions.isEmpty ? nil : dietaryRestrictions
        updatedGuest.notes = notes.isEmpty ? nil : notes
        updatedGuest.updatedAt = Date()

        await guestStore.updateGuest(updatedGuest)
        dismiss()
    }
}
