//
//  GlobalSidebarViewV1.swift
//  I Do Blueprint
//
//  Created by Claude on 1/6/26.
//  Glassmorphism navigation sidebar - V1 implementation
//  Inspired by modern macOS app design with frosted glass effects
//

import SwiftUI

// MARK: - Global Sidebar View V1

/// Premium glassmorphism sidebar navigation matching the HTML design reference
/// Features:
/// - Frosted glass background with backdrop blur
/// - Expandable Budget section with grouped subsections
/// - Theme-aware colors using SemanticColors
/// - Smooth hover animations
/// - Active item highlighting
struct GlobalSidebarViewV1: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var appStores: AppStores

    // Track expanded state for collapsible sections
    @State private var isBudgetExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with logo
            SidebarHeaderV1()
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.sm)

            // Scrollable navigation content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Spacing.xxs) {
                    // Main navigation items
                    mainNavigationSection

                    // Expandable Budget folder
                    budgetFolderSection

                    // Additional items
                    additionalNavigationSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
            }

            // Divider
            NativeDividerStyle(opacity: 0.3)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)

            // Settings at bottom
            settingsSection
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
        }
        .frame(maxHeight: .infinity)
        .background(
            GlassSidebarBackground()
        )
    }

    // MARK: - Main Navigation Section

    private var mainNavigationSection: some View {
        VStack(spacing: Spacing.xxs) {
            SidebarNavItemV1(
                tab: .dashboard,
                icon: "square.grid.2x2",
                title: "Dashboard",
                isSelected: coordinator.selectedTab == .dashboard
            ) {
                coordinator.navigate(to: .dashboard)
            }

            SidebarNavItemV1(
                tab: .guests,
                icon: "person.2",
                title: "Guest Management",
                isSelected: coordinator.selectedTab == .guests
            ) {
                coordinator.navigate(to: .guests)
            }

            SidebarNavItemV1(
                tab: .vendors,
                icon: "storefront",
                title: "Vendor Management",
                isSelected: coordinator.selectedTab == .vendors
            ) {
                coordinator.navigate(to: .vendors)
            }
        }
    }

    // MARK: - Budget Folder Section

    private var budgetFolderSection: some View {
        VStack(spacing: 0) {
            // Budget folder header (expandable)
            BudgetFolderHeaderV1(
                isExpanded: $isBudgetExpanded
            )
            .padding(.top, Spacing.sm)

            // Expanded content
            if isBudgetExpanded {
                VStack(spacing: Spacing.lg) {
                    // Planning & Analysis subsection (5 pages)
                    BudgetSubsectionV1(
                        title: "Planning & Analysis",
                        items: [
                            BudgetSubItem(icon: BudgetPage.budgetOverview.icon, title: "Budget Overview", page: .budgetOverview),
                            BudgetSubItem(icon: BudgetPage.budgetBuilder.icon, title: "Budget Builder", page: .budgetBuilder),
                            BudgetSubItem(icon: BudgetPage.analytics.icon, title: "Analytics Hub", page: .analytics),
                            BudgetSubItem(icon: BudgetPage.cashFlow.icon, title: "Cash Flow", page: .cashFlow),
                            BudgetSubItem(icon: BudgetPage.calculator.icon, title: "Calculator", page: .calculator)
                        ],
                        selectedPage: coordinator.budgetPage
                    ) { page in
                        coordinator.navigateToBudget(page: page)
                    }

                    // Expenses subsection (4 pages)
                    BudgetSubsectionV1(
                        title: "Expenses",
                        items: [
                            BudgetSubItem(icon: BudgetPage.expenseTracker.icon, title: "Expense Tracker", page: .expenseTracker),
                            BudgetSubItem(icon: BudgetPage.expenseReports.icon, title: "Expense Reports", page: .expenseReports),
                            BudgetSubItem(icon: BudgetPage.expenseCategories.icon, title: "Categories", page: .expenseCategories),
                            BudgetSubItem(icon: BudgetPage.paymentSchedule.icon, title: "Payment Schedule", page: .paymentSchedule)
                        ],
                        selectedPage: coordinator.budgetPage
                    ) { page in
                        coordinator.navigateToBudget(page: page)
                    }

                    // Income subsection (3 pages)
                    BudgetSubsectionV1(
                        title: "Income",
                        items: [
                            BudgetSubItem(icon: BudgetPage.moneyTracker.icon, title: "Money Tracker", page: .moneyTracker),
                            BudgetSubItem(icon: BudgetPage.moneyReceived.icon, title: "Money Received", page: .moneyReceived),
                            BudgetSubItem(icon: BudgetPage.moneyOwed.icon, title: "Money Owed", page: .moneyOwed)
                        ],
                        selectedPage: coordinator.budgetPage
                    ) { page in
                        coordinator.navigateToBudget(page: page)
                    }
                }
                .padding(.leading, Spacing.md)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    // MARK: - Additional Navigation Section

    private var additionalNavigationSection: some View {
        VStack(spacing: Spacing.xxs) {
            SidebarNavItemV1(
                tab: .notes,
                icon: "note.text",
                title: "Notes",
                isSelected: coordinator.selectedTab == .notes
            ) {
                coordinator.navigate(to: .notes)
            }

            SidebarNavItemV1(
                tab: .documents,
                icon: "doc.text",
                title: "Documents",
                isSelected: coordinator.selectedTab == .documents
            ) {
                coordinator.navigate(to: .documents)
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        SidebarNavItemV1(
            tab: .settings,
            icon: "gearshape",
            title: "Settings",
            isSelected: coordinator.selectedTab == .settings
        ) {
            coordinator.navigate(to: .settings)
        }
    }
}

// MARK: - Sidebar Header V1

private struct SidebarHeaderV1: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Logo container with ring and leaf icons
            ZStack {
                Circle()
                    .fill(SemanticColors.primaryActionLight.opacity(0.5))
                    .frame(width: 40, height: 40)

                Image(systemName: "ring")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(SemanticColors.primaryAction)
                    .rotationEffect(.degrees(-12))

                // Small leaf accent
                Image(systemName: "leaf.fill")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(SemanticColors.statusSuccess)
                    .offset(x: 10, y: 8)
            }

            Text("I Do Blueprint")
                .font(Typography.heading)
                .fontWeight(.bold)
                .foregroundStyle(SemanticColors.textPrimary)

            Spacer()
        }
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Sidebar Navigation Item V1

private struct SidebarNavItemV1: View {
    let tab: AppCoordinator.AppTab
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 20, alignment: .center)

                Text(title)
                    .font(Typography.bodySmall)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(textColor)

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(backgroundStyle)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .accessibleListItem(
            label: title,
            hint: "Navigate to \(title)",
            isSelected: isSelected
        )
    }

    private var iconColor: Color {
        if isSelected {
            return SemanticColors.textPrimary
        }
        return isHovered ? SemanticColors.textSecondary : SemanticColors.textTertiary
    }

    private var textColor: Color {
        if isSelected {
            return SemanticColors.textPrimary
        }
        return isHovered ? SemanticColors.textSecondary : SemanticColors.textSecondary
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if isSelected {
            // Active state - warm beige/stone color like HTML's glass-active
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(SemanticColors.backgroundTertiary)
        } else if isHovered {
            // Hover state - subtle highlight
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.black.opacity(0.05))
        } else {
            // Default state - transparent
            Color.clear
        }
    }
}

