//
//  DashboardSection.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct DashboardSection<Content: View>: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let priority: SectionPriority
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Priority Badge
                if priority != .normal {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(priority.color)
                            .frame(width: 8, height: 8)

                        Text(priority.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(priority.color)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(priority.color.opacity(0.1)))
                }
            }

            // Content
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(priority.borderColor, lineWidth: 2))
    }
}

// MARK: - Section Priority

enum SectionPriority {
    case high
    case medium
    case normal

    var displayName: String {
        switch self {
        case .high: "High Priority"
        case .medium: "Medium Priority"
        case .normal: "Normal"
        }
    }

    var color: Color {
        switch self {
        case .high: .red
        case .medium: .orange
        case .normal: .gray
        }
    }

    var borderColor: Color {
        switch self {
        case .high: .red.opacity(0.2)
        case .medium: .orange.opacity(0.2)
        case .normal: .gray.opacity(0.1)
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardSection(
        title: "Priority & Alerts",
        description: "Urgent items that need immediate attention",
        icon: "exclamationmark.triangle.fill",
        iconColor: .red,
        priority: .high) {
        Text("Content goes here")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
    .padding()
    .frame(width: 800)
}
