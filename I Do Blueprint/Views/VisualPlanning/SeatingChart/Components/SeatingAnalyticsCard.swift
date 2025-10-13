//
//  SeatingAnalyticsCard.swift
//  My Wedding Planning App
//
//  Analytics card component for displaying seating statistics
//

import SwiftUI

struct SeatingAnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovering ? 0.12 : 0.06),
                    radius: isHovering ? 8 : 3,
                    x: 0,
                    y: isHovering ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.05), color.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)))
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
