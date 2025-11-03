//
//  ModernGuestCard.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct ModernGuestCard: View {
    let guest: Guest
    let isSelected: Bool
    @State private var isHovering = false
    @State private var avatarImage: NSImage?
    @State private var isLoadingAvatar = false

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Avatar
            Group {
                if let image = avatarImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(guest.rsvpStatus.color.opacity(0.3), lineWidth: 2)
                        )
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
                            .frame(width: 48, height: 48)

                        Text(guest.initials)
                            .font(Typography.heading)
                            .fontWeight(.semibold)
                            .foregroundColor(guest.rsvpStatus.color)
                    }
                }
            }
            .task {
                await loadAvatar()
            }
            .accessibilityLabel("Avatar for \(guest.fullName)")

            // Guest Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(guest.fullName)
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    // RSVP Badge
                    Text(guest.rsvpStatus.displayName)
                        .badge(color: guest.rsvpStatus.color, size: .small)

                    if let email = guest.email {
                        Text(email)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Metadata
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                if let invitationNumber = guest.invitationNumber {
                    Text("#\(invitationNumber)")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.info)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(AppColors.infoLight)
                        )
                }

                HStack(spacing: Spacing.sm) {
                    if guest.plusOneAllowed {
                        Label("Plus One", systemImage: "plus.circle")
                            .font(Typography.caption2)
                            .foregroundColor(AppColors.Guest.plusOne)
                    }

                    if let table = guest.tableAssignment {
                        Label("Table \(table)", systemImage: "tablecells")
                            .font(Typography.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }

            // Selection Indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary.opacity(0.5))
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(isSelected ? AppColors.primaryLight : AppColors.cardBackground)
                .shadow(
                    color: isHovering ? AppColors.shadowMedium : AppColors.shadowLight,
                    radius: isHovering ? 6 : 3,
                    x: 0,
                    y: isHovering ? 3 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    isSelected ? AppColors.primary : (isHovering ? AppColors.borderHover : AppColors.borderLight),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(AnimationStyle.fast, value: isHovering)
        .animation(AnimationStyle.fast, value: isSelected)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 96, height: 96) // 2x for retina
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
