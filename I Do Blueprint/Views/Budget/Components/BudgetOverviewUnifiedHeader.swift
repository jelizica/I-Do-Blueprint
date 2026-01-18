//
//  BudgetOverviewUnifiedHeader.swift
//  I Do Blueprint
//
//  Unified responsive header for Budget Overview Dashboard
//  Follows compact style from PaymentScheduleUnifiedHeader with glassmorphism
//

import SwiftUI

struct BudgetOverviewUnifiedHeader: View {
    let windowSize: WindowSize

    // Scenario bindings
    @Binding var selectedScenarioId: String
    @Binding var searchQuery: String
    @Binding var viewMode: BudgetOverviewDashboardViewV2.ViewMode

    // Data
    let allScenarios: [SavedScenario]
    let currentScenario: SavedScenario?
    let primaryScenario: SavedScenario?
    let loading: Bool
    let activeFilters: [BudgetFilter]

    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool { colorScheme == .dark }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Left: Title + Search
            HStack(spacing: Spacing.md) {
                // Title section with icon badge
                HStack(spacing: Spacing.sm) {
                    // Icon badge
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 3, x: 0, y: 1)

                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        Text("Budget")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(SemanticColors.textPrimary)

                        Text("Overview")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SemanticColors.textTertiary)
                    }
                }

                // Inline search field (regular mode)
                if windowSize != .compact {
                    inlineSearchField
                        .frame(width: searchQuery.isEmpty ? 160 : 220)
                        .animation(.easeInOut(duration: 0.2), value: searchQuery.isEmpty)
                }
            }

            Spacer()

            // Right: Scenario badge + view toggle + ellipsis
            HStack(spacing: Spacing.md) {
                // Scenario context badge (regular mode)
                if windowSize != .compact {
                    scenarioBadge
                }

                // View mode toggle (regular mode)
                if windowSize != .compact {
                    viewModeToggle
                }

                ellipsisMenu
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

    // MARK: - Inline Search Field

    private var inlineSearchField: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(SemanticColors.textTertiary)

            TextField("Search", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
        )
    }

    // MARK: - Scenario Badge

    private var scenarioBadge: some View {
        Menu {
            ForEach(allScenarios, id: \.id) { scenario in
                Button {
                    selectedScenarioId = scenario.id
                } label: {
                    HStack {
                        if scenario.isPrimary {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        Text(scenario.scenarioName)
                        if scenario.id == selectedScenarioId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow)

                if let scenario = currentScenario {
                    Text(scenario.scenarioName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SemanticColors.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("Select Scenario")
                        .font(.system(size: 11))
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
                    .foregroundColor(SemanticColors.textTertiary)
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
        .buttonStyle(.plain)
        .help("Select budget scenario")
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: 2) {
            viewModeButton(mode: .cards, icon: "square.grid.2x2")
            viewModeButton(mode: .table, icon: "list.bullet")
            viewModeButton(mode: .bouquet, icon: "leaf.fill")
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
        )
    }

    private func viewModeButton(mode: BudgetOverviewDashboardViewV2.ViewMode, icon: String) -> some View {
        Button {
            viewMode = mode
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(viewMode == mode ? SemanticColors.textPrimary : SemanticColors.textTertiary)
                .frame(width: 28, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(viewMode == mode ? (isDarkMode ? Color.white.opacity(0.1) : Color.white) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Ellipsis Menu

    private var ellipsisMenu: some View {
        Menu {
            // Export Summary (placeholder for future)
            Button(action: {
                AppLogger.ui.info("Export Summary - Not yet implemented")
            }) {
                Label("Export Summary", systemImage: "square.and.arrow.up")
            }

            // View mode toggle (compact only - not visible in header bar)
            if windowSize == .compact {
                Divider()

                Section("View Mode") {
                    Button {
                        viewMode = .cards
                    } label: {
                        Label("Cards", systemImage: "square.grid.2x2")
                        if viewMode == .cards {
                            Image(systemName: "checkmark")
                        }
                    }

                    Button {
                        viewMode = .table
                    } label: {
                        Label("Table", systemImage: "list.bullet")
                        if viewMode == .table {
                            Image(systemName: "checkmark")
                        }
                    }

                    Button {
                        viewMode = .bouquet
                    } label: {
                        Label("Bouquet", systemImage: "leaf.fill")
                        if viewMode == .bouquet {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                // Scenario selection for compact mode
                Section("Scenario") {
                    ForEach(allScenarios, id: \.id) { scenario in
                        Button {
                            selectedScenarioId = scenario.id
                        } label: {
                            HStack {
                                if scenario.isPrimary {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                                Text(scenario.scenarioName)
                                if scenario.id == selectedScenarioId {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }

            // Filter indicator
            if !activeFilters.isEmpty {
                Divider()
                Text("\(activeFilters.count) filter\(activeFilters.count == 1 ? "" : "s") active")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .help("More actions")
    }
}
