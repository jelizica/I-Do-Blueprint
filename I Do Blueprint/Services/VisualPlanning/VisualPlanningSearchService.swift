//
//  VisualPlanningSearchService.swift
//  My Wedding Planning App
//
//  Comprehensive search and filtering service for visual planning content
//

import Combine
import Foundation
import SwiftUI

@MainActor
class VisualPlanningSearchService: ObservableObject {
    @Published var searchResults: SearchResults = .init()
    @Published var searchQuery = ""
    @Published var isSearching = false
    @Published var activeFilters: SearchFilters = .init()
    @Published var savedSearches: [SavedSearch] = []

    private let supabaseService: SupabaseVisualPlanningService
    private var searchCancellable: AnyCancellable?
    private let logger = AppLogger.general

    init(supabaseService: SupabaseVisualPlanningService) {
        self.supabaseService = supabaseService
        setupSearchDebouncing()
        loadSavedSearches()
    }

    // MARK: - Search Functionality

    private func setupSearchDebouncing() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                if !query.isEmpty {
                    Task {
                        await self?.performSearch()
                    }
                }
            }
    }

    func performSearch() async {
        isSearching = true
        defer { isSearching = false }

        do {
            let results = try await searchContent(
                query: searchQuery,
                filters: activeFilters)
            searchResults = results
        } catch {
            logger.warning("Search failed: \(error.localizedDescription)")
            searchResults = SearchResults()
        }
    }

    private func searchContent(query: String, filters: SearchFilters) async throws -> SearchResults {
        var results = SearchResults()

        // Search mood boards
        let moodBoards = try await searchMoodBoards(query: query, filters: filters)
        results.moodBoards = moodBoards

        // Search color palettes
        let colorPalettes = try await searchColorPalettes(query: query, filters: filters)
        results.colorPalettes = colorPalettes

        // Search seating charts
        let seatingCharts = try await searchSeatingCharts(query: query, filters: filters)
        results.seatingCharts = seatingCharts

        // Search style preferences
        if let stylePreferences = try await searchStylePreferences(query: query, filters: filters) {
            results.stylePreferences = [stylePreferences]
        }

        // Calculate relevance scores
        results.sortByRelevance(query: query)

        return results
    }

    // MARK: - Mood Board Search

    private func searchMoodBoards(query: String, filters: SearchFilters) async throws -> [MoodBoard] {
        // This would use your Supabase service with full-text search
        // For now, implementing a basic search that you can enhance

        let allMoodBoards = try await supabaseService.fetchMoodBoards(for: filters.tenantId)

        return allMoodBoards.filter { moodBoard in
            matchesMoodBoardCriteria(moodBoard, query: query, filters: filters)
        }
    }

    private func matchesMoodBoardCriteria(_ moodBoard: MoodBoard, query: String, filters: SearchFilters) -> Bool {
        // Text search
        let matchesText = query.isEmpty ||
            moodBoard.boardName.localizedCaseInsensitiveContains(query) ||
            (moodBoard.boardDescription?.localizedCaseInsensitiveContains(query) ?? false) ||
            moodBoard.tags.contains { $0.localizedCaseInsensitiveContains(query) }

        // Style filter
        let matchesStyle = filters.styleCategories.isEmpty ||
            filters.styleCategories.contains(moodBoard.styleCategory)

        // Date range filter
        let matchesDateRange: Bool
        if let dateRange = filters.dateRange {
            matchesDateRange = dateRange.contains(moodBoard.createdAt)
        } else {
            matchesDateRange = true
        }

        // Template filter
        let matchesTemplate = !filters.showTemplatesOnly || moodBoard.isTemplate

        // Color filter (if mood board contains elements with matching colors)
        let matchesColor = filters.colors.isEmpty ||
            moodBoard.elements.contains { element in
                if let elementColor = element.elementData.color {
                    return filters.colors.contains { filterColor in
                        colorsSimilar(elementColor, filterColor, threshold: 50)
                    }
                }
                return false
            }

        return matchesText && matchesStyle && matchesDateRange && matchesTemplate && matchesColor
    }

    // MARK: - Color Palette Search

    private func searchColorPalettes(query: String, filters: SearchFilters) async throws -> [ColorPalette] {
        let allPalettes = try await supabaseService.fetchColorPalettes(for: filters.tenantId)

        return allPalettes.filter { palette in
            matchesColorPaletteCriteria(palette, query: query, filters: filters)
        }
    }

    private func matchesColorPaletteCriteria(_ palette: ColorPalette, query: String, filters: SearchFilters) -> Bool {
        // Text search
        let matchesText = query.isEmpty ||
            palette.name.localizedCaseInsensitiveContains(query) ||
            (palette.description?.localizedCaseInsensitiveContains(query) ?? false)

        // Season filter (ColorPalette no longer has season property)
        let matchesSeason = filters.seasons.isEmpty

        // Palette type filter (ColorPalette no longer has visibility property)
        let matchesPaletteVisibility = filters.paletteVisibility.isEmpty

        // Favorites filter
        let matchesFavorites = !filters.favoritesOnly || palette.isDefault

        // Color similarity filter
        let matchesColor = filters.colors.isEmpty ||
            filters.colors.contains { filterColor in
                palette.colors.compactMap { Color.fromHexString($0) }.contains { paletteColor in
                    colorsSimilar(paletteColor, filterColor, threshold: 50)
                }
            }

        // Date range filter
        let matchesDateRange: Bool
        if let dateRange = filters.dateRange {
            matchesDateRange = dateRange.contains(palette.createdAt)
        } else {
            matchesDateRange = true
        }

        return matchesText && matchesSeason && matchesPaletteVisibility && matchesFavorites && matchesColor &&
            matchesDateRange
    }

    // MARK: - Seating Chart Search

    private func searchSeatingCharts(query: String, filters: SearchFilters) async throws -> [SeatingChart] {
        let allCharts = try await supabaseService.fetchSeatingCharts(for: filters.tenantId)

        return allCharts.filter { chart in
            matchesSeatingChartCriteria(chart, query: query, filters: filters)
        }
    }

    private func matchesSeatingChartCriteria(_ chart: SeatingChart, query: String, filters: SearchFilters) -> Bool {
        // Text search
        let matchesText = query.isEmpty ||
            chart.chartName.localizedCaseInsensitiveContains(query) ||
            (chart.chartDescription?.localizedCaseInsensitiveContains(query) ?? false) ||
            chart.guests.contains { guest in
                "\(guest.firstName) \(guest.lastName)".localizedCaseInsensitiveContains(query)
            }

        // Venue layout filter
        let matchesVenueLayout = filters.venueLayouts.isEmpty ||
            filters.venueLayouts.contains(chart.venueLayoutType)

        // Guest count range filter
        let matchesGuestCount: Bool
        if let guestCountRange = filters.guestCountRange {
            matchesGuestCount = guestCountRange.contains(chart.guests.count)
        } else {
            matchesGuestCount = true
        }

        // Finalized filter
        let matchesFinalized = !filters.finalizedOnly || chart.isFinalized

        // Date range filter
        let matchesDateRange: Bool
        if let dateRange = filters.dateRange {
            matchesDateRange = dateRange.contains(chart.createdAt)
        } else {
            matchesDateRange = true
        }

        return matchesText && matchesVenueLayout && matchesGuestCount && matchesFinalized && matchesDateRange
    }

    // MARK: - Style Preferences Search

    private func searchStylePreferences(query: String, filters: SearchFilters) async throws -> StylePreferences? {
        let preferences = try await supabaseService.fetchStylePreferences(for: filters.tenantId)

        guard let preferences else { return nil }

        let matchesText = query.isEmpty ||
            preferences.inspirationKeywords.contains { $0.localizedCaseInsensitiveContains(query) } ||
            preferences.primaryStyle?.displayName.localizedCaseInsensitiveContains(query) == true ||
            preferences.styleInfluences.contains { $0.displayName.localizedCaseInsensitiveContains(query) }

        return matchesText ? preferences : nil
    }

    // MARK: - Advanced Filtering

    func applyQuickFilter(_ filter: QuickFilter) {
        switch filter {
        case .recent:
            activeFilters.dateRange = Date().addingTimeInterval(-7 * 24 * 60 * 60) ... Date()
        case .favorites:
            activeFilters.favoritesOnly = true
        case .templates:
            activeFilters.showTemplatesOnly = true
        case .completed:
            activeFilters.finalizedOnly = true
        case .myColors:
            // Apply user's primary colors from style preferences
            Task {
                if let preferences = try? await supabaseService.fetchStylePreferences(for: activeFilters.tenantId) {
                    activeFilters.colors = preferences.primaryColors
                    await performSearch()
                }
            }
        }

        Task {
            await performSearch()
        }
    }

    func clearFilters() {
        activeFilters = SearchFilters(tenantId: activeFilters.tenantId)
        Task {
            await performSearch()
        }
    }

    // MARK: - Saved Searches

    func saveCurrentSearch(name: String) {
        let savedSearch = SavedSearch(
            name: name,
            query: searchQuery,
            filters: activeFilters,
            createdAt: Date())

        savedSearches.append(savedSearch)
        saveSavedSearchesToUserDefaults()
    }

    func loadSavedSearch(_ savedSearch: SavedSearch) {
        searchQuery = savedSearch.query
        activeFilters = savedSearch.filters

        Task {
            await performSearch()
        }
    }

    func deleteSavedSearch(at index: Int) {
        savedSearches.remove(at: index)
        saveSavedSearchesToUserDefaults()
    }

    private func loadSavedSearches() {
        if let data = UserDefaults.standard.data(forKey: "SavedSearches"),
           let searches = try? JSONDecoder().decode([SavedSearch].self, from: data) {
            savedSearches = searches
        }
    }

    private func saveSavedSearchesToUserDefaults() {
        if let data = try? JSONEncoder().encode(savedSearches) {
            UserDefaults.standard.set(data, forKey: "SavedSearches")
        }
    }

    // MARK: - Color Comparison Helper

    private func colorsSimilar(_ color1: Color, _ color2: Color, threshold: Double) -> Bool {
        // Convert colors to HSB and compare
        let hsb1 = color1.hsb
        let hsb2 = color2.hsb

        let hueDiff = abs(hsb1.hue - hsb2.hue)
        let satDiff = abs(hsb1.saturation - hsb2.saturation)
        let brightDiff = abs(hsb1.brightness - hsb2.brightness)

        let totalDiff = hueDiff + satDiff + brightDiff
        return totalDiff < threshold
    }

    // MARK: - Smart Suggestions

    func getSearchSuggestions(for query: String) -> [String] {
        var suggestions: [String] = []

        // Style category suggestions
        let styleMatches = StyleCategory.allCases.filter {
            $0.displayName.localizedCaseInsensitiveContains(query)
        }
        suggestions.append(contentsOf: styleMatches.map(\.displayName))

        // Color name suggestions
        let colorNames = [
            "red",
            "blue",
            "green",
            "yellow",
            "purple",
            "pink",
            "orange",
            "black",
            "white",
            "gold",
            "silver"
        ]
        let colorMatches = colorNames.filter { $0.localizedCaseInsensitiveContains(query) }
        suggestions.append(contentsOf: colorMatches)

        // Common wedding terms
        let weddingTerms = ["romantic", "elegant", "rustic", "modern", "vintage", "floral", "natural", "luxurious"]
        let termMatches = weddingTerms.filter { $0.localizedCaseInsensitiveContains(query) }
        suggestions.append(contentsOf: termMatches)

        return Array(Set(suggestions)).prefix(5).map { $0 }
    }
}

