//
//  UnifiedEmptyStateView.swift
//  I Do Blueprint
//
//  Unified empty state component for consistent empty state UI across the app
//  Replaces duplicate empty state implementations in Guests, Vendors, Notes, etc.
//

import SwiftUI

/// Unified empty state view with icon, title, message, and optional action button
struct UnifiedEmptyStateView: View {
    let config: EmptyStateConfig
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Icon
            Image(systemName: config.icon)
                .font(.system(size: 64))
                .foregroundColor(AppColors.textTertiary)
                .accessibilityHidden(true)
            
            // Text content
            VStack(spacing: Spacing.sm) {
                Text(config.title)
                    .font(Typography.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .accessibleHeading(level: 2)
                
                Text(config.message)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.lg)
            
            // Optional action button
            if let action = config.action {
                Button(action: action.handler) {
                    Label(action.title, systemImage: action.icon)
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibleActionButton(
                    label: action.title,
                    hint: "Creates a new item"
                )
            }
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("Guests Empty State") {
    UnifiedEmptyStateView(config: .guests(onAdd: {}))
}

#Preview("Vendors Empty State") {
    UnifiedEmptyStateView(config: .vendors(onAdd: {}))
}

#Preview("Notes Empty State") {
    UnifiedEmptyStateView(config: .notes(onAdd: {}))
}

#Preview("Search Results Empty State") {
    UnifiedEmptyStateView(config: .searchResults(query: "wedding cake"))
}

#Preview("Filtered Results Empty State") {
    UnifiedEmptyStateView(config: .filteredResults())
}

#Preview("Custom Empty State") {
    UnifiedEmptyStateView(
        config: .custom(
            icon: "star.fill",
            title: "Custom Empty State",
            message: "This is a custom empty state with a custom action.",
            actionTitle: "Custom Action",
            actionIcon: "star.circle.fill",
            onAction: {}
        )
    )
}
