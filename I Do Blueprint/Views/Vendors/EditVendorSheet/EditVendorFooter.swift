//
//  EditVendorFooter.swift
//  I Do Blueprint
//
//  Component for edit vendor sheet footer actions
//

import SwiftUI

struct EditVendorFooter: View {
    let isSaving: Bool
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Button("Cancel") {
                onCancel()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button {
                onSave()
            } label: {
                if isSaving {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Saving...")
                    }
                } else {
                    Text("Save Changes")
                }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(isSaving || !canSave)
        }
        .padding()
        .background(AppColors.controlBackground)
    }
}

#Preview {
    VStack {
        Spacer()
        EditVendorFooter(
            isSaving: false,
            canSave: true,
            onCancel: {},
            onSave: {}
        )
    }
}
