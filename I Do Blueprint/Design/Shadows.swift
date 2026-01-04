//
//  Shadows.swift
//  I Do Blueprint
//
//  Shadow styles for consistent elevation and depth
//  Includes macOS-native shadow system for premium visual effects
//

import SwiftUI

// MARK: - Legacy Shadows (Compatibility)

public enum ShadowStyle {
    case none
    case light
    case medium
    case heavy

    public var radius: CGFloat {
        switch self {
        case .none: return 0
        case .light: return 3
        case .medium: return 6
        case .heavy: return 10
        }
    }

    public var offset: CGSize {
        switch self {
        case .none: return .zero
        case .light: return CGSize(width: 0, height: 2)
        case .medium: return CGSize(width: 0, height: 4)
        case .heavy: return CGSize(width: 0, height: 6)
        }
    }

    public var color: Color {
        switch self {
        case .none: return .clear
        case .light: return AppColors.shadowLight
        case .medium: return AppColors.shadowMedium
        case .heavy: return AppColors.shadowHeavy
        }
    }
}

// MARK: - macOS Native Shadow System

/// Multi-layer shadow system inspired by native macOS apps (Finder, Notes, Calendar)
/// Each shadow level uses 3 layers for realistic depth perception:
/// - Contact shadow: Tight, dark shadow where element meets surface
/// - Ambient shadow: Medium spread for general depth
/// - Depth shadow: Large, soft shadow for elevation
public enum MacOSShadow {
    /// Subtle shadow for Level 1 cards (resting state)
    /// Use for: Dashboard cards, list items, panels
    case subtle
    
    /// Elevated shadow for hover/selected states
    /// Use for: Hovered cards, selected items, focused elements
    case elevated
    
    /// Floating shadow for popovers and tooltips
    /// Use for: Dropdown menus, context menus, tooltips
    case floating
    
    /// Modal shadow for sheets and dialogs
    /// Use for: Modal sheets, alert dialogs, overlays
    case modal
    
    /// Shadow layers as (color, radius, x, y) tuples
    /// Apply all layers for complete shadow effect
    public var layers: [(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)] {
        switch self {
        case .subtle:
            return [
                (Color.black.opacity(0.03), 1, 0, 0.5),   // Contact shadow
                (Color.black.opacity(0.05), 4, 0, 2),     // Ambient shadow
                (Color.black.opacity(0.02), 8, 0, 4)      // Depth shadow
            ]
        case .elevated:
            return [
                (Color.black.opacity(0.04), 1, 0, 1),     // Contact shadow
                (Color.black.opacity(0.08), 8, 0, 4),     // Ambient shadow
                (Color.black.opacity(0.04), 16, 0, 8)     // Depth shadow
            ]
        case .floating:
            return [
                (Color.black.opacity(0.05), 2, 0, 1),     // Contact shadow
                (Color.black.opacity(0.10), 12, 0, 6),    // Ambient shadow
                (Color.black.opacity(0.05), 24, 0, 12)    // Depth shadow
            ]
        case .modal:
            return [
                (Color.black.opacity(0.08), 4, 0, 2),     // Contact shadow
                (Color.black.opacity(0.15), 20, 0, 10),   // Ambient shadow
                (Color.black.opacity(0.08), 40, 0, 20)    // Depth shadow
            ]
        }
    }
}

// MARK: - Shadow View Modifier

/// Applies macOS-native multi-layer shadows to any view
public struct MacOSShadowModifier: ViewModifier {
    let shadow: MacOSShadow
    
    public func body(content: Content) -> some View {
        var result = AnyView(content)
        for layer in shadow.layers {
            result = AnyView(
                result.shadow(
                    color: layer.color,
                    radius: layer.radius,
                    x: layer.x,
                    y: layer.y
                )
            )
        }
        return result
    }
}

// MARK: - View Extension for macOS Shadows

extension View {
    /// Applies macOS-native multi-layer shadow
    /// - Parameter shadow: The shadow style to apply
    /// - Returns: View with multi-layer shadow applied
    public func macOSShadow(_ shadow: MacOSShadow) -> some View {
        modifier(MacOSShadowModifier(shadow: shadow))
    }
}
