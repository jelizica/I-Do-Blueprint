//
//  ImportSuccessView.swift
//  I Do Blueprint
//
//  Success confirmation view for import wizard
//

import SwiftUI

struct ImportSuccessView: View {
    let stats: ImportStats
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Import Complete!")
                .font(Typography.title3)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: Spacing.xs) {
                if stats.added > 0 {
                    ImportStatRow(icon: "✅", label: "Added", count: stats.added, suffix: "guests")
                }

                if stats.updated > 0 {
                    ImportStatRow(icon: "🔄", label: "Updated", count: stats.updated, suffix: "guests")
                }

                if stats.deleted > 0 {
                    ImportStatRow(icon: "🗑️", label: "Removed", count: stats.deleted, suffix: "guests")
                }

                if stats.skipped > 0 {
                    ImportStatRow(icon: "⏭️", label: "Skipped", count: stats.skipped, suffix: "duplicates")
                }
            }

            Button(action: onDone) {
                Text("Done")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: 300)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.sm)
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Stat Row

private struct ImportStatRow: View {
    let icon: String
    let label: String
    let count: Int
    let suffix: String

    var body: some View {
        Text("\(icon) \(label): \(count) \(suffix)")
            .font(Typography.bodyRegular)
            .foregroundColor(AppColors.textPrimary)
    }
}
