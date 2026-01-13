//
//  GuestDetailHeader.swift
//  I Do Blueprint
//
//  Glassmorphism header with avatar for guest detail modal
//  Uses frosted glass effect matching V7 dashboard design
//

import SwiftUI

struct GuestDetailHeader: View {
    let guest: Guest
    let settings: CoupleSettings
    let onDismiss: () -> Void

    @State private var avatarImage: NSImage?

    private var invitedByText: String {
        guard let invitedBy = guest.invitedBy else { return "Unknown" }
        return invitedBy.displayName(with: settings)
    }

    private var relationshipText: String {
        guest.relationshipToCouple ?? "Guest"
    }

    // Generate a consistent color based on guest name (matches GuestCardV4 pattern)
    private var avatarColor: Color {
        let colors: [Color] = [
            AppGradients.weddingPink,
            AppGradients.sageGreen,
            SemanticColors.primaryAction,
            Color.fromHex("9370DB"), // Purple
            Color.fromHex("E8A87C"), // Peach
            Color.fromHex("5DADE2")  // Blue
        ]
        let hash = guest.fullName.hashValue
        let index = abs(hash) % colors.count
        return colors[index]
    }

    var body: some View {
        ZStack {
            // Glassmorphism Background
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .overlay(
                    // Subtle gradient overlay for depth
                    LinearGradient(
                        colors: [
                            AppGradients.weddingPink.opacity(0.15),
                            AppGradients.sageGreen.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: Spacing.md) {
                // Close Button
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SemanticColors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.6))
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
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            )
                    } else {
                        Circle()
                            .fill(avatarColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundColor(avatarColor)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            )
                    }
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(guest.fullName)")

                // Name
                Text(guest.fullName)
                    .font(Typography.title2)
                    .foregroundColor(SemanticColors.textPrimary)

                // Relationship with status badge
                HStack(spacing: Spacing.sm) {
                    Text("\(invitedByText) • \(relationshipText)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    GuestStatusBadge(status: guest.rsvpStatus)
                }

                Spacer()
            }
        }
        .frame(height: 200)
    }
    
    // MARK: - Avatar Loading
    
    private func loadAvatar() async {
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
