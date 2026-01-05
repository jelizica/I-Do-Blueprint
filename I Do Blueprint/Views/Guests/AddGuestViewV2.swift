//
//  AddGuestViewV2.swift
//  I Do Blueprint
//
//  Glassmorphic Add Guest modal matching HTML design aesthetics
//  Uses design system colors with glassmorphism effects
//

import SwiftUI
import PhoneNumberKit

struct AddGuestViewV2: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var relationshipToCouple = ""
    @State private var invitedBy: InvitedBy = .both
    @State private var rsvpStatus: RSVPStatus = .pending
    @State private var plusOneAllowed = false
    @State private var plusOneName = ""
    @State private var attendingCeremony = false
    @State private var attendingReception = false
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
    @State private var focusedField: FocusedField? = nil

    let onSave: (Guest) async -> Void

    enum FocusedField: Hashable {
        case firstName, lastName, relationship
    }

    var body: some View {
        ZStack {
            backgroundGradient
            modalContent
        }
        .alert("Cannot Save Guest", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(errorMessage)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.91, blue: 1.0),
                Color(red: 0.99, green: 0.91, blue: 0.95),
                Color(red: 0.82, green: 0.98, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var modalContent: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().background(Color.white.opacity(0.6))
            tabContentSection
            Divider().background(Color.white.opacity(0.6))
            footerSection
        }
        .frame(maxWidth: 850)
        .background(Color.white.opacity(0.65).background(.ultraThinMaterial))
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 25)
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.6), lineWidth: 1))
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Add Guest")
                .font(Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(SemanticColors.textPrimary)

            tabPills
        }
        .padding(Spacing.xl)
        .background(Color.white.opacity(0.65).background(.ultraThinMaterial))
    }

    private var tabPills: some View {
        HStack(spacing: Spacing.xs) {
            TabPill(title: "Basic", isSelected: selectedTab == 0) { selectedTab = 0 }
            TabPill(title: "Contact", isSelected: selectedTab == 1) { selectedTab = 1 }
            TabPill(title: "Preferences", isSelected: selectedTab == 2) { selectedTab = 2 }
            TabPill(title: "Additional", isSelected: selectedTab == 3) { selectedTab = 3 }
        }
        .padding(Spacing.xs)
        .background(Color.white.opacity(0.3))
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.4), lineWidth: 1))
    }

    private var tabContentSection: some View {
        ScrollView {
            Group {
                switch selectedTab {
                case 0:
                    BasicInfoTab(
                        firstName: $firstName,
                        lastName: $lastName,
                        relationshipToCouple: $relationshipToCouple,
                        invitedBy: $invitedBy,
                        rsvpStatus: $rsvpStatus,
                        attendingCeremony: $attendingCeremony,
                        attendingReception: $attendingReception,
                        plusOneAllowed: $plusOneAllowed,
                        plusOneName: $plusOneName,
                        settingsStore: settingsStore,
                        focusedField: $focusedField
                    )
                case 1:
                    ContactTab(
                        email: $email,
                        phone: $phone,
                        preferredContactMethod: $preferredContactMethod,
                        addressLine1: $addressLine1,
                        addressLine2: $addressLine2,
                        city: $city,
                        state: $state,
                        zipCode: $zipCode,
                        country: $country
                    )
                case 2:
                    PreferencesTab(
                        mealOption: $mealOption,
                        dietaryRestrictions: $dietaryRestrictions,
                        accessibilityNeeds: $accessibilityNeeds,
                        isWeddingParty: $isWeddingParty,
                        weddingPartyRole: $weddingPartyRole,
                        settingsStore: settingsStore
                    )
                case 3:
                    AdditionalTab(notes: $notes)
                default:
                    EmptyView()
                }
            }
            .padding(Spacing.xl)
        }
        .background(Color.clear)
    }

    private var footerSection: some View {
        HStack(spacing: Spacing.md) {
            Spacer()
            Button("Cancel") { dismiss() }
                .buttonStyle(AddGuestCancelButtonStyle())
                .keyboardShortcut(.cancelAction)
            Button("Save") { Task { await saveGuest() } }
                .buttonStyle(AddGuestSaveButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidForm)
        }
        .padding(Spacing.xl)
        .background(Color.white.opacity(0.65).background(.ultraThinMaterial))
    }

    private var isValidForm: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func saveGuest() async {
        guard let coupleId = SessionManager.shared.getTenantId() else {
            AppLogger.ui.error("Cannot save guest: No couple selected")
            errorMessage = "Please select a couple before adding a guest. You can select a couple from the Settings."
            showingError = true
            return
        }

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
            attendingRehearsal: attendingCeremony,
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
            coupleId: coupleId,
            mealOption: mealOption.isEmpty ? nil : mealOption.trimmingCharacters(in: .whitespacesAndNewlines),
            giftReceived: false,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            hairDone: false,
            makeupDone: false)

        await onSave(newGuest)
        dismiss()
    }
}

