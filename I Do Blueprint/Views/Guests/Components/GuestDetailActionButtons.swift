//
//  GuestDetailActionButtons.swift
//  I Do Blueprint
//
//  Glassmorphism action buttons for guest detail modal
//

import SwiftUI

struct GuestDetailActionButtons: View {
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Edit Button - Primary action with glass effect
            Button {
                onEdit()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "pencil")
                    Text("Edit Guest")
                        .font(Typography.bodySmall)
                        .fontWeight(.medium)
                }
                .foregroundColor(SemanticColors.textOnPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColors.primaryAction)
                )
            }
            .buttonStyle(.plain)
            .shadow(color: SemanticColors.primaryAction.opacity(0.3), radius: 8, x: 0, y: 4)

            // Delete Button - Glass style with subtle error color
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Terracotta.shade500)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(Terracotta.shade100)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Terracotta.shade200, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
        .background(
            // Frosted glass footer
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                )
        )
    }
}
