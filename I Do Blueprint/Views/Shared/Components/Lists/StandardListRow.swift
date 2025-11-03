//
//  StandardListRow.swift
//  I Do Blueprint
//
//  Standard list row component for consistent list items
//

import SwiftUI

/// Standard list row with icon, title, subtitle, and optional accessories
struct StandardListRow: View {
    let icon: String?
    let iconColor: Color?
    let title: String
    let subtitle: String?
    let badge: String?
    let badgeColor: Color?
    let accessory: Accessory
    let action: (() -> Void)?

    @State private var isHovering = false

    init(
        icon: String? = nil,
        iconColor: Color? = nil,
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        badgeColor: Color? = nil,
        accessory: Accessory = .none,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.badgeColor = badgeColor
        self.accessory = accessory
        self.action = action
    }

    enum Accessory {
        case none
        case chevron
        case checkmark
        case toggle(Binding<Bool>)
        case button(String, () -> Void)
    }

    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: Spacing.md) {
                // Icon
                if let icon = icon {
                    Circle()
                        .fill((iconColor ?? .blue).opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: icon)
                                .font(.body)
                                .foregroundColor(iconColor ?? .blue)
                        )
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Spacing.sm) {
                        Text(title)
                            .font(Typography.bodyRegular)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.textPrimary)

                        if let badge = badge {
                            Text(badge)
                                .font(Typography.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill((badgeColor ?? .blue).opacity(0.15))
                                )
                                .foregroundColor(badgeColor ?? .blue)
                        }
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Accessory
                accessoryView
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isHovering ? AppColors.hoverBackground : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil && !hasInteractiveAccessory)
        .onHover { hovering in
            withAnimation(AnimationStyle.fast) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(action != nil ? .isButton : [])
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .none:
            EmptyView()

        case .chevron:
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)

        case .checkmark:
            Image(systemName: "checkmark")
                .font(.body)
                .foregroundColor(AppColors.success)

        case .toggle(let binding):
            Toggle("", isOn: binding)
                .labelsHidden()

        case .button(let title, let buttonAction):
            Button(action: buttonAction) {
                Text(title)
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
        }
    }

    private var hasInteractiveAccessory: Bool {
        switch accessory {
        case .toggle, .button:
            return true
        default:
            return false
        }
    }

    private var accessibilityLabel: String {
        var label = title
        if let subtitle = subtitle {
            label += ", \(subtitle)"
        }
        if let badge = badge {
            label += ", \(badge)"
        }
        return label
    }
}

// MARK: - Selectable List Row

/// List row with selection state
struct SelectableListRow: View {
    let icon: String?
    let iconColor: Color?
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)

                // Icon
                if let icon = icon {
                    Circle()
                        .fill((iconColor ?? .blue).opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: icon)
                                .font(.callout)
                                .foregroundColor(iconColor ?? .blue)
                        )
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.bodyRegular)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? AppColors.primaryLight : (isHovering ? AppColors.hoverBackground : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AnimationStyle.fast) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title + (subtitle != nil ? ", \(subtitle!)" : ""))
        .accessibilityAddTraits([.isButton, isSelected ? .isSelected : []])
    }
}

// MARK: - Previews

#Preview("Standard List Rows") {
    VStack(spacing: 0) {
        StandardListRow(
            icon: "person.fill",
            iconColor: .blue,
            title: "John Smith",
            subtitle: "john@example.com",
            accessory: .chevron,
            action: {}
        )

        Divider()

        StandardListRow(
            icon: "building.2.fill",
            iconColor: .purple,
            title: "Grand Ballroom",
            subtitle: "Downtown Hotel • Booked",
            badge: "Confirmed",
            badgeColor: .green,
            accessory: .checkmark
        )

        Divider()

        StandardListRow(
            icon: "bell.fill",
            iconColor: .orange,
            title: "Push Notifications",
            subtitle: "Receive updates about your wedding",
            accessory: .toggle(.constant(true))
        )

        Divider()

        StandardListRow(
            icon: "doc.fill",
            iconColor: .red,
            title: "Contract.pdf",
            subtitle: "Uploaded 2 days ago • 2.4 MB",
            accessory: .button("Download", {})
        )
    }
    .padding()
}

#Preview("Selectable List Rows") {
    VStack(spacing: Spacing.xs) {
        SelectableListRow(
            icon: "person.fill",
            iconColor: .blue,
            title: "John Smith",
            subtitle: "Attending",
            isSelected: true,
            action: {}
        )

        SelectableListRow(
            icon: "person.fill",
            iconColor: .blue,
            title: "Jane Doe",
            subtitle: "Pending",
            isSelected: false,
            action: {}
        )

        SelectableListRow(
            icon: "person.fill",
            iconColor: .blue,
            title: "Bob Johnson",
            subtitle: "Declined",
            isSelected: false,
            action: {}
        )
    }
    .padding()
}
