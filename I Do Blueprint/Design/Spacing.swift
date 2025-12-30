//
//  Spacing.swift
//  I Do Blueprint
//
//  Spacing, layout, and corner radius constants for consistent UI
//

import SwiftUI

// MARK: - Spacing

public enum Spacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 32
    public static let huge: CGFloat = 48
}

// MARK: - Responsive Layout

/// Responsive layout helpers for adaptive UI
public enum ResponsiveLayout {
    /// Calculates optimal list panel width based on container geometry
    public static func listPanelWidth(for geometry: GeometryProxy) -> CGFloat {
        let width = geometry.size.width
        if width < 600 {
            return width * 0.95 // 95% on small screens
        } else if width < 1200 {
            return min(480, width * 0.4) // 40% or 480px max
        } else {
            return min(600, width * 0.35) // 35% or 600px max
        }
    }

    /// Minimum width for list panels
    public static let minListPanelWidth: CGFloat = 320
    /// Maximum width for list panels
    public static let maxListPanelWidth: CGFloat = 600
}

// MARK: - Corner Radius

public enum CornerRadius {
    public static let sm: CGFloat = 6
    public static let md: CGFloat = 8
    public static let lg: CGFloat = 12
    public static let xl: CGFloat = 16
    public static let pill: CGFloat = 999
}
