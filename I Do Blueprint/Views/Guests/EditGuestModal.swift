//
//  EditGuestModal.swift
//  I Do Blueprint
//
//  Glassmorphic Edit Guest modal with 3-tab design
//  Matches AddGuestViewV2 styling with theme-aware colors
//  Tab 1: Basic & Wedding | Tab 2: Dining & Gifts | Tab 3: History
//

import SwiftUI
import PhoneNumberKit

struct EditGuestModal: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @EnvironmentObject var coordinator: AppCoordinator
    @ObservedObject var guestStore: GuestStoreV2

    let guest: Guest
    let onSave: (Guest) -> Void
    let onDelete: (() -> Void)?
    let onCancel: (() -> Void)?

    // Proportional Modal Sizing Pattern
    private let minWidth: CGFloat = 820
    private let maxWidth: CGFloat = 960
    private let minHeight: CGFloat = 620
    private let maxHeight: CGFloat = 720
    private let windowChromeBuffer: CGFloat = 40
    private let widthProportion: CGFloat = 0.70
    private let heightProportion: CGFloat = 0.80

    // Avatar state
    @State private var avatarImage: NSImage?

    // Tab state
    @State private var selectedTab = 0

    // Form state - Basic & Wedding
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var relationshipToCouple: String
    @State private var invitedBy: InvitedBy?
    @State private var rsvpStatus: RSVPStatus
    @State private var isWeddingParty: Bool
    @State private var weddingPartyRole: String
    @State private var attendingCeremony: Bool
    @State private var attendingReception: Bool
    @State private var attendingRehearsal: Bool
    @State private var plusOneAllowed: Bool
    @State private var plusOneName: String
    @State private var plusOneAttending: Bool
    @State private var notes: String
    @State private var accessibilityNeeds: String
    @State private var preferredContactMethod: PreferredContactMethod?
    @State private var addressLine1: String
    @State private var addressLine2: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var country: String

    // Form state - Dining & Gifts
    @State private var mealOption: String
    @State private var dietaryRestrictions: String
    @State private var giftReceived: Bool
    @State private var tableAssignment: Int?
    @State private var seatNumber: Int?

    // Form state - Wedding Party Details
    @State private var hairDone: Bool
    @State private var makeupDone: Bool
    @State private var preparationNotes: String

    // History filter
    @State private var historyFilter: HistoryFilter = .all

    // Save state
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false

    init(guest: Guest, guestStore: GuestStoreV2, onSave: @escaping (Guest) -> Void, onDelete: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.guest = guest
        self.guestStore = guestStore
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel

        // Initialize form state from guest
        _firstName = State(initialValue: guest.firstName)
        _lastName = State(initialValue: guest.lastName)
        _email = State(initialValue: guest.email ?? "")
        _phone = State(initialValue: guest.phone ?? "")
        _relationshipToCouple = State(initialValue: guest.relationshipToCouple ?? "")
        _invitedBy = State(initialValue: guest.invitedBy)
        _rsvpStatus = State(initialValue: guest.rsvpStatus)
        _isWeddingParty = State(initialValue: guest.isWeddingParty)
        _weddingPartyRole = State(initialValue: guest.weddingPartyRole ?? "")
        _attendingCeremony = State(initialValue: guest.attendingCeremony)
        _attendingReception = State(initialValue: guest.attendingReception)
        _attendingRehearsal = State(initialValue: guest.attendingRehearsal)
        _plusOneAllowed = State(initialValue: guest.plusOneAllowed)
        _plusOneName = State(initialValue: guest.plusOneName ?? "")
        _plusOneAttending = State(initialValue: guest.plusOneAttending)
        _notes = State(initialValue: guest.notes ?? "")
        _accessibilityNeeds = State(initialValue: guest.accessibilityNeeds ?? "")
        _preferredContactMethod = State(initialValue: guest.preferredContactMethod)
        _addressLine1 = State(initialValue: guest.addressLine1 ?? "")
        _addressLine2 = State(initialValue: guest.addressLine2 ?? "")
        _city = State(initialValue: guest.city ?? "")
        _state = State(initialValue: guest.state ?? "")
        _zipCode = State(initialValue: guest.zipCode ?? "")
        _country = State(initialValue: guest.country ?? "USA")
        _mealOption = State(initialValue: guest.mealOption ?? "")
        _dietaryRestrictions = State(initialValue: guest.dietaryRestrictions ?? "")
        _giftReceived = State(initialValue: guest.giftReceived)
        _tableAssignment = State(initialValue: guest.tableAssignment)
        _seatNumber = State(initialValue: guest.seatNumber)
        _hairDone = State(initialValue: guest.hairDone)
        _makeupDone = State(initialValue: guest.makeupDone)
        _preparationNotes = State(initialValue: guest.preparationNotes ?? "")
    }

    private var guestInitials: String {
        let first = guest.firstName.prefix(1).uppercased()
        let last = guest.lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
                .ignoresSafeArea()

            modalContent
        }
        .confirmationDialog(
            "Remove Guest",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Guest", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \(guest.fullName) from your guest list? This action cannot be undone.")
        }
    }

    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = parentSize.width * widthProportion
        let targetHeight = parentSize.height * heightProportion - windowChromeBuffer
        let finalWidth = min(maxWidth, max(minWidth, targetWidth))
        let finalHeight = min(maxHeight, max(minHeight, targetHeight))
        return CGSize(width: finalWidth, height: finalHeight)
    }

    private var modalContent: some View {
        VStack(spacing: 0) {
            // Header with avatar and tabs
            headerSection

            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    basicAndWeddingTab
                case 1:
                    diningAndGiftsTab
                case 2:
                    historyTab
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer(minLength: Spacing.md)

            // Footer
            footerSection
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.45))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 20)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.lg) {
                // Avatar
                avatarView

                // Name and status
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Edit Guest")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.gray)

                    Text("\(firstName) \(lastName)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                }

                Spacer()

                // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.gray)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
            }

            // Tab pills
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    let titles = ["Basic & Wedding", "Dining & Gifts", "History"]
                    let icons = ["person.fill", "fork.knife", "clock.arrow.circlepath"]
                    Button(action: { selectedTab = index }) {
                        HStack(spacing: 6) {
                            Image(systemName: icons[index])
                                .font(.system(size: 12))
                            Text(titles[index])
                                .font(.system(size: 14, weight: selectedTab == index ? .semibold : .medium))
                        }
                        .foregroundColor(selectedTab == index ? Color(red: 0.25, green: 0.25, blue: 0.3) : Color.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == index {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 1.0, green: 0.96, blue: 0.96),
                                                    Color(red: 0.95, green: 0.88, blue: 0.85)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.4))
            )
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.md)
    }

    private var avatarView: some View {
        Group {
            if let image = avatarImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.55, blue: 0.65),
                                    Color(red: 0.75, green: 0.55, blue: 0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Text(guestInitials)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            await loadAvatar()
        }
    }

    // MARK: - Tab 1: Basic & Wedding

    private var basicAndWeddingTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Left Column
                VStack(spacing: Spacing.md) {
                    personalInfoCard
                    contactDetailsCard
                }
                .frame(maxWidth: .infinity)

                // Right Column
                VStack(spacing: Spacing.md) {
                    weddingStatusCard
                    attendanceCard
                    notesAndRequirementsCard
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Spacing.md)
        }
    }

    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            cardHeader(icon: "person.fill", title: "Personal Information", iconColor: Color(red: 0.85, green: 0.4, blue: 0.5))

            VStack(spacing: Spacing.sm) {
                GlassInputField(label: "First Name", text: $firstName, isRequired: true, isFocused: false)
                GlassInputField(label: "Last Name", text: $lastName, isRequired: true, isFocused: false)
                GlassInputField(label: "Relationship", text: $relationshipToCouple, placeholder: "e.g., Cousin, College Friend", isFocused: false)
            }
        }
        .padding(Spacing.lg)
        .background(pinkCardBackground)
    }

    private var contactDetailsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            cardHeader(icon: "envelope.fill", title: "Contact Details", iconColor: Color(red: 0.4, green: 0.55, blue: 0.75))

            VStack(spacing: Spacing.sm) {
                GlassInputField(label: "Email", text: $email, placeholder: "email@example.com", isFocused: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Phone")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)
                    PhoneNumberTextFieldWrapper(
                        phoneNumber: $phone,
                        defaultRegion: "US",
                        placeholder: "(555) 123-4567"
                    )
                    .frame(height: 38)
                }

                // Preferred Contact
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preferred Contact")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)

                    Menu {
                        Button("Not specified") { preferredContactMethod = nil }
                        ForEach(PreferredContactMethod.allCases, id: \.self) { method in
                            Button(method.displayName) { preferredContactMethod = method }
                        }
                    } label: {
                        HStack {
                            Text(preferredContactMethod?.displayName ?? "Not specified")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Color.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Address fields (collapsed)
                DisclosureGroup("Address") {
                    VStack(spacing: Spacing.sm) {
                        GlassInputField(label: "Address Line 1", text: $addressLine1, isFocused: false)
                        GlassInputField(label: "Address Line 2", text: $addressLine2, isOptional: true, isFocused: false)
                        HStack(spacing: Spacing.sm) {
                            GlassInputField(label: "City", text: $city, isFocused: false)
                            GlassInputField(label: "State", text: $state, isFocused: false)
                                .frame(width: 80)
                        }
                        HStack(spacing: Spacing.sm) {
                            GlassInputField(label: "ZIP Code", text: $zipCode, isFocused: false)
                            GlassInputField(label: "Country", text: $country, isFocused: false)
                        }
                    }
                    .padding(.top, Spacing.sm)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.gray)
            }
        }
        .padding(Spacing.lg)
        .background(neutralCardBackground)
    }

    private var weddingStatusCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            cardHeader(icon: "heart.fill", title: "Wedding Status & Party", iconColor: Color(red: 0.85, green: 0.4, blue: 0.5))

            VStack(spacing: Spacing.md) {
                // RSVP Status
                HStack {
                    Text("RSVP Status")
                        .font(.system(size: 13))
                        .foregroundColor(Color.gray)
                    Spacer()
                    Menu {
                        ForEach(RSVPStatus.allCases, id: \.self) { status in
                            Button {
                                rsvpStatus = status
                            } label: {
                                HStack {
                                    Image(systemName: status.icon)
                                    Text(status.displayName)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: rsvpStatus.icon)
                                .font(.system(size: 10))
                            Text(rsvpStatus.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(rsvpStatusTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(rsvpStatusBackgroundColor)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Invited By
                HStack {
                    Text("Invited By")
                        .font(.system(size: 13))
                        .foregroundColor(Color.gray)
                    Spacer()
                    Menu {
                        Button("Not specified") { invitedBy = nil }
                        ForEach(InvitedBy.allCases, id: \.self) { option in
                            Button(option.displayName(with: settingsStore.settings)) {
                                invitedBy = option
                            }
                        }
                    } label: {
                        Text(invitedBy?.displayName(with: settingsStore.settings) ?? "Not specified")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.6))
                            )
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Wedding Party Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wedding Party Member")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                        Text("Part of the bridal party?")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    Spacer()
                    PinkToggle(isOn: $isWeddingParty)
                }

                if isWeddingParty {
                    VStack(spacing: Spacing.sm) {
                        GlassInputField(label: "Role", text: $weddingPartyRole, placeholder: "e.g., Bridesmaid, Best Man", isFocused: false)

                        HStack(spacing: Spacing.md) {
                            HStack(spacing: 6) {
                                Image(systemName: "scissors")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.gray)
                                Text("Hair")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gray)
                                Spacer()
                                SmallGreenToggle(isOn: $hairDone)
                            }
                            .frame(maxWidth: .infinity)

                            HStack(spacing: 6) {
                                Image(systemName: "paintbrush.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.gray)
                                Text("Makeup")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gray)
                                Spacer()
                                SmallGreenToggle(isOn: $makeupDone)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 1.0, green: 0.97, blue: 0.95))
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .background(pinkCardBackground)
    }

    private var attendanceCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            cardHeader(icon: "calendar.badge.checkmark", title: "Attendance", iconColor: Color(red: 0.3, green: 0.65, blue: 0.45))

            VStack(spacing: Spacing.sm) {
                ColoredToggleRow(label: "Ceremony", isOn: $attendingCeremony)
                ColoredToggleRow(label: "Reception", isOn: $attendingReception)
                ColoredToggleRow(label: "Rehearsal Dinner", isOn: $attendingRehearsal)

                Divider()

                // Plus One section
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Plus One")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                    }
                    Spacer()
                    SmallGreenToggle(isOn: $plusOneAllowed)
                }

                if plusOneAllowed {
                    VStack(spacing: Spacing.sm) {
                        GlassInputField(label: "Plus One Name", text: $plusOneName, placeholder: "Guest name", isFocused: false)

                        HStack {
                            Text("Attending")
                                .font(.system(size: 12))
                                .foregroundColor(Color.gray)
                            Spacer()
                            SmallGreenToggle(isOn: $plusOneAttending)
                        }
                    }
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.95, green: 0.98, blue: 0.96))
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .background(greenCardBackground)
    }

    private var notesAndRequirementsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            cardHeader(icon: "note.text", title: "Notes & Requirements", iconColor: Color(red: 0.6, green: 0.5, blue: 0.7))

            VStack(spacing: Spacing.sm) {
                // Notes
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)
                    TextEditor(text: $notes)
                        .font(.system(size: 13))
                        .frame(minHeight: 60)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .scrollContentBackground(.hidden)
                }

                // Accessibility
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.roll")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                        Text("Accessibility Needs")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gray)
                    }
                    TextField("Any special requirements...", text: $accessibilityNeeds)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(Spacing.lg)
        .background(neutralCardBackground)
    }

    // MARK: - Tab 2: Dining & Gifts

    private var diningAndGiftsTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Left Column - Dining
                VStack(spacing: Spacing.md) {
                    diningPreferencesCard
                }
                .frame(maxWidth: .infinity)

                // Right Column - Gift Status
                VStack(spacing: Spacing.md) {
                    giftStatusCard
                    seatingCard
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Spacing.md)
        }
    }

    private var diningPreferencesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            cardHeader(icon: "fork.knife", title: "Dining Preferences", iconColor: Color(red: 0.85, green: 0.65, blue: 0.4))

            VStack(spacing: Spacing.md) {
                // Meal Option
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meal Option")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)

                    Menu {
                        Button("Not Selected") { mealOption = "" }
                        ForEach(settingsStore.settings.guests.customMealOptions, id: \.self) { option in
                            Button(option) { mealOption = option }
                        }
                    } label: {
                        HStack {
                            if mealOption.isEmpty {
                                Text("Select meal option...")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.gray.opacity(0.7))
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.4))
                                    Text(mealOption)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Color.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Dietary Restrictions
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.85, green: 0.55, blue: 0.3))
                        Text("Dietary Restrictions")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gray)
                    }
                    TextEditor(text: $dietaryRestrictions)
                        .font(.system(size: 13))
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 1.0, green: 0.97, blue: 0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(red: 0.9, green: 0.8, blue: 0.65), lineWidth: 1)
                                )
                        )
                        .scrollContentBackground(.hidden)
                        .overlay(
                            Group {
                                if dietaryRestrictions.isEmpty {
                                    Text("e.g., Vegetarian, Gluten-free, Nut allergy...")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.gray.opacity(0.6))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }

                Text("Dietary information is shared with the caterer.")
                    .font(.system(size: 11))
                    .foregroundColor(Color.gray)
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.97, blue: 0.94).opacity(0.7),
                            Color(red: 0.98, green: 0.95, blue: 0.92).opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var giftStatusCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            cardHeader(icon: "gift.fill", title: "Gift Status", iconColor: Color(red: 0.6, green: 0.5, blue: 0.7))

            VStack(spacing: Spacing.md) {
                // Gift Received Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gift Received")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                        Text("Has the guest sent a gift?")
                            .font(.system(size: 11))
                            .foregroundColor(Color.gray)
                    }
                    Spacer()
                    SmallGreenToggle(isOn: $giftReceived)
                }

                if giftReceived {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.3, green: 0.65, blue: 0.45))
                        Text("Gift has been received")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.3, green: 0.65, blue: 0.45))
                    }
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.92, green: 0.98, blue: 0.95))
                    )
                }

                // Coming Soon note
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray.opacity(0.6))
                    Text("Gift description and thank you tracking coming soon")
                        .font(.system(size: 11))
                        .foregroundColor(Color.gray)
                }
            }
        }
        .padding(Spacing.lg)
        .background(neutralCardBackground)
    }

    private var seatingCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            cardHeader(icon: "tablecells", title: "Seating", iconColor: Color(red: 0.4, green: 0.55, blue: 0.75))

            HStack(spacing: Spacing.md) {
                // Table Assignment
                VStack(alignment: .leading, spacing: 4) {
                    Text("Table")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)

                    TextField("—", value: $tableAssignment, format: .number)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(width: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                }

                // Seat Number
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seat")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)

                    TextField("—", value: $seatNumber, format: .number)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(width: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                }

                Spacer()
            }

            Text("Visual seating chart coming in a future update.")
                .font(.system(size: 11))
                .foregroundColor(Color.gray)
        }
        .padding(Spacing.lg)
        .background(neutralCardBackground)
    }

    // MARK: - Tab 3: History

    private var historyTab: some View {
        VStack(spacing: Spacing.md) {
            // Filter pills
            historyFilterRow

            // Timeline
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    historyTimelineContent
                }
            }
        }
        .padding(.vertical, Spacing.md)
    }

    private var historyFilterRow: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                Button {
                    historyFilter = filter
                } label: {
                    Text(filter.displayName)
                        .font(.system(size: 12, weight: historyFilter == filter ? .semibold : .medium))
                        .foregroundColor(historyFilter == filter ? .white : Color.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(historyFilter == filter ?
                                    Color(red: 0.85, green: 0.4, blue: 0.5) :
                                    Color.white.opacity(0.6)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var historyTimelineContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Created event
            HistoryTimelineItem(
                icon: "person.badge.plus",
                iconColor: Color(red: 0.85, green: 0.4, blue: 0.5),
                title: "Guest Added",
                subtitle: "Added to guest list",
                date: guest.createdAt,
                isFirst: true,
                isLast: guest.rsvpDate == nil && guest.updatedAt == guest.createdAt
            )

            // RSVP event (if exists)
            if let rsvpDate = guest.rsvpDate {
                HistoryTimelineItem(
                    icon: guest.rsvpStatus.icon,
                    iconColor: rsvpStatusIconColor,
                    title: "RSVP Status Updated",
                    subtitle: "Status changed to \(guest.rsvpStatus.displayName)",
                    date: rsvpDate,
                    isFirst: false,
                    isLast: guest.updatedAt == rsvpDate
                )
            }

            // Last updated (if different from created)
            if guest.updatedAt != guest.createdAt && guest.updatedAt != guest.rsvpDate {
                HistoryTimelineItem(
                    icon: "pencil",
                    iconColor: Color(red: 0.4, green: 0.55, blue: 0.75),
                    title: "Guest Updated",
                    subtitle: "Profile information modified",
                    date: guest.updatedAt,
                    isFirst: false,
                    isLast: true
                )
            }

            // Empty state if only created
            if guest.rsvpDate == nil && guest.updatedAt == guest.createdAt {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "clock")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray.opacity(0.4))
                    Text("No activity yet")
                        .font(.system(size: 13))
                        .foregroundColor(Color.gray)
                    Text("Changes to this guest will appear here")
                        .font(.system(size: 11))
                        .foregroundColor(Color.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
            }
        }
        .padding(Spacing.lg)
        .background(neutralCardBackground)
    }

    private var rsvpStatusIconColor: Color {
        switch guest.rsvpStatus {
        case .attending, .confirmed:
            return Color(red: 0.3, green: 0.65, blue: 0.45)
        case .declined:
            return Color(red: 0.8, green: 0.35, blue: 0.35)
        case .maybe:
            return Color(red: 0.85, green: 0.65, blue: 0.3)
        default:
            return Color.gray
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: Spacing.md) {
            // Remove Guest button (only if onDelete is provided)
            if onDelete != nil {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                        Text("Remove Guest")
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(red: 1.0, green: 0.95, blue: 0.95))
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.9, green: 0.85, blue: 0.85), lineWidth: 1)
                        )
                )
                .buttonStyle(.plain)
            }

            Spacer()

            // Cancel button - returns to ViewGuestModal if onCancel provided
            Button("Cancel") {
                if let onCancel = onCancel {
                    onCancel()
                } else {
                    dismiss()
                }
            }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.gray)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.6))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                )
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)

            // Save button
            Button {
                Task { await saveGuest() }
            } label: {
                if isSaving {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Saving...")
                    }
                } else {
                    Text("Save Changes")
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.55, blue: 0.65),
                                Color(red: 0.75, green: 0.55, blue: 0.55)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(red: 0.95, green: 0.55, blue: 0.65).opacity(0.4), radius: 8, y: 4)
            )
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .disabled(isSaving || firstName.isEmpty || lastName.isEmpty)
            .opacity(isSaving || firstName.isEmpty || lastName.isEmpty ? 0.6 : 1.0)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Helper Views

    private func cardHeader(icon: String, title: String, iconColor: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
        }
    }

    private var pinkCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.95).opacity(0.7),
                        Color(red: 0.98, green: 0.92, blue: 0.90).opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
    }

    private var greenCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.98, blue: 0.95).opacity(0.7),
                        Color(red: 0.88, green: 0.95, blue: 0.92).opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
    }

    private var neutralCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
    }

    private var rsvpStatusTextColor: Color {
        switch rsvpStatus {
        case .attending, .confirmed:
            return Color(red: 0.2, green: 0.55, blue: 0.35)
        case .declined:
            return Color(red: 0.7, green: 0.25, blue: 0.25)
        case .maybe:
            return Color(red: 0.6, green: 0.45, blue: 0.15)
        default:
            return Color.gray
        }
    }

    private var rsvpStatusBackgroundColor: Color {
        switch rsvpStatus {
        case .attending, .confirmed:
            return Color(red: 0.85, green: 0.95, blue: 0.88)
        case .declined:
            return Color(red: 0.98, green: 0.88, blue: 0.88)
        case .maybe:
            return Color(red: 0.98, green: 0.95, blue: 0.85)
        default:
            return Color.gray.opacity(0.15)
        }
    }

    // MARK: - Actions

    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(size: CGSize(width: 128, height: 128))
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials fallback
        }
    }

    @MainActor
    private func saveGuest() async {
        isSaving = true
        defer { isSaving = false }

        var updatedGuest = guest
        updatedGuest.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.email = email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.phone = phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.relationshipToCouple = relationshipToCouple.isEmpty ? nil : relationshipToCouple.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.invitedBy = invitedBy
        updatedGuest.rsvpStatus = rsvpStatus
        updatedGuest.isWeddingParty = isWeddingParty
        updatedGuest.weddingPartyRole = weddingPartyRole.isEmpty ? nil : weddingPartyRole.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.attendingCeremony = attendingCeremony
        updatedGuest.attendingReception = attendingReception
        updatedGuest.attendingRehearsal = attendingRehearsal
        updatedGuest.plusOneAllowed = plusOneAllowed
        updatedGuest.plusOneName = plusOneName.isEmpty ? nil : plusOneName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.plusOneAttending = plusOneAttending
        updatedGuest.notes = notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.accessibilityNeeds = accessibilityNeeds.isEmpty ? nil : accessibilityNeeds.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.preferredContactMethod = preferredContactMethod
        updatedGuest.addressLine1 = addressLine1.isEmpty ? nil : addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.addressLine2 = addressLine2.isEmpty ? nil : addressLine2.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.city = city.isEmpty ? nil : city.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.state = state.isEmpty ? nil : state.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.zipCode = zipCode.isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.country = country.isEmpty ? nil : country.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.mealOption = mealOption.isEmpty ? nil : mealOption.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.dietaryRestrictions = dietaryRestrictions.isEmpty ? nil : dietaryRestrictions.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.giftReceived = giftReceived
        updatedGuest.tableAssignment = tableAssignment
        updatedGuest.seatNumber = seatNumber
        updatedGuest.hairDone = hairDone
        updatedGuest.makeupDone = makeupDone
        updatedGuest.preparationNotes = preparationNotes.isEmpty ? nil : preparationNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGuest.updatedAt = Date()

        await guestStore.updateGuest(updatedGuest)
        onSave(updatedGuest)
        dismiss()
    }
}

