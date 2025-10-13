//
//  AddGuestView.swift
//  My Wedding Planning App
//
//  Created by Jessica Clark on 9/26/25.
//

import SwiftUI

struct AddGuestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var relationshipToCouple = ""
    @State private var invitedBy: InvitedBy = .both
    @State private var rsvpStatus: RSVPStatus = .pending
    @State private var plusOneAllowed = false
    @State private var plusOneName = ""
    @State private var attendingCeremony = true
    @State private var attendingReception = true
    @State private var dietaryRestrictions = ""
    @State private var accessibilityNeeds = ""
    @State private var mealOption = ""
    @State private var notes = ""
    @State private var preferredContactMethod: PreferredContactMethod = .email
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = "USA"
    @State private var invitationNumber: String?
    @State private var isWeddingParty = false
    @State private var weddingPartyRole = ""
    @State private var selectedTab = 0

    let onSave: (Guest) async -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Tab 1: Basic Info
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Personal Information
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("First Name *", text: $firstName)
                                        .textFieldStyle(.roundedBorder)
                                    TextField("Last Name *", text: $lastName)
                                        .textFieldStyle(.roundedBorder)
                                    TextField("Relationship to Couple", text: $relationshipToCouple)
                                        .textFieldStyle(.roundedBorder)
                                    #if !os(macOS)
                                        .textInputAutocapitalization(.words)
                                    #endif
                                }
                                .padding()
                            } label: {
                                Label("Personal Information", systemImage: "person")
                                    .font(.headline)
                            }

                            // Wedding Details
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    Picker("Invited By", selection: $invitedBy) {
                                        ForEach(InvitedBy.allCases, id: \.self) { invitedBy in
                                            Text(invitedBy.displayName(with: settingsStore.settings)).tag(invitedBy)
                                        }
                                    }
                                    .pickerStyle(.menu)

                                    Picker("RSVP Status", selection: $rsvpStatus) {
                                        ForEach(RSVPStatus.allCases, id: \.self) { status in
                                            Text(status.displayName).tag(status)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                .padding()
                            } label: {
                                Label("Wedding Details", systemImage: "heart")
                                    .font(.headline)
                            }

                            // Attendance
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    Toggle("Attending Ceremony", isOn: $attendingCeremony)
                                    Toggle("Attending Reception", isOn: $attendingReception)
                                    Toggle("Plus One Allowed", isOn: $plusOneAllowed)

                                    if plusOneAllowed {
                                        TextField("Plus One Name", text: $plusOneName)
                                            .textFieldStyle(.roundedBorder)
                                        #if !os(macOS)
                                            .textInputAutocapitalization(.words)
                                        #endif
                                    }
                                }
                                .padding()
                            } label: {
                                Label("Attendance", systemImage: "calendar")
                                    .font(.headline)
                            }
                        }
                        .padding()
                    }
                    .tag(0)

                    // Tab 2: Contact & Address
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Contact Information
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Email Address", text: $email)
                                        .textFieldStyle(.roundedBorder)
                                    #if os(macOS)
                                        .textContentType(.emailAddress)
                                    #else
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                    #endif

                                    TextField("Phone Number", text: $phone)
                                        .textFieldStyle(.roundedBorder)
                                    #if os(macOS)
                                        .textContentType(.telephoneNumber)
                                    #else
                                        .textContentType(.telephoneNumber)
                                        .keyboardType(.phonePad)
                                    #endif

                                    Picker("Preferred Contact Method", selection: $preferredContactMethod) {
                                        ForEach(PreferredContactMethod.allCases, id: \.self) { method in
                                            Text(method.displayName).tag(method)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                .padding()
                            } label: {
                                Label("Contact Information", systemImage: "envelope")
                                    .font(.headline)
                            }

                            // Address
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Address Line 1", text: $addressLine1)
                                        .textFieldStyle(.roundedBorder)
                                    #if !os(macOS)
                                        .textInputAutocapitalization(.words)
                                    #endif
                                    TextField("Address Line 2", text: $addressLine2)
                                        .textFieldStyle(.roundedBorder)
                                    #if !os(macOS)
                                        .textInputAutocapitalization(.words)
                                    #endif

                                    HStack {
                                        TextField("City", text: $city)
                                            .textFieldStyle(.roundedBorder)
                                        #if !os(macOS)
                                            .textInputAutocapitalization(.words)
                                        #endif
                                        TextField("State", text: $state)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(maxWidth: 80)
                                        #if !os(macOS)
                                            .textInputAutocapitalization(.characters)
                                        #endif
                                        TextField("ZIP", text: $zipCode)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(maxWidth: 100)
                                        #if !os(macOS)
                                            .keyboardType(.numberPad)
                                        #endif
                                    }

                                    TextField("Country", text: $country)
                                        .textFieldStyle(.roundedBorder)
                                    #if !os(macOS)
                                        .textInputAutocapitalization(.words)
                                    #endif
                                }
                                .padding()
                            } label: {
                                Label("Address", systemImage: "location")
                                    .font(.headline)
                            }
                        }
                        .padding()
                    }
                    .tag(1)

                    // Tab 3: Preferences
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Dining Preferences
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Meal Option", text: $mealOption)
                                        .textFieldStyle(.roundedBorder)
                                    #if !os(macOS)
                                        .textInputAutocapitalization(.words)
                                    #endif

                                    TextField("Dietary Restrictions", text: $dietaryRestrictions, axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .lineLimit(2 ... 4)
                                    #if !os(macOS)
                                        .textInputAutocapitalization(.sentences)
                                    #endif
                                }
                                .padding()
                            } label: {
                                Label("Dining Preferences", systemImage: "fork.knife")
                                    .font(.headline)
                            }

                            // Accessibility
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Accessibility Needs", text: $accessibilityNeeds, axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .lineLimit(2 ... 4)
                                    #if !os(macOS)
                                        .textInputAutocapitalization(.sentences)
                                    #endif
                                }
                                .padding()
                            } label: {
                                Label("Accessibility", systemImage: "accessibility")
                                    .font(.headline)
                            }

                            // Wedding Party
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    Toggle("Wedding Party Member", isOn: $isWeddingParty)

                                    if isWeddingParty {
                                        TextField("Wedding Party Role", text: $weddingPartyRole)
                                            .textFieldStyle(.roundedBorder)
                                        #if !os(macOS)
                                            .textInputAutocapitalization(.words)
                                            .textContentType(.jobTitle)
                                        #endif
                                    }
                                }
                                .padding()
                            } label: {
                                Label("Wedding Party", systemImage: "crown")
                                    .font(.headline)
                            }
                        }
                        .padding()
                    }
                    .tag(2)

                    // Tab 4: Additional
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Additional Information
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Notes", text: $notes, axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .lineLimit(3 ... 6)
                                    #if !os(macOS)
                                        .textInputAutocapitalization(.sentences)
                                    #endif
                                }
                                .padding()
                            } label: {
                                Label("Additional Notes", systemImage: "note.text")
                                    .font(.headline)
                            }

                            // Future features placeholder
                            GroupBox {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Gift tracking and other features coming soon...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                            } label: {
                                Label("Future Features", systemImage: "gift")
                                    .font(.headline)
                            }
                        }
                        .padding()
                    }
                    .tag(3)
                }
                #if os(macOS)
                .tabViewStyle(.automatic)
                #else
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif

                // Segmented Control for Tab Navigation
                Picker("Sections", selection: $selectedTab) {
                    Text("Basic").tag(0)
                    Text("Contact").tag(1)
                    Text("Preferences").tag(2)
                    Text("Additional").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
            }
            .navigationTitle("Add Guest")
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    #if os(macOS)
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button("Save") {
                            Task {
                                await saveGuest()
                            }
                        }
                        .disabled(!isValidForm)
                    }
                    #else
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            Task {
                                await saveGuest()
                            }
                        }
                        .disabled(!isValidForm)
                    }
                    #endif
                }
        }
    }

    private var isValidForm: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func saveGuest() async {
        let newGuest = Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            guestGroupId: nil,
            relationshipToCouple: relationshipToCouple.isEmpty ? nil : relationshipToCouple
                .trimmingCharacters(in: .whitespacesAndNewlines),
            invitedBy: invitedBy,
            rsvpStatus: rsvpStatus,
            rsvpDate: nil,
            plusOneAllowed: plusOneAllowed,
            plusOneName: plusOneName.isEmpty ? nil : plusOneName.trimmingCharacters(in: .whitespacesAndNewlines),
            plusOneAttending: false,
            attendingCeremony: attendingCeremony,
            attendingReception: attendingReception,
            attendingOtherEvents: nil,
            dietaryRestrictions: dietaryRestrictions.isEmpty ? nil : dietaryRestrictions
                .trimmingCharacters(in: .whitespacesAndNewlines),
            accessibilityNeeds: accessibilityNeeds.isEmpty ? nil : accessibilityNeeds
                .trimmingCharacters(in: .whitespacesAndNewlines),
            tableAssignment: nil,
            seatNumber: nil,
            preferredContactMethod: preferredContactMethod,
            addressLine1: addressLine1.isEmpty ? nil : addressLine1.trimmingCharacters(in: .whitespacesAndNewlines),
            addressLine2: addressLine2.isEmpty ? nil : addressLine2.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.isEmpty ? nil : city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: state.isEmpty ? nil : state.trimmingCharacters(in: .whitespacesAndNewlines),
            zipCode: zipCode.isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.isEmpty ? "USA" : country.trimmingCharacters(in: .whitespacesAndNewlines),
            invitationNumber: invitationNumber,
            isWeddingParty: isWeddingParty,
            weddingPartyRole: weddingPartyRole.isEmpty ? nil : weddingPartyRole
                .trimmingCharacters(in: .whitespacesAndNewlines),
            preparationNotes: nil,
            coupleId: UUID(), // This should be set to the actual couple ID
            mealOption: mealOption.isEmpty ? nil : mealOption.trimmingCharacters(in: .whitespacesAndNewlines),
            giftReceived: false,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            hairDone: false,
            makeupDone: false)

        await onSave(newGuest)
        dismiss()
    }
}

#Preview {
    AddGuestView { guest in
        print("Saving guest: \(guest.fullName)")
    }
}
