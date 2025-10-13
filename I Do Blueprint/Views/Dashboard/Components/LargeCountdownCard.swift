//
//  LargeCountdownCard.swift
//  My Wedding Planning App
//
//  Extracted from DashboardViewV2.swift
//

import SwiftUI

struct LargeCountdownCard: View {
    let daysRemaining: Int
    let weddingDate: Date
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 28))
                    .foregroundColor(foregroundColor.opacity(0.6))
                Spacer()
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("^")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(foregroundColor.opacity(0.6))
                    .offset(y: -20)
                Text("\(daysRemaining)")
                    .font(.system(size: 96, weight: .black))
                    .foregroundColor(foregroundColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Days Until Wedding")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(foregroundColor)

                Text(weddingDate, style: .date)
                    .font(.system(size: 15))
                    .foregroundColor(foregroundColor.opacity(0.7))
            }

            HStack {
                Spacer()
                Text("...")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(foregroundColor.opacity(0.4))
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 3)
        )
    }
}
