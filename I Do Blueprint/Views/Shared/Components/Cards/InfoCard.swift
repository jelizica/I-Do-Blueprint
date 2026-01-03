//
//  InfoCard.swift
//  I Do Blueprint
//
//  Informational card component for displaying key information
//

import SwiftUI

/// Informational card for displaying key details with icon, title, and content
struct InfoCard: View {
    private let logger = AppLogger.ui
    let icon: String
    let title: String
    let content: String
    let color: Color
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        content: String,
        color: Color = .blue,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.content = content
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: Spacing.md) {
                // Icon
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                    )

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.subheading)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text(content)
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Chevron if actionable
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }
            .padding(Spacing.lg)
            .card(shadow: .light)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(content)")
        .accessibilityAddTraits(action != nil ? .isButton : .isStaticText)
    }
}

// MARK: - Previews

#Preview("Info Card") {
    VStack(spacing: Spacing.md) {
        InfoCard(
            icon: "calendar",
            title: "Wedding Date",
            content: "June 15, 2024",
            color: .blue
        )

        InfoCard(
            icon: "mappin.circle.fill",
            title: "Venue",
            content: "Grand Ballroom, Downtown Hotel",
            color: .purple,
            action: {
                // TODO: Implement action - print("Venue tapped")
            }
        )

        InfoCard(
            icon: "person.2.fill",
            title: "Guest Count",
            content: "150 confirmed guests",
            color: .green
        )
    }
    .padding()
}
