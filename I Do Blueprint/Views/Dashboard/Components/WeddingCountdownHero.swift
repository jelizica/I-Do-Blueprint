//
//  WeddingCountdownHero.swift
//  I Do Blueprint
//
//  Hero countdown card with elegant design
//

import SwiftUI

struct WeddingCountdownHero: View {
    let weddingDate: Date?
    let daysUntil: Int

    var body: some View {
        ZStack {
            // Background with gradient and pattern
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.fromHex( "FDF2F8"),
                            Color.fromHex( "FCE7F3"),
                            Color.fromHex( "F3E8FF")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.fromHex( "FBCFE8"),
                                    Color.fromHex( "E9D5FF")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            VStack(spacing: Spacing.xl) {
                // Icons
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.fromHex( "EC4899"), Color.fromHex( "DB2777")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(Color.fromHex( "A855F7"))
                }

                // Title
                Text("Our Wedding Journey")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.fromHex( "DB2777"),
                                Color.fromHex( "F43F5E"),
                                Color.fromHex( "9333EA")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)

                // Subtitle
                if let weddingDate = weddingDate {
                    Text(formattedWeddingDate(weddingDate))
                        .font(Typography.title3)
                        .foregroundColor(AppColors.textSecondary)
                }

                // Countdown Card
                VStack(spacing: Spacing.md) {
                    Text("\(daysUntil)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.fromHex( "DB2777"), Color.fromHex( "9333EA")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Days Until Forever")
                        .font(Typography.bodyLarge)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(Spacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(AppColors.textPrimary.opacity(0.6))
                        .shadow(color: Color.fromHex( "FBCFE8").opacity(0.5), radius: 20, y: 10)
                )
            }
            .padding(Spacing.xxxl)
        }
        .frame(height: 400)
    }

    private func formattedWeddingDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    WeddingCountdownHero(
        weddingDate: Date().addingTimeInterval(60 * 60 * 24 * 120),
        daysUntil: 120
    )
    .padding()
    .frame(width: 800)
}
