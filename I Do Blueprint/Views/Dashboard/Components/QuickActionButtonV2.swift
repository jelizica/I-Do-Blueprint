//
//  QuickActionButtonV2.swift
//  My Wedding Planning App
//
//  Extracted from DashboardViewV2.swift
//

import SwiftUI

struct QuickActionButtonV2: View {
    let icon: String
    let title: String
    let backgroundColor: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: {
            HapticFeedback.buttonTap()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .overlay(
                Rectangle()
                    .stroke(AppColors.textPrimary, lineWidth: 2)
            )
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .shadow(color: AppColors.textPrimary.opacity(isHovering ? 0.2 : 0), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .animation(AnimationPresets.hover, value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
