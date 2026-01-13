//
//  VendorDetailHeaderV2.swift
//  I Do Blueprint
//
//  Enhanced header component for vendor detail modal with action buttons
//

import SwiftUI

struct VendorDetailHeaderV2: View {
    let vendor: Vendor
    let loadedImage: NSImage?
    let onCall: () -> Void
    let onEmail: () -> Void
    let onWebsite: () -> Void
    let onEdit: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Vendor Icon or Logo
            vendorIcon

            // Vendor Info
            vendorInfo

            Spacer()

            // Action Buttons
            actionButtons

            // Close Button
            closeButton
        }
        .padding(Spacing.xl)
    }

    // MARK: - Components

    private var vendorIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientForVendorType(vendor.vendorType ?? ""),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)

            if let image = loadedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
            } else {
                Image(systemName: iconForVendorType(vendor.vendorType ?? ""))
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
    }

    private var vendorInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(vendor.vendorName)
                .font(Typography.title2)
                .foregroundColor(SemanticColors.textPrimary)

            HStack(spacing: Spacing.sm) {
                if let type = vendor.vendorType {
                    Text(type)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                if vendor.isBooked == true {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                        Text("Booked")
                            .font(Typography.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(AppColors.Vendor.booked)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(AppColors.Vendor.booked.opacity(Opacity.subtle))
                    .cornerRadius(CornerRadius.pill)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            // Call Button
            if vendor.phoneNumber != nil {
                VendorActionButton(
                    icon: "phone.fill",
                    label: "Call",
                    color: SemanticColors.success,
                    action: onCall
                )
            }

            // Email Button
            if vendor.email != nil {
                VendorActionButton(
                    icon: "envelope.fill",
                    label: "Email",
                    color: SemanticColors.primaryAction,
                    action: onEmail
                )
            }

            // Website Button
            if vendor.website != nil {
                VendorActionButton(
                    icon: "globe",
                    label: "Website",
                    color: AppColors.Vendor.contacted,
                    action: onWebsite
                )
            }

            // Edit Button
            VendorActionButton(
                icon: "pencil",
                label: "Edit",
                color: SemanticColors.warning,
                action: onEdit
            )
        }
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(GlassCloseButtonStyle())
        .accessibleActionButton(label: "Close modal", hint: "Closes vendor details")
    }

    // MARK: - Helper Functions

    private func iconForVendorType(_ type: String) -> String {
        switch type.lowercased() {
        case "venue": return "mappin.circle.fill"
        case "photography", "photographer": return "camera.fill"
        case "catering", "caterer": return "fork.knife"
        case "music", "dj", "band": return "music.note"
        case "florist", "flowers": return "leaf.fill"
        case "cake", "bakery": return "birthday.cake.fill"
        case "dress", "attire": return "tshirt.fill"
        case "hair", "makeup": return "sparkles"
        case "transportation": return "car.fill"
        case "videography", "videographer": return "video.fill"
        case "planner", "event planner", "coordinator": return "calendar.badge.checkmark"
        case "officiant": return "person.fill"
        case "invitations", "stationery": return "envelope.fill"
        case "rentals": return "archivebox.fill"
        case "lighting": return "lightbulb.fill"
        default: return "briefcase.fill"
        }
    }

    private func gradientForVendorType(_ type: String) -> [Color] {
        switch type.lowercased() {
        case "venue": return [Color.fromHex("EC4899"), Color.fromHex("F43F5E")]
        case "photography", "photographer": return [Color.fromHex("A855F7"), Color.fromHex("EC4899")]
        case "catering", "caterer": return [Color.fromHex("F97316"), Color.fromHex("EC4899")]
        case "music", "dj", "band": return [Color.fromHex("3B82F6"), Color.fromHex("A855F7")]
        case "florist", "flowers": return [Color.fromHex("10B981"), Color.fromHex("059669")]
        case "cake", "bakery": return [Color.fromHex("F472B6"), Color.fromHex("EC4899")]
        case "dress", "attire": return [Color.fromHex("8B5CF6"), Color.fromHex("A855F7")]
        case "hair", "makeup": return [Color.fromHex("EC4899"), Color.fromHex("F472B6")]
        case "transportation": return [Color.fromHex("6366F1"), Color.fromHex("3B82F6")]
        case "videography", "videographer": return [Color.fromHex("EF4444"), Color.fromHex("F97316")]
        case "planner", "event planner", "coordinator": return [Color.fromHex("10B981"), Color.fromHex("3B82F6")]
        default: return [Color.fromHex("6366F1"), Color.fromHex("8B5CF6")]
        }
    }
}

// MARK: - Supporting Views

struct VendorActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(Typography.caption2)
            }
            .frame(width: 56, height: 52)
        }
        .buttonStyle(GlassActionButtonStyle(color: color))
        .accessibleActionButton(label: label, hint: "Opens \(label.lowercased()) action")
    }
}
