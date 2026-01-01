//
//  WindowSize.swift
//  I Do Blueprint
//
//  Responsive breakpoints for adaptive layouts across the app
//  LLM Council unanimous recommendation: Design system location
//

import SwiftUI

/// Defines responsive breakpoints for adaptive layouts
/// Used across Guest Management, Vendor Management, Budget, and other views
///
/// Breakpoints:
/// - compact: < 700pt (split screen on 13" MacBook Air)
/// - regular: 700-1000pt (standard window sizes)
/// - large: > 1000pt (expanded windows)
enum WindowSize: Int, Comparable, CaseIterable {
    case compact
    case regular
    case large

    /// Initialize WindowSize based on available width
    /// - Parameter width: The available width in points
    init(width: CGFloat) {
        switch width {
        case ..<WindowSize.Breakpoints.compactMax:
            self = .compact
        case WindowSize.Breakpoints.compactMax..<WindowSize.Breakpoints.regularMax:
            self = .regular
        default:
            self = .large
        }
    }

    /// Breakpoint values for reference and consistency
    struct Breakpoints {
        /// Maximum width for compact mode (below this is compact)
        static let compactMax: CGFloat = 700

        /// Maximum width for regular mode (below this is regular, above is large)
        static let regularMax: CGFloat = 1000
    }

    // MARK: - Comparable Conformance

    /// Enables comparison logic like `if windowSize < .large`
    static func < (lhs: WindowSize, rhs: WindowSize) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - CGFloat Extension

extension CGFloat {
    /// Convenience property to get WindowSize for a width value
    ///
    /// Example:
    /// ```swift
    /// let size = geometry.size.width.windowSize
    /// ```
    var windowSize: WindowSize {
        WindowSize(width: self)
    }
}
