//
//  NotesSection.swift
//  I Do Blueprint
//
//  Component for vendor notes editor
//

import SwiftUI

struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VendorSectionHeader(title: "Notes", icon: "note.text")
            
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SemanticColors.textSecondary.opacity(Opacity.light), lineWidth: 1)
                )
        }
    }
}

#Preview {
    NotesSection(notes: .constant("Sample notes about the vendor"))
        .padding()
}
