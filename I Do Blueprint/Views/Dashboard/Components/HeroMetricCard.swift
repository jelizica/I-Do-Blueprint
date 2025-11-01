//
//  HeroMetricCard.swift
//  My Wedding Planning App
//
//  Extracted from DashboardViewV2.swift
//

import SwiftUI

struct HeroMetricCard: View {
    let value: String
    let subtitle: String
    let detail: String
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("^")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(foregroundColor.opacity(0.6))
                Spacer()
            }

            Spacer()

            Text(value)
                .font(.system(size: 72, weight: .black))
                .foregroundColor(foregroundColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(foregroundColor)

                Text(detail)
                    .font(.system(size: 14))
                    .foregroundColor(foregroundColor.opacity(0.7))
            }

            HStack {
                Spacer()
                Text("...")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(foregroundColor.opacity(0.4))
            }
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(AppColors.textPrimary, lineWidth: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle)
        .accessibilityValue("\(value). \(detail)")
    }
}
