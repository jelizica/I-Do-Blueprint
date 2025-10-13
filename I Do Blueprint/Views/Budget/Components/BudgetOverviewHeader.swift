//
//  BudgetOverviewHeader.swift
//  I Do Blueprint
//
//  Created by Claude on 10/9/25.
//

import SwiftUI

struct BudgetOverviewHeader: View {
    @Binding var selectedScenarioId: String
    @Binding var searchQuery: String
    @Binding var viewMode: BudgetOverviewDashboardViewV2.ViewMode

    let allScenarios: [SavedScenario]
    let currentScenario: SavedScenario?
    let primaryScenario: SavedScenario?
    let isRefreshing: Bool
    let loading: Bool
    let activeFilters: [BudgetFilter]
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Budget Overview Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    // Refresh button
                    Button(action: onRefresh) {
                        HStack(spacing: 4) {
                            Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                .animation(
                                    isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                    value: isRefreshing)
                            Text(isRefreshing ? "Refreshing..." : "Refresh")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(loading)
                }

                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(currentScenario?.scenarioName ?? "Loading scenario...")
                    if let currentScenario,
                       let primaryScenario,
                       currentScenario.id == primaryScenario.id {
                        Text("(Primary)")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            // Controls section
            HStack(spacing: 12) {
                // Scenario selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scenario")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Scenario", selection: $selectedScenarioId) {
                        ForEach(allScenarios, id: \.id) { scenario in
                            HStack {
                                if scenario.isPrimary {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                                Text(scenario.scenarioName)
                                if scenario.isPrimary {
                                    Text("(Primary)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(scenario.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 240)
                }

                // Budget filters
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filters")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(action: {
                        AppLogger.ui.debug("BudgetFiltersDemo not yet implemented")
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(activeFilters.isEmpty ? "All Items" : "\(activeFilters.count) filters")
                        }
                    }
                    .buttonStyle(.bordered)
                }

                // Search field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Search")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search budget items, vendors, categories...", text: $searchQuery)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .frame(minWidth: 300)
                }

                Spacer()

                // View toggle
                Picker("View Mode", selection: $viewMode) {
                    Image(systemName: "square.grid.2x2")
                        .tag(BudgetOverviewDashboardViewV2.ViewMode.cards)
                    Image(systemName: "list.bullet")
                        .tag(BudgetOverviewDashboardViewV2.ViewMode.table)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}
