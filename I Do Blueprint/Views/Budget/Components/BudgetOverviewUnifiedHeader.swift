//
//  BudgetOverviewUnifiedHeader.swift
//  I Do Blueprint
//
//  Unified responsive header for Budget Overview Dashboard
//  Follows pattern from BudgetDevelopmentUnifiedHeader.swift
//

import SwiftUI

struct BudgetOverviewUnifiedHeader: View {
    let windowSize: WindowSize
    @Binding var currentPage: BudgetPage
    
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
    
    var body: some View {
        VStack(spacing: windowSize == .compact ? Spacing.md : Spacing.lg) {
            // Title row with ellipsis and nav
            titleRow
            
            // Form fields (responsive)
            if windowSize == .compact {
                compactFormFields
            } else {
                regularFormFields
            }
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Title Row
    
    private var titleRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget")
                    .font(Typography.displaySmall)
                    .foregroundColor(SemanticColors.textPrimary)
                
                HStack(spacing: 8) {
                    Text("Budget Overview")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                    
                    if let scenario = currentScenario {
                        Text("•")
                            .foregroundColor(SemanticColors.textSecondary)
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(scenario.scenarioName)
                            .font(Typography.bodySmall)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                ellipsisMenu
                budgetPageDropdown
            }
        }
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
            
            // View mode toggle (compact only)
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
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundColor(SemanticColors.textPrimary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Navigation Dropdown
    
    private var budgetPageDropdown: some View {
        Menu {
            Button {
                currentPage = .hub
            } label: {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            
            Divider()
            
            ForEach(BudgetGroup.allCases) { group in
                Section(group.rawValue) {
                    ForEach(group.pages) { page in
                        Button {
                            currentPage = page
                        } label: {
                            Label(page.rawValue, systemImage: page.icon)
                            if currentPage == page {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: currentPage.icon)
                    .font(.system(size: windowSize == .compact ? 20 : 16))
                if windowSize != .compact {
                    Text(currentPage.rawValue)
                        .font(.headline)
                }
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(SemanticColors.textPrimary)
            .frame(width: windowSize == .compact ? 44 : nil, height: 44)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Compact Form Fields
    
    @ViewBuilder
    private var compactFormFields: some View {
        VStack(spacing: Spacing.md) {
            // Scenario selector (full width) with label
            VStack(alignment: .leading, spacing: 4) {
                Text("Scenario Management")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("", selection: $selectedScenarioId) {
                    ForEach(allScenarios, id: \.id) { scenario in
                        HStack {
                            if scenario.isPrimary {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            Text(scenario.scenarioName)
                        }
                        .tag(scenario.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            
            // Search field (full width) - no label, placeholder is sufficient
            searchField
            
            // Filter placeholder (keep existing button)
            if !activeFilters.isEmpty {
                HStack {
                    Text("\(activeFilters.count) filter\(activeFilters.count == 1 ? "" : "s") active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Regular Form Fields
    
    @ViewBuilder
    private var regularFormFields: some View {
        HStack(spacing: Spacing.lg) {
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
                        }
                        .tag(scenario.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 200)
            }
            
            // Search field
            VStack(alignment: .leading, spacing: 4) {
                Text("Search")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                searchField
            }
            
            // Filters placeholder (keep existing functionality)
            if !activeFilters.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(activeFilters.count) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // View toggle (regular mode only)
            Picker("View Mode", selection: $viewMode) {
                Image(systemName: "square.grid.2x2")
                    .tag(BudgetOverviewDashboardViewV2.ViewMode.cards)
                Image(systemName: "list.bullet")
                    .tag(BudgetOverviewDashboardViewV2.ViewMode.table)
                Image(systemName: "leaf.fill")
                    .tag(BudgetOverviewDashboardViewV2.ViewMode.bouquet)
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
    }
    
    // MARK: - Search Field
    
    @ViewBuilder
    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(SemanticColors.textSecondary)
            
            TextField("Search budget items...", text: $searchQuery)
                .textFieldStyle(.plain)
            
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .frame(maxWidth: windowSize == .compact ? .infinity : 250)
    }
}
