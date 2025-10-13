//
//  GuestAvatarViewV2.swift
//  My Wedding Planning App
//
//  Illustrated guest avatar using DiceBear Personas API
//  Created for Seating Chart V2
//

import SwiftUI

/// Displays a guest avatar with illustrated person using DiceBear Personas API
/// Shows guest name above and below the avatar illustration
struct GuestAvatarViewV2: View {
    let guest: SeatingGuest
    let size: CGFloat
    let showName: Bool

    @State private var isHovering = false

    init(guest: SeatingGuest, size: CGFloat = 40, showName: Bool = true) {
        self.guest = guest
        self.size = size
        self.showName = showName
    }

    // MARK: - Avatar URL

    private var avatarURL: URL? {
        AvatarHelpers.avatarURL(for: guest.id, size: Int(size * 2)) // 2x for retina
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Avatar illustration from DiceBear using custom SVG loader
            SVGAvatarView(
                url: avatarURL,
                size: size,
                borderColor: borderColor,
                borderWidth: borderWidth,
                isHovering: $isHovering,
                fallbackView: fallbackAvatar,
                guestName: "\(guest.firstName) \(guest.lastName)"
            )

            // Curved names above avatar
            if showName {
                CurvedNamesView(
                    firstName: guest.firstName,
                    lastName: guest.lastName,
                    radius: size / 2,
                    size: size
                )
                .offset(y: -size * 0.3) // Position above the avatar
            }
        }
        .frame(width: size * 2.5, height: size * 2.5)
    }

    // MARK: - Subviews

    private var loadingPlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .overlay {
                ProgressView()
                    .scaleEffect(0.6)
            }
    }

    private var fallbackAvatar: some View {
        Circle()
            .fill(AvatarHelpers.fallbackColor(for: guest.initials))
            .frame(width: size, height: size)
            .overlay {
                Text(guest.initials)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        borderColor,
                        lineWidth: borderWidth
                    )
            }
    }

    // MARK: - Helper Properties

    private var borderColor: Color {
        guest.isVIP ? AvatarHelpers.vipBorderColor : AvatarHelpers.regularBorderColor
    }

    private var borderWidth: CGFloat {
        guest.isVIP ? AvatarHelpers.vipBorderWidth : AvatarHelpers.regularBorderWidth
    }
}

// MARK: - Preview Provider

#if DEBUG
struct GuestAvatarViewV2_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Regular guest
            GuestAvatarViewV2(
                guest: SeatingGuest(
                    firstName: "Jane",
                    lastName: "Smith",
                    group: "Bride's Friends"
                ),
                size: 40,
                showName: true
            )

            // VIP guest
            GuestAvatarViewV2(
                guest: SeatingGuest(
                    firstName: "John",
                    lastName: "Doe",
                    group: "Family",
                    isVIP: true
                ),
                size: 40,
                showName: true
            )

            // Small size without name
            GuestAvatarViewV2(
                guest: SeatingGuest(
                    firstName: "Alice",
                    lastName: "Johnson"
                ),
                size: 30,
                showName: false
            )

            // Large size
            GuestAvatarViewV2(
                guest: SeatingGuest(
                    firstName: "Robert",
                    lastName: "Williams",
                    group: "Groom's Friends"
                ),
                size: 60,
                showName: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
