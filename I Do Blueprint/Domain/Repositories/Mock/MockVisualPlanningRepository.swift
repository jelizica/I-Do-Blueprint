//
//  MockVisualPlanningRepository.swift
//  My Wedding Planning App
//
//  Mock implementation for testing
//

import Foundation

@MainActor
class MockVisualPlanningRepository: VisualPlanningRepositoryProtocol {
    var moodBoards: [MoodBoard] = []
    var colorPalettes: [ColorPalette] = []
    var seatingCharts: [SeatingChart] = []

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1)

    // MARK: - Mood Boards

    func fetchMoodBoards() async throws -> [MoodBoard] {
        if shouldThrowError { throw errorToThrow }
        return moodBoards
    }

    func fetchMoodBoard(id: UUID) async throws -> MoodBoard? {
        if shouldThrowError { throw errorToThrow }
        return moodBoards.first(where: { $0.id == id })
    }

    func createMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        if shouldThrowError { throw errorToThrow }
        var board = moodBoard
        board.createdAt = Date()
        board.updatedAt = Date()
        moodBoards.append(board)
        return board
    }

    func updateMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        if shouldThrowError { throw errorToThrow }

        guard let index = moodBoards.firstIndex(where: { $0.id == moodBoard.id }) else {
            throw NSError(domain: "test", code: 404)
        }

        var updated = moodBoard
        updated.updatedAt = Date()
        moodBoards[index] = updated
        return updated
    }

    func deleteMoodBoard(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        moodBoards.removeAll { $0.id == id }
    }

    // MARK: - Color Palettes

    func fetchColorPalettes() async throws -> [ColorPalette] {
        if shouldThrowError { throw errorToThrow }
        return colorPalettes
    }

    func fetchColorPalette(id: UUID) async throws -> ColorPalette? {
        if shouldThrowError { throw errorToThrow }
        return colorPalettes.first(where: { $0.id == id })
    }

    func createColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        if shouldThrowError { throw errorToThrow }
        var newPalette = palette
        newPalette.createdAt = Date()
        newPalette.updatedAt = Date()
        colorPalettes.append(newPalette)
        return newPalette
    }

    func updateColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        if shouldThrowError { throw errorToThrow }

        guard let index = colorPalettes.firstIndex(where: { $0.id == palette.id }) else {
            throw NSError(domain: "test", code: 404)
        }

        var updated = palette
        updated.updatedAt = Date()
        colorPalettes[index] = updated
        return updated
    }

    func deleteColorPalette(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        colorPalettes.removeAll { $0.id == id }
    }

    // MARK: - Seating Charts

    func fetchSeatingCharts() async throws -> [SeatingChart] {
        if shouldThrowError { throw errorToThrow }
        return seatingCharts
    }

    func fetchSeatingChart(id: UUID) async throws -> SeatingChart? {
        if shouldThrowError { throw errorToThrow }
        return seatingCharts.first(where: { $0.id == id })
    }

    func createSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        if shouldThrowError { throw errorToThrow }
        var newChart = chart
        newChart.createdAt = Date()
        newChart.updatedAt = Date()
        seatingCharts.append(newChart)
        return newChart
    }

    func updateSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        if shouldThrowError { throw errorToThrow }

        guard let index = seatingCharts.firstIndex(where: { $0.id == chart.id }) else {
            throw NSError(domain: "test", code: 404)
        }

        var updated = chart
        updated.updatedAt = Date()
        seatingCharts[index] = updated
        return updated
    }

    func deleteSeatingChart(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        seatingCharts.removeAll { $0.id == id }
    }

    // MARK: - Seating Chart Details

    func fetchSeatingGuests(for tenantId: String) async throws -> [SeatingGuest] {
        if shouldThrowError { throw errorToThrow }
        // Return mock guests for testing
        return []
    }

    func fetchTables(for chartId: UUID) async throws -> [Table] {
        if shouldThrowError { throw errorToThrow }
        // Return tables from the matching chart
        return seatingCharts.first(where: { $0.id == chartId })?.tables ?? []
    }

    func fetchSeatAssignments(for chartId: UUID) async throws -> [SeatingAssignment] {
        if shouldThrowError { throw errorToThrow }
        // Return assignments from the matching chart
        return seatingCharts.first(where: { $0.id == chartId })?.seatingAssignments ?? []
    }
}
