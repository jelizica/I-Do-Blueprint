//
//  GuestCompactCard.swift
//  I Do Blueprint
//
//  Compact guest card for narrow windows
//  Horizontal layout with avatar, name, and status badge
//

import SwiftUI

struct GuestCompactCard: View {
    let guest: Guest
    let settings: CoupleSettings
    @State private var avatarImage: NSImage?

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Avatar Circle
            Group {
                if let image = avatarImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(AppColors.cardBackground)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        )
                }
            }
            .task {
                await loadAvatar()
            }
            .accessibilityLabel("Avatar for \(guest.fullName)")

            // Guest Info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(guest.fullName)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                if let email = guest.email, !email.isEmpty {
                    Text(email)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status Badge
            GuestStatusBadge(status: guest.rsvpStatus)
        }
        .padding(Spacing.md)
        .frame(height: 72)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.borderLight, lineWidth: 0.5)
        )
        .accessibleListItem(
            label: guest.fullName,
            hint: "Tap to view guest details",
            value: guest.rsvpStatus.displayName
        )
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 80, height: 80) // 2x for retina
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
