//
//  IndividualPaymentNotesCardV1.swift
//  I Do Blueprint
//
//  Notes card for individual payment detail view
//

import SwiftUI

struct IndividualPaymentNotesCardV1: View {
    let notes: String
    var onEditNotes: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Notes")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                if let onEdit = onEditNotes {
                    Button(action: onEdit) {
                        Text("Edit Notes")
                            .font(Typography.caption.weight(.medium))
                            .foregroundColor(AppColors.Budget.allocated)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Notes content
            Text(notes)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
                .italic()
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }
}
