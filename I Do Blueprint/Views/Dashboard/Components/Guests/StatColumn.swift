//
//  StatColumn.swift
//  I Do Blueprint
//
//  Extracted from DashboardViewV4.swift
//  Stat column component displaying a numeric value with label and color
//

import SwiftUI

struct StatColumn: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text("\(value)")
                .font(Typography.numberMedium)
                .foregroundColor(color)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