// MARK: - Data Models

struct SearchResults {
    var moodBoards: [MoodBoard] = []
    var colorPalettes: [ColorPalette] = []
    var seatingCharts: [SeatingChart] = []
    var stylePreferences: [StylePreferences] = []

    var isEmpty: Bool {
        moodBoards.isEmpty && colorPalettes.isEmpty && seatingCharts.isEmpty && stylePreferences.isEmpty
    }

    var totalCount: Int {
        moodBoards.count + colorPalettes.count + seatingCharts.count + stylePreferences.count
    }

    mutating func sortByRelevance(query: String) {
        // Sort each category by relevance to the search query
        let localMoodBoards = moodBoards.sorted { calculateRelevance($0.boardName, to: query) > calculateRelevance(
            $1.boardName,
            to: query) }
        let localColorPalettes = colorPalettes
            .sorted { calculateRelevance($0.name, to: query) > calculateRelevance(
                $1.name,
                to: query) }
        let localSeatingCharts = seatingCharts
            .sorted { calculateRelevance($0.chartName, to: query) > calculateRelevance(
                $1.chartName,
                to: query) }

        moodBoards = localMoodBoards
        colorPalettes = localColorPalettes
        seatingCharts = localSeatingCharts
    }

    private func calculateRelevance(_ text: String, to query: String) -> Double {
        let lowercaseText = text.lowercased()
        let lowercaseQuery = query.lowercased()

        if lowercaseText == lowercaseQuery { return 1.0 }
        if lowercaseText.hasPrefix(lowercaseQuery) { return 0.8 }
        if lowercaseText.contains(lowercaseQuery) { return 0.6 }

        // Calculate fuzzy matching score
        let words = lowercaseQuery.components(separatedBy: " ")
        let matchingWords = words.filter { lowercaseText.contains($0) }
        return Double(matchingWords.count) / Double(words.count) * 0.4
    }
}

