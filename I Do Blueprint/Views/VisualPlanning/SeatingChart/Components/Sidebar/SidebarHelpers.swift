//
//  SidebarHelpers.swift
//  I Do Blueprint
//
//  Helper components and utilities for modern sidebar
//

import SwiftUI

// MARK: - Sidebar Empty State View

struct SidebarEmptyStateView: View {
    let icon: String
    let message: String
    let action: String?
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text(message)
                .font(.seatingCaption)
                .foregroundColor(.secondary)

            if let action {
                Button(action: onAction) {
                    Text(action)
                        .font(.seatingCaptionBold)
                        .foregroundColor(.seatingAccentTeal)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Guest Group Editor Sheet

struct GuestGroupEditorSheet: View {
    @Binding var groups: [SeatingGuestGroup]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Guest Group Editor")
                .font(.seatingH2)
                .padding()

            // Guest group editor: Future feature for managing custom guest groups
            // Would allow users to:
            // - Create custom groups (e.g., "College Friends", "Work Colleagues")
            // - Assign colors and icons to groups
            // - Set group preferences (e.g., "seat together", "separate from")
            // - Manage group visibility in sidebar
            Text("Group management coming soon")
                .font(.seatingBody)
                .foregroundColor(.secondary)
                .padding()
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 500, height: 400)
    }
}
