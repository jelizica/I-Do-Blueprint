//
//  VisualPlanningStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for VisualPlanningStoreV2
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class VisualPlanningStoreV2Tests: XCTestCase {
    var store: VisualPlanningStoreV2!
    var mockRepository: MockVisualPlanningRepository!

    override func setUp() async throws {
        mockRepository = MockVisualPlanningRepository()
        store = withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }
    }

    override func tearDown() async throws {
        store = nil
        mockRepository = nil
    }

    // MARK: - Load Mood Boards Tests

    func testLoadMoodBoards_Success() async throws {
        // Given
        let mockBoards = [
            createMockMoodBoard(name: "Rustic"),
            createMockMoodBoard(name: "Modern"),
        ]
        mockRepository.moodBoards = mockBoards

        // When
        await store.loadMoodBoards()

        // Then
        XCTAssertEqual(store.moodBoards.count, 2)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadMoodBoards_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await store.loadMoodBoards()

        // Then
        XCTAssertTrue(store.moodBoards.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Create Mood Board Tests

    func testCreateMoodBoard_Success() async throws {
        // Given
        let newBoard = createMockMoodBoard(name: "Elegant")
        mockRepository.createdMoodBoard = newBoard

        // When
        await store.createMoodBoard(newBoard)

        // Then
        XCTAssertEqual(store.moodBoards.count, 1)
        XCTAssertEqual(store.moodBoards[0].name, "Elegant")
        XCTAssertNil(store.error)
    }

    // MARK: - Update Mood Board Tests

    func testUpdateMoodBoard_Success() async throws {
        // Given
        let originalBoard = createMockMoodBoard(name: "Original")
        store.moodBoards = [originalBoard]

        var updatedBoard = originalBoard
        updatedBoard.name = "Updated"
        mockRepository.updatedMoodBoard = updatedBoard

        // When
        await store.updateMoodBoard(updatedBoard)

        // Then
        XCTAssertEqual(store.moodBoards[0].name, "Updated")
        XCTAssertNil(store.error)
    }

    func testUpdateMoodBoard_RollbackOnError() async throws {
        // Given
        let originalBoard = createMockMoodBoard(name: "Original")
        store.moodBoards = [originalBoard]

        var updatedBoard = originalBoard
        updatedBoard.name = "Updated"
        mockRepository.shouldThrowError = true

        // When
        await store.updateMoodBoard(updatedBoard)

        // Then
        XCTAssertEqual(store.moodBoards[0].name, "Original")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Delete Mood Board Tests

    func testDeleteMoodBoard_Success() async throws {
        // Given
        let board = createMockMoodBoard(name: "To Delete")
        store.moodBoards = [board]

        // When
        await store.deleteMoodBoard(board)

        // Then
        XCTAssertTrue(store.moodBoards.isEmpty)
        XCTAssertNil(store.error)
    }

    func testDeleteMoodBoard_RollbackOnError() async throws {
        // Given
        let board = createMockMoodBoard(name: "To Delete")
        store.moodBoards = [board]
        mockRepository.shouldThrowError = true

        // When
        await store.deleteMoodBoard(board)

        // Then
        XCTAssertEqual(store.moodBoards.count, 1)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Load Color Palettes Tests

    func testLoadColorPalettes_Success() async throws {
        // Given
        let mockPalettes = [
            createMockColorPalette(name: "Summer"),
            createMockColorPalette(name: "Winter"),
        ]
        mockRepository.colorPalettes = mockPalettes

        // When
        await store.loadColorPalettes()

        // Then
        XCTAssertEqual(store.colorPalettes.count, 2)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    // MARK: - Create Color Palette Tests

    func testCreateColorPalette_Success() async throws {
        // Given
        let newPalette = createMockColorPalette(name: "Autumn")
        mockRepository.createdColorPalette = newPalette

        // When
        await store.createColorPalette(newPalette)

        // Then
        XCTAssertEqual(store.colorPalettes.count, 1)
        XCTAssertEqual(store.colorPalettes[0].name, "Autumn")
        XCTAssertNil(store.error)
    }

    // MARK: - Update Color Palette Tests

    func testUpdateColorPalette_Success() async throws {
        // Given
        let originalPalette = createMockColorPalette(name: "Original")
        store.colorPalettes = [originalPalette]

        var updatedPalette = originalPalette
        updatedPalette.name = "Updated"
        mockRepository.updatedColorPalette = updatedPalette

        // When
        await store.updateColorPalette(updatedPalette)

        // Then
        XCTAssertEqual(store.colorPalettes[0].name, "Updated")
        XCTAssertNil(store.error)
    }

    // MARK: - Delete Color Palette Tests

    func testDeleteColorPalette_Success() async throws {
        // Given
        let palette = createMockColorPalette(name: "To Delete")
        store.colorPalettes = [palette]

        // When
        await store.deleteColorPalette(palette)

        // Then
        XCTAssertTrue(store.colorPalettes.isEmpty)
        XCTAssertNil(store.error)
    }

    // MARK: - Load Seating Charts Tests

    func testLoadSeatingCharts_Success() async throws {
        // Given
        let mockCharts = [
            createMockSeatingChart(name: "Reception"),
        ]
        mockRepository.seatingCharts = mockCharts

        // When
        await store.loadSeatingCharts()

        // Then
        XCTAssertEqual(store.seatingCharts.count, 1)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    // MARK: - Create Seating Chart Tests

    func testCreateSeatingChart_Success() async throws {
        // Given
        let newChart = createMockSeatingChart(name: "Ceremony")
        mockRepository.createdSeatingChart = newChart

        // When
        await store.createSeatingChart(newChart)

        // Then
        XCTAssertEqual(store.seatingCharts.count, 1)
        XCTAssertEqual(store.seatingCharts[0].name, "Ceremony")
        XCTAssertNil(store.error)
    }

    // MARK: - Update Seating Chart Tests

    func testUpdateSeatingChart_Success() async throws {
        // Given
        let originalChart = createMockSeatingChart(name: "Original")
        store.seatingCharts = [originalChart]

        var updatedChart = originalChart
        updatedChart.name = "Updated"
        mockRepository.updatedSeatingChart = updatedChart

        // When
        await store.updateSeatingChart(updatedChart)

        // Then
        XCTAssertEqual(store.seatingCharts[0].name, "Updated")
        XCTAssertNil(store.error)
    }

    // MARK: - Delete Seating Chart Tests

    func testDeleteSeatingChart_Success() async throws {
        // Given
        let chart = createMockSeatingChart(name: "To Delete")
        store.seatingCharts = [chart]

        // When
        await store.deleteSeatingChart(chart)

        // Then
        XCTAssertTrue(store.seatingCharts.isEmpty)
        XCTAssertNil(store.error)
    }

    // MARK: - Computed Properties Tests

    func testActivePalettes_ReturnsAllPalettes() {
        // Given
        store.colorPalettes = [
            createMockColorPalette(name: "Palette 1"),
            createMockColorPalette(name: "Palette 2"),
        ]

        // When
        let active = store.activePalettes

        // Then
        XCTAssertEqual(active.count, 2)
    }

    func testFavoritePalettes_ReturnsDefaultPalettes() {
        // Given
        store.colorPalettes = [
            createMockColorPalette(name: "Fav", isDefault: true),
            createMockColorPalette(name: "Regular", isDefault: false),
        ]

        // When
        let favorites = store.favoritePalettes

        // Then
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites[0].name, "Fav")
    }

    func testActiveSeatingChart_ReturnsActiveChart() {
        // Given
        store.seatingCharts = [
            createMockSeatingChart(name: "Inactive", isActive: false),
            createMockSeatingChart(name: "Active", isActive: true),
        ]

        // When
        let active = store.activeSeatingChart

        // Then
        XCTAssertEqual(active?.name, "Active")
    }

    // MARK: - Helper Methods

    private func createMockMoodBoard(name: String) -> MoodBoard {
        MoodBoard(
            id: UUID(),
            tenantId: UUID(),
            name: name,
            description: nil,
            theme: nil,
            images: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockColorPalette(name: String, isDefault: Bool = false) -> ColorPalette {
        ColorPalette(
            id: UUID(),
            tenantId: UUID(),
            name: name,
            description: nil,
            primaryColor: "#FFFFFF",
            secondaryColor: "#000000",
            accentColor: "#FF0000",
            neutralColor: "#CCCCCC",
            additionalColors: [],
            isDefault: isDefault,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockSeatingChart(name: String, isActive: Bool = false) -> SeatingChart {
        SeatingChart(
            id: UUID(),
            tenantId: UUID(),
            name: name,
            description: nil,
            totalSeats: 100,
            assignedSeats: 0,
            isActive: isActive,
            createdAt: Date(),
            updatedAt: Date(),
            guests: [],
            tables: [],
            seatingAssignments: []
        )
    }
}

// MARK: - Mock Repository

class MockVisualPlanningRepository: VisualPlanningRepositoryProtocol {
    var moodBoards: [MoodBoard] = []
    var colorPalettes: [ColorPalette] = []
    var seatingCharts: [SeatingChart] = []
    var createdMoodBoard: MoodBoard?
    var updatedMoodBoard: MoodBoard?
    var createdColorPalette: ColorPalette?
    var updatedColorPalette: ColorPalette?
    var createdSeatingChart: SeatingChart?
    var updatedSeatingChart: SeatingChart?
    var shouldThrowError = false

    func fetchMoodBoards() async throws -> [MoodBoard] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return moodBoards
    }

    func createMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return createdMoodBoard ?? moodBoard
    }

    func updateMoodBoard(_ moodBoard: MoodBoard) async throws -> MoodBoard {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return updatedMoodBoard ?? moodBoard
    }

    func deleteMoodBoard(id: UUID) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func fetchColorPalettes() async throws -> [ColorPalette] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return colorPalettes
    }

    func createColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return createdColorPalette ?? palette
    }

    func updateColorPalette(_ palette: ColorPalette) async throws -> ColorPalette {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return updatedColorPalette ?? palette
    }

    func deleteColorPalette(id: UUID) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func fetchSeatingCharts() async throws -> [SeatingChart] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return seatingCharts
    }

    func fetchTables(for chartId: UUID) async throws -> [SeatingTable] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return []
    }

    func fetchSeatAssignments(for chartId: UUID) async throws -> [SeatAssignment] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return []
    }

    func fetchSeatingGuests(for tenantId: UUID) async throws -> [SeatingGuest] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return []
    }

    func createSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return createdSeatingChart ?? chart
    }

    func updateSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return updatedSeatingChart ?? chart
    }

    func deleteSeatingChart(id: UUID) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func invalidateCache() async {
        // No-op for mock
    }
}