struct SearchFilters: Codable {
    let tenantId: String
    var styleCategories: [StyleCategory] = []
    var seasons: [WeddingSeason] = []
    var paletteVisibility: [PaletteVisibility] = []
    var venueLayouts: [VenueLayout] = []
    var colors: [Color] = []
    var dateRange: ClosedRange<Date>?
    var guestCountRange: ClosedRange<Int>?
    var favoritesOnly = false
    var showTemplatesOnly = false
    var finalizedOnly = false
    var sortBy: SortOption = .relevance
    var sortOrder: SortOrder = .descending

    init(tenantId: String = "default") {
        self.tenantId = tenantId
    }

    enum CodingKeys: String, CodingKey {
        case tenantId = "tenantId"
        case styleCategories = "styleCategories"
        case seasons = "seasons"
        case paletteVisibility = "paletteVisibility"
        case venueLayouts = "venueLayouts"
        case favoritesOnly = "favoritesOnly"
        case showTemplatesOnly = "showTemplatesOnly"
        case finalizedOnly = "finalizedOnly"
        case sortBy = "sortBy"
        case sortOrder = "sortOrder"
        case dateRangeStart = "dateRangeStart"
        case dateRangeEnd = "dateRangeEnd"
        case guestCountRangeStart = "guestCountRangeStart"
        case guestCountRangeEnd = "guestCountRangeEnd"
        case colorData = "colorData"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tenantId = try container.decode(String.self, forKey: .tenantId)
        styleCategories = try container.decodeIfPresent([StyleCategory].self, forKey: .styleCategories) ?? []
        seasons = try container.decodeIfPresent([WeddingSeason].self, forKey: .seasons) ?? []
        paletteVisibility = try container.decodeIfPresent([PaletteVisibility].self, forKey: .paletteVisibility) ?? []
        venueLayouts = try container.decodeIfPresent([VenueLayout].self, forKey: .venueLayouts) ?? []
        favoritesOnly = try container.decodeIfPresent(Bool.self, forKey: .favoritesOnly) ?? false
        showTemplatesOnly = try container.decodeIfPresent(Bool.self, forKey: .showTemplatesOnly) ?? false
        finalizedOnly = try container.decodeIfPresent(Bool.self, forKey: .finalizedOnly) ?? false
        sortBy = try container.decodeIfPresent(SortOption.self, forKey: .sortBy) ?? .relevance
        sortOrder = try container.decodeIfPresent(SortOrder.self, forKey: .sortOrder) ?? .descending

