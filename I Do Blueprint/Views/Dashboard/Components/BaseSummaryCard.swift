//
//  BaseSummaryCard.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct BaseSummaryCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isHovered: Bool
    let hasAlert: Bool
    @ViewBuilder let content: () -> Content

    init(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        isHovered: Binding<Bool>,
        hasAlert: Bool = false,
        @ViewBuilder content: @escaping () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        _isHovered = isHovered
        self.hasAlert = hasAlert
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            .linearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if hasAlert {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }

            // Content
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: isHovered ? color.opacity(0.15) : .black.opacity(0.05),
                    radius: isHovered ? 16 : 8,
                    x: 0,
                    y: isHovered ? 8 : 4))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    .linearGradient(
                        colors: isHovered ? [color.opacity(0.3), color.opacity(0.2)] : [
                            Color.gray.opacity(0.1),
                            Color.gray.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing),
                    lineWidth: 2))
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
}
