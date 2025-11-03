//
//  ListHeader.swift
//  I Do Blueprint
//
//  List header component for section headers
//

import SwiftUI

/// Standard list header with title and optional action
struct ListHeader: View {
    let title: String
    let count: Int?
    let action: ActionConfig?

    init(title: String, count: Int? = nil, action: ActionConfig? = nil) {
        self.title = title
        self.count = count
        self.action = action
    }

    struct ActionConfig {
        let title: String
        let icon: String?
        let handler: () -> Void

        init(title: String, icon: String? = nil, handler: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.handler = handler
        }
    }

    var body: some View {
        HStack {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)

                if let count = count {
                    Text("(\(count))")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

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
                .accessibilityLabel(action.title)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .contain)
        .accessibleHeading(level: 2)
    }
}

// MARK: - Sticky List Header

/// Sticky header that stays at top during scroll
struct StickyListHeader: View {
    let title: String
    let count: Int?
    let icon: String?
    let color: Color

    init(title: String, count: Int? = nil, icon: String? = nil, color: Color = .blue) {
        self.title = title
        self.count = count
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
            }

            Text(title)
                .font(Typography.subheading)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            if let count = count {
                Text("\(count)")
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                    )
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(AppColors.background.opacity(0.95))
        .accessibilityElement(children: .combine)
        .accessibleHeading(level: 2)
    }
}

// MARK: - Collapsible List Header

/// Header with expand/collapse functionality
struct CollapsibleListHeader: View {
    let title: String
    let count: Int?
    @Binding var isExpanded: Bool

    var body: some View {
        Button(action: {
            withAnimation(AnimationStyle.spring) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 16)

                Text(title)
                    .font(Typography.subheading)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)

                if let count = count {
                    Text("(\(count))")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)\(count != nil ? ", \(count!) items" : "")")
        .accessibilityHint(isExpanded ? "Collapse section" : "Expand section")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#Preview("List Headers") {
    VStack(spacing: Spacing.lg) {
        ListHeader(
            title: "Recent Guests",
            count: 25
        )

        Divider()

        ListHeader(
            title: "Vendors",
            count: 12,
            action: ListHeader.ActionConfig(
                title: "Add",
                icon: "plus",
                handler: {}
            )
        )

        Divider()

        StickyListHeader(
            title: "Confirmed",
            count: 120,
            icon: "checkmark.circle.fill",
            color: .green
        )

        Divider()

        CollapsibleListHeader(
            title: "Pending Responses",
            count: 25,
            isExpanded: .constant(true)
        )

        CollapsibleListHeader(
            title: "Declined",
            count: 5,
            isExpanded: .constant(false)
        )
    }
    .padding()
}

#Preview("List with Headers") {
    ScrollView {
        VStack(spacing: 0) {
            ListHeader(
                title: "All Guests",
                count: 150,
                action: ListHeader.ActionConfig(
                    title: "Add Guest",
                    icon: "plus",
                    handler: {}
                )
            )

            Divider()

            StickyListHeader(
                title: "Confirmed",
                count: 120,
                icon: "checkmark.circle.fill",
                color: .green
            )

            ForEach(0..<3) { _ in
                StandardListRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: "Guest Name",
                    subtitle: "Attending",
                    accessory: .chevron
                )
                Divider()
            }

            StickyListHeader(
                title: "Pending",
                count: 25,
                icon: "clock.fill",
                color: .orange
            )

            ForEach(0..<2) { _ in
                StandardListRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: "Guest Name",
                    subtitle: "Awaiting response",
                    accessory: .chevron
                )
                Divider()
            }
        }
    }
    .frame(height: 400)
}
