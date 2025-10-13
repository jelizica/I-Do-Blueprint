//
//  VisualPlanningStore.swift
//  My Wedding Planning App
//
//  ObservableObject store for managing visual planning data
//

import Combine
import Foundation
import SwiftUI

@MainActor
class VisualPlanningStore: ObservableObject {
    @Published var moodBoards: [MoodBoard] = []
    @Published var colorPalettes: [ColorPalette] = []
    @Published var seatingCharts: [SeatingChart] = []
    @Published var stylePreferences: StylePreferences?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Sheet presentations
    @Published var showingMoodBoardCreator = false
    @Published var showingColorPaletteCreator = false
    @Published var showingStylePreferences = false

    private let tenantId =
        "c507b4c9-7ef4-4b76-a71a-63887984b9ab" // Admin couple ID
    private var supabaseService: SupabaseVisualPlanningService?
    private let persistenceEnabled: Bool
    private let logger = AppLogger.database

    init() {
        // Try to initialize Supabase service, but continue if it fails
        do {
            supabaseService = SupabaseVisualPlanningService()
            persistenceEnabled = true
        } catch {
            logger.warning("Supabase not configured - running in local mode only")
            supabaseService = nil
            persistenceEnabled = false
        }

        loadSampleData()

        if persistenceEnabled {
            Task {
                await loadPersistedData()
            }
        }
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        // Sample color palettes
        colorPalettes = [
            ColorPalette(
                name: "Romantic Blush",
                colors: ["#E8B4B8", "#F4E4E6", "#C7969B", "#F8F6F7", "#D4A5A9", "#EDD1D3"],
                description: "Soft romantic blush and pink tones",
                isDefault: false),
            ColorPalette(
                name: "Garden Sage",
                colors: ["#9CAF88", "#F0F4EC", "#7A8471", "#FEFFFE", "#B8C5A8", "#D4E0C7"],
                description: "Natural green and sage garden tones",
                isDefault: false),
            ColorPalette(
                name: "Coastal Blue",
                colors: ["#6B9DC2", "#E6F1FA", "#4A7BA7", "#F8FBFD", "#89B3D1", "#A8C8E1"],
                description: "Ocean and coastal blue palette",
                isDefault: false)
        ]

        // Sample mood boards
        moodBoards = [
            MoodBoard(
                tenantId: tenantId,
                boardName: "Romantic Garden Wedding",
                boardDescription: "Soft, dreamy aesthetic with natural elements",
                styleCategory: .romantic,
                colorPaletteId: colorPalettes[0].id,
                backgroundColor: Color.fromHex("#F8F6F7")),
            MoodBoard(
                tenantId: tenantId,
                boardName: "Modern Minimalist",
                boardDescription: "Clean lines, neutral tones, contemporary style",
                styleCategory: .minimalist,
                backgroundColor: Color.white)
        ]

        // Sample style preferences
        stylePreferences = StylePreferences(tenantId: tenantId)
    }

    // MARK: - Mood Board Management

    func createMoodBoard(_ moodBoard: MoodBoard) {
        moodBoards.append(moodBoard)
        Task {
            await saveMoodBoard(moodBoard)
        }
    }

    func updateMoodBoard(_ moodBoard: MoodBoard) {
        if let index = moodBoards.firstIndex(where: { $0.id == moodBoard.id }) {
            var updatedMoodBoard = moodBoard
            updatedMoodBoard.updatedAt = Date()
            moodBoards[index] = updatedMoodBoard
            Task {
                await saveMoodBoard(updatedMoodBoard)
            }
        }
    }

    func deleteMoodBoard(_ moodBoard: MoodBoard) {
        moodBoards.removeAll { $0.id == moodBoard.id }
        Task {
            guard persistenceEnabled, let service = supabaseService else { return }
            do {
                try await service.deleteMoodBoard(id: moodBoard.id)
            } catch {
                errorMessage = "Failed to delete mood board: \(error.localizedDescription)"
            }
        }
    }

