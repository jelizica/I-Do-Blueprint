//
//  ModernGuestDetailView.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct ModernGuestDetailView: View {
    let guest: Guest
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var avatarImage: NSImage?
    @State private var isLoadingAvatar = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                // Header
                VStack(spacing: Spacing.lg) {
                    // Large Avatar
                    Group {
                        if let image = avatarImage {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(guest.rsvpStatus.color.opacity(0.5), lineWidth: 3)
                                )
                                .shadow(color: guest.rsvpStatus.color.opacity(0.3), radius: 10)
                        } else {
                            // Fallback to initials
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                guest.rsvpStatus.color.opacity(0.3),
                                                guest.rsvpStatus.color.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 96, height: 96)

                                Text(guest.initials)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(guest.rsvpStatus.color)
                            }
                            .shadow(color: guest.rsvpStatus.color.opacity(0.3), radius: 10)
                        }
                    }
                    .task {
                        await loadDetailAvatar()
                    }
                    .accessibilityLabel("Avatar for \(guest.fullName)")

                    VStack(spacing: Spacing.sm) {
                        Text(guest.fullName)
                            .font(Typography.title2)
                            .fontWeight(.bold)

                        Text(guest.rsvpStatus.displayName)
                            .badge(color: guest.rsvpStatus.color, size: .large)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xxl)

                Divider()

                // Contact Information
                DetailSection(title: "Contact Information") {
                    if let email = guest.email {
                        GuestListDetailRow(
                            icon: "envelope.fill",
                            label: "Email",
                            value: email,
                            color: .blue
                        )
                    }

                    if let phone = guest.phone {
                        GuestListDetailRow(
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

                        GuestListDetailRow(
                            icon: "mappin.circle.fill",
                            label: "Address",
                            value: fullAddress,
                            color: .red
                        )
                    }
                }

                // Event Details
                DetailSection(title: "Event Details") {
                    if let invitedBy = guest.invitedBy {
                        GuestListDetailRow(
                            icon: "person.2.fill",
                            label: "Invited By",
                            value: invitedBy.displayName(with: settingsStore.settings),
                            color: .purple
                        )
                    }

                    if let invitationNumber = guest.invitationNumber {
                        GuestListDetailRow(
                            icon: "number",
                            label: "Invitation #",
                            value: "#\(invitationNumber)",
                            color: .orange
                        )
                    }

                    if let table = guest.tableAssignment {
                        GuestListDetailRow(
                            icon: "tablecells",
                            label: "Table Assignment",
                            value: "Table \(table)",
                            color: .cyan
                        )
                    }

                    GuestListDetailRow(
                        icon: guest.plusOneAllowed ? "checkmark.circle.fill" : "xmark.circle.fill",
                        label: "Plus One",
                        value: guest.plusOneAllowed ? "Allowed" : "Not Allowed",
                        color: guest.plusOneAllowed ? .green : .gray
                    )
                }

                // Meal Preferences
                if let mealOption = guest.mealOption, !mealOption.isEmpty {
                    DetailSection(title: "Meal Selection") {
                        GuestListDetailRow(
                            icon: "fork.knife",
                            label: "Choice",
                            value: mealOption,
                            color: .brown
                        )
                    }
                }

                // Dietary Restrictions
                if let dietary = guest.dietaryRestrictions, !dietary.isEmpty {
                    DetailSection(title: "Dietary Restrictions") {
                        Text(dietary)
                            .font(Typography.bodyRegular)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(AppColors.cardBackground)
                            )
                    }
                }

                // Notes
                if let notes = guest.notes, !notes.isEmpty {
                    DetailSection(title: "Notes") {
                        Text(notes)
                            .font(Typography.bodyRegular)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(AppColors.cardBackground)
                            )
                    }
                }
            }
            .padding(Spacing.xxl)
        }
        .background(AppColors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Avatar Loading
    
    private func loadDetailAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 192, height: 192) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials
            // Error already logged by MultiAvatarService
        }
    }
}
