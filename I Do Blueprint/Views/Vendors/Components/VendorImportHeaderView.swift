//
//  VendorImportHeaderView.swift
//  I Do Blueprint
//
//  Extracted from VendorCSVImportView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Header section for vendor import view
struct VendorImportHeaderView: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.primaryAction)
            
            Text("Import Vendors")
                .font(Typography.title2)
                .foregroundColor(SemanticColors.textPrimary)
            
            Text("Upload a CSV or Excel file to add or sync your vendor list")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.lg)
    }
}
