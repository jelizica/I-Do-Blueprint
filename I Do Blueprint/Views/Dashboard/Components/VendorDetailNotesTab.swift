//
//  VendorDetailNotesTab.swift
//  I Do Blueprint
//
//  Notes tab content for vendor detail modal
//

import SwiftUI

struct VendorDetailNotesTab: View {
    let vendor: Vendor
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            if let notes = vendor.notes, !notes.isEmpty {
                notesContent(notes)
            } else {
                VendorEmptyStateView(
                    icon: "note.text",
                    title: "No Notes",
                    message: "Add notes to keep track of important details about this vendor."
                )
            }
        }
    }
    
    // MARK: - Components
    
    private func notesContent(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Notes",
                icon: "note.text.fill",
                color: SemanticColors.primaryAction
            )
            
            Text(notes)
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textPrimary)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SemanticColors.backgroundSecondary)
                .cornerRadius(CornerRadius.md)
        }
    }
}
