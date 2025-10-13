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
                        case 0: overviewTab
                        case 1: contactTab
                        case 2: eventDetailsTab
                        case 3: preferencesTab
                        case 4: notesTab
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

    // MARK: - Tab Content

    private var overviewTab: some View {
        VStack(spacing: Spacing.xxxl) {
            // Quick Actions Toolbar
            QuickActionsToolbar(actions: quickActions)

            // Quick Info Cards
            QuickInfoSection(guest: guest)
        }
    }

    private var quickActions: [QuickAction] {
        var actions: [QuickAction] = []

        // Call action
        if let phone = guest.phone {
            actions.append(QuickAction(icon: "phone.fill", title: "Call", color: .green) {
                if let url = URL(string: "tel:\(phone.filter { !$0.isWhitespace && $0 != "-" && $0 != "(" && $0 != ")" })") {
                    NSWorkspace.shared.open(url)
                }
            })
        }

        // Email action
        if let email = guest.email {
            actions.append(QuickAction(icon: "envelope.fill", title: "Email", color: .blue) {
                if let url = URL(string: "mailto:\(email)") {
                    NSWorkspace.shared.open(url)
                }
            })
        }

        // Edit action
        actions.append(QuickAction(icon: "pencil", title: "Edit", color: AppColors.primary) {
            showingEditSheet = true
        })

        return actions
    }

    private var contactTab: some View {
        VStack(spacing: Spacing.xxxl) {
            if hasContactInfo {
                VisualContactSection(guest: guest)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "envelope.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Contact Information")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Add email, phone, or address to this guest's profile.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }

    private var eventDetailsTab: some View {
        VStack(spacing: Spacing.xxxl) {
            // Event Details
            VisualEventDetailsSection(guest: guest)
        }
    }

    private var preferencesTab: some View {
        VStack(spacing: Spacing.xxxl) {
            if hasMealOrDietary {
                VisualPreferencesSection(guest: guest)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Preferences Set")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Add meal preferences and dietary restrictions for this guest.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }

    private var notesTab: some View {
        VStack(spacing: Spacing.xxxl) {
            if let notes = guest.notes, !notes.isEmpty {
                VisualNotesSection(notes: notes)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Notes")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Add notes to keep track of important details about this guest.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }

    // MARK: - Computed Properties

    private var hasContactInfo: Bool {
        guest.email != nil || guest.phone != nil || guest.addressLine1 != nil
    }

    private var hasMealOrDietary: Bool {
        (guest.mealOption != nil && !guest.mealOption!.isEmpty) ||
        (guest.dietaryRestrictions != nil && !guest.dietaryRestrictions!.isEmpty)
    }
}

// MARK: - Hero Header

struct HeroHeaderView: View {
    let guest: Guest
    var onEdit: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [
                    guest.rsvpStatus.color.opacity(0.3),
                    guest.rsvpStatus.color.opacity(0.1),
                    AppColors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)

            // Decorative pattern overlay
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height: CGFloat = 280

                    // Diagonal lines pattern
                    for i in stride(from: -100, to: Int(width) + 100, by: 30) {
                        path.move(to: CGPoint(x: CGFloat(i), y: 0))
                        path.addLine(to: CGPoint(x: CGFloat(i) + 100, y: height))
                    }
                }
                .stroke(guest.rsvpStatus.color.opacity(0.05), lineWidth: 1)
            }
            .frame(height: 280)

            // Profile content
            VStack(spacing: Spacing.lg) {
                // Avatar with decorative ring
                ZStack {
                    // Outer decorative ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    guest.rsvpStatus.color.opacity(0.5),
                                    guest.rsvpStatus.color.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 128, height: 128)

                    // Avatar circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    guest.rsvpStatus.color.opacity(0.3),
                                    guest.rsvpStatus.color.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(guest.initials)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(guest.rsvpStatus.color)
                        )
                        .shadow(color: guest.rsvpStatus.color.opacity(0.3), radius: 15, y: 5)
                }

                // Name and status
                VStack(spacing: Spacing.sm) {
                    Text(guest.fullName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        Image(systemName: guest.rsvpStatus.iconName)
                            .font(.caption)
                        Text(guest.rsvpStatus.displayName)
                            .font(Typography.subheading)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        Capsule()
                            .fill(guest.rsvpStatus.color.opacity(0.15))
                    )
                    .foregroundColor(guest.rsvpStatus.color)
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .overlay(alignment: .topTrailing) {
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 36, height: 36)
                        )
                }
                .buttonStyle(.plain)
                .padding()
            }
        }
    }
}

// MARK: - Quick Info Section

