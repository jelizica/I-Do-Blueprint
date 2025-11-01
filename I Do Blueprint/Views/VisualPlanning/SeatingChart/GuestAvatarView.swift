//
//  GuestAvatarView.swift
//  My Wedding Planning App
//
//  Avatar view for guests with Kingfisher image loading
//

import SwiftUI
import Kingfisher

struct GuestAvatarView: View {
    let guest: SeatingGuest
    let size: CGFloat
    let showName: Bool
    let showBorder: Bool

    @State private var isHovering = false

    init(
        guest: SeatingGuest,
        size: CGFloat = 40,
        showName: Bool = false,
        showBorder: Bool = true
    ) {
        self.guest = guest
        self.size = size
        self.showName = showName
        self.showBorder = showBorder
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Avatar or initials
                if let photoURL = guest.photoURL, let url = URL(string: photoURL) {
                    KFImage(url)
                        .placeholder {
                            initialsAvatar
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    initialsAvatar
                }

                // Border
                if showBorder {
                    Circle()
                        .stroke(
                            isHovering ? Color.seatingAccentTeal : AppColors.textPrimary,
                            lineWidth: isHovering ? 3 : 2
                        )
                        .frame(width: size, height: size)
                }
            }
            .overlay(alignment: .topTrailing) {
                // VIP badge
                if guest.isVIP {
                    Image(systemName: "star.fill")
                        .font(.system(size: size * 0.3))
                        .foregroundColor(.seatingGold)
                        .offset(x: size * 0.15, y: -size * 0.15)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            .scaleEffect(isHovering ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
            .popover(isPresented: .constant(isHovering && size > 30)) {
                GuestDetailsPopover(guest: guest)
            }

            // Optional name label
            if showName {
                Text("\(guest.firstName) \(guest.lastName)")
                    .font(.seatingCaption)
                    .foregroundColor(.seatingDeepNavy)
                    .lineLimit(1)
                    .frame(maxWidth: size * 2)
            }
        }
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            gradientColorForGuest.opacity(0.9),
                            gradientColorForGuest.opacity(0.6),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Text(guest.initials)
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private var gradientColorForGuest: Color {
        // Generate consistent color based on guest group or name
        if let group = guest.group {
            switch group.lowercased() {
            case "wedding party": return .groupWeddingParty
            case "family": return .groupFamily
            case "friends": return .groupFriends
            case "colleagues": return .groupColleagues
            default: return .seatingAccentTeal
            }
        }

        // Fallback to color based on first letter of last name
        let firstLetter = guest.lastName.first?.uppercased() ?? "A"
        let letterValue = firstLetter.unicodeScalars.first?.value ?? 65
        let hue = Double((letterValue - 65) % 12) / 12.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}

// MARK: - Guest Details Popover

struct GuestDetailsPopover: View {
    let guest: SeatingGuest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with avatar
            HStack(spacing: 12) {
                GuestAvatarView(guest: guest, size: 50, showBorder: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(guest.firstName) \(guest.lastName)")
                        .font(.seatingH4)
                        .foregroundColor(.seatingDeepNavy)

                    if let group = guest.group {
                        Text(group)
                            .font(.seatingCaption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(groupBackgroundColor)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                if guest.isVIP {
                    Image(systemName: "star.fill")
                        .foregroundColor(.seatingGold)
                }
            }

            Divider()

            // Details
            VStack(alignment: .leading, spacing: 8) {
                if !guest.email.isEmpty {
                    GuestDetailRow(icon: "envelope", text: guest.email)
                }

                if !guest.phone.isEmpty {
                    GuestDetailRow(icon: "phone", text: guest.phone)
                }

                if !guest.dietaryRestrictions.isEmpty {
                    GuestDetailRow(icon: "leaf", text: guest.dietaryRestrictions)
                }

                if !guest.preferences.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Seating Preferences:")
                            .font(.seatingCaptionBold)
                            .foregroundColor(.secondary)

                        ForEach(guest.preferences, id: \.self) { pref in
                            Text("• \(pref)")
                                .font(.seatingCaption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .frame(width: 300)
        .background(Color.seatingCream)
    }

    private var groupBackgroundColor: Color {
        guard let group = guest.group else { return .gray.opacity(0.2) }

        switch group.lowercased() {
        case "wedding party": return .groupWeddingParty.opacity(0.2)
        case "family": return .groupFamily.opacity(0.2)
        case "friends": return .groupFriends.opacity(0.2)
        case "colleagues": return .groupColleagues.opacity(0.2)
        default: return .gray.opacity(0.2)
        }
    }
}

// MARK: - Detail Row

struct GuestDetailRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.seatingCaption)
                .foregroundColor(.seatingAccentTeal)
                .frame(width: 20)

            Text(text)
                .font(.seatingCaption)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GuestAvatarView(
            guest: SeatingGuest(
                firstName: "John",
                lastName: "Smith",
                email: "john@example.com",
                phone: "555-1234",
                group: "Family",
                isVIP: true
            ),
            size: 60,
            showName: true
        )

        GuestAvatarView(
            guest: SeatingGuest(
                firstName: "Jane",
                lastName: "Doe",
                email: "jane@example.com",
                group: "Friends",
                isVIP: false
            ),
            size: 40,
            showName: false
        )
    }
    .padding()
}
