//
//  MoneyManagementUnifiedHeader.swift
//  I Do Blueprint
//
//  Unified responsive header for Money Management page
//  Follows compact 56px bar pattern from BudgetOverviewUnifiedHeader
//  with glassmorphism styling
//

import SwiftUI

struct MoneyManagementUnifiedHeader: View {
    let windowSize: WindowSize

    // Filter state
    @Binding var selectedTab: MoneyTab
    @Binding var searchText: String

    // Stats
    let contributorCount: Int
    let totalContributions: Double

    // Actions
    let onAddContribution: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool { colorScheme == .dark }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Left: Title section with icon badge
            HStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    // Icon badge
                    Circle()
                        .fill(SageGreen.shade500)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .shadow(color: SageGreen.shade500.opacity(0.3), radius: 3, x: 0, y: 1)

                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        Text("Budget")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(SemanticColors.textPrimary)

                        Text("Money Management")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                }
            }

            Spacer()

            // Center: Tab selector (regular mode only)
            if windowSize != .compact {
                tabSelector
            }

            Spacer()

            // Right: Search + Add button
            HStack(spacing: Spacing.md) {
                // Search field (regular mode)
                if windowSize != .compact {
                    searchField
                }

                // Add contribution button
                addButton
            }
        }
        .frame(height: 56)
        .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(
            ZStack {
                // Base blur layer - glassmorphism
                Rectangle()
                    .fill(.ultraThinMaterial)

                // Semi-transparent overlay
                Rectangle()
                    .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.3))

                // Subtle top glow
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
        .overlay(
            Divider()
                .foregroundColor(SemanticColors.borderLight),
            alignment: .bottom
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 2) {
            ForEach(MoneyTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .white : SemanticColors.textSecondary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(selectedTab == tab ? SageGreen.shade500 : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(isDarkMode ? Color.white.opacity(0.05) : SemanticColors.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(SemanticColors.textTertiary)

            TextField("Search contributions...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .frame(width: 160)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(isDarkMode ? Color.white.opacity(0.05) : SemanticColors.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button(action: onAddContribution) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                Text("Add")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(SageGreen.shade500)
            )
        }
        .buttonStyle(.plain)
        .help("Add new contribution")
    }
}
