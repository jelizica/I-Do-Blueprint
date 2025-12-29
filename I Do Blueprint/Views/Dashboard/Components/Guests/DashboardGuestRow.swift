//
//  DashboardGuestRow.swift
//  I Do Blueprint
//
//  Extracted from DashboardViewV4.swift
//  Row component displaying a single guest with avatar and RSVP status
//

import SwiftUI

struct DashboardV4GuestRow: View {
    let guest: Guest
    @State private var avatarImage: NSImage?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Avatar
            avatarView
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")

            Text(guest.fullName)
                .font(Typography.caption)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Text(statusText)
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(statusColor)
        }
    }

    private var statusText: String {
        switch guest.rsvpStatus {
        case .attending, .confirmed:
            return "Attending"
        case .declined:
            return "Declined"
        default:
            return "Pending"
        }
    }

    private var statusColor: Color {
        switch guest.rsvpStatus {
        case .attending, .confirmed:
            return AppColors.success
        case .declined:
            return AppColors.error
        default:
            return AppColors.textSecondary
        }
    }

    // MARK: - Avatar View

    @ViewBuilder
    private var avatarView: some View {
        if let image = avatarImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 24, height: 24)
                .clipShape(Circle())
        } else {
            // Fallback to initials
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 24, height: 24)
                .overlay {
                    Text(guestInitials)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(statusColor)
                }
        }
    }

    private var guestInitials: String {
        let first = guest.firstName.prefix(1).uppercased()
        let last = guest.lastName.prefix(1).uppercased()
        return first + last
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 48, height: 48) // 2x for retina
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
