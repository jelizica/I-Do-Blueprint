//
//  ImportFilePickerView.swift
//  I Do Blueprint
//
//  File picker and mode selection view for import wizard
//

import SwiftUI

struct ImportFilePickerView: View {
    @Binding var importMode: ImportMode
    let onSelectFile: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Import mode selection
            ImportModeSelectionView(importMode: $importMode)

            // File picker button
            Button(action: onSelectFile) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(SemanticColors.primaryAction)

                    Text("Choose File")
                        .font(Typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.primaryAction)

                    Text("Supported formats: CSV, Excel (.xlsx)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .frame(maxWidth: 400)
                .padding(.vertical, Spacing.xl)
                .padding(.horizontal, Spacing.xl)
                .background(SemanticColors.primaryAction.opacity(Opacity.subtle))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SemanticColors.primaryAction, style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Mode Selection

private struct ImportModeSelectionView: View {
    @Binding var importMode: ImportMode

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Import Mode:")
                .font(Typography.bodyRegular)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textPrimary)

            VStack(spacing: Spacing.sm) {
                ImportModeOption(
                    mode: .addOnly,
                    title: "Add Only",
                    description: "Add new guests from the file. Existing guests won't be modified or deleted.",
                    icon: "plus.circle",
                    isSelected: importMode == .addOnly,
                    onSelect: { importMode = .addOnly }
                )

                ImportModeOption(
                    mode: .sync,
                    title: "Sync",
                    description: "Add new guests, update existing ones, and remove guests not in the file.",
                    icon: "arrow.triangle.2.circlepath",
                    isSelected: importMode == .sync,
                    onSelect: { importMode = .sync }
                )
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: 500)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(8)
    }
}

// MARK: - Mode Option

private struct ImportModeOption: View {
    let mode: ImportMode
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? SemanticColors.primaryAction : SemanticColors.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text(description)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? SemanticColors.primaryAction : SemanticColors.textSecondary)
            }
            .padding(Spacing.md)
            .background(isSelected ? SemanticColors.primaryAction.opacity(Opacity.subtle) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
