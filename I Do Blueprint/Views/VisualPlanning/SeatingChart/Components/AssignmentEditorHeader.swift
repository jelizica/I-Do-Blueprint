//
//  AssignmentEditorHeader.swift
//  I Do Blueprint
//
//  Header component for assignment editor with save/cancel actions
//

import SwiftUI

struct AssignmentEditorHeader: View {
    let selectedGuest: SeatingGuest?
    let isValid: Bool
    let validationMessage: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit Seating Assignment")
                    .font(Typography.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .accessibleHeading(level: 1)

                if let guest = selectedGuest {
                    Text("Assigning \(guest.fullName)")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: Spacing.md) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .accessibleActionButton(
                    label: "Cancel editing",
                    hint: "Discards changes and closes the editor"
                )

                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .accessibleActionButton(
                    label: "Save assignment",
                    hint: isValid ? "Saves changes and closes the editor" : "Cannot save: \(validationMessage)"
                )
            }
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Preview

#Preview {
    let sampleGuest = SeatingGuest(
        firstName: "John",
        lastName: "Doe",
        relationship: .friend
    )
    
    return VStack {
        AssignmentEditorHeader(
            selectedGuest: sampleGuest,
            isValid: true,
            validationMessage: "",
            onSave: {},
            onCancel: {}
        )
        
        Divider()
        
        AssignmentEditorHeader(
            selectedGuest: nil,
            isValid: false,
            validationMessage: "Please select a guest",
            onSave: {},
            onCancel: {}
        )
    }
    .frame(width: 700)
}
