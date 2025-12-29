//
//  StatusBadge.swift
//  I Do Blueprint
//
//  Generic status badge component for Budget views
//

import SwiftUI

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
            )
    }
}
