//
//  ProgressCard.swift
//  My Wedding Planning App
//
//  Extracted from DashboardViewV2.swift
//

import SwiftUI

struct ProgressCard: View {
    let value: String
    let percentage: Double
    let label: String
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(foregroundColor.opacity(0.6))
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(foregroundColor)
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("^")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(foregroundColor.opacity(0.6))
                    .offset(y: -12)
                Text(value)
                    .font(.system(size: 64, weight: .black))
                    .foregroundColor(foregroundColor)
            }

            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(foregroundColor.opacity(0.9))

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(foregroundColor.opacity(0.2))
                        .frame(height: 8)

                    Rectangle()
                        .fill(foregroundColor)
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Spacer()
                Text("...")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(foregroundColor.opacity(0.4))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue("\(value), \(Int(percentage))% complete")
    }
}
