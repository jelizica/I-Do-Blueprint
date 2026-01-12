//
//  BillCalculatorSectionView.swift
//  I Do Blueprint
//
//  Reusable section container for Bill Calculator item groups
//

import SwiftUI

struct BillCalculatorSectionView<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let sectionTotal: Double
    let gradientColors: [Color]
    let accentColor: Color
    @ViewBuilder let content: () -> Content

    @Environment(\.appStores) private var appStores

    var body: some View {
        VStack(spacing: 0) {
            headerView
            contentContainer
        }
        .background(SemanticColors.backgroundPrimary)
        .cornerRadius(CornerRadius.lg)
        .macOSShadow(.subtle)
    }

    private var headerView: some View {
        HStack {
            HStack(spacing: Spacing.md) {
                iconView
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(Typography.heading)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("Section Total")
                    .font(Typography.caption)
                    .foregroundColor(.white.opacity(0.9))
                Text(formatCurrency(sectionTotal))
                    .font(Typography.numberLarge)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.lg)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.white.opacity(0.2))
                .frame(width: 32, height: 32)

            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var contentContainer: some View {
        VStack(spacing: Spacing.md) {
            content()
        }
        .padding(Spacing.lg)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = appStores.settings.settings.global.currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
