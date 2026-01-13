//
//  ViewGuestModal.swift
//  I Do Blueprint
//
//  Vibrant glassmorphic View Guest modal with 3-column card layout
//  Theme-aware styling using SemanticColors and color palettes
//  All cards always shown with placeholders for empty data
//

import SwiftUI

struct ViewGuestModal: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @EnvironmentObject var coordinator: AppCoordinator

    let guest: Guest
    let onEdit: () -> Void

    // Multiavatar state (matches GuestDetailHeader, GuestCardV4 pattern)
    @State private var avatarImage: NSImage?

    // Proportional Modal Sizing Pattern
    private let minWidth: CGFloat = 820
    private let maxWidth: CGFloat = 960
    private let minHeight: CGFloat = 620
    private let maxHeight: CGFloat = 720
    private let windowChromeBuffer: CGFloat = 40
    private let widthProportion: CGFloat = 0.70
    private let heightProportion: CGFloat = 0.80

    /// Compute initials from first and last name
    private var guestInitials: String {
        let first = guest.firstName.prefix(1).uppercased()
        let last = guest.lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.001)
                .ignoresSafeArea()

            modalContent
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
            // Header
            headerSection

            // Three-column content
            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    // Column 1: Personal Info + Contact
                    VStack(spacing: Spacing.md) {
                        personalInfoCard
                        contactCard
                    }
                    .frame(maxWidth: .infinity)

                    // Column 2: Attendance + Wedding Party + Accessibility
                    VStack(spacing: Spacing.md) {
                        attendanceCard
                        weddingPartyCard
                        accessibilityCard
                    }
                    .frame(maxWidth: .infinity)

                    // Column 3: Dining + Notes
                    VStack(spacing: Spacing.md) {
                        diningCard
                        notesCard
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
            }

            // Footer
            footerSection
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .background(
            ZStack {
                // Native macOS vibrancy - provides true translucent blur effect
                VisualEffectBackground(
                    material: .popover,
                    blendingMode: .behindWindow,
                    state: .active
                )

                // Subtle theme-aware gradient overlay
                LinearGradient(
                    colors: [
                        SemanticColors.primaryAction.opacity(0.06),
                        SemanticColors.secondaryAction.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: Spacing.lg) {
            // Avatar with Multiavatar (matches GuestDetailHeader, GuestCardV4 pattern)
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
                    // Fallback: Theme-aware gradient circle with initials
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        SemanticColors.primaryAction,
                                        SemanticColors.primaryAction.opacity(0.7)
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
            .accessibilityLabel("Avatar for \(guest.fullName)")

            // Name and details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(guest.fullName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(SemanticColors.textPrimary)

                HStack(spacing: Spacing.md) {
                    // Status badge
                    statusBadge

                    // Invited by
                    if let invitedBy = guest.invitedBy {
                        Text("Invited by \(invitedBy.displayName(with: settingsStore.settings))")
                            .font(.system(size: 13))
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
            }

            Spacer()

            // Close button (X)
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(SemanticColors.backgroundSecondary.opacity(0.6))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.md)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: guest.rsvpStatus.icon)
                .font(.system(size: 10))
            Text(guest.rsvpStatus.displayName)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(statusTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(statusBackgroundColor)
        )
    }

    private var statusTextColor: Color {
        switch guest.rsvpStatus {
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

    private var statusBackgroundColor: Color {
        switch guest.rsvpStatus {
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

    // MARK: - Personal Info Card

    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            cardHeader(icon: "person.fill", title: "Personal Info", iconColor: SemanticColors.primaryAction)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                ViewGuestInfoRow(label: "Name", value: guest.fullName)
                ViewGuestInfoRow(
                    label: "Relation",
                    value: guest.relationshipToCouple,
                    placeholder: "Not specified",
                    valueColor: guest.relationshipToCouple != nil ? SemanticColors.primaryAction : nil
                )
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(style: .primary))
    }

    // MARK: - Contact Card

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            cardHeader(icon: "rectangle.stack.person.crop.fill", title: "Contact", iconColor: SemanticColors.secondaryAction)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Email
                ViewGuestContactRow(
                    icon: "envelope.fill",
                    label: "Email",
                    value: guest.email,
                    placeholder: "Not provided"
                )

                // Phone
                ViewGuestContactRow(
                    icon: "phone.fill",
                    label: "Phone",
                    value: guest.phone,
                    placeholder: "Not provided"
                )

                // Address
                ViewGuestContactRow(
                    icon: "mappin.circle.fill",
                    label: "Address",
                    value: hasAddress ? formattedAddress : nil,
                    placeholder: "Not provided"
                )
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(style: .neutral))
    }

    private var hasAddress: Bool {
        [guest.addressLine1, guest.city, guest.state, guest.zipCode].compactMap { $0 }.filter { !$0.isEmpty }.count > 0
    }

    private var formattedAddress: String {
        var parts: [String] = []
        if let line1 = guest.addressLine1, !line1.isEmpty { parts.append(line1) }
        if let line2 = guest.addressLine2, !line2.isEmpty { parts.append(line2) }

        var cityStateZip: [String] = []
        if let city = guest.city, !city.isEmpty { cityStateZip.append(city) }
        if let state = guest.state, !state.isEmpty { cityStateZip.append(state) }
        if let zip = guest.zipCode, !zip.isEmpty { cityStateZip.append(zip) }
        if !cityStateZip.isEmpty { parts.append(cityStateZip.joined(separator: ", ")) }

        if let country = guest.country, !country.isEmpty && country != "USA" { parts.append(country) }

        return parts.joined(separator: "\n")
    }

    // MARK: - Attendance Card

    private var attendanceCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            cardHeader(icon: "calendar.badge.checkmark", title: "Attendance", iconColor: SemanticColors.statusSuccess)

            // Event pills
            HStack(spacing: Spacing.sm) {
                AttendancePill(label: "Ceremony", isAttending: guest.attendingCeremony)
                AttendancePill(label: "Reception", isAttending: guest.attendingReception)
            }

            // Rehearsal (show even if not attending)
            AttendancePill(label: "Rehearsal", isAttending: guest.attendingRehearsal)

            // Plus One section
            Divider()
                .padding(.vertical, Spacing.xs)

            HStack(spacing: Spacing.sm) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Plus One")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SemanticColors.textSecondary)

                    if guest.plusOneAllowed {
                        Text(guest.plusOneName ?? "Not specified")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textPrimary)
                    } else {
                        Text("Not allowed")
                            .font(.system(size: 14))
                            .foregroundColor(SemanticColors.textSecondary.opacity(0.7))
                            .italic()
                    }
                }

                Spacer()

                if guest.plusOneAllowed && guest.plusOneAttending {
                    Text("Attending")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SemanticColors.statusSuccess)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(SemanticColors.statusSuccess.opacity(0.15))
                        )
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(style: .success))
    }

    // MARK: - Wedding Party Card

    private var weddingPartyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            cardHeader(icon: "crown.fill", title: "Wedding Party", iconColor: SemanticColors.statusWarning)

            if guest.isWeddingParty {
                // Role
                VStack(alignment: .leading, spacing: 4) {
                    Text("Role")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SemanticColors.textSecondary)
                    Text(guest.weddingPartyRole ?? "Not specified")
                        .font(.system(size: 14))
                        .foregroundColor(guest.weddingPartyRole != nil ? SemanticColors.primaryAction : SemanticColors.textSecondary.opacity(0.7))
                        .italic(guest.weddingPartyRole == nil)
                }

                // Hair & Makeup status
                HStack(spacing: Spacing.lg) {
                    HairMakeupPill(label: "Hair", icon: "scissors", isDone: guest.hairDone)
                    HairMakeupPill(label: "Makeup", icon: "paintbrush.fill", isDone: guest.makeupDone)
                }

                // Prep Notes
                if let prepNotes = guest.preparationNotes, !prepNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prep Notes")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SemanticColors.textSecondary)
                        Text(prepNotes)
                            .font(.system(size: 13))
                            .foregroundColor(SemanticColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                // Not in wedding party placeholder
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textSecondary.opacity(0.6))
                    Text("Not in wedding party")
                        .font(.system(size: 13))
                        .foregroundColor(SemanticColors.textSecondary.opacity(0.7))
                        .italic()
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(style: .warning))
    }

    // MARK: - Accessibility Card

    private var accessibilityCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            cardHeader(icon: "figure.roll", title: "Accessibility", iconColor: SemanticColors.secondaryAction)

            if let needs = guest.accessibilityNeeds, !needs.isEmpty {
                Text(needs)
                    .font(.system(size: 13))
                    .foregroundColor(SemanticColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // No requirements placeholder
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textSecondary.opacity(0.6))
                    Text("No requirements")
                        .font(.system(size: 13))
                        .foregroundColor(SemanticColors.textSecondary.opacity(0.7))
                        .italic()
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(style: .secondary))
    }

    // MARK: - Dining Card

    private var diningCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            cardHeader(icon: "fork.knife", title: "Dining", iconColor: SemanticColors.textSecondary)

            // Meal Selection section header
            Text("Meal Selection")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SemanticColors.textSecondary)

            // Meal option pill
            if let mealOption = guest.mealOption, !mealOption.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(SemanticColors.statusWarning)
                    Text(mealOption)
                        .font(.system(size: 14))
                        .foregroundColor(SemanticColors.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SemanticColors.statusWarning.opacity(0.1))
                )
            } else {
                Text("Not selected")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textSecondary.opacity(0.7))
                    .italic()
            }

            // Dietary Notes section header
            Text("Dietary Notes")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SemanticColors.textSecondary)
                .padding(.top, Spacing.xs)

            // Dietary restrictions with alert styling (domain-specific - keeps warning colors)
            if let dietary = guest.dietaryRestrictions, !dietary.isEmpty {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.statusWarning)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alert")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SemanticColors.statusError)
                        Text(dietary)
                            .font(.system(size: 13))
                            .foregroundColor(SemanticColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SemanticColors.statusWarning.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(SemanticColors.statusWarning.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                Text("None specified")
                    .font(.system(size: 13))
                    .foregroundColor(SemanticColors.textSecondary.opacity(0.7))
                    .italic()
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(style: .neutral))
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            cardHeader(icon: "note.text", title: "Notes", iconColor: SemanticColors.statusWarning)

            if let notes = guest.notes, !notes.isEmpty {
                Text("\"\(notes)\"")
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(SemanticColors.textPrimary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // No notes placeholder
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "text.badge.minus")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textSecondary.opacity(0.6))
                    Text("No notes added")
                        .font(.system(size: 13))
                        .foregroundColor(SemanticColors.textSecondary.opacity(0.7))
                        .italic()
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(style: .accent))
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: Spacing.md) {
            Spacer()

            // Close button
            Button("Close") { dismiss() }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.textSecondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(SemanticColors.backgroundSecondary.opacity(0.6))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                )
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)

            // Edit Guest button - theme-aware gradient
            Button {
                dismiss()
                onEdit()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                    Text("Edit Guest")
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
                                SemanticColors.primaryAction,
                                SemanticColors.primaryAction.opacity(0.75)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: SemanticColors.primaryAction.opacity(0.4), radius: 8, y: 4)
            )
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 128, height: 128) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials fallback
            // Error already logged by MultiAvatarJSService
        }
    }

    // MARK: - Helper Views

    private func cardHeader(icon: String, title: String, iconColor: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)
        }
    }

    // Card background styles - glassmorphism with theme-aware color tints
    private enum CardBackgroundStyle {
        case primary    // Uses theme's primary color (pink for blush, sage for sage-serenity, etc.)
        case secondary  // Uses theme's secondary color
        case success    // Uses success/green tones
        case warning    // Uses warning/gold tones
        case accent     // Uses a complementary accent
        case neutral    // Neutral frosted glass
    }

    @ViewBuilder
    private func cardBackground(style: CardBackgroundStyle) -> some View {
        switch style {
        case .primary:
            // Glassmorphism with theme primary color tint
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    SemanticColors.primaryAction.opacity(0.08),
                                    SemanticColors.primaryAction.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(SemanticColors.primaryAction.opacity(0.15), lineWidth: 1)
                )
        case .secondary:
            // Glassmorphism with theme secondary color tint
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    SemanticColors.secondaryAction.opacity(0.08),
                                    SemanticColors.secondaryAction.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(SemanticColors.secondaryAction.opacity(0.15), lineWidth: 1)
                )
        case .success:
            // Glassmorphism with success/green tint
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    SemanticColors.statusSuccess.opacity(0.08),
                                    SemanticColors.statusSuccess.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(SemanticColors.statusSuccess.opacity(0.15), lineWidth: 1)
                )
        case .warning:
            // Glassmorphism with warning/gold tint
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    SemanticColors.statusWarning.opacity(0.08),
                                    SemanticColors.statusWarning.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(SemanticColors.statusWarning.opacity(0.15), lineWidth: 1)
                )
        case .accent:
            // Glassmorphism with complementary accent tint
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    SemanticColors.primaryAction.opacity(0.05),
                                    SemanticColors.secondaryAction.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        case .neutral:
            // Pure glassmorphism with subtle white tint
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Supporting Components

