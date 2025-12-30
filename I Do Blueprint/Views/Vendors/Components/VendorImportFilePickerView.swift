//
//  VendorImportFilePickerView.swift
//  I Do Blueprint
//
//  Extracted from VendorCSVImportView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// File picker section with import mode selection
struct VendorImportFilePickerView: View {
    @Binding var importMode: ImportMode
    let onSelectFile: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Import mode selection
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Import Mode:")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                VStack(spacing: Spacing.sm) {
                    VendorImportModeOption(
                        mode: .addOnly,
                        title: "Add Only",
                        description: "Add new vendors from the file. Existing vendors won't be modified.",
                        icon: "plus.circle",
                        selectedMode: $importMode
                    )
                    
                    VendorImportModeOption(
                        mode: .sync,
                        title: "Sync",
                        description: "Add new vendors, update existing ones, and remove vendors not in the file.",
                        icon: "arrow.triangle.2.circlepath",
                        selectedMode: $importMode
                    )
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: 500)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            
            // File picker button
            Button(action: onSelectFile) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.primary)
                    
                    Text("Choose File")
                        .font(Typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                    
                    Text("Supported formats: CSV, Excel (.xlsx)")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: 400)
                .padding(.vertical, Spacing.xl)
                .padding(.horizontal, Spacing.xl)
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.primary, style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Import Mode Option

struct VendorImportModeOption: View {
    let mode: ImportMode
    let title: String
    let description: String
    let icon: String
    @Binding var selectedMode: ImportMode
    
    var body: some View {
        Button(action: { selectedMode = mode }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedMode == mode ? AppColors.primary : AppColors.textSecondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(description)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: selectedMode == mode ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedMode == mode ? AppColors.primary : AppColors.textSecondary)
            }
            .padding(Spacing.md)
            .background(selectedMode == mode ? AppColors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
