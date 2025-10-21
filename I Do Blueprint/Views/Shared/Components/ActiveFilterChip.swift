//
//  ActiveFilterChip.swift
//  I Do Blueprint
//
//  Component for displaying active filter tags with remove button
//

import SwiftUI

struct ActiveFilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.textPrimary)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(label) filter")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColors.primaryLight)
        .cornerRadius(CornerRadius.pill)
    }
}
