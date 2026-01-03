//
//  ImportHeaderView.swift
//  I Do Blueprint
//
//  Header view for import wizard
//

import SwiftUI

struct ImportHeaderView: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.primaryAction)

            Text("Import Guests")
                .font(Typography.title2)
                .foregroundColor(SemanticColors.textPrimary)

            Text("Upload a CSV or Excel file to add or sync your guest list")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.lg)
    }
}
