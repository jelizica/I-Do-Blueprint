//
//  DashboardProgressCard.swift
//  I Do Blueprint
//
//  Dashboard-specific progress card using unified ProgressBar component
//

import SwiftUI

/// Dashboard progress card with unified ProgressBar
struct DashboardProgressCard: View {
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

            // Use unified ProgressBar component
            ProgressBar(
                value: percentage / 100,
                color: foregroundColor,
                backgroundColor: foregroundColor.opacity(0.2),
                height: 8,
                showPercentage: false
            )

            HStack {
                Spacer()
                Text("...")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(foregroundColor.opacity(0.4))
            }
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(SemanticColors.textPrimary, lineWidth: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue("\(value), \(Int(percentage))% complete")
    }
}

// MARK: - Preview

#Preview {
    DashboardProgressCard(
        value: "30/50",
        percentage: 60,
        label: "Tasks Complete",
        backgroundColor: ThemeAwareDashboard.taskProgressCard,
        foregroundColor: .white
    )
    .frame(width: 400, height: 240)
}
