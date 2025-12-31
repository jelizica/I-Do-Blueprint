//
//  VisualPlanningSearchView.swift
//  My Wedding Planning App
//
//  Comprehensive search interface for visual planning content
//

import SwiftUI

struct VisualPlanningSearchView: View {
    @StateObject private var searchService: VisualPlanningSearchService
    @State private var showingFilters = false
    @State private var showingSavedSearches = false
    @State private var searchSuggestions: [String] = []
    @State private var selectedResultType: ResultType = .all

    init(supabaseService: SupabaseVisualPlanningService) {
        _searchService = StateObject(wrappedValue: VisualPlanningSearchService(supabaseService: supabaseService))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search header
            searchHeaderSection

            // Quick filters
            quickFiltersSection

            // Results content
            searchResultsSection
        }
        .navigationTitle("Search Visual Planning")
        .sheet(isPresented: $showingFilters) {
            SearchFiltersView(
                filters: $searchService.activeFilters,
                onApply: {
                    Task {
                        await searchService.performSearch()
                    }
                    showingFilters = false
                },
                onDismiss: {
                    showingFilters = false
                }
            )
        }
        .sheet(isPresented: $showingSavedSearches) {
            SavedSearchesView(
                savedSearches: searchService.savedSearches,
                onSelect: { search in
                    searchService.loadSavedSearch(search)
                    showingSavedSearches = false
                },
                onDelete: { search in
                    if let index = searchService.savedSearches.firstIndex(where: { $0.id == search.id }) {
                        searchService.deleteSavedSearch(at: index)
                    }
                },
                onDismiss: {
                    showingSavedSearches = false
                }
            )
        }
    }

    // MARK: - Search Header

    private var searchHeaderSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search mood boards, colors, seating...", text: $searchService.searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task {
                                await searchService.performSearch()
                            }
                        }

                    if searchService.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    if !searchService.searchQuery.isEmpty {
                        Button(action: {
                            searchService.searchQuery = ""
                            searchSuggestions = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                // Action buttons
                HStack(spacing: 8) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" :
                            "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? .blue : .secondary)
                    }
                    .help("Filters")

                    Button(action: { showingSavedSearches = true }) {
                        Image(systemName: "bookmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .help("Saved Searches")

                    Menu {
                        Button("Save Current Search") {
                            saveCurrentSearch()
                        }
                        .disabled(searchService.searchQuery.isEmpty)

                        Divider()

                        Button("Clear All Filters") {
                            searchService.clearFilters()
                        }
                        .disabled(!hasActiveFilters)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                    .help("More Options")
                }
            }

            // Search suggestions
            if !searchSuggestions.isEmpty, !searchService.searchQuery.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(searchSuggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                searchService.searchQuery = suggestion
                                searchSuggestions = []
                                Task {
                                    await searchService.performSearch()
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: searchService.searchQuery) { _, newValue in
            if !newValue.isEmpty {
                searchSuggestions = searchService.getSearchSuggestions(for: newValue)
            } else {
                searchSuggestions = []
            }
        }
    }

    // MARK: - Quick Filters

    private var quickFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(QuickFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        searchService.applyQuickFilter(filter)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.caption)

                            Text(filter.displayName)
                                .font(.caption)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(AppColors.textSecondary.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(spacing: 0) {
            // Result type picker
            if !searchService.searchResults.isEmpty || searchService.isSearching {
                Picker("Result Type", selection: $selectedResultType) {
                    Text("All (\(searchService.searchResults.totalCount))").tag(ResultType.all)
                    Text("Mood Boards (\(searchService.searchResults.moodBoards.count))").tag(ResultType.moodBoards)
                    Text("Color Palettes (\(searchService.searchResults.colorPalettes.count))")
                        .tag(ResultType.colorPalettes)
                    Text("Seating Charts (\(searchService.searchResults.seatingCharts.count))")
                        .tag(ResultType.seatingCharts)
                    if !searchService.searchResults.stylePreferences.isEmpty {
                        Text("Style Preferences").tag(ResultType.stylePreferences)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom)
            }

            // Results content
            Group {
                if searchService.searchQuery.isEmpty, !searchService.isSearching {
                    emptySearchState
                } else if searchService.isSearching {
                    loadingState
                } else if searchService.searchResults.isEmpty {
                    noResultsState
                } else {
                    resultsContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var resultsContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                switch selectedResultType {
                case .all:
                    allResultsView
                case .moodBoards:
                    moodBoardResultsView
                case .colorPalettes:
                    colorPaletteResultsView
                case .seatingCharts:
                    seatingChartResultsView
                case .stylePreferences:
                    stylePreferencesResultsView
                }
            }
            .padding()
        }
    }

    // MARK: - Result Views

    private var allResultsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !searchService.searchResults.moodBoards.isEmpty {
                SearchResultSection(
                    title: "Mood Boards",
                    count: searchService.searchResults.moodBoards.count) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(searchService.searchResults.moodBoards.prefix(6)) { moodBoard in
                            MoodBoardSearchResultCard(moodBoard: moodBoard) {
                                // Handle selection - navigate to mood board detail
                                AppLogger.ui.info("Selected mood board: \(moodBoard.boardName)")
                            }
                        }
                    }

                    if searchService.searchResults.moodBoards.count > 6 {
                        Button("View All \(searchService.searchResults.moodBoards.count) Mood Boards") {
                            selectedResultType = .moodBoards
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }

            if !searchService.searchResults.colorPalettes.isEmpty {
                SearchResultSection(
                    title: "Color Palettes",
                    count: searchService.searchResults.colorPalettes.count) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(Array(searchService.searchResults.colorPalettes.prefix(4))) { palette in
                            ColorPaletteSearchResultCard(palette: palette) {
                                // Handle selection - navigate to color palette detail
                                AppLogger.ui.info("Selected color palette: \(palette.name)")
                            }
                        }
                    }

                    if searchService.searchResults.colorPalettes.count > 4 {
                        Button("View All \(searchService.searchResults.colorPalettes.count) Color Palettes") {
                            selectedResultType = .colorPalettes
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }

            if !searchService.searchResults.seatingCharts.isEmpty {
                SearchResultSection(
                    title: "Seating Charts",
                    count: searchService.searchResults.seatingCharts.count) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ForEach(searchService.searchResults.seatingCharts.prefix(4)) { chart in
                            SeatingChartSearchResultCard(chart: chart) {
                                // Handle selection - navigate to seating chart detail
                                AppLogger.ui.info("Selected seating chart: \(chart.chartName)")
                            }
                        }
                    }

                    if searchService.searchResults.seatingCharts.count > 4 {
                        Button("View All \(searchService.searchResults.seatingCharts.count) Seating Charts") {
                            selectedResultType = .seatingCharts
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    private var moodBoardResultsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            ForEach(searchService.searchResults.moodBoards) { moodBoard in
                MoodBoardSearchResultCard(moodBoard: moodBoard) {
                    AppLogger.ui.info("Selected mood board: \(moodBoard.boardName)")
                }
            }
        }
    }

    private var colorPaletteResultsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(searchService.searchResults.colorPalettes) { palette in
                ColorPaletteSearchResultCard(palette: palette) {
                    AppLogger.ui.info("Selected color palette: \(palette.name)")
                }
            }
        }
    }

    private var seatingChartResultsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(searchService.searchResults.seatingCharts) { chart in
                SeatingChartSearchResultCard(chart: chart) {
                    AppLogger.ui.info("Selected seating chart: \(chart.chartName)")
                }
            }
        }
    }

    private var stylePreferencesResultsView: some View {
        VStack(spacing: 16) {
            ForEach(searchService.searchResults.stylePreferences, id: \.tenantId) { preferences in
                StylePreferencesSearchResultCard(
                    stylePreferences: preferences,
                    onTap: {
                        AppLogger.ui.info("Selected style preferences")
                        // Navigate to style preferences view
                    }
                )
            }
        }
    }

    // MARK: - Empty States

    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Search Your Visual Planning")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Find mood boards, color palettes, seating charts, and style preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                SearchTipRow(icon: "photo.on.rectangle.angled", text: "Search mood boards by name or style")
                SearchTipRow(icon: "paintpalette", text: "Find color palettes by mood or season")
                SearchTipRow(icon: "tablecells", text: "Locate seating charts by guest names")
                SearchTipRow(icon: "sparkles", text: "Discover by style preferences")
            }
        }
        .padding(Spacing.xxxl)
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.xxxl)
    }

    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Try adjusting your search terms or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button("Clear Filters") {
                    searchService.clearFilters()
                }
                .buttonStyle(.bordered)
                .disabled(!hasActiveFilters)

                Button("Browse All") {
                    searchService.searchQuery = ""
                    searchService.clearFilters()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Spacing.xxxl)
    }

    // MARK: - Helper Views and Methods

    private var hasActiveFilters: Bool {
        !searchService.activeFilters.styleCategories.isEmpty ||
            !searchService.activeFilters.seasons.isEmpty ||
            !searchService.activeFilters.colors.isEmpty ||
            searchService.activeFilters.favoritesOnly ||
            searchService.activeFilters.showTemplatesOnly ||
            searchService.activeFilters.finalizedOnly ||
            searchService.activeFilters.dateRange != nil
    }

    private func saveCurrentSearch() {
        // Show alert to get name for saved search
        let alert = NSAlert()
        alert.messageText = "Save Search"
        alert.informativeText = "Enter a name for this search:"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = searchService.searchQuery.isEmpty ? "My Search" : searchService.searchQuery
        alert.accessoryView = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let name = textField.stringValue.isEmpty ? "Untitled Search" : textField.stringValue
            searchService.saveCurrentSearch(name: name)
        }
    }

    enum ResultType: String, CaseIterable {
        case all = "all"
        case moodBoards = "mood_boards"
        case colorPalettes = "color_palettes"
        case seatingCharts = "seating_charts"
        case stylePreferences = "style_preferences"
    }
}

// MARK: - Supporting Views

struct SearchTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

struct SearchResultSection<Content: View>: View {
    let title: String
    let count: Int
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)

                Text("(\(count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }

            content
        }
    }
}

#Preview {
    VisualPlanningSearchView(supabaseService: SupabaseVisualPlanningService())
        .frame(width: 800, height: 600)
}