    func duplicateMoodBoard(_ moodBoard: MoodBoard) {
        let duplicate = MoodBoard(
            id: UUID(),
            tenantId: moodBoard.tenantId,
            boardName: "\(moodBoard.boardName) Copy",
            boardDescription: moodBoard.boardDescription,
            styleCategory: moodBoard.styleCategory,
            colorPaletteId: moodBoard.colorPaletteId,
            canvasSize: moodBoard.canvasSize,
            backgroundColor: moodBoard.backgroundColor,
            backgroundImage: moodBoard.backgroundImage,
            elements: moodBoard.elements,
            isTemplate: moodBoard.isTemplate)
        moodBoards.append(duplicate)
        Task {
            await saveMoodBoard(duplicate)
        }
    }

    private func saveMoodBoard(_ moodBoard: MoodBoard) async {
        guard persistenceEnabled, let service = supabaseService else {
            logger.warning("Cannot save mood board - persistence not enabled or no service")
            return
        }
        do {
            logger.debug("Saving mood board: \(moodBoard.boardName) with \(moodBoard.elements.count) elements")
            try await service.saveMoodBoard(moodBoard)
            logger.info("Mood board saved successfully: \(moodBoard.id)")
        } catch {
            logger.error("Failed to save mood board", error: error)
            errorMessage = "Failed to save mood board: \(error.localizedDescription)"
        }
    }

    // MARK: - Color Palette Management

    func createColorPalette(_ palette: ColorPalette) {
        colorPalettes.append(palette)
        Task {
            await saveColorPalette(palette)
        }
    }

    func updateColorPalette(_ palette: ColorPalette) {
        if let index = colorPalettes.firstIndex(where: { $0.id == palette.id }) {
            var updatedPalette = palette
            updatedPalette.updatedAt = Date()
            colorPalettes[index] = updatedPalette
            Task {
                await saveColorPalette(updatedPalette)
            }
        }
    }

    func deleteColorPalette(_ palette: ColorPalette) {
        colorPalettes.removeAll { $0.id == palette.id }
        Task {
            guard persistenceEnabled, let service = supabaseService else { return }
            do {
                try await service.deleteColorPalette(id: palette.id)
            } catch {
                errorMessage = "Failed to delete color palette: \(error.localizedDescription)"
            }
        }
    }

    func duplicateColorPalette(_ palette: ColorPalette) {
        let duplicate = ColorPalette(
            id: UUID(),
            name: "\(palette.name) Copy",
            colors: palette.colors,
            description: palette.description,
            isDefault: palette.isDefault)
        colorPalettes.append(duplicate)
        Task {
            await saveColorPalette(duplicate)
        }
    }

    func setActivePalette(_ palette: ColorPalette) {
        // Deactivate all palettes
        for index in colorPalettes.indices {
            colorPalettes[index].isDefault = false
        }

        // Activate the selected palette
        if let index = colorPalettes.firstIndex(where: { $0.id == palette.id }) {
            colorPalettes[index].isDefault = true
            colorPalettes[index].updatedAt = Date()
            Task {
                await saveColorPalette(colorPalettes[index])
            }
        }
    }

    private func saveColorPalette(_ palette: ColorPalette) async {
        guard persistenceEnabled, let service = supabaseService else { return }
        do {
            try await service.saveColorPalette(palette)
        } catch {
            errorMessage = "Failed to save color palette: \(error.localizedDescription)"
        }
    }

    // MARK: - Seating Chart Management

    func createSeatingChart(_ chart: SeatingChart) {
        seatingCharts.append(chart)
        Task {
            await saveSeatingChart(chart)
        }
    }

    func updateSeatingChart(_ chart: SeatingChart) {
        if let index = seatingCharts.firstIndex(where: { $0.id == chart.id }) {
            var updatedChart = chart
            updatedChart.updatedAt = Date()
            seatingCharts[index] = updatedChart
            Task {
                await saveSeatingChart(updatedChart)
            }
        }
    }

    func deleteSeatingChart(_ chart: SeatingChart) {
        seatingCharts.removeAll { $0.id == chart.id }
        Task {
            guard persistenceEnabled, let service = supabaseService else { return }
            do {
                try await service.saveSeatingChart(chart)
            } catch {
                errorMessage = "Failed to delete seating chart: \(error.localizedDescription)"
            }
        }
    }

