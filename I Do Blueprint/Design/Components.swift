//
//  Components.swift
//  I Do Blueprint
//
//  Reusable view modifiers and component styles
//  Includes macOS-native card styles for premium visual effects
//

import SwiftUI

// MARK: - macOS Native Materials

/// SwiftUI Material wrapper for consistent usage across the app
/// Materials create visual separation using blur and translucency
public enum MacOSMaterial {
    /// Maximum background visibility - Control Center style
    case ultraThin
    /// High background visibility
    case thin
    /// Balanced visibility - most common for cards
    case regular
    /// Low background visibility - modals
    case thick
    /// Minimal background visibility - toolbars
    case chrome
    
    /// Convert to SwiftUI Material type
    public var swiftUIMaterial: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .chrome: return .bar
        }
    }
}

// MARK: - Native Card Style (macOS)

/// Premium card style inspired by native macOS apps (Finder, Notes, Calendar)
/// Features:
/// - Material background with vibrancy
/// - Gradient border stroke for depth
/// - Multi-layer shadows
/// - Hover elevation animation
public struct NativeCardStyle: ViewModifier {
    let depth: DepthLevel
    let material: MacOSMaterial
    let showBorder: Bool
    @State private var isHovered = false
    
    public init(
        depth: DepthLevel = .card,
        material: MacOSMaterial = .regular,
        showBorder: Bool = true
    ) {
        self.depth = depth
        self.material = material
        self.showBorder = showBorder
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: depth.cornerRadius)
                    .fill(material.swiftUIMaterial)
            )
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: depth.cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isHovered ? 0.35 : 0.25),
                                        Color.white.opacity(isHovered ? 0.15 : 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                }
            )
            .macOSShadow(isHovered ? .elevated : depth.shadow)
            .scaleEffect(isHovered ? 1.005 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Native Progress Bar Style

/// Premium progress bar with inner shadow and glow effect
/// Inspired by native macOS progress indicators
public struct NativeProgressBarStyle: ViewModifier {
    let progress: Double
    let color: Color
    let height: CGFloat
    let showGlow: Bool
    
    public init(
        progress: Double,
        color: Color,
        height: CGFloat = 8,
        showGlow: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.height = height
        self.showGlow = showGlow
    }
    
    public func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track with inner shadow effect
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(nsColor: .separatorColor).opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: height / 2)
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    )
                    .frame(height: height)
                
                // Progress fill with gradient and glow
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geometry.size.width * progress, height), height: height)
                    .shadow(color: showGlow ? color.opacity(0.4) : .clear, radius: 4, x: 0, y: 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Native Divider Style

/// Gradient divider that fades at edges - native macOS style
public struct NativeDividerStyle: View {
    let opacity: Double
    
    public init(opacity: Double = 0.5) {
        self.opacity = opacity
    }
    
    public var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color(nsColor: .separatorColor).opacity(opacity),
                        Color(nsColor: .separatorColor).opacity(opacity),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

// MARK: - Native Icon Badge Style

/// Circular icon badge with gradient background - native macOS style
public struct NativeIconBadge: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    
    public init(systemName: String, color: Color, size: CGFloat = 40) {
        self.systemName = systemName
        self.color = color
        self.size = size
    }
    
    public var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.2),
                        color.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Legacy View Modifiers (Compatibility)

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
    // MARK: - Native macOS Card Styles
    
    /// Apply native macOS card style with material background and hover effects
    /// - Parameters:
    ///   - depth: The depth level for shadow and corner radius
    ///   - material: The material type for background vibrancy
    ///   - showBorder: Whether to show gradient border stroke
    /// - Returns: View with native card styling applied
    public func nativeCard(
        depth: DepthLevel = .card,
        material: MacOSMaterial = .regular,
        showBorder: Bool = true
    ) -> some View {
        modifier(NativeCardStyle(depth: depth, material: material, showBorder: showBorder))
    }
    
    // MARK: - Legacy Card Styles
    
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
