//
//  GuestDetailActionButtons.swift
//  I Do Blueprint
//
//  Action buttons for guest detail modal
//

import SwiftUI

struct GuestDetailActionButtons: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Edit Button
            Button {
                onEdit()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "pencil")
                    Text("Edit Guest")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(SemanticColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(SemanticColors.primaryAction)
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
            
            // Delete Button
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SemanticColors.textPrimary)
                    .frame(width: 48, height: 48)
                    .background(SemanticColors.error)
                    .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.xl)
    }
}