struct QuickInfoSection: View {
    let guest: Guest
    @EnvironmentObject var settingsStore: SettingsStoreV2

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Quick Info",
                icon: "info.circle.fill",
                color: .blue
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: Spacing.md
            ) {
                if let invitedBy = guest.invitedBy {
                    QuickInfoCard(
                        icon: "person.2.fill",
                        title: "Invited By",
                        value: invitedBy.displayName(with: settingsStore.settings),
                        color: .purple
                    )
                }

                if let invitationNumber = guest.invitationNumber {
                    QuickInfoCard(
                        icon: "number",
                        title: "Invitation",
                        value: "#\(invitationNumber)",
                        color: .orange
                    )
                }

                if let table = guest.tableAssignment {
                    QuickInfoCard(
                        icon: "tablecells",
                        title: "Table",
                        value: "\(table)",
                        color: .cyan
                    )
                }

                QuickInfoCard(
                    icon: guest.plusOneAllowed ? "person.badge.plus" : "person",
                    title: "Plus One",
                    value: guest.plusOneAllowed ? "Yes" : "No",
                    color: guest.plusOneAllowed ? .green : .gray
                )
            }
        }
    }
}

struct QuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(Typography.numberMedium)
                .foregroundColor(AppColors.textPrimary)

            Text(title)
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Visual Contact Section

struct VisualContactSection: View {
    let guest: Guest

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Contact",
                icon: "envelope.circle.fill",
                color: .blue
            )

            VStack(spacing: Spacing.sm) {
                if let email = guest.email {
                    GuestContactRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: email,
                        color: .blue
                    )
                }

                if let phone = guest.phone {
                    GuestContactRow(
                        icon: "phone.fill",
                        label: "Phone",
                        value: phone,
                        color: .green
                    )
                }

                if let addressLine1 = guest.addressLine1 {
                    let fullAddress = [
                        addressLine1,
                        guest.addressLine2,
                        guest.city,
                        guest.state,
                        guest.zipCode
                    ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")

                    GuestContactRow(
                        icon: "mappin.circle.fill",
                        label: "Address",
                        value: fullAddress,
                        color: .red
                    )
                }
            }
        }
    }
}

struct GuestContactRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(value)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
    }
}

// MARK: - Visual Event Details Section

struct VisualEventDetailsSection: View {
    let guest: Guest

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Event Details",
                icon: "calendar.circle.fill",
                color: .purple
            )

            VStack(spacing: Spacing.sm) {
                EventDetailCard(
                    icon: "music.note.house.fill",
                    title: "Ceremony",
                    value: guest.attendingCeremony ? "Attending" : "Not Attending",
                    color: guest.attendingCeremony ? .green : .gray
                )

                EventDetailCard(
                    icon: "party.popper.fill",
                    title: "Reception",
                    value: guest.attendingReception ? "Attending" : "Not Attending",
                    color: guest.attendingReception ? .green : .gray
                )

                if guest.isWeddingParty {
                    EventDetailCard(
                        icon: "star.circle.fill",
                        title: "Wedding Party",
                        value: guest.weddingPartyRole ?? "Member",
                        color: .yellow
                    )
                }
            }
        }
    }
}

struct EventDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)

                Text(value)
                    .font(Typography.caption)
                    .foregroundColor(color)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(color)
                .font(.title3)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
    }
}

// MARK: - Visual Preferences Section

struct VisualPreferencesSection: View {
    let guest: Guest

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Preferences",
                icon: "fork.knife.circle.fill",
                color: .brown
            )

            VStack(spacing: Spacing.sm) {
                if let mealOption = guest.mealOption, !mealOption.isEmpty {
                    PreferenceCard(
                        icon: "fork.knife",
                        title: "Meal Choice",
                        value: mealOption,
                        color: .brown
                    )
                }

                if let dietary = guest.dietaryRestrictions, !dietary.isEmpty {
                    PreferenceCard(
                        icon: "leaf.fill",
                        title: "Dietary Restrictions",
                        value: dietary,
                        color: .green
                    )
                }
            }
        }
    }
}

struct PreferenceCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text(value)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(color.opacity(0.1))
                )
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
    }
}

// MARK: - Visual Notes Section

struct VisualNotesSection: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Notes",
                icon: "note.text",
                color: .gray
            )

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(notes)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(AppColors.cardBackground)
                    .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Section Header V2

struct SectionHeaderV2: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            // Decorative line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 100, height: 2)
        }
        .padding(.bottom, Spacing.sm)
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
    .environmentObject(SettingsViewModel())
}

// MARK: - Edit Guest Sheet

struct EditGuestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var guestStore = GuestStoreV2()
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