// MARK: - Tab Pills

struct TabPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.bodyRegular)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? SemanticColors.textPrimary : SemanticColors.textSecondary)
                .padding(.vertical, Spacing.sm)
                .padding(.horizontal, Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.95, blue: 0.96),  // #fff0f3
                                    Color(red: 0.91, green: 0.84, blue: 0.80)  // #e8d5cc
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: -2)
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(25)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Basic Info Tab

struct BasicInfoTab: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var relationshipToCouple: String
    @Binding var invitedBy: InvitedBy
    @Binding var rsvpStatus: RSVPStatus
    @Binding var attendingCeremony: Bool
    @Binding var attendingReception: Bool
    @Binding var plusOneAllowed: Bool
    @Binding var plusOneName: String
    let settingsStore: SettingsStoreV2
    @Binding var focusedField: AddGuestViewV2.FocusedField?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xl) {
            // Left Column
            VStack(spacing: Spacing.lg) {
                GlassPanel(title: "Personal Information", icon: "person") {
                    VStack(spacing: Spacing.md) {
                        GlassTextField(
                            label: "First Name",
                            text: $firstName,
                            isRequired: true,
                            isFocused: focusedField == .firstName
                        )
                        .onTapGesture {
                            focusedField = .firstName
                        }

                        GlassTextField(
                            label: "Last Name",
                            text: $lastName,
                            isRequired: true,
                            isFocused: focusedField == .lastName
                        )
                        .onTapGesture {
                            focusedField = .lastName
                        }

                        GlassTextField(
                            label: "Relationship to Couple",
                            text: $relationshipToCouple,
                            isFocused: focusedField == .relationship
                        )
                        .onTapGesture {
                            focusedField = .relationship
                        }
                    }
                }

                GlassPanel(title: "Wedding Details", icon: "heart") {
                    VStack(spacing: Spacing.md) {
                        GlassDropdown(
                            label: "Invited By",
                            selection: $invitedBy,
                            options: InvitedBy.allCases,
                            displayName: { $0.displayName(with: settingsStore.settings) }
                        )

                        GlassDropdown(
                            label: "RSVP Status",
                            selection: $rsvpStatus,
                            options: RSVPStatus.allCases,
                            displayName: { $0.displayName }
                        )
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right Column
            VStack(spacing: Spacing.lg) {
                GlassPanel(title: "Attendance", icon: "calendar") {
                    VStack(spacing: Spacing.md) {
                        GlassToggle(label: "Attending Ceremony", isOn: $attendingCeremony)
                        GlassToggle(label: "Attending Reception", isOn: $attendingReception)
                        GlassToggle(label: "Plus One Allowed", isOn: $plusOneAllowed)

                        if plusOneAllowed {
                            GlassTextField(
                                label: "Plus One Name",
                                text: $plusOneName,
                                isFocused: false
                            )
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Contact Tab

struct ContactTab: View {
    @Binding var email: String
    @Binding var phone: String
    @Binding var preferredContactMethod: PreferredContactMethod
    @Binding var addressLine1: String
    @Binding var addressLine2: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var country: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            GlassPanel(title: "Contact Information", icon: "envelope") {
                VStack(spacing: Spacing.md) {
                    GlassTextField(label: "Email Address", text: $email, isFocused: false)

                    PhoneNumberTextFieldWrapper(
                        phoneNumber: $phone,
                        defaultRegion: "US",
                        placeholder: "Phone Number"
                    )
                    .frame(height: 40)

                    GlassDropdown(
                        label: "Preferred Contact Method",
                        selection: $preferredContactMethod,
                        options: PreferredContactMethod.allCases,
                        displayName: { $0.displayName }
                    )
                }
            }

            GlassPanel(title: "Address", icon: "location") {
                VStack(spacing: Spacing.md) {
                    GlassTextField(label: "Address Line 1", text: $addressLine1, isFocused: false)
                    GlassTextField(label: "Address Line 2", text: $addressLine2, isFocused: false)

                    HStack(spacing: Spacing.md) {
                        GlassTextField(label: "City", text: $city, isFocused: false)
                        GlassTextField(label: "State", text: $state, isFocused: false)
                            .frame(maxWidth: 80)
                        GlassTextField(label: "ZIP", text: $zipCode, isFocused: false)
                            .frame(maxWidth: 100)
                    }

                    GlassTextField(label: "Country", text: $country, isFocused: false)
                }
            }
        }
    }
}

// MARK: - Preferences Tab

struct PreferencesTab: View {
    @Binding var mealOption: String
    @Binding var dietaryRestrictions: String
    @Binding var accessibilityNeeds: String
    @Binding var isWeddingParty: Bool
    @Binding var weddingPartyRole: String
    let settingsStore: SettingsStoreV2

    var body: some View {
        VStack(spacing: Spacing.lg) {
            GlassPanel(title: "Dining Preferences", icon: "fork.knife") {
                VStack(spacing: Spacing.md) {
                    GlassDropdown(
                        label: "Meal Option",
                        selection: $mealOption,
                        options: [""] + settingsStore.settings.guests.customMealOptions,
                        displayName: { $0.isEmpty ? "Not Selected" : $0 }
                    )

                    GlassTextArea(
                        label: "Dietary Restrictions",
                        text: $dietaryRestrictions
                    )
                }
            }

            GlassPanel(title: "Accessibility", icon: "accessibility") {
                GlassTextArea(
                    label: "Accessibility Needs",
                    text: $accessibilityNeeds
                )
            }

            GlassPanel(title: "Wedding Party", icon: "crown") {
                VStack(spacing: Spacing.md) {
                    GlassToggle(label: "Wedding Party Member", isOn: $isWeddingParty)

                    if isWeddingParty {
                        GlassTextField(
                            label: "Wedding Party Role",
                            text: $weddingPartyRole,
                            isFocused: false
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Additional Tab

struct AdditionalTab: View {
    @Binding var notes: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            GlassPanel(title: "Additional Notes", icon: "note.text") {
                GlassTextArea(
                    label: "Notes",
                    text: $notes
                )
            }

            GlassPanel(title: "Future Features", icon: "gift") {
                Text("Gift tracking and other features coming soon...")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
    }
}

// MARK: - Glass Components

struct GlassPanel<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label(title, systemImage: icon)
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)

            content
        }
        .padding(Spacing.lg)
        .background(
            Color.white.opacity(0.4)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

struct GlassTextField: View {
    let label: String
    @Binding var text: String
    var isRequired: Bool = false
    var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Text(label)
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textSecondary)
                if isRequired {
                    Text("*")
                        .font(Typography.caption)
                        .foregroundColor(BlushPink.shade600)
                }
            }

            TextField(label, text: $text)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .padding(Spacing.sm)
                .background(
                    isFocused ?
                        Color(red: 1.0, green: 0.94, blue: 0.95) :  // #fff0f3
                        Color(red: 0.95, green: 0.90, blue: 0.85)   // #f3e6d8
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ?
                                Color(red: 1.0, green: 0.70, blue: 0.76) :  // #ffb3c1
                                Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isFocused ?
                        Color(red: 1.0, green: 0.56, blue: 0.67).opacity(0.4) :  // #FF8FAB
                        Color.clear,
                    radius: isFocused ? 10 : 0,
                    x: 0,
                    y: 0
                )
        }
    }
}

struct GlassTextArea: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textSecondary)

            TextEditor(text: $text)
                .font(Typography.bodyRegular)
                .frame(minHeight: 80)
                .padding(Spacing.sm)
                .background(Color(red: 0.95, green: 0.90, blue: 0.85))  // #f3e6d8
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.clear, lineWidth: 1)
                )
        }
    }
}

struct GlassDropdown<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let options: [T]
    let displayName: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textSecondary)

            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayName(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .font(Typography.bodyRegular)
            .fontWeight(.medium)
            .padding(Spacing.sm)
            .background(Color(red: 0.95, green: 0.90, blue: 0.85))  // #f3e6d8
            .cornerRadius(12)
        }
    }
}

struct GlassToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textPrimary)

            Spacer()

            // Custom toggle switch
            ZStack {
                // Track
                RoundedRectangle(cornerRadius: 13)
                    .fill(isOn ? SageGreen.shade600 : Color.white)
                    .frame(width: 48, height: 26)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .offset(x: isOn ? 11 : -11)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
            }
            .onTapGesture {
                isOn.toggle()
            }
        }
    }
}

// MARK: - Button Styles

struct AddGuestCancelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.bodyRegular)
            .fontWeight(.medium)
            .foregroundColor(SemanticColors.textSecondary)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.lg)
            .background(Color.white.opacity(0.4).background(.ultraThinMaterial))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.6), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AddGuestSaveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.bodyRegular)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.xl)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.45, blue: 0.71),  // #F472B6
                        Color(red: 0.86, green: 0.37, blue: 0.53),  // #db5e88
                        Color(red: 0.53, green: 0.66, blue: 0.57)   // #87a892
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .shadow(color: Color(red: 0.96, green: 0.45, blue: 0.71).opacity(0.4), radius: 15, x: 0, y: 4)
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    AddGuestViewV2 { guest in
        // Guest saved via callback
    }
    .environmentObject(SettingsStoreV2())
}