// MARK: - History Filter

enum HistoryFilter: String, CaseIterable {
    case all
    case rsvp
    case updates
    case messages

    var displayName: String {
        switch self {
        case .all: return "All"
        case .rsvp: return "RSVP"
        case .updates: return "Updates"
        case .messages: return "Messages"
        }
    }
}

// MARK: - History Timeline Item

struct HistoryTimelineItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let date: Date
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Timeline connector
            VStack(spacing: 0) {
                // Top line (hidden for first item)
                Rectangle()
                    .fill(isFirst ? Color.clear : Color.gray.opacity(0.2))
                    .frame(width: 2, height: 12)

                // Icon circle
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(iconColor)
                }

                // Bottom line (hidden for last item)
                Rectangle()
                    .fill(isLast ? Color.clear : Color.gray.opacity(0.2))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)

                Text(formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(Color.gray.opacity(0.7))
            }
            .padding(.vertical, Spacing.sm)

            Spacer()
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Edit Guest Modal - Full Details") {
    EditGuestModal(
        guest: Guest(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date().addingTimeInterval(-86400 * 2),
            firstName: "Sarah",
            lastName: "Jenkins",
            email: "sarah.j@example.com",
            phone: "(555) 123-4567",
            guestGroupId: nil,
            relationshipToCouple: "Cousin (Bride)",
            invitedBy: .bride1,
            rsvpStatus: .confirmed,
            rsvpDate: Date().addingTimeInterval(-86400 * 7),
            plusOneAllowed: true,
            plusOneName: "Michael Smith",
            plusOneAttending: true,
            attendingCeremony: true,
            attendingReception: true,
            attendingRehearsal: false,
            attendingOtherEvents: nil,
            dietaryRestrictions: "Gluten-free preferred. No peanuts.",
            accessibilityNeeds: nil,
            tableAssignment: 5,
            seatNumber: 3,
            preferredContactMethod: .email,
            addressLine1: "123 Maple Street",
            addressLine2: "Apt 4B",
            city: "Springfield",
            state: "IL",
            zipCode: "62704",
            country: "USA",
            invitationNumber: "INV-001",
            isWeddingParty: true,
            weddingPartyRole: "Bridesmaid",
            preparationNotes: nil,
            coupleId: UUID(),
            mealOption: "Chicken Piccata",
            giftReceived: true,
            notes: "So excited to celebrate with you both!",
            hairDone: true,
            makeupDone: false
        ),
        guestStore: GuestStoreV2(),
        onSave: { _ in },
        onDelete: {}
    )
    .environmentObject(SettingsStoreV2())
    .environmentObject(AppCoordinator.shared)
}

#Preview("Edit Guest Modal - Minimal") {
    EditGuestModal(
        guest: Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "John",
            lastName: "Smith",
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
        guestStore: GuestStoreV2(),
        onSave: { _ in }
    )
    .environmentObject(SettingsStoreV2())
    .environmentObject(AppCoordinator.shared)
}