// MARK: - Budget Folder Header V1

private struct BudgetFolderHeaderV1: View {
    @Binding var isExpanded: Bool
    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: isExpanded ? "folder" : "folder.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SemanticColors.textSecondary)
                    .frame(width: 20, alignment: .center)

                Text("Budget")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(SemanticColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(SemanticColors.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isHovered ? Color.black.opacity(0.05) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Budget Subsection V1

private struct BudgetSubsectionV1: View {
    let title: String
    let items: [BudgetSubItem]
    let selectedPage: BudgetPage?
    let onSelect: (BudgetPage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            // Section header
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(SemanticColors.textTertiary)
                .padding(.leading, Spacing.xxxl)
                .padding(.bottom, Spacing.xxs)

            // Items
            ForEach(items, id: \.page) { item in
                BudgetSubItemViewV1(
                    item: item,
                    isSelected: selectedPage == item.page,
                    onSelect: { onSelect(item.page) }
                )
            }
        }
    }
}

// MARK: - Budget Sub Item

private struct BudgetSubItem {
    let icon: String
    let title: String
    let page: BudgetPage
}

private struct BudgetSubItemViewV1: View {
    let item: BudgetSubItem
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                Image(systemName: item.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 20, alignment: .center)

                Text(item.title)
                    .font(Typography.bodySmall)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(textColor)

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs + 2)
            .background(backgroundStyle)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var iconColor: Color {
        if isSelected {
            return SemanticColors.textPrimary
        }
        return isHovered ? SemanticColors.textSecondary : SemanticColors.textTertiary
    }

    private var textColor: Color {
        if isSelected {
            return SemanticColors.textPrimary
        }
        return SemanticColors.textSecondary
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(SemanticColors.backgroundTertiary)
        } else if isHovered {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.black.opacity(0.05))
        } else {
            Color.clear
        }
    }
}

// MARK: - Glass Sidebar Background

private struct GlassSidebarBackground: View {
    var body: some View {
        ZStack {
            // Base blur layer
            Rectangle()
                .fill(.ultraThinMaterial)

            // Semi-transparent white overlay (reduced opacity for transparency)
            Rectangle()
                .fill(Color.white.opacity(0.40))

            // Inner glow for depth
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
        }
        .overlay(
            // Gradient border on right edge only
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1),
            alignment: .trailing
        )
        // Multi-layer shadow for floating effect
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 5, y: 0)
        .shadow(color: Color.black.opacity(0.03), radius: 30, x: 10, y: 0)
    }
}

// MARK: - Preview

#Preview("Global Sidebar V1") {
    HStack(spacing: 0) {
        GlobalSidebarViewV1()
            .frame(width: 280)
            .environmentObject(AppCoordinator.shared)
            .environmentObject(AppStores.shared)

        // Mock detail area
        Rectangle()
            .fill(Color.gray.opacity(0.1))
    }
    .frame(width: 1000, height: 700)
    .background(
        // Gradient background blobs like HTML
        ZStack {
            Circle()
                .fill(Color.pink.opacity(0.15))
                .frame(width: 600, height: 600)
                .blur(radius: 120)
                .offset(x: -100, y: -200)

            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 600, height: 600)
                .blur(radius: 120)
                .offset(x: 300, y: 100)
        }
    )
}

#Preview("Global Sidebar V1 - Dark") {
    HStack(spacing: 0) {
        GlobalSidebarViewV1()
            .frame(width: 280)
            .environmentObject(AppCoordinator.shared)
            .environmentObject(AppStores.shared)

        Rectangle()
            .fill(Color.gray.opacity(0.1))
    }
    .frame(width: 1000, height: 700)
    .preferredColorScheme(.dark)
}
