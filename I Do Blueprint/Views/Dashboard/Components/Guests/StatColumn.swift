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
    let icon: String?

    init(value: Int, label: String, color: Color, icon: String? = nil) {
        self.value = value
        self.label = label
        self.color = color
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                }

                Text("\(value)")
                    .font(Typography.numberMedium)
                    .foregroundColor(color)
            }

            Text(label)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
