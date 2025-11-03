//
//  GuestDetailViewV4.swift
//  I Do Blueprint
//
//  Modern modal guest detail view with gradient header
//

// swiftlint:disable file_length

import SwiftUI

struct GuestDetailViewV4: View {
    let guestId: UUID
    @ObservedObject var guestStore: GuestStoreV2
    @State private var avatarImage: NSImage?
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

    private var invitedByText: String {
        guard let invitedBy = guest?.invitedBy else { return "Unknown" }
        return invitedBy.displayName(with: settings)
    }

    private var relationshipText: String {
        guard let relationship = guest?.relationshipToCouple else { return "Guest" }
        return relationship
    }

    private var hasAddress: Bool {
        guard let guest = guest else { return false }
        return guest.addressLine1 != nil || guest.city != nil || guest.state != nil
    }

    private var shouldShowAdditionalDetails: Bool {
        guard let guest = guest else { return false }
        return guest.preferredContactMethod != nil || guest.invitationNumber != nil || guest.giftReceived ||
        guest.isWeddingParty || guest.tableAssignment != nil || guest.seatNumber != nil
    }

    // MARK: - Status Row

    @ViewBuilder
    private var statusRow: some View {
        if let guest = guest {
            HStack(spacing: Spacing.xxxl) {
                // RSVP Status
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("RSVP Status")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)

                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(statusColor(for: guest.rsvpStatus))
                            .frame(width: 8, height: 8)

                        Text(guest.rsvpStatus.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(statusTextColor(for: guest.rsvpStatus))
                    }
                }

                Spacer()

                // Meal Choice
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Meal Choice")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)

                    Text(guest.mealOption ?? "Not selected")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
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
                        headerSection

                        // Content Section
                        ScrollView {
                            VStack(alignment: .leading, spacing: Spacing.xl) {
                                // Contact Information
                                contactSection

                                // RSVP Status and Meal Choice Row
                                statusRow

                                // Dietary Restrictions
                                if let restrictions = guest.dietaryRestrictions, !restrictions.isEmpty {
                                    dietarySection(restrictions)
                                }

                                // Event Attendance
                                eventAttendanceSection

                                // Address Information
                                if hasAddress {
                                    addressSection
                                }

                                // Notes
                                if let notes = guest.notes, !notes.isEmpty {
                                    notesSection(notes)
                                }

                                // Additional Details (collapsed at bottom)
                                if shouldShowAdditionalDetails {
                                    Divider()
                                    additionalDetailsSection
                                }
                            }
                            .padding(Spacing.xl)
                        }

                        // Action Buttons
                        actionButtons
                    }
                    .frame(width: 600, height: 700)
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

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        if let guest = guest {
            ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    AppColors.error.opacity(0.9),
                    AppColors.error
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: Spacing.md) {
                // Close Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(AppColors.textPrimary.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)

                // Avatar with Multiavatar
                Group {
                    if let image = avatarImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AppColors.textPrimary.opacity(0.3), lineWidth: 2)
                            )
                    } else {
                        Circle()
                            .fill(AppColors.textPrimary.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                            )
                    }
                }
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")

                // Name
                Text(guest.fullName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                // Relationship
                Text("\(invitedByText) • \(relationshipText)")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary.opacity(0.9))

                Spacer()
            }
        }
            .frame(height: 200)
            .cornerRadius(CornerRadius.lg, corners: [.topLeft, .topRight])
        }
    }

    // MARK: - Contact Section

    @ViewBuilder
    private var contactSection: some View {
        if let guest = guest {
        VStack(spacing: Spacing.md) {
            // Email
            if let email = guest.email {
                    GuestDetailContactRow(
                        icon: "envelope.fill",
                        iconColor: AppColors.errorLight,
                        label: "Email",
                        value: email
                    )
            }

            // Phone
            if let phone = guest.phone {
                    GuestDetailContactRow(
                        icon: "phone.fill",
                        iconColor: AppColors.errorLight,
                        label: "Phone",
                        value: phone
                    )
            }

            // Plus One
            if guest.plusOneAllowed {
                    GuestDetailContactRow(
                        icon: "person.2.fill",
                        iconColor: AppColors.errorLight,
                        label: "Plus One",
                        value: guest.plusOneName ?? "Not specified"
                    )
            }
        }
        }
    }

    // MARK: - Dietary Section

    private func dietarySection(_ restrictions: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Dietary Restrictions")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            // Parse restrictions and create badges
            HStack(spacing: Spacing.sm) {
                ForEach(parseRestrictions(restrictions), id: \.self) { restriction in
                    DietaryBadge(text: restriction)
                }
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Notes")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            Text(notes)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Event Attendance Section

    @ViewBuilder
    private var eventAttendanceSection: some View {
        if let guest = guest {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Event Attendance")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: Spacing.xxxl) {
                    AttendanceItem(
                        label: "Ceremony",
                        isAttending: guest.attendingCeremony
                    )

                    AttendanceItem(
                        label: "Reception",
                        isAttending: guest.attendingReception
                    )
                }
            }
        }
    }

    // MARK: - Address Section

    @ViewBuilder
    private var addressSection: some View {
        if let guest = guest {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Address")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let address1 = guest.addressLine1 {
                        Text(address1)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                    }

                    if let address2 = guest.addressLine2 {
                        Text(address2)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                    }

                    HStack(spacing: Spacing.xs) {
                        if let city = guest.city {
                            Text(city)
                        }
                        if let state = guest.state {
                            Text(", \(state)")
                        }
                        if let zip = guest.zipCode {
                            Text(zip)
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)

                    if let country = guest.country {
                        Text(country)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Wedding Party Section

    @ViewBuilder
    private var weddingPartySection: some View {
        if let guest = guest {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Wedding Party")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                if let role = guest.weddingPartyRole {
                    DetailItem(label: "Role", value: role)
                }

                if let prepNotes = guest.preparationNotes, !prepNotes.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Preparation Notes")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        Text(prepNotes)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                HStack(spacing: Spacing.xl) {
                    if guest.hairDone {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.success)
                            Text("Hair Done")
                                .font(.system(size: 14))
                        }
                    }

                    if guest.makeupDone {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.success)
                            Text("Makeup Done")
                                .font(.system(size: 14))
                        }
                    }
                }
            }
            .padding(Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Dietary & Accessibility Section

    @ViewBuilder
    private var dietaryAccessibilitySection: some View {
        if let guest = guest {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if let restrictions = guest.dietaryRestrictions, !restrictions.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Dietary Restrictions")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        GuestDetailFlowLayout(spacing: Spacing.sm) {
                            ForEach(parseRestrictions(restrictions), id: \.self) { restriction in
                                DietaryBadge(text: restriction)
                            }
                        }
                    }
                }

                if let accessibility = guest.accessibilityNeeds, !accessibility.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Accessibility Needs")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        Text(accessibility)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Additional Details Section

    @ViewBuilder
    private var additionalDetailsSection: some View {
        if let guest = guest {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Additional Details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                VStack(spacing: Spacing.sm) {
                    if let contactMethod = guest.preferredContactMethod {
                        DetailItem(label: "Preferred Contact", value: contactMethod.rawValue.capitalized)
                    }

                    if let invitationNum = guest.invitationNumber {
                        DetailItem(label: "Invitation #", value: invitationNum)
                    }

                    if guest.giftReceived {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "gift.fill")
                                .foregroundColor(AppColors.success)
                            Text("Gift Received")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                }
            }
            .padding(Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            // Edit Button
            Button {
                showingEditSheet = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "pencil")
                    Text("Edit Guest")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(AppColors.primary)
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)

            // Delete Button
            Button {
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(AppColors.error)
                    .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Helper Functions

    private func statusColor(for status: RSVPStatus) -> Color {
        switch status {
        case .confirmed, .attending:
            return AppColors.success
        case .pending, .invited, .maybe:
            return AppColors.warning
        case .declined:
            return AppColors.error
        default:
            return AppColors.textSecondary
        }
    }

    private func statusTextColor(for status: RSVPStatus) -> Color {
        switch status {
        case .confirmed, .attending:
            return AppColors.success
        case .pending, .invited, .maybe:
            return AppColors.warning
        case .declined:
            return AppColors.error
        default:
            return AppColors.textSecondary
        }
    }

    private func parseRestrictions(_ restrictions: String) -> [String] {
        // Split by common delimiters
        let separators = CharacterSet(charactersIn: ",;")
        return restrictions.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        guard let guest = guest else { return }

        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 160, height: 160) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials
            // Error already logged by MultiAvatarJSService
        }
    }
}

