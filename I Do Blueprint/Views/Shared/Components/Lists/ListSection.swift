//
//  ListSection.swift
//  I Do Blueprint
//
//  List section component for grouped content
//

import SwiftUI

/// Standard list section with header and content
struct ListSection<Content: View>: View {
    let title: String
    let count: Int?
    let icon: String?
    let color: Color
    let footer: String?
    let content: Content
    
    init(
        title: String,
        count: Int? = nil,
        icon: String? = nil,
        color: Color = .blue,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.count = count
        self.icon = icon
        self.color = color
        self.footer = footer
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            StickyListHeader(
                title: title,
                count: count,
                icon: icon,
                color: color
            )
            
            // Content
            content
            
            // Footer
            if let footer = footer {
                Text(footer)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
            }
        }
    }
}

// MARK: - Collapsible List Section

/// List section with expand/collapse functionality
struct CollapsibleListSection<Content: View>: View {
    let title: String
    let count: Int?
    let content: Content
    @State private var isExpanded: Bool
    
    init(
        title: String,
        count: Int? = nil,
        isExpandedByDefault: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.count = count
        self.content = content()
        self._isExpanded = State(initialValue: isExpandedByDefault)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            CollapsibleListHeader(
                title: title,
                count: count,
                isExpanded: $isExpanded
            )
            
            // Content
            if isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Card List Section

/// List section styled as a card
struct CardListSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let action: ListHeader.ActionConfig?
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        action: ListHeader.ActionConfig? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    if let action = action {
                        Button(action: action.handler) {
                            HStack(spacing: 4) {
                                if let icon = action.icon {
                                    Image(systemName: icon)
                                        .font(.caption)
                                }
                                Text(action.title)
                                    .font(Typography.bodySmall)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(AppColors.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Divider()
            
            // Content
            content
        }
        .padding(Spacing.lg)
        .card(shadow: .light)
    }
}

// MARK: - Previews

#Preview("List Section") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            ListSection(
                title: "Confirmed Guests",
                count: 120,
                icon: "checkmark.circle.fill",
                color: .green,
                footer: "All guests have confirmed their attendance"
            ) {
                ForEach(0..<3) { index in
                    StandardListRow(
                        icon: "person.fill",
                        iconColor: .blue,
                        title: "Guest \(index + 1)",
                        subtitle: "Attending",
                        accessory: .chevron
                    )
                    if index < 2 {
                        Divider()
                    }
                }
            }
            
            ListSection(
                title: "Pending Responses",
                count: 25,
                icon: "clock.fill",
                color: .orange
            ) {
                ForEach(0..<2) { index in
                    StandardListRow(
                        icon: "person.fill",
                        iconColor: .blue,
                        title: "Guest \(index + 4)",
                        subtitle: "Awaiting response",
                        accessory: .chevron
                    )
                    if index < 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
    }
}

#Preview("Collapsible List Section") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            CollapsibleListSection(
                title: "Confirmed",
                count: 120,
                isExpandedByDefault: true
            ) {
                ForEach(0..<3) { index in
                    StandardListRow(
                        icon: "person.fill",
                        iconColor: .green,
                        title: "Guest \(index + 1)",
                        subtitle: "Attending"
                    )
                    Divider()
                }
            }
            
            CollapsibleListSection(
                title: "Pending",
                count: 25,
                isExpandedByDefault: false
            ) {
                ForEach(0..<2) { index in
                    StandardListRow(
                        icon: "person.fill",
                        iconColor: .orange,
                        title: "Guest \(index + 4)",
                        subtitle: "Awaiting response"
                    )
                    Divider()
                }
            }
        }
        .padding()
    }
}

#Preview("Card List Section") {
    VStack(spacing: Spacing.lg) {
        CardListSection(
            title: "Recent Activity",
            subtitle: "Last 7 days",
            action: ListHeader.ActionConfig(
                title: "View All",
                handler: {}
            )
        ) {
            VStack(spacing: Spacing.sm) {
                ForEach(0..<3) { index in
                    StandardListRow(
                        icon: "bell.fill",
                        iconColor: .blue,
                        title: "Activity \(index + 1)",
                        subtitle: "\(index + 1) hours ago"
                    )
                }
            }
        }
        
        CardListSection(
            title: "Quick Actions"
        ) {
            VStack(spacing: Spacing.xs) {
                CompactActionCard(
                    icon: "person.badge.plus",
                    title: "Add Guest",
                    color: .blue,
                    action: {}
                )
                
                CompactActionCard(
                    icon: "building.2.badge.plus",
                    title: "Add Vendor",
                    color: .purple,
                    action: {}
                )
            }
        }
    }
    .padding()
}
