//
//  VendorCompactCard.swift
//  I Do Blueprint
//
//  Compact vendor card for narrow windows
//  Vertical mini-card layout with avatar, name, and status circle
//

import SwiftUI

struct VendorCompactCard: View {
    let vendor: Vendor
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
                            .fill(AppColors.controlBackground)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "building.2")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.textSecondary)
                            )
                    }
                }
                .task {
                    await loadAvatar()
                }
                .accessibilityLabel("Avatar for \(vendor.vendorName)")

                // Status Circle Indicator (12px)
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
                    .accessibilityLabel(statusAccessibilityLabel)
            }

            // Vendor Name (centered, 2 lines max)
            Text(vendor.vendorName)
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
            label: vendor.vendorName,
            hint: "Tap to view vendor details",
            value: vendor.isBooked == true ? "Booked" : "Available"
        )
    }

    // MARK: - Status Color Mapping

    private var statusColor: Color {
        if vendor.isArchived {
            return AppColors.textSecondary.opacity(0.4)
        } else if vendor.isBooked == true {
            return AppColors.success
        } else {
            return AppColors.warning
        }
    }

    private var statusAccessibilityLabel: String {
        if vendor.isArchived {
            return "Archived"
        } else if vendor.isBooked == true {
            return "Booked"
        } else {
            return "Available"
        }
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        guard let imageUrl = vendor.imageUrl,
              let url = URL(string: imageUrl) else {
            avatarImage = nil
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                await MainActor.run {
                    avatarImage = nsImage
                }
            }
        } catch {
            await MainActor.run {
                avatarImage = nil
            }
        }
    }
}