// MARK: - Supporting Views

private struct GuestDetailContactRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Circle()
                .fill(iconColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.error)
                )

            // Label and Value
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)

                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
        }
    }
}

private struct DietaryBadge: View {
    let text: String

    private var badgeColor: (background: Color, text: Color) {
        // Alternate colors for variety
let colors: [(Color, Color)] = [
            (AppColors.warningLight, AppColors.warning),
            (AppColors.infoLight, AppColors.info)
        ]
        let index = abs(text.hashValue) % colors.count
        return (colors[index].0, colors[index].1)
    }

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(badgeColor.text)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(badgeColor.background)
            .cornerRadius(CornerRadius.pill)
    }
}

private struct AttendanceItem: View {
    let label: String
    let isAttending: Bool

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: isAttending ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(isAttending ? AppColors.success : AppColors.textTertiary)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

private struct DetailItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

private struct GuestDetailFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int

    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)

    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0

        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
                    radius: topRight,
                    startAngle: Angle(degrees: -90),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
                    radius: bottomRight,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 90),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
                    radius: bottomLeft,
                    startAngle: Angle(degrees: 90),
                    endAngle: Angle(degrees: 180),
                    clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
                    radius: topLeft,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 270),
                    clockwise: false)

        return path
    }
}

#Preview {
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
        attendingOtherEvents: nil,
        dietaryRestrictions: "Vegetarian, Gluten-Free",
        accessibilityNeeds: nil,
        tableAssignment: 5,
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
        mealOption: "Vegetarian",
        giftReceived: false,
        notes: "Sarah requested a seat near the bridal party table. She's also volunteering to help with decorations on the wedding morning.",
        hairDone: false,
        makeupDone: false
    )

    let store = GuestStoreV2()
    // Note: In preview, the guest won't be in the store, so the modal will dismiss immediately
    // For a working preview, you'd need to add the guest to the store first

    return GuestDetailViewV4(
        guestId: testGuest.id,
        guestStore: store
    )
    .environmentObject(SettingsStoreV2())
    .environmentObject(AppCoordinator.shared)
}