    private func saveSeatingChart(_ chart: SeatingChart) async {
        guard persistenceEnabled, let service = supabaseService else { return }
        do {
            try await service.saveSeatingChart(chart)
        } catch {
            errorMessage = "Failed to save seating chart: \(error.localizedDescription)"
        }
    }

    // MARK: - Style Preferences Management

    func updateStylePreferences(_ preferences: StylePreferences) {
        var updatedPreferences = preferences
        updatedPreferences.updatedAt = Date()
        stylePreferences = updatedPreferences
        Task {
            await saveStylePreferences(updatedPreferences)
        }
    }

    private func saveStylePreferences(_ preferences: StylePreferences) async {
        guard persistenceEnabled, let service = supabaseService else { return }
        do {
            try await service.saveStylePreferences(preferences)
        } catch {
            errorMessage = "Failed to save style preferences: \(error.localizedDescription)"
        }
    }

    // MARK: - Data Loading

    private func loadPersistedData() async {
        guard let service = supabaseService else {
            logger.warning("No Supabase service available")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            logger.debug("Loading persisted data for tenant: \(tenantId)")
            // Load all data from Supabase
            async let loadedMoodBoards = service.fetchMoodBoards(for: tenantId)
            async let loadedPalettes = service.fetchColorPalettes(for: tenantId)
            async let loadedCharts = service.fetchSeatingCharts(for: tenantId)
            async let loadedPreferences = service.fetchStylePreferences(for: tenantId)

            let (boards, palettes, charts, preferences) = try await (
                loadedMoodBoards,
                loadedPalettes,
                loadedCharts,
                loadedPreferences)

            logger.info("Loaded \(boards.count) mood boards, \(palettes.count) color palettes, \(charts.count) seating charts")

            // Update published properties - always update to show persisted data
            // For mood boards and palettes, keep sample data if no persisted data
            if !boards.isEmpty {
                moodBoards = boards
            }
            if !palettes.isEmpty {
                colorPalettes = palettes
            }
            // For seating charts, always update (even if empty) since we don't have sample data
            seatingCharts = charts
            logger.debug("Seating charts now has \(seatingCharts.count) items")

            if let prefs = preferences {
                stylePreferences = prefs
            }
        } catch {
            logger.error("Failed to load data", error: error)
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
    }

    // MARK: - Statistics

    func getStatistics() -> VisualPlanningStatistics {
        let totalMoodBoards = moodBoards.count
        let totalColorPalettes = colorPalettes.count

        // Style categories (ColorPalette no longer has styleCategory)
        let styleCategories = moodBoards.map(\.styleCategory)
        let styleCounts = Dictionary(grouping: styleCategories, by: { $0 })
            .mapValues { $0.count }
        let favoriteStyles = styleCounts.sorted { $0.value > $1.value }.map(\.key)

        // All colors from all palettes
        let allColors = colorPalettes.flatMap { $0.colors }
        let colorCounts = Dictionary(grouping: allColors, by: { $0 })
            .mapValues { $0.count }
        let mostUsedColors = colorCounts.sorted { $0.value > $1.value }.map(\.key)

        return VisualPlanningStatistics(
            totalMoodBoards: totalMoodBoards,
            totalColorPalettes: totalColorPalettes,
            favoriteStyleCategories: Array(favoriteStyles.prefix(5)),
            mostUsedColors: Array(mostUsedColors.prefix(5)),
            boardsWithElements: moodBoards.filter { !$0.elements.isEmpty }.count,
            averageElementsPerBoard: totalMoodBoards > 0 ? Double(moodBoards.map(\.elements.count).reduce(0, +)) /
                Double(totalMoodBoards) : 0,
            templatesCreated: moodBoards.filter(\.isTemplate).count + 0) // ColorPalette no longer has isTemplate property
    }
}

// MARK: - Statistics Model

struct VisualPlanningStatistics {
    let totalMoodBoards: Int
    let totalColorPalettes: Int
    let favoriteStyleCategories: [StyleCategory]
    let mostUsedColors: [String]
    let boardsWithElements: Int
    let averageElementsPerBoard: Double
    let templatesCreated: Int
}
