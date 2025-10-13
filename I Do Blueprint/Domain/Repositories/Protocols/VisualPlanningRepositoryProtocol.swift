//
//  VisualPlanningRepositoryProtocol.swift
//  My Wedding Planning App
//
//  Repository protocol for visual planning (mood boards, palettes, seating)
//

import Dependencies
import Foundation

protocol VisualPlanningRepositoryProtocol: Sendable {
    // MARK: - Mood Boards

    func fetchMoodBoards() async throws -> [MoodBoard]
    func fetchMoodBoard(id: UUID) async throws -> MoodBoard?
    func createMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard
    func updateMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard
    func deleteMoodBoard(id: UUID) async throws

    // MARK: - Color Palettes

    func fetchColorPalettes() async throws -> [ColorPalette]
    func fetchColorPalette(id: UUID) async throws -> ColorPalette?
    func createColorPalette(_ palette: ColorPalette) async throws -> ColorPalette
    func updateColorPalette(_ palette: ColorPalette) async throws -> ColorPalette
    func deleteColorPalette(id: UUID) async throws

    // MARK: - Seating Charts

    func fetchSeatingCharts() async throws -> [SeatingChart]
    func fetchSeatingChart(id: UUID) async throws -> SeatingChart?
    func createSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart
    func updateSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart
    func deleteSeatingChart(id: UUID) async throws

    // MARK: - Seating Chart Details

    func fetchSeatingGuests(for tenantId: String) async throws -> [SeatingGuest]
    func fetchTables(for chartId: UUID) async throws -> [Table]
    func fetchSeatAssignments(for chartId: UUID) async throws -> [SeatingAssignment]
}
