//
//  VendorCardV4.swift
//  I Do Blueprint
//
//  Premium glassmorphism vendor card with image loading and initials fallback
//

import SwiftUI

struct VendorCardV4: View {
    let vendor: Vendor
    @State private var loadedImage: NSImage?
    @State private var isHovered = false

    // Generate initials from vendor name
    private var initials: String {
        let words = vendor.vendorName.split(separator: " ")
        if words.count >= 2 {
            let first = words[0].prefix(1)
            let second = words[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else if let firstWord = words.first {
            return String(firstWord.prefix(2)).uppercased()
        }
        return "V"
    }

    // Generate a consistent color based on vendor name
    private var avatarColor: Color {
        let colors: [Color] = [
            AppGradients.weddingPink,
            AppGradients.sageGreen,
            SemanticColors.primaryAction,
            Color.fromHex("9370DB"), // Purple
            Color.fromHex("E8A87C"), // Peach
            Color.fromHex("5DADE2")  // Blue
        ]
        let hash = vendor.vendorName.hashValue
        let index = abs(hash) % colors.count
        return colors[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section: Avatar and Status Badge
            HStack(alignment: .top) {
                avatarView
                Spacer()
                statusBadge
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            // Vendor Name
            Text(vendor.vendorName)
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)

            // Contact Email
            if let email = vendor.email, !email.isEmpty {
                Text(email)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xs)
            }

            // Vendor Type with icon
            if let vendorType = vendor.vendorType, !vendorType.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: vendorTypeIcon(for: vendorType))
                        .font(.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    Text(vendorType)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
            }

            Spacer()

            // Bottom: Quoted Amount
            quotedAmountSection
        }
        .frame(minWidth: 220, maxWidth: .infinity)
        .frame(height: 220)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.white.opacity(isHovered ? 0.35 : 0.25))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.8 : 0.6),
                            Color.white.opacity(isHovered ? 0.3 : 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.12 : 0.08), radius: isHovered ? 16 : 12, x: 0, y: isHovered ? 8 : 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibleListItem(
            label: vendor.vendorName,
            hint: "Tap to view vendor details",
            value: vendor.isBooked == true ? "Booked" : "Available"
        )
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
    }

    // MARK: - Avatar View

    private var avatarView: some View {
        Circle()
            .fill(avatarColor.opacity(0.2))
            .frame(width: 56, height: 56)
            .overlay(
                Group {
                    if let image = loadedImage {
                        // Show loaded image
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } else {
                        // Show initials as fallback
                        Text(initials)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(avatarColor)
                    }
                }
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
    }

    // MARK: - Status Badge
    // Uses GlassStatusBadge from Design/Components.swift for consistent V7 styling

    private var statusBadge: some View {
        Group {
            if vendor.isArchived {
                GlassStatusBadge(
                    text: "Archived",
                    color: Terracotta.shade500,
                    backgroundColor: Terracotta.shade100
                )
            } else if vendor.isBooked == true {
                GlassStatusBadge(status: .booked)
            } else {
                GlassStatusBadge(status: .pending)
            }
        }
    }

    // MARK: - Quoted Amount Section

    private var quotedAmountSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.3))

            HStack {
                Text("Quoted")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Text(formatCurrency(vendor.quotedAmount ?? 0))
                    .font(Typography.numberMedium)
                    .foregroundColor(SemanticColors.textPrimary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Helper Methods

    private func loadVendorImage() async {
        guard let imageUrl = vendor.imageUrl,
              let url = URL(string: imageUrl) else {
            loadedImage = nil
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                await MainActor.run {
                    loadedImage = nsImage
                }
            }
        } catch {
            await MainActor.run {
                loadedImage = nil
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }

    private func vendorTypeIcon(for type: String) -> String {
        let lowercased = type.lowercased()
        if lowercased.contains("photo") { return "camera.fill" }
        if lowercased.contains("video") { return "video.fill" }
        if lowercased.contains("cater") || lowercased.contains("food") { return "fork.knife" }
        if lowercased.contains("flor") || lowercased.contains("flower") { return "leaf.fill" }
        if lowercased.contains("music") || lowercased.contains("dj") || lowercased.contains("band") { return "music.note" }
        if lowercased.contains("venue") || lowercased.contains("location") { return "building.columns.fill" }
        if lowercased.contains("dress") || lowercased.contains("attire") || lowercased.contains("suit") { return "tshirt.fill" }
        if lowercased.contains("cake") || lowercased.contains("baker") { return "birthday.cake.fill" }
        if lowercased.contains("hair") || lowercased.contains("makeup") || lowercased.contains("beauty") { return "sparkles" }
        if lowercased.contains("plan") || lowercased.contains("coordinator") { return "list.clipboard.fill" }
        if lowercased.contains("transport") || lowercased.contains("limo") || lowercased.contains("car") { return "car.fill" }
        if lowercased.contains("invite") || lowercased.contains("stationery") { return "envelope.fill" }
        return "tag.fill"
    }
}

// MARK: - Badge Component

struct BadgeV4: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(Typography.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(color.opacity(Opacity.light))
            )
    }
}
