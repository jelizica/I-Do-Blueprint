//
//  ImportPreviewView.swift
//  I Do Blueprint
//
//  Preview and validation view for import wizard
//

import SwiftUI

struct ImportPreviewView: View {
    let preview: ImportPreview
    let importMode: ImportMode
    let validationResult: ImportValidationResult?
    let isImporting: Bool
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // File info
            ImportFileInfoView(
                fileName: preview.fileName,
                totalRows: preview.totalRows,
                importMode: importMode,
                isImporting: isImporting,
                onClear: onClear
            )

            // Preview table
            ImportDataTableView(preview: preview)

            // Validation or importing status
            if let validation = validationResult {
                ImportValidationView(validation: validation)
            } else if isImporting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Importing guests...")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(Spacing.md)
            }
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - File Info

private struct ImportFileInfoView: View {
    let fileName: String
    let totalRows: Int
    let importMode: ImportMode
    let isImporting: Bool
    let onClear: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .foregroundColor(AppColors.primary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(fileName)
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)

                Text("\(totalRows) guests • \(importMode == .addOnly ? "Add Only" : "Sync") Mode")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            if !isImporting {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(8)
    }
}

// MARK: - Data Table

private struct ImportDataTableView: View {
    let preview: ImportPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    // Headers
                    HStack(spacing: 0) {
                        ForEach(preview.headers, id: \.self) { header in
                            Text(header)
                                .font(Typography.bodySmall)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(Spacing.sm)
                                .frame(minWidth: 120, alignment: .leading)
                                .background(AppColors.cardBackground)
                        }
                    }

                    Divider()

                    // Rows (show first 10)
                    ForEach(Array(preview.rows.prefix(10).enumerated()), id: \.offset) { index, row in
                        HStack(spacing: 0) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell)
                                    .font(Typography.bodySmall)
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(Spacing.sm)
                                    .frame(minWidth: 120, alignment: .leading)
                            }
                        }
                        .background(index % 2 == 0 ? Color.clear : AppColors.cardBackground.opacity(0.5))
                    }
                }
            }
            .frame(maxHeight: 250)
            .background(AppColors.cardBackground)
            .cornerRadius(8)

            if preview.totalRows > 10 {
                Text("Showing first 10 of \(preview.totalRows) guests")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, Spacing.xs)
            }
        }
    }
}

// MARK: - Validation

private struct ImportValidationView: View {
    let validation: ImportValidationResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if validation.isValid {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Validation passed! Importing...")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textPrimary)
                }
            } else {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Validation errors found:")
                            .font(Typography.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }

                    ForEach(Array(validation.errors.prefix(5).enumerated()), id: \.offset) { _, error in
                        Text("• Row \(error.row): \(error.message)")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    if validation.errors.count > 5 {
                        Text("... and \(validation.errors.count - 5) more errors")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: 500)
        .background(validation.isValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}
