//
//  V3VendorQuickActions.swift
//  I Do Blueprint
//
//  Quick action buttons for V3 vendor detail view (Call, Email, Website, Edit)
//

import SwiftUI

struct V3VendorQuickActions: View {
    let vendor: Vendor
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Call action
            if let phoneURL = vendor.phoneURL {
                V3QuickActionButton(
                    icon: "phone.fill",
                    title: "Call",
                    color: AppColors.Vendor.booked
                ) {
                    NSWorkspace.shared.open(phoneURL)
                }
            }

            // Email action
            if let emailURL = vendor.emailURL {
                V3QuickActionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    color: AppColors.Vendor.contacted
                ) {
                    NSWorkspace.shared.open(emailURL)
                }
            }

            // Website action
            if let websiteURL = vendor.websiteURL {
                V3QuickActionButton(
                    icon: "globe",
                    title: "Website",
                    color: AppColors.Vendor.pending
                ) {
                    NSWorkspace.shared.open(websiteURL)
                }
            }

            // Edit action (always shown)
            V3QuickActionButton(
                icon: "pencil",
                title: "Edit",
                color: AppColors.primary
            ) {
                onEdit()
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: AppColors.textPrimary.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Quick Action Button

private struct V3QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: {
            HapticFeedback.buttonTap()
            action()
        }) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color.opacity(isHovering ? 0.2 : 0.1))
                    )
                    .scaleEffect(isHovering ? 1.1 : 1.0)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(minWidth: 70)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .help(title)
        .accessibilityLabel(title)
        .accessibilityHint("Activate to \(title.lowercased())")
    }
}

// MARK: - Preview

#Preview("Quick Actions - All") {
    V3VendorQuickActions(
        vendor: .makeTest(),
        onEdit: { }
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Quick Actions - No Contact") {
    V3VendorQuickActions(
        vendor: .makeTest(
            phoneNumber: nil,
            email: nil,
            website: nil
        ),
        onEdit: { }
    )
    .padding()
    .background(AppColors.background)
}
