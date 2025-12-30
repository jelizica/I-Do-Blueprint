//
//  MockVisualPlanningRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of VisualPlanningRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockVisualPlanningRepository: VisualPlanningRepositoryProtocol {
    var moodBoards: [MoodBoard] = []
    var colorPalettes: [ColorPalette] = []
    var seatingCharts: [SeatingChart] = []
    var seatingGuests: [SeatingGuest] = []
    var tables: [Table] = []
    var seatAssignments: [SeatingAssignment] = []
    var shouldThrowError = false
    var errorToThrow: VisualPlanningError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

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
        moodBoards.append(moodBoard)
        return moodBoard
    }

    func updateMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        if shouldThrowError { throw errorToThrow }
        if let index = moodBoards.firstIndex(where: { $0.id == moodBoard.id }) {
            moodBoards[index] = moodBoard
        }
        return moodBoard
    }

    func deleteMoodBoard(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        moodBoards.removeAll(where: { $0.id == id })
    }

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
        colorPalettes.append(palette)
        return palette
    }

    func updateColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        if shouldThrowError { throw errorToThrow }
        if let index = colorPalettes.firstIndex(where: { $0.id == palette.id }) {
            colorPalettes[index] = palette
        }
        return palette
    }

    func deleteColorPalette(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        colorPalettes.removeAll(where: { $0.id == id })
    }

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
        seatingCharts.append(chart)
        return chart
    }

    func updateSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        if shouldThrowError { throw errorToThrow }
        if let index = seatingCharts.firstIndex(where: { $0.id == chart.id }) {
            seatingCharts[index] = chart
        }
        return chart
    }

    func deleteSeatingChart(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        seatingCharts.removeAll(where: { $0.id == id })
    }

    func fetchSeatingGuests(for tenantId: String) async throws -> [SeatingGuest] {
        if shouldThrowError { throw errorToThrow }
        return seatingGuests
    }

    func fetchTables(for chartId: UUID) async throws -> [Table] {
        if shouldThrowError { throw errorToThrow }
        guard let chart = seatingCharts.first(where: { $0.id == chartId }) else {
            return []
        }
        return chart.tables
    }

    func fetchSeatAssignments(for chartId: UUID) async throws -> [SeatingAssignment] {
        if shouldThrowError { throw errorToThrow }
        guard let chart = seatingCharts.first(where: { $0.id == chartId }) else {
            return []
        }
        return chart.seatingAssignments
    }
}
