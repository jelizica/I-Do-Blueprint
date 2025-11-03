//
//  EmptyStateConfig.swift
//  I Do Blueprint
//
//  Configuration model for UnifiedEmptyStateView
//  Provides factory methods for common empty state scenarios
//

import SwiftUI

/// Configuration for empty state views
struct EmptyStateConfig {
    let icon: String
    let title: String
    let message: String
    let action: ActionConfig?

    struct ActionConfig {
        let title: String
        let icon: String
        let handler: () -> Void

        init(title: String, icon: String = "plus.circle.fill", handler: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.handler = handler
        }
    }

    init(icon: String, title: String, message: String, action: ActionConfig? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
    }
}

// MARK: - Factory Methods

extension EmptyStateConfig {
    /// Empty state for guest list
    static func guests(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "person.3.fill",
            title: "No Guests Yet",
            message: "Start building your guest list by adding your first guest.",
            action: ActionConfig(title: "Add Guest", handler: onAdd)
        )
    }

    /// Empty state for vendor list
    static func vendors(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "building.2.fill",
            title: "No Vendors Yet",
            message: "Add vendors to track your bookings and contracts.",
            action: ActionConfig(title: "Add Vendor", handler: onAdd)
        )
    }

    /// Empty state for notes
    static func notes(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "note.text",
            title: "No Notes Yet",
            message: "Create notes to keep track of important details and ideas.",
            action: ActionConfig(title: "Add Note", handler: onAdd)
        )
    }

    /// Empty state for documents
    static func documents(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "doc.fill",
            title: "No Documents Yet",
            message: "Upload and organize your wedding documents in one place.",
            action: ActionConfig(title: "Add Document", handler: onAdd)
        )
    }

    /// Empty state for tasks
    static func tasks(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "checkmark.circle.fill",
            title: "No Tasks Yet",
            message: "Create tasks to stay organized and on track.",
            action: ActionConfig(title: "Add Task", handler: onAdd)
        )
    }

    /// Empty state for timeline events
    static func timeline(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "calendar",
            title: "No Events Yet",
            message: "Add events to your wedding timeline.",
            action: ActionConfig(title: "Add Event", handler: onAdd)
        )
    }

    /// Empty state for mood boards
    static func moodBoards(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "photo.on.rectangle.angled",
            title: "No Mood Boards Yet",
            message: "Create mood boards to visualize your wedding style and inspiration.",
            action: ActionConfig(title: "Create Mood Board", handler: onAdd)
        )
    }

    /// Empty state for color palettes
    static func colorPalettes(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "paintpalette.fill",
            title: "No Color Palettes Yet",
            message: "Create color palettes to define your wedding color scheme.",
            action: ActionConfig(title: "Create Palette", handler: onAdd)
        )
    }

    /// Empty state for budget categories
    static func budgetCategories(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "dollarsign.circle.fill",
            title: "No Budget Categories",
            message: "Add categories to organize your wedding expenses.",
            action: ActionConfig(title: "Add Category", handler: onAdd)
        )
    }

    /// Empty state for expenses
    static func expenses(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "creditcard.fill",
            title: "No Expenses Yet",
            message: "Track your wedding expenses to stay within budget.",
            action: ActionConfig(title: "Add Expense", handler: onAdd)
        )
    }

    /// Generic empty state with custom configuration
    static func custom(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        actionIcon: String = "plus.circle.fill",
        onAction: (() -> Void)? = nil
    ) -> EmptyStateConfig {
        let action: ActionConfig? = if let actionTitle = actionTitle, let onAction = onAction {
            ActionConfig(title: actionTitle, icon: actionIcon, handler: onAction)
        } else {
            nil
        }

        return EmptyStateConfig(
            icon: icon,
            title: title,
            message: message,
            action: action
        )
    }

    /// Empty state for search results
    static func searchResults(query: String) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "No items match '\(query)'. Try adjusting your search.",
            action: nil
        )
    }

    /// Empty state for filtered results
    static func filteredResults() -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "line.3.horizontal.decrease.circle",
            title: "No Matching Items",
            message: "No items match your current filters. Try adjusting your criteria.",
            action: nil
        )
    }
}
