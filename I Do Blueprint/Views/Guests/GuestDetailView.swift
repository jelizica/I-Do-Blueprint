//
//  GuestDetailView.swift
//  My Wedding Planning App
//
//  Created by Jessica Clark on 9/26/25.
//

import SwiftUI

extension Notification.Name {
    static let deleteGuest = Notification.Name("deleteGuest")
    static let updateGuest = Notification.Name("updateGuest")
}

struct GuestDetailView: View {
    @State private var guest: Guest
    @State private var showingEditModal = false
    @State private var showingDeleteAlert = false

    private let logger = AppLogger.ui

    init(guest: Guest) {
        _guest = State(initialValue: guest)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Avatar and Name
                VStack(spacing: 20) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [guest.rsvpStatus.color.opacity(0.3), guest.rsvpStatus.color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(guest.firstName.prefix(1) + guest.lastName.prefix(1)))
                                .font(.system(size: 36, weight: .bold, design: .default))
                                .foregroundColor(guest.rsvpStatus.color))
                        .shadow(color: guest.rsvpStatus.color.opacity(0.3), radius: 12, x: 0, y: 6)

                    VStack(spacing: 12) {
                        Text("\(guest.firstName) \(guest.lastName)")
                            .font(.system(size: 28, weight: .bold, design: .default))

                        HStack(spacing: 8) {
                            Circle()
                                .fill(guest.rsvpStatus.color)
                                .frame(width: 8, height: 8)
                            Text(guest.rsvpStatus.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .fill(guest.rsvpStatus.color.opacity(0.12)))
                        .foregroundColor(guest.rsvpStatus.color)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("RSVP status: \(guest.rsvpStatus.displayName)")
                    }
                }
                .padding(Spacing.xxl)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4))

                // Contact Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    VStack(spacing: 16) {
                        if let email = guest.email, !email.isEmpty {
                            InfoRow(label: "Email", value: email, icon: "envelope.fill")
                        }

                        if let phone = guest.phone, !phone.isEmpty {
                            InfoRow(label: "Phone", value: phone, icon: "phone.fill")
                        }

                        if let method = guest.preferredContactMethod {
                            InfoRow(label: "Preferred Contact", value: method.displayName, icon: "star.fill")
                        }
                    }
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3))

                // Wedding Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Wedding Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    VStack(spacing: 16) {
                        if let invitationNumber = guest.invitationNumber {
                            InfoRow(label: "Invitation #", value: invitationNumber, icon: "envelope.fill")
                        }

                        if let invitedBy = guest.invitedBy {
                            InfoRow(label: "Invited By", value: invitedBy.displayName, icon: "heart.fill")
                        }

                        if let relationship = guest.relationshipToCouple, !relationship.isEmpty {
                            InfoRow(label: "Relationship", value: relationship, icon: "person.2.fill")
                        }

                        InfoRow(
                            label: "Ceremony",
                            value: guest.attendingCeremony ? "Attending" : "Not Attending",
                            icon: "calendar")

                        InfoRow(
                            label: "Reception",
                            value: guest.attendingReception ? "Attending" : "Not Attending",
                            icon: "party.popper.fill")

                        if guest.plusOneAllowed {
                            InfoRow(
                                label: "Plus One",
                                value: guest.plusOneAttending ? (guest.plusOneName ?? "Yes") : "Not Attending",
                                icon: "plus")
                        }
                    }
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3))

                // Meal & Dietary Information
                if guest.mealOption != nil || guest.dietaryRestrictions != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Dietary & Meal Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        VStack(spacing: 16) {
                            if let meal = guest.mealOption, !meal.isEmpty {
                                InfoRow(label: "Meal Selection", value: meal, icon: "fork.knife")
                            }

                            if let dietary = guest.dietaryRestrictions, !dietary.isEmpty {
                                InfoRow(
                                    label: "Dietary Restrictions",
                                    value: dietary,
                                    icon: "exclamationmark.triangle.fill",
                                    isAlert: true)
                            }

                            if let accessibility = guest.accessibilityNeeds, !accessibility.isEmpty {
                                InfoRow(
                                    label: "Accessibility Needs",
                                    value: accessibility,
                                    icon: "accessibility",
                                    isAlert: true)
                            }
                        }
                    }
                    .padding(Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3))
                }

                // Seating Information
                if guest.tableAssignment != nil || guest.seatNumber != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Seating Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        VStack(spacing: 16) {
                            if let table = guest.tableAssignment {
                                InfoRow(label: "Table Assignment", value: "Table \(table)", icon: "tablecells")
                            }

                            if let seat = guest.seatNumber {
                                InfoRow(label: "Seat Number", value: "Seat \(seat)", icon: "chair.fill")
                            }
                        }
                    }
                    .padding(Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3))
                }

                // Wedding Party Information
                if guest.isWeddingParty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wedding Party")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        VStack(spacing: 16) {
                            InfoRow(label: "Wedding Party Member", value: "Yes", icon: "crown.fill")

                            if let role = guest.weddingPartyRole, !role.isEmpty {
                                InfoRow(label: "Role", value: role, icon: "person.crop.circle.badge.checkmark")
                            }

                            if guest.hairDone || guest.makeupDone {
                                HStack(spacing: 12) {
                                    if guest.hairDone {
                                        HStack(spacing: 6) {
                                            Image(systemName: "scissors")
                                                .foregroundColor(.green)
                                            Text("Hair Done")
                                                .fontWeight(.medium)
                                        }
                                    }
                                    if guest.makeupDone {
                                        HStack(spacing: 6) {
                                            Image(systemName: "paintbrush.fill")
                                                .foregroundColor(.pink)
                                            Text("Makeup Done")
                                                .fontWeight(.medium)
                                        }
                                    }
                                    Spacer()
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    .padding(Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3))
                }

                // Additional Information
                if guest.notes != nil || guest.giftReceived {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        VStack(spacing: 16) {
                            if guest.giftReceived {
                                InfoRow(label: "Gift Received", value: "Yes", icon: "gift.fill")
                            }

                            if let notes = guest.notes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "note.text")
                                            .foregroundColor(.blue)
                                            .frame(width: 20)
                                        Text("Notes")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    Text(notes)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .padding(.leading, Spacing.xxxl)
                                }
                            }
                        }
                    }
                    .padding(Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3))
                }

                // Address Information
                if hasAddress {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Address")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 6) {
                            if let address1 = guest.addressLine1, !address1.isEmpty {
                                Text(address1)
                                    .font(.body)
                            }
                            if let address2 = guest.addressLine2, !address2.isEmpty {
                                Text(address2)
                                    .font(.body)
                            }
                            HStack(spacing: 4) {
                                if let city = guest.city, !city.isEmpty {
                                    Text(city + ",")
                                        .font(.body)
                                }
                                if let state = guest.state, !state.isEmpty {
                                    Text(state)
                                        .font(.body)
                                }
                                if let zip = guest.zipCode, !zip.isEmpty {
                                    Text(zip)
                                        .font(.body)
                                }
                            }
                            if let country = guest.country, !country.isEmpty, country != "USA" {
                                Text(country)
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3))
                }
            }
            .padding(Spacing.xxl)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle("Guest Details")
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEditModal = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                                                        showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditModal = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                                                        showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingEditModal) {
                EditGuestView(guest: guest)
                #if os(macOS)
                    .frame(minWidth: 500, maxWidth: 600, minHeight: 500, maxHeight: 650)
                #endif
            }
            .onReceive(NotificationCenter.default.publisher(for: .updateGuest)) { notification in
                if let updatedGuestData = notification.userInfo?["guest"] as? Data,
                   let updatedGuest = try? JSONDecoder().decode(Guest.self, from: updatedGuestData) {
                                        guest = updatedGuest
                }
            }
            .alert("Delete Guest", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                                        
                    // Capture just the ID to avoid memory corruption
                    let guestId = guest.id
                    
                    // Post notification with the guest ID instead of using closures
                                        NotificationCenter.default.post(
                        name: .deleteGuest,
                        object: nil,
                        userInfo: ["guestId": guestId.uuidString])
                }
                Button("Cancel", role: .cancel) {
                                    }
            } message: {
                Text(
                    "Are you sure you want to delete \(guest.firstName) \(guest.lastName)? This action cannot be undone.")
            }
    }

    private var hasAddress: Bool {
        !(guest.addressLine1?.isEmpty ?? true) ||
            !(guest.addressLine2?.isEmpty ?? true) ||
            !(guest.city?.isEmpty ?? true) ||
            !(guest.state?.isEmpty ?? true) ||
            !(guest.zipCode?.isEmpty ?? true) ||
            (!(guest.country?.isEmpty ?? true) && guest.country != "USA")
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    var isAlert: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(isAlert ? .orange : .blue)
                .font(.body)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    GuestDetailView(guest: Guest(
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
