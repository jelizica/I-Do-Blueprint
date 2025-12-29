//
//  V3VendorNotesContent.swift
//  I Do Blueprint
//
//  Notes tab content for V3 vendor detail view
//

import SwiftUI

struct V3VendorNotesContent: View {
    let notes: String?

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            if let notes = notes, !notes.isEmpty {
                notesContent(notes: notes)
            } else {
                emptyState
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text("No Notes")
                .font(Typography.heading)
                .foregroundColor(AppColors.textSecondary)

            Text("Add notes to keep track of important details about this vendor.")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxxl)
    }

    // MARK: - Notes Content

    private func notesContent(notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            V3SectionHeader(
                title: "Notes",
                icon: "note.text.fill",
                color: AppColors.primary
            )

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(notes)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(4)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview("Notes Content - With Notes") {
    V3VendorNotesContent(
        notes: "3-Tier Cake (72 people)\n\nFlavors discussed:\n- Vanilla with raspberry filling\n- Chocolate with ganache\n\nDelivery scheduled for 2pm on wedding day."
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Notes Content - Empty") {
    V3VendorNotesContent(notes: nil)
        .padding()
        .background(AppColors.background)
}
