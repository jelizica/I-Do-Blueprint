//
//  GuestCompactCard.swift
//  I Do Blueprint
//
//  Compact guest card for narrow windows
//  Vertical mini-card layout with avatar, name, and status circle
//

import SwiftUI

struct GuestCompactCard: View {
    let guest: Guest
    let settings: CoupleSettings
    @State private var avatarImage: NSImage?

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Avatar with Status Circle Overlay
            ZStack(alignment: .bottomTrailing) {
                // Avatar Circle (48px)
                Group {
                    if let image = avatarImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            )
                    }
                }
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")

                // Status Circle Indicator (12px)
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2) // Slight offset for prominence
                    .accessibilityLabel(statusAccessibilityLabel)
            }

            // Guest Name (centered, 2 lines max)
            Text(guest.fullName)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        // CRITICAL: Modifier order matters for preventing overflow
        // 1. First, constrain the content to max 130px
        .frame(maxWidth: 130)
        // 2. Apply visual styling to the constrained size (background uses 130px max)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.borderLight, lineWidth: 0.5)
        )
        // 3. Then allow the card to center within the grid column
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibleListItem(
            label: guest.fullName,
            hint: "Tap to view guest details",
            value: guest.rsvpStatus.displayName
        )
    }

    // MARK: - Status Color Mapping

    private var statusColor: Color {
        switch guest.rsvpStatus {
        case .attending, .confirmed:
            return AppColors.success // Green
        case .declined, .noResponse:
            return AppColors.error // Red
        case .pending, .maybe, .invited:
            return AppColors.warning // Yellow/Orange
        default:
            return AppColors.textSecondary.opacity(0.4)
        }
    }

    private var statusAccessibilityLabel: String {
        switch guest.rsvpStatus {
        case .attending, .confirmed:
            return "Attending"
        case .declined:
            return "Declined"
        case .noResponse:
            return "No response"
        case .pending, .maybe, .invited:
            return "Pending response"
        default:
            return guest.rsvpStatus.displayName
        }
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
            // Error already logged by MultiAvatarJSService
        }
    }
}
