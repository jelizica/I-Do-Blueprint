//
//  GuestDetailSection.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(Typography.subheading)
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            content
        }
    }
}
