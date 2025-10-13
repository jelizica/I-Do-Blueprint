//
//  AccessibilityExtensions.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2025-10-12.
//

import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    /// Makes a view accessible as a list item with proper traits and labeling
    /// - Parameters:
    ///   - label: The accessibility label for the item
    /// - Returns: Modified view with accessibility traits
    func accessibleListItem(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
    }

    /// Makes an action button accessible with descriptive labeling
    /// - Parameters:
    ///   - label: The accessibility label for the button
    ///   - hint: Optional hint describing what the button does
    /// - Returns: Modified view with accessibility traits
    func accessibleActionButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(hint ?? "")
    }

}
