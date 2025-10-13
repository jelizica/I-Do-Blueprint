//
//  EmptyVendorListView.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/9/25.
//  Empty state view for vendor list
//

import SwiftUI

struct EmptyVendorListView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "building.2.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))

            Text("No vendors found")
                .font(Typography.title3)
                .fontWeight(.semibold)

            Text("Add your first vendor or adjust your search filters")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxxl)
    }
}
