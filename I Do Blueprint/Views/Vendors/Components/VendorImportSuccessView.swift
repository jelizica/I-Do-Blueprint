//
//  VendorImportSuccessView.swift
//  I Do Blueprint
//
//  Extracted from VendorCSVImportView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Success message showing import statistics
struct VendorImportSuccessView: View {
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
                    Text("✅ Added: \(stats.added) vendors")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if stats.updated > 0 {
                    Text("🔄 Updated: \(stats.updated) vendors")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if stats.deleted > 0 {
                    Text("🗑️ Removed: \(stats.deleted) vendors")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                if stats.skipped > 0 {
                    Text("⏭️ Skipped: \(stats.skipped) duplicates")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
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
