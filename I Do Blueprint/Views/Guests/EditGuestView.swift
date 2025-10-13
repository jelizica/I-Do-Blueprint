//
//  EditGuestView.swift
//  My Wedding Planning App
//
//  Created by Jessica Clark on 9/26/25.
//

import Lottie
import SwiftUI

struct EditGuestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var relationshipToCouple: String
    @State private var invitedBy: InvitedBy
    @State private var rsvpStatus: RSVPStatus

    private let logger = AppLogger.ui
    @State private var plusOneAllowed: Bool
    @State private var plusOneName: String
    @State private var plusOneAttending: Bool
    @State private var attendingCeremony: Bool
    @State private var attendingReception: Bool
    @State private var dietaryRestrictions: String
    @State private var accessibilityNeeds: String
    @State private var mealOption: String
    @State private var notes: String
    @State private var preferredContactMethod: PreferredContactMethod
    @State private var addressLine1: String
    @State private var addressLine2: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var country: String
    @State private var invitationNumber: String
    @State private var isWeddingParty: Bool
    @State private var weddingPartyRole: String
    @State private var tableAssignment: String
    @State private var seatNumber: String
    @State private var giftReceived: Bool
    @State private var hairDone: Bool
    @State private var makeupDone: Bool
    @State private var showConfetti = false

    private let originalGuest: Guest

    init(guest: Guest) {
        originalGuest = guest

        _firstName = State(initialValue: guest.firstName)
        _lastName = State(initialValue: guest.lastName)
        _email = State(initialValue: guest.email ?? "")
        _phone = State(initialValue: guest.phone ?? "")
        _relationshipToCouple = State(initialValue: guest.relationshipToCouple ?? "")
        _invitedBy = State(initialValue: guest.invitedBy ?? .both)
        _rsvpStatus = State(initialValue: guest.rsvpStatus)
        _plusOneAllowed = State(initialValue: guest.plusOneAllowed)
        _plusOneName = State(initialValue: guest.plusOneName ?? "")
        _plusOneAttending = State(initialValue: guest.plusOneAttending)
        _attendingCeremony = State(initialValue: guest.attendingCeremony)
        _attendingReception = State(initialValue: guest.attendingReception)
        _dietaryRestrictions = State(initialValue: guest.dietaryRestrictions ?? "")
        _accessibilityNeeds = State(initialValue: guest.accessibilityNeeds ?? "")
        _mealOption = State(initialValue: guest.mealOption ?? "")
        _notes = State(initialValue: guest.notes ?? "")
        _preferredContactMethod = State(initialValue: guest.preferredContactMethod ?? .email)
        _addressLine1 = State(initialValue: guest.addressLine1 ?? "")
        _addressLine2 = State(initialValue: guest.addressLine2 ?? "")
        _city = State(initialValue: guest.city ?? "")
        _state = State(initialValue: guest.state ?? "")
        _zipCode = State(initialValue: guest.zipCode ?? "")
        _country = State(initialValue: guest.country ?? "USA")
        _invitationNumber = State(initialValue: guest.invitationNumber ?? "")
        _isWeddingParty = State(initialValue: guest.isWeddingParty)
        _weddingPartyRole = State(initialValue: guest.weddingPartyRole ?? "")
        _tableAssignment = State(initialValue: guest.tableAssignment?.description ?? "")
        _seatNumber = State(initialValue: guest.seatNumber?.description ?? "")
        _giftReceived = State(initialValue: guest.giftReceived)
        _hairDone = State(initialValue: guest.hairDone)
        _makeupDone = State(initialValue: guest.makeupDone)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Basic Information
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(.roundedBorder)
                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                            #if os(macOS)
                                .textContentType(.emailAddress)
                            #else
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                            #endif
                            TextField("Phone", text: $phone)
                                .textFieldStyle(.roundedBorder)
                            #if os(macOS)
                                .textContentType(.telephoneNumber)
                            #else
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                            #endif
                        }
                        .padding()
                    } label: {
                        Label("Basic Information", systemImage: "person")
                            .font(.headline)
                    }

                    // Wedding Details
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("Relationship to Couple", text: $relationshipToCouple)
                                .textFieldStyle(.roundedBorder)

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
                            .onChange(of: rsvpStatus) { oldValue, newValue in
                                // Show confetti when status changes to attending
                                if oldValue != .attending, newValue == .attending {
                                    showConfetti = true
                                }
                            }

                            HStack {
                                Text("Invitation Number")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(invitationNumber)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                    } label: {
                        Label("Wedding Details", systemImage: "heart")
                            .font(.headline)
                    }

                    // Attendance
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Attending Ceremony", isOn: $attendingCeremony)
                            Toggle("Attending Reception", isOn: $attendingReception)
                            Toggle("Plus One Allowed", isOn: $plusOneAllowed)

                            if plusOneAllowed {
                                TextField("Plus One Name", text: $plusOneName)
                                    .textFieldStyle(.roundedBorder)
                                Toggle("Plus One Attending", isOn: $plusOneAttending)
                            }
                        }
                        .padding()
                    } label: {
                        Label("Attendance", systemImage: "calendar")
                            .font(.headline)
                    }

                    // Meal & Dietary
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("Meal Option", text: $mealOption)
                                .textFieldStyle(.roundedBorder)
                            TextField("Dietary Restrictions", text: $dietaryRestrictions, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2 ... 4)
                            TextField("Accessibility Needs", text: $accessibilityNeeds, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2 ... 4)
                        }
                        .padding()
                    } label: {
                        Label("Meal & Dietary", systemImage: "fork.knife")
                            .font(.headline)
                    }

                    // Seating
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("Table Assignment", text: $tableAssignment)
                                .textFieldStyle(.roundedBorder)
                            #if !os(macOS)
                                .keyboardType(.numberPad)
                            #endif
                            TextField("Seat Number", text: $seatNumber)
                                .textFieldStyle(.roundedBorder)
                            #if !os(macOS)
                                .keyboardType(.numberPad)
                            #endif
                        }
                        .padding()
                    } label: {
                        Label("Seating", systemImage: "chair")
                            .font(.headline)
                    }

                    // Contact Preferences
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker("Preferred Contact Method", selection: $preferredContactMethod) {
                                ForEach(PreferredContactMethod.allCases, id: \.self) { method in
                                    Text(method.displayName).tag(method)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding()
                    } label: {
                        Label("Contact Preferences", systemImage: "envelope")
                            .font(.headline)
                    }

                    // Address
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("Address Line 1", text: $addressLine1)
                                .textFieldStyle(.roundedBorder)
                            TextField("Address Line 2", text: $addressLine2)
                                .textFieldStyle(.roundedBorder)
                            HStack(spacing: 12) {
                                TextField("City", text: $city)
                                    .textFieldStyle(.roundedBorder)
                                TextField("State", text: $state)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 80)
                                TextField("ZIP", text: $zipCode)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 100)
                            }
                            TextField("Country", text: $country)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding()
                    } label: {
                        Label("Address", systemImage: "location")
                            .font(.headline)
                    }

                    // Wedding Party
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Wedding Party Member", isOn: $isWeddingParty)

                            if isWeddingParty {
                                TextField("Role", text: $weddingPartyRole)
                                    .textFieldStyle(.roundedBorder)
                                Toggle("Hair Done", isOn: $hairDone)
                                Toggle("Makeup Done", isOn: $makeupDone)
                            }
                        }
                        .padding()
                    } label: {
                        Label("Wedding Party", systemImage: "crown")
                            .font(.headline)
                    }

                    // Additional
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Gift Received", isOn: $giftReceived)
                            TextField("Notes", text: $notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3 ... 6)
                        }
                        .padding()
                    } label: {
                        Label("Additional Information", systemImage: "note.text")
                            .font(.headline)
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Guest")
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
        .overlay(
            ConfettiOverlay(isShowing: $showConfetti))
    }

    private var isValidForm: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func saveGuest() async {
        var updatedGuest = originalGuest

        updatedGuest.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.email = email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.phone = phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.relationshipToCouple = relationshipToCouple.isEmpty ? nil : relationshipToCouple
            .trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.invitedBy = invitedBy
        updatedGuest.rsvpStatus = rsvpStatus
        updatedGuest.plusOneAllowed = plusOneAllowed
        updatedGuest.plusOneName = plusOneName.isEmpty ? nil : plusOneName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.plusOneAttending = plusOneAttending
        updatedGuest.attendingCeremony = attendingCeremony
        updatedGuest.attendingReception = attendingReception
        updatedGuest.dietaryRestrictions = dietaryRestrictions.isEmpty ? nil : dietaryRestrictions
            .trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.accessibilityNeeds = accessibilityNeeds.isEmpty ? nil : accessibilityNeeds
            .trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.mealOption = mealOption.isEmpty ? nil : mealOption.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.notes = notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.preferredContactMethod = preferredContactMethod
        updatedGuest.addressLine1 = addressLine1.isEmpty ? nil : addressLine1
            .trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.addressLine2 = addressLine2.isEmpty ? nil : addressLine2
            .trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.city = city.isEmpty ? nil : city.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.state = state.isEmpty ? nil : state.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.zipCode = zipCode.isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.country = country.isEmpty ? "USA" : country.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.invitationNumber = invitationNumber.isEmpty ? nil : invitationNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.isWeddingParty = isWeddingParty
        updatedGuest.weddingPartyRole = weddingPartyRole.isEmpty ? nil : weddingPartyRole
            .trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.tableAssignment = tableAssignment.isEmpty ? nil : Int(tableAssignment)
        updatedGuest.seatNumber = seatNumber.isEmpty ? nil : Int(seatNumber)
        updatedGuest.giftReceived = giftReceived
        updatedGuest.hairDone = hairDone
        updatedGuest.makeupDone = makeupDone
        updatedGuest.updatedAt = Date()

        // Post notification with the updated guest data
        do {
            let guestData = try JSONEncoder().encode(updatedGuest)
            logger.debug("Posting update notification for guest: \(updatedGuest.firstName) \(updatedGuest.lastName)")
            NotificationCenter.default.post(
                name: .updateGuest,
                object: nil,
                userInfo: ["guest": guestData])
            dismiss()
        } catch {
            logger.error("Failed to encode guest for notification", error: error)
        }
    }
}

#Preview {
    EditGuestView(guest: Guest(
        id: UUID(),
        createdAt: Date(),
        updatedAt: Date(),
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        phone: "+1 (555) 123-4567",
        guestGroupId: nil,
        relationshipToCouple: "Friend",
        invitedBy: .both,
        rsvpStatus: .attending,
        rsvpDate: nil,
        plusOneAllowed: true,
        plusOneName: "Jane Doe",
        plusOneAttending: true,
        attendingCeremony: true,
        attendingReception: true,
        attendingOtherEvents: nil,
        dietaryRestrictions: "Vegetarian",
        accessibilityNeeds: nil,
        tableAssignment: 5,
        seatNumber: 3,
        preferredContactMethod: .email,
        addressLine1: "123 Main St",
        addressLine2: nil,
        city: "Seattle",
        state: "WA",
        zipCode: "98101",
        country: "USA",
        invitationNumber: "INV-001",
        isWeddingParty: false,
        weddingPartyRole: nil,
        preparationNotes: nil,
        coupleId: UUID(),
        mealOption: "Chicken",
        giftReceived: false,
        notes: "Longtime friend from college",
        hairDone: false,
        makeupDone: false))
}
