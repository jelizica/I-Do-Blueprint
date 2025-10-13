//
//  EmptyVendorDetailView.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/9/25.
//  Empty state view for vendor detail panel
//

import SwiftUI

struct EmptyVendorDetailView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))

            Text("Select a vendor")
                .font(Typography.title3)
                .fontWeight(.semibold)

            Text("Choose a vendor from the list to view their details")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
