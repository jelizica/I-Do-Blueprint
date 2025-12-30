//
//  Components.swift
//  I Do Blueprint
//
//  Reusable view modifiers and component styles
//

import SwiftUI

// MARK: - View Modifiers

public struct CardStyle: ViewModifier {
    public var padding: CGFloat = Spacing.lg
    public var shadow: ShadowStyle = .light

    public init(padding: CGFloat = Spacing.lg, shadow: ShadowStyle = .light) {
        self.padding = padding
        self.shadow = shadow
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(AppColors.cardBackground)
                    .shadow(
                        color: shadow.color,
                        radius: shadow.radius,
                        x: shadow.offset.width,
                        y: shadow.offset.height
                    )
            )
    }
}

public struct HoverableCardStyle: ViewModifier {
    @State private var isHovering = false
    public var padding: CGFloat = Spacing.lg

    public init(padding: CGFloat = Spacing.lg) {
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(AppColors.cardBackground)
                    .shadow(
                        color: isHovering ? AppColors.shadowMedium : AppColors.shadowLight,
                        radius: isHovering ? 6 : 3,
                        x: 0,
                        y: isHovering ? 3 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isHovering ? AppColors.borderHover : AppColors.borderLight, lineWidth: 1)
            )
            .scaleEffect(isHovering ? 1.01 : 1.0)
            .animation(AnimationStyle.fast, value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

public struct BadgeStyle: ViewModifier {
    public var color: Color
    public var size: BadgeSize = .medium

    public enum BadgeSize {
        case small, medium, large

        public var fontSize: Font {
            switch self {
            case .small: return Typography.caption2
            case .medium: return Typography.caption
            case .large: return Typography.bodySmall
            }
        }

        public var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8)
            case .large: return EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
            }
        }
    }

    public init(color: Color, size: BadgeSize = .medium) {
        self.color = color
        self.size = size
    }

    public func body(content: Content) -> some View {
        content
            .font(size.fontSize)
            .fontWeight(.medium)
            .padding(size.padding)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// MARK: - Accessibility Helpers

/// Accessibility modifier for interactive list items
public struct AccessibleListItem: ViewModifier {
    public let label: String
    public let hint: String?
    public let value: String?
    public let isSelected: Bool

    public init(label: String, hint: String? = nil, value: String? = nil, isSelected: Bool = false) {
        self.label = label
        self.hint = hint
        self.value = value
        self.isSelected = isSelected
    }

    public func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Accessibility modifier for form fields
public struct AccessibleFormField: ViewModifier {
    public let label: String
    public let hint: String?
    public let isRequired: Bool

    public init(label: String, hint: String? = nil, isRequired: Bool = false) {
        self.label = label
        self.hint = hint
        self.isRequired = isRequired
    }

    public func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? (isRequired ? "Required field" : ""))
            .accessibilityAddTraits(isRequired ? .isHeader : [])
    }
}

/// Accessibility modifier for action buttons
public struct AccessibleActionButton: ViewModifier {
    public let label: String
    public let hint: String?
    public let isDestructive: Bool

    public init(label: String, hint: String? = nil, isDestructive: Bool = false) {
        self.label = label
        self.hint = hint
        self.isDestructive = isDestructive
    }

    public func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(isDestructive ? [.isButton, .isHeader] : .isButton)
    }
}

/// Accessibility modifier for status badges
public struct AccessibleBadge: ViewModifier {
    public let status: String
    public let description: String?

    public init(status: String, description: String? = nil) {
        self.status = status
        self.description = description
    }

    public func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(status)\(description != nil ? ", \(description!)" : "")")
            .accessibilityAddTraits(.isStaticText)
    }
}

/// Accessibility modifier for headings
public struct AccessibleHeading: ViewModifier {
    public let level: Int

    public init(level: Int) {
        self.level = level
    }

    public func body(content: Content) -> some View {
        // Clamp level to 1...3 and map to accessibility heading level
        let clamped = max(1, min(level, 3))
        let headingLevel: AccessibilityHeadingLevel = (clamped == 1) ? .h1 : (clamped == 2 ? .h2 : .h3)
        // Higher priority announces earlier
        let sortPriority: Double = (clamped == 1) ? 100 : (clamped == 2 ? 80 : 60)

        return content
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(headingLevel)
            .accessibilitySortPriority(sortPriority)
    }
}

// MARK: - View Extensions

extension View {
    public func card(padding: CGFloat = Spacing.lg, shadow: ShadowStyle = .light) -> some View {
        modifier(CardStyle(padding: padding, shadow: shadow))
    }

    public func hoverableCard(padding: CGFloat = Spacing.lg) -> some View {
        modifier(HoverableCardStyle(padding: padding))
    }

    public func badge(color: Color, size: BadgeStyle.BadgeSize = .medium) -> some View {
        modifier(BadgeStyle(color: color, size: size))
    }

    // MARK: - Accessibility Extensions

    /// Make a list item accessible with proper labels and hints
    public func accessibleListItem(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        isSelected: Bool = false
    ) -> some View {
        modifier(AccessibleListItem(
            label: label,
            hint: hint,
            value: value,
            isSelected: isSelected
        ))
    }

    /// Make a form field accessible with proper labels and required status
    public func accessibleFormField(
        label: String,
        hint: String? = nil,
        isRequired: Bool = false
    ) -> some View {
        modifier(AccessibleFormField(
            label: label,
            hint: hint,
            isRequired: isRequired
        ))
    }

    /// Make an action button accessible with proper labels and hints
    public func accessibleActionButton(
        label: String,
        hint: String? = nil,
        isDestructive: Bool = false
    ) -> some View {
        modifier(AccessibleActionButton(
            label: label,
            hint: hint,
            isDestructive: isDestructive
        ))
    }

    /// Make a status badge accessible
    public func accessibleBadge(
        status: String,
        description: String? = nil
    ) -> some View {
        modifier(AccessibleBadge(
            status: status,
            description: description
        ))
    }

    /// Mark view as a heading for screen readers
    public func accessibleHeading(level: Int = 1) -> some View {
        modifier(AccessibleHeading(level: level))
    }
}