        // Handle date range
        if let startDate = try container.decodeIfPresent(Date.self, forKey: .dateRangeStart),
           let endDate = try container.decodeIfPresent(Date.self, forKey: .dateRangeEnd) {
            dateRange = startDate ... endDate
        } else {
            dateRange = nil
        }

        // Handle guest count range
        if let startCount = try container.decodeIfPresent(Int.self, forKey: .guestCountRangeStart),
           let endCount = try container.decodeIfPresent(Int.self, forKey: .guestCountRangeEnd) {
            guestCountRange = startCount ... endCount
        } else {
            guestCountRange = nil
        }

        // Handle colors - for now, skip encoding/decoding colors
        colors = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tenantId, forKey: .tenantId)
        try container.encode(styleCategories, forKey: .styleCategories)
        try container.encode(seasons, forKey: .seasons)
        try container.encode(paletteVisibility, forKey: .paletteVisibility)
        try container.encode(venueLayouts, forKey: .venueLayouts)
        try container.encode(favoritesOnly, forKey: .favoritesOnly)
        try container.encode(showTemplatesOnly, forKey: .showTemplatesOnly)
        try container.encode(finalizedOnly, forKey: .finalizedOnly)
        try container.encode(sortBy, forKey: .sortBy)
        try container.encode(sortOrder, forKey: .sortOrder)

