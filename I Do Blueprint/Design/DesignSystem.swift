//
//  DesignSystem.swift
//  I Do Blueprint
//
//  Design system facade for consistent UI/UX across the application
//
//  This file serves as the main entry point for the design system.
//  Individual components are organized in separate files:
//  - ColorPalette.swift: Color definitions, semantic colors, and accessibility helpers
//  - Typography.swift: Typography system and text styles
//  - Spacing.swift: Spacing, layout, and corner radius constants
//  - Shadows.swift: Shadow styles and elevation
//  - Animations.swift: Animation styles and transitions
//  - Components.swift: View modifiers and component styles
//  - Gradients.swift: Gradient definitions
//
//  All components can be accessed directly (e.g., AppColors.primary, Typography.title1, Spacing.lg)
//

import SwiftUI

// MARK: - Design System Facade
//
// This file intentionally left minimal to serve as a facade.
// All design system components are now split into separate, focused files.
//
// ## Usage
//
// Import individual components as needed:
// ```swift
// // Colors
// Text("Hello").foregroundColor(AppColors.textPrimary)
//
// // Typography
// Text("Title").font(Typography.title1)
//
// // Spacing
// VStack(spacing: Spacing.md) { ... }
//
// // Shadows
// .shadow(color: ShadowStyle.light.color, radius: ShadowStyle.light.radius)
//
// // Animations
// .animation(AnimationStyle.spring, value: isExpanded)
//
// // Gradients
// .background(AppGradients.appBackground)
// ```
//
// ## Architecture
//
// The design system follows a modular architecture:
// - **ColorPalette.swift**: Semantic colors, feature-specific colors, accessibility helpers
// - **Typography.swift**: Font styles, text modifiers
// - **Spacing.swift**: Layout constants, corner radii
// - **Shadows.swift**: Shadow definitions for elevation
// - **Animations.swift**: Animation presets and transitions
// - **Components.swift**: Reusable view modifiers and component styles
// - **Gradients.swift**: Gradient definitions for backgrounds and effects
//
// This modular approach:
// - Improves maintainability by separating concerns
// - Reduces file size for easier navigation
// - Enables better code organization and discoverability
// - Follows single responsibility principle
