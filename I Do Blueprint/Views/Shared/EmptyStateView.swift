//
//  EmptyStateView.swift
//  I Do Blueprint
//
//  Shared empty state component for consistent no-results/empty UX
//

import SwiftUI

struct SharedEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(actionTitle)
                .accessibilityHint("Performs the primary action")
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Search-Specific Empty State

struct SearchEmptyStateView: View {
    let searchText: String
    let onClearSearch: () -> Void

    var body: some View {
        SharedEmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "No items match '\(searchText)'. Try a different search term.",
            actionTitle: "Clear Search",
            action: onClearSearch
        )
    }
}

// MARK: - List Count Header

struct ListCountHeaderView: View {
    let filteredCount: Int
    let totalCount: Int
    let itemName: String

    var body: some View {
        HStack {
            if filteredCount < totalCount {
                Text("\(filteredCount) of \(totalCount) \(itemName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(totalCount) \(itemName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .accessibilityLabel("\(filteredCount) of \(totalCount) \(itemName) shown")
    }
}

// MARK: - Previews

#Preview("Empty State - No Items") {
    SharedEmptyStateView(
        icon: "person.3",
        title: "No Guests Yet",
        message: "Start adding guests to your wedding to keep track of RSVPs and seating arrangements.",
        actionTitle: "Add Guest",
        action: { print("Add guest") }
    )
}

#Preview("Empty State - Search") {
    SearchEmptyStateView(
        searchText: "John",
        onClearSearch: { print("Clear search") }
    )
}

#Preview("List Count Header") {
    VStack {
        ListCountHeaderView(filteredCount: 10, totalCount: 50, itemName: "guests")
        ListCountHeaderView(filteredCount: 50, totalCount: 50, itemName: "vendors")
    }
}
