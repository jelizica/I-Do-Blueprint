//
//  EditGuestSheetV2.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/8/25.
//  Modal for editing guest details from guest list
//

import SwiftUI
import PhoneNumberKit

struct EditGuestSheetV2: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var guestStore: GuestStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2

    let guest: Guest
    let onSave: (Guest) -> Void

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

    init(guest: Guest, guestStore: GuestStoreV2, onSave: @escaping (Guest) -> Void) {
        self.guest = guest
        self.guestStore = guestStore
        self.onSave = onSave
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
            VStack(spacing: 0) {
                // Header
                HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Guest")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(guest.firstName) \(guest.lastName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Form Content - Two Column Layout
            ScrollView {
                HStack(alignment: .top, spacing: 20) {
                    // Left Column
                    VStack(spacing: 20) {
                        // Basic Information
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Basic Information", icon: "person.circle.fill")

                            VStack(spacing: 12) {
                                FormField(label: "First Name", required: true) {
                                    TextField("First name", text: $firstName)
                                        .textFieldStyle(.roundedBorder)
                                }

                                FormField(label: "Last Name", required: true) {
                                    TextField("Last name", text: $lastName)
                                        .textFieldStyle(.roundedBorder)
                                }

                                FormField(label: "Relationship") {
                                    TextField("e.g., Friend, Family", text: $relationshipToCouple)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }

                        Divider()

                        // Contact Information
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Contact Information", icon: "envelope.circle.fill")

                            VStack(spacing: 12) {
                                FormField(label: "Email") {
                                    TextField("email@example.com", text: $email)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.emailAddress)
                                }

                                FormField(label: "Phone") {
                                    PhoneNumberTextFieldWrapper(
                                        phoneNumber: $phone,
                                        defaultRegion: "US",
                                        placeholder: "(555) 123-4567"
                                    )
                                    .frame(height: 40)
                                }
                            }
                        }

                        Divider()

                        // Meal Preferences
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Meal & Dietary", icon: "fork.knife.circle.fill")

                            VStack(spacing: 12) {
                                FormField(label: "Meal Option") {
                                    Picker("Meal Option", selection: $mealOption) {
                                        Text("Not Selected").tag("")
                                        ForEach(settingsStore.settings.guests.customMealOptions, id: \.self) { option in
                                            Text(option).tag(option)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }

                                FormField(label: "Dietary Restrictions") {
                                    TextField("e.g., Gluten-free, Vegan", text: $dietaryRestrictions)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Right Column
                    VStack(spacing: 20) {
                        // RSVP Status
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "RSVP Status", icon: "checkmark.circle.fill")

                            VStack(spacing: 12) {
                                FormField(label: "Status") {
                                    Picker("RSVP Status", selection: $rsvpStatus) {
                                        ForEach(RSVPStatus.allCases, id: \.self) { status in
                                            Text(status.displayName).tag(status)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }

                                FormField(label: "Invited By") {
                                    Picker("Invited By", selection: $invitedBy) {
                                        Text("Not Selected").tag(nil as InvitedBy?)
                                        ForEach(InvitedBy.allCases, id: \.self) { inviter in
                                            Text(inviter.displayName(with: settingsStore.settings)).tag(inviter as InvitedBy?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                        }

                        Divider()

                        // Plus One
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Plus One", icon: "person.2.fill")

                            VStack(spacing: 12) {
                                FormField(label: "Allow Plus One") {
                                    Toggle("Plus one allowed", isOn: $plusOneAllowed)
                                        .toggleStyle(.switch)
                                }

                                if plusOneAllowed {
                                    FormField(label: "Plus One Name") {
                                        TextField("Guest name", text: $plusOneName)
                                            .textFieldStyle(.roundedBorder)
                                    }

                                    FormField(label: "Plus One Attending") {
                                        Toggle("Attending", isOn: $plusOneAttending)
                                            .toggleStyle(.switch)
                                    }
                                }
                            }
                        }

                        Divider()

                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Notes", icon: "note.text")

                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(Spacing.xl)
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    Task {
                        await saveGuest()
                    }
                } label: {
                    if isSaving {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Saving...")
                        }
                    } else {
                        Text("Save Changes")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || firstName.isEmpty || lastName.isEmpty)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            }
        }
        .frame(width: 850, height: 650)
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
        onSave(updatedGuest)
        dismiss()
    }
}

#Preview {
    EditGuestSheetV2(
        guest: Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            phone: "(555) 123-4567",
            guestGroupId: nil,
            relationshipToCouple: "Friend",
            invitedBy: .bride1,
            rsvpStatus: .pending,
            rsvpDate: nil,
            plusOneAllowed: true,
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
        ),
        guestStore: GuestStoreV2(),
        onSave: { _ in }
    )
    .environmentObject(SettingsStoreV2())
}
