//
//  EmptyGuestDetailView.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.crop.square.fill.and.at.rectangle")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))

            Text("Select a guest")
                .font(Typography.title3)
                .fontWeight(.semibold)

            Text("Choose a guest from the list to view their details")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}
