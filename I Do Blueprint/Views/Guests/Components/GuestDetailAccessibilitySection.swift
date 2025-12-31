//
//  GuestDetailAccessibilitySection.swift
//  I Do Blueprint
//
//  Accessibility needs section for guest detail modal
//

import SwiftUI

struct GuestDetailAccessibilitySection: View {
    let accessibilityNeeds: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "accessibility")
                    .foregroundColor(AppColors.info)
                Text("Accessibility Needs")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text(accessibilityNeeds)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(AppColors.info.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.info.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    GuestDetailAccessibilitySection(
        accessibilityNeeds: "Wheelchair accessible seating required. Needs to be near an exit."
    )
    .padding()
    .frame(width: 400)
}
