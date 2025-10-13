//
//  CompactStatCard.swift
//  My Wedding Planning App
//
//  Extracted from DashboardViewV2.swift
//

import SwiftUI

struct CompactStatCard: View {
    let value: String
    let label: String
    let icon: String
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(foregroundColor.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(foregroundColor)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(foregroundColor.opacity(0.8))

            HStack {
                Spacer()
                Text("...")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(foregroundColor.opacity(0.3))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
