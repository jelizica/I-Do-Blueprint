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
    @available(*, deprecated, message: "Use DesignSystem accessibleListItem(label:hint:value:isSelected:) from Design/DesignSystem.swift")
    func accessibleListItem(label: String) -> some View {
        // Forward to DesignSystem's AccessibleListItem modifier to unify behavior
        self.modifier(AccessibleListItem(
            label: label,
            hint: nil,
            value: nil,
            isSelected: false
        ))
    }

    /// Makes an action button accessible with descriptive labeling
    /// - Parameters:
    ///   - label: The accessibility label for the button
    ///   - hint: Optional hint describing what the button does
    /// - Returns: Modified view with accessibility traits
    @available(*, deprecated, message: "Use accessibleActionButton(label:hint:isDestructive:) from Design/DesignSystem.swift")
    func accessibleActionButton(label: String, hint: String? = nil) -> some View {
        // Forward to DesignSystem's AccessibleActionButton modifier to unify behavior
        self.modifier(AccessibleActionButton(
            label: label,
            hint: hint,
            isDestructive: false
        ))
    }

}