struct ViewGuestInfoRow: View {
    let label: String
    let value: String?
    var placeholder: String = "Not specified"
    var valueColor: Color? = nil

    init(label: String, value: String) {
        self.label = label
        self.value = value
        self.placeholder = "Not specified"
        self.valueColor = nil
    }

    init(label: String, value: String?, placeholder: String = "Not specified", valueColor: Color? = nil) {
        self.label = label
        self.value = value
        self.placeholder = placeholder
        self.valueColor = valueColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 60, alignment: .leading)

            if let value = value, !value.isEmpty {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(valueColor ?? SemanticColors.textPrimary)
            } else {
                Text(placeholder)
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.textSecondary.opacity(0.7))
                    .italic()
            }
        }
    }
}

struct ViewGuestContactRow: View {
    let icon: String
    let label: String
    let value: String?
    var placeholder: String = "Not provided"

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(value != nil ? SemanticColors.secondaryAction : SemanticColors.textSecondary.opacity(0.5))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .tracking(0.3)

                if let value = value, !value.isEmpty {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundColor(SemanticColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(placeholder)
                        .font(.system(size: 13))
                        .foregroundColor(SemanticColors.textSecondary.opacity(0.7))
                        .italic()
                }
            }
        }
    }
}

struct AttendancePill: View {
    let label: String
    let isAttending: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isAttending ? "checkmark" : "xmark")
                .font(.system(size: 10, weight: .medium))
            Text(label)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(isAttending ? SemanticColors.statusSuccess : SemanticColors.textSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isAttending ? SemanticColors.statusSuccess.opacity(0.12) : SemanticColors.textSecondary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isAttending ? SemanticColors.statusSuccess.opacity(0.3) : SemanticColors.textSecondary.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

struct HairMakeupPill: View {
    let label: String
    let icon: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 12))
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))
        }
        .foregroundColor(isDone ? SemanticColors.statusSuccess : SemanticColors.primaryAction.opacity(0.7))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(isDone ? SemanticColors.statusSuccess.opacity(0.12) : SemanticColors.primaryAction.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview("View Guest - Full Details") {
    ViewGuestModal(
        guest: Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "Sarah",
            lastName: "Jenkins",
            email: "sarah.j@example.com",
            phone: "(555) 123-4567",
            guestGroupId: nil,
            relationshipToCouple: "Cousin (Bride)",
            invitedBy: .bride1,
            rsvpStatus: .confirmed,
            rsvpDate: Date(),
            plusOneAllowed: false,
            plusOneName: nil,
            plusOneAttending: false,
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
            notes: "So excited to celebrate with you both! Might arrive a little late to the welcome dinner due to flights.",
            hairDone: true,
            makeupDone: false
        ),
        onEdit: {}
    )
    .environmentObject(SettingsStoreV2())
    .environmentObject(AppCoordinator.shared)
}

#Preview("View Guest - Minimal") {
    ViewGuestModal(
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
            invitedBy: .both,
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
        onEdit: {}
    )
    .environmentObject(SettingsStoreV2())
    .environmentObject(AppCoordinator.shared)
}
