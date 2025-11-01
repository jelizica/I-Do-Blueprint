//
//  SummaryCardView.swift
//  I Do Blueprint
//
//  Extracted from BudgetDevelopmentView.swift
//

import AppKit
import SwiftUI

struct SummaryCardView: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    var formatAsCurrency: Bool = true

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Enhanced icon with background circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }

                Spacer()

                // Subtle trend indicator (optional - could be expanded later)
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(color.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(formatAsCurrency ? formatCurrency(value) : String(format: "%.0f", value))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.03), color.opacity(0.01)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing)))
                .overlay(
                    // Enhanced border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(isHovered ? 0.3 : 0.1), lineWidth: isHovered ? 2 : 1)))
        .shadow(
            color: color.opacity(isHovered ? 0.15 : 0.08),
            radius: isHovered ? 12 : 6,
            x: 0,
            y: isHovered ? 6 : 3)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true

        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
