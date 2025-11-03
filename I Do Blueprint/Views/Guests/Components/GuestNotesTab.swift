//
//  GuestNotesTab.swift
//  I Do Blueprint
//
//  Notes tab content for guest detail view
//

import SwiftUI

struct GuestNotesTab: View {
    let guest: Guest

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            if let notes = guest.notes, !notes.isEmpty {
                VisualNotesSection(notes: notes)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Notes")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Add notes to keep track of important details about this guest.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }
}
