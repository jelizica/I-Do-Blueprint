//
//  VisualPlanningStoreV2.swift
//  My Wedding Planning App
//
//  New architecture version of visual planning using repository pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

@MainActor
class VisualPlanningStoreV2: ObservableObject {
    @Published private(set) var moodBoards: [MoodBoard] = []
    @Published private(set) var colorPalettes: [ColorPalette] = []
    @Published private(set) var seatingCharts: [SeatingChart] = []

    @Published var selectedMoodBoard: MoodBoard?
    @Published var selectedPalette: ColorPalette?
    @Published var selectedSeatingChart: SeatingChart?

    @Published var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published var error: VisualPlanningError?

    // Sheet presentation
    @Published var showingMoodBoardCreator = false
    @Published var showingColorPaletteCreator = false

    // Style Preferences (not yet in repository, stored locally for now)
    @Published var stylePreferences: StylePreferences?

    @Dependency(\.visualPlanningRepository) var repository

    // MARK: - Mood Boards

    func loadMoodBoards() async {
        isLoading = true
        error = nil

        do {
            moodBoards = try await repository.fetchMoodBoards()
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func createMoodBoard(_ moodBoard: MoodBoard) async {
        do {
            let created = try await repository.createMoodBoard(moodBoard)
            moodBoards.insert(created, at: 0)
            showSuccess("Mood board created successfully")
        } catch {
            self.error = .createFailed(underlying: error)
            await handleError(error, operation: "create mood board") { [weak self] in
                await self?.createMoodBoard(moodBoard)
            }
        }
    }

    func updateMoodBoard(_ moodBoard: MoodBoard) async {
        // Optimistic update
        if let index = moodBoards.firstIndex(where: { $0.id == moodBoard.id }) {
            let original = moodBoards[index]
            moodBoards[index] = moodBoard

            do {
                let updated = try await repository.updateMoodBoard(moodBoard)
                moodBoards[index] = updated
                showSuccess("Mood board updated successfully")
            } catch {
                // Rollback on error
                moodBoards[index] = original
                self.error = .updateFailed(underlying: error)
                await handleError(error, operation: "update mood board") { [weak self] in
                    await self?.updateMoodBoard(moodBoard)
                }
            }
        }
    }

    func deleteMoodBoard(_ moodBoard: MoodBoard) async {
        // Optimistic delete
        guard let index = moodBoards.firstIndex(where: { $0.id == moodBoard.id }) else { return }
        let removed = moodBoards.remove(at: index)

        do {
            try await repository.deleteMoodBoard(id: moodBoard.id)
            showSuccess("Mood board deleted successfully")
        } catch {
            // Rollback on error
            moodBoards.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
            await handleError(error, operation: "delete mood board") { [weak self] in
                await self?.deleteMoodBoard(moodBoard)
            }
        }
    }

    // MARK: - Color Palettes

    func loadColorPalettes() async {
        isLoading = true
        error = nil

        do {
            colorPalettes = try await repository.fetchColorPalettes()
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func createColorPalette(_ palette: ColorPalette) async {
        do {
            let created = try await repository.createColorPalette(palette)
            colorPalettes.insert(created, at: 0)
            showSuccess("Color palette created successfully")
        } catch {
            self.error = .createFailed(underlying: error)
            await handleError(error, operation: "create color palette") { [weak self] in
                await self?.createColorPalette(palette)
            }
        }
    }

    func updateColorPalette(_ palette: ColorPalette) async {
        // Optimistic update
        if let index = colorPalettes.firstIndex(where: { $0.id == palette.id }) {
            let original = colorPalettes[index]
            colorPalettes[index] = palette

            do {
                let updated = try await repository.updateColorPalette(palette)
                colorPalettes[index] = updated
                showSuccess("Color palette updated successfully")
            } catch {
                // Rollback on error
                colorPalettes[index] = original
                self.error = .updateFailed(underlying: error)
                await handleError(error, operation: "update color palette") { [weak self] in
                    await self?.updateColorPalette(palette)
                }
            }
        }
    }

    func deleteColorPalette(_ palette: ColorPalette) async {
        // Optimistic delete
        guard let index = colorPalettes.firstIndex(where: { $0.id == palette.id }) else { return }
        let removed = colorPalettes.remove(at: index)

        do {
            try await repository.deleteColorPalette(id: palette.id)
            showSuccess("Color palette deleted successfully")
        } catch {
            // Rollback on error
            colorPalettes.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
            await handleError(error, operation: "delete color palette") { [weak self] in
                await self?.deleteColorPalette(palette)
            }
        }
    }

    // MARK: - Seating Charts

    func loadSeatingCharts() async {
        isLoading = true
        error = nil

        do {
            seatingCharts = try await repository.fetchSeatingCharts()

            // Load guests and tables for each chart
            for index in seatingCharts.indices {
                let chart = seatingCharts[index]

                // Load tables from database
                let tables = try await repository.fetchTables(for: chart.id)
                seatingCharts[index].tables = tables

                // Load assignments from database
                let assignments = try await repository.fetchSeatAssignments(for: chart.id)
                seatingCharts[index].seatingAssignments = assignments

                // Load guests from guest_list (once for all charts, using tenant_id)
                if seatingCharts[index].guests.isEmpty {
                    let guests = try await repository.fetchSeatingGuests(for: chart.tenantId)
                    seatingCharts[index].guests = guests
                }
            }
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func createSeatingChart(_ chart: SeatingChart) async {
        do {
            let created = try await repository.createSeatingChart(chart)
            seatingCharts.insert(created, at: 0)
            showSuccess("Seating chart created successfully")
        } catch {
            self.error = .createFailed(underlying: error)
            await handleError(error, operation: "create seating chart") { [weak self] in
                await self?.createSeatingChart(chart)
            }
        }
    }

    func updateSeatingChart(_ chart: SeatingChart) async {
        // Optimistic update
        if let index = seatingCharts.firstIndex(where: { $0.id == chart.id }) {
            let original = seatingCharts[index]
            seatingCharts[index] = chart

            do {
                let updated = try await repository.updateSeatingChart(chart)
                seatingCharts[index] = updated
                showSuccess("Seating chart updated successfully")
            } catch {
                // Rollback on error
                seatingCharts[index] = original
                self.error = .updateFailed(underlying: error)
                await handleError(error, operation: "update seating chart") { [weak self] in
                    await self?.updateSeatingChart(chart)
                }
            }
        }
    }

    func deleteSeatingChart(_ chart: SeatingChart) async {
        // Optimistic delete
        guard let index = seatingCharts.firstIndex(where: { $0.id == chart.id }) else { return }
        let removed = seatingCharts.remove(at: index)

        do {
            try await repository.deleteSeatingChart(id: chart.id)
            showSuccess("Seating chart deleted successfully")
        } catch {
            // Rollback on error
            seatingCharts.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
            await handleError(error, operation: "delete seating chart") { [weak self] in
                await self?.deleteSeatingChart(chart)
            }
        }
    }

    // MARK: - Computed Properties

    var activePalettes: [ColorPalette] {
        colorPalettes // ColorPalette no longer has isActive property
    }

    var favoritePalettes: [ColorPalette] {
        colorPalettes.filter(\.isDefault) // Use isDefault as favorite indicator
    }

    var activeSeatingChart: SeatingChart? {
        seatingCharts.first(where: \.isActive)
    }
}
