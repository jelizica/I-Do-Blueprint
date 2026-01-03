//
//  ActionCard.swift
//  I Do Blueprint
//
//  Action card component for primary actions
//

import SwiftUI

/// Action card for prominent call-to-action buttons
struct ActionCard: View {
    private let logger = AppLogger.ui
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let color: Color
    let action: () -> Void

    @State private var isHovering = false

    init(
        icon: String,
        title: String,
        description: String,
        buttonTitle: String,
        color: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.buttonTitle = buttonTitle
        self.color = color
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Icon
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                )

            // Content
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title)
                    .font(Typography.title3)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(description)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action button
            Button(action: action) {
                HStack {
                    Text(buttonTitle)
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .foregroundColor(SemanticColors.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(color)
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
            .accessibleActionButton(
                label: buttonTitle,
                hint: description
            )
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColors.backgroundSecondary)
                .shadow(
                    color: isHovering ? SemanticColors.shadow : SemanticColors.shadowLight,
                    radius: isHovering ? 6 : 3,
                    x: 0,
                    y: isHovering ? 3 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(isHovering ? color.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(AnimationStyle.fast, value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Compact Action Card

/// Compact version of action card for smaller spaces
struct CompactActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundColor(color)
                    )

                Text(title)
                    .font(Typography.bodyRegular)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(SemanticColors.backgroundSecondary)
                    .shadow(
                        color: isHovering ? SemanticColors.shadow : SemanticColors.shadowLight,
                        radius: isHovering ? 4 : 2,
                        x: 0,
                        y: 2
                    )
            )
            .scaleEffect(isHovering ? 1.01 : 1.0)
            .animation(AnimationStyle.fast, value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibleActionButton(label: title)
    }
}

// MARK: - Previews

#Preview("Action Card") {
    VStack(spacing: Spacing.lg) {
        ActionCard(
            icon: "person.badge.plus",
            title: "Add Guests",
            description: "Start building your guest list and track RSVPs for your wedding.",
            buttonTitle: "Add Your First Guest",
            color: .blue,
            action: {
                print("Add guest tapped")
            }
        )

        ActionCard(
            icon: "building.2.fill",
            title: "Find Vendors",
            description: "Browse and book trusted vendors for your special day.",
            buttonTitle: "Browse Vendors",
            color: .purple,
            action: {
                // TODO: Implement action - print("Browse vendors tapped")
            }
        )
    }
    .padding()
}

#Preview("Compact Action Card") {
    VStack(spacing: Spacing.sm) {
        CompactActionCard(
            icon: "calendar.badge.plus",
            title: "Add Event",
            color: .blue,
            action: {}
        )

        CompactActionCard(
            icon: "doc.badge.plus",
            title: "Upload Document",
            color: .green,
            action: {}
        )

        CompactActionCard(
            icon: "note.text.badge.plus",
            title: "Create Note",
            color: .orange,
            action: {}
        )
    }
    .padding()
}
