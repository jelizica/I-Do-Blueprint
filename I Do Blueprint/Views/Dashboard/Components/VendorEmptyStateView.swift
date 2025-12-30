//
//  VendorEmptyStateView.swift
//  I Do Blueprint
//
//  Empty state view for vendor detail modal tabs
//

import SwiftUI

struct VendorEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)
            
            Text(title)
                .font(Typography.heading)
                .foregroundColor(AppColors.textSecondary)
            
            Text(message)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