        // Handle date range
        if let dateRange {
            try container.encode(dateRange.lowerBound, forKey: .dateRangeStart)
            try container.encode(dateRange.upperBound, forKey: .dateRangeEnd)
        }

        // Handle guest count range
        if let guestCountRange {
            try container.encode(guestCountRange.lowerBound, forKey: .guestCountRangeStart)
            try container.encode(guestCountRange.upperBound, forKey: .guestCountRangeEnd)
        }

        // Colors are not encoded for now
    }

    enum SortOption: String, CaseIterable, Codable {
        case relevance = "relevance"
        case name = "name"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case usage = "usage"

        var displayName: String {
            switch self {
            case .relevance: "Relevance"
            case .name: "Name"
            case .dateCreated: "Date Created"
            case .dateModified: "Date Modified"
            case .usage: "Usage"
            }
        }
    }

    enum SortOrder: String, CaseIterable, Codable {
        case ascending = "asc"
        case descending = "desc"

        var displayName: String {
            switch self {
            case .ascending: "Ascending"
            case .descending: "Descending"
            }
        }
    }
}

enum QuickFilter: String, CaseIterable {
case recent = "recent"
case favorites = "favorites"
case templates = "templates"
case completed = "completed"
case myColors = "my_colors"

    var displayName: String {
        switch self {
        case .recent: "Recent"
        case .favorites: "Favorites"
        case .templates: "Templates"
        case .completed: "Completed"
        case .myColors: "My Colors"
        }
    }

    var icon: String {
        switch self {
        case .recent: "clock"
        case .favorites: "heart.fill"
        case .templates: "doc.on.doc"
        case .completed: "checkmark.circle"
        case .myColors: "paintpalette"
        }
    }
}

struct SavedSearch: Codable, Identifiable {
    let id = UUID()
    let name: String
    let query: String
    let filters: SearchFilters
    let createdAt: Date
    let lastUsed: Date?

    init(name: String, query: String, filters: SearchFilters, createdAt: Date, lastUsed: Date? = nil) {
        self.name = name
        self.query = query
        self.filters = filters
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }
}

// MARK: - Color HSB Extension

extension Color {
    var hsb: (hue: Double, saturation: Double, brightness: Double) {
        let uiColor = NSColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return (Double(hue * 360), Double(saturation * 100), Double(brightness * 100))
    }
}
