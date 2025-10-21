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
    var mockRepository: MockVisualPlanningRepository!
    var tenantId: String!

    override func setUp() async throws {
        mockRepository = MockVisualPlanningRepository()
        tenantId = UUID().uuidString
    }

    override func tearDown() {
        mockRepository = nil
        tenantId = nil
    }

    // MARK: - Load Tests

    func testLoadMoodBoards_Success() async throws {
        // Given
        let testBoards = [
            MoodBoard.makeTest(id: UUID(), tenantId: tenantId, boardName: "Modern Wedding"),
            MoodBoard.makeTest(id: UUID(), tenantId: tenantId, boardName: "Rustic Theme")
        ]
        mockRepository.moodBoards = testBoards

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadMoodBoards()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.moodBoards.count, 2)
        XCTAssertEqual(store.moodBoards[0].boardName, "Modern Wedding")
    }

    func testLoadMoodBoards_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadMoodBoards()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.moodBoards.count, 0)
    }

    func testLoadMoodBoards_Empty() async throws {
        // Given
        mockRepository.moodBoards = []

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadMoodBoards()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.moodBoards.count, 0)
    }

    func testLoadColorPalettes_Success() async throws {
        // Given
        let testPalettes = [
            ColorPalette.makeTest(id: UUID(), name: "Spring Colors"),
            ColorPalette.makeTest(id: UUID(), name: "Autumn Tones")
        ]
        mockRepository.colorPalettes = testPalettes

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadColorPalettes()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.colorPalettes.count, 2)
    }

    func testLoadColorPalettes_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadColorPalettes()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    func testLoadSeatingCharts_Success() async throws {
        // Given
        let testCharts = [
            SeatingChart.makeTest(id: UUID(), tenantId: tenantId, chartName: "Main Reception"),
            SeatingChart.makeTest(id: UUID(), tenantId: tenantId, chartName: "Ceremony")
        ]
        mockRepository.seatingCharts = testCharts

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadSeatingCharts()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.seatingCharts.count, 2)
    }

    func testLoadSeatingCharts_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadSeatingCharts()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Create Tests

    func testCreateMoodBoard_OptimisticUpdate() async throws {
        // Given
        let existingBoard = MoodBoard.makeTest(tenantId: tenantId, boardName: "Existing Board")
        mockRepository.moodBoards = [existingBoard]

        let newBoard = MoodBoard.makeTest(tenantId: tenantId, boardName: "New Board")

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadMoodBoards()
        await store.createMoodBoard(newBoard)

        // Then
        XCTAssertEqual(store.moodBoards.count, 2)
    }

    func testUpdateMoodBoard_Success() async throws {
        // Given
        let board = MoodBoard.makeTest(id: UUID(), tenantId: tenantId, boardName: "Original Name")
        mockRepository.moodBoards = [board]

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadMoodBoards()

        var updatedBoard = board
        updatedBoard.boardName = "Updated Name"
        await store.updateMoodBoard(updatedBoard)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.moodBoards.first?.boardName, "Updated Name")
    }

    func testUpdateMoodBoard_Failure_RollsBack() async throws {
        // Given
        let board = MoodBoard.makeTest(id: UUID(), tenantId: tenantId, boardName: "Original Name")
        mockRepository.moodBoards = [board]

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadMoodBoards()

        var updatedBoard = board
        updatedBoard.boardName = "Updated Name"

        mockRepository.shouldThrowError = true
        await store.updateMoodBoard(updatedBoard)

        // Then - Should rollback to original
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.moodBoards.first?.boardName, "Original Name")
    }

    // MARK: - Delete Tests

    func testDeleteMoodBoard_Success() async throws {
        // Given
        let board1 = MoodBoard.makeTest(id: UUID(), tenantId: tenantId, boardName: "Board 1")
        let board2 = MoodBoard.makeTest(id: UUID(), tenantId: tenantId, boardName: "Board 2")
        mockRepository.moodBoards = [board1, board2]

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadMoodBoards()
        await store.deleteMoodBoard(board1)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.moodBoards.count, 1)
        XCTAssertEqual(store.moodBoards.first?.boardName, "Board 2")
    }

    func testDeleteMoodBoard_Failure_RollsBack() async throws {
        // Given
        let board = MoodBoard.makeTest(id: UUID(), tenantId: tenantId, boardName: "Board")
        mockRepository.moodBoards = [board]

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadMoodBoards()

        mockRepository.shouldThrowError = true
        await store.deleteMoodBoard(board)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.moodBoards.count, 1)
    }

    func testCreateColorPalette() async throws {
        // Given
        let newPalette = ColorPalette.makeTest(name: "New Palette")

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.createColorPalette(newPalette)

        // Then
        XCTAssertEqual(store.colorPalettes.count, 1)
    }

    func testCreateSeatingChart() async throws {
        // Given
        let newChart = SeatingChart.makeTest(tenantId: tenantId, chartName: "New Chart")

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.createSeatingChart(newChart)

        // Then
        XCTAssertEqual(store.seatingCharts.count, 1)
    }

    // MARK: - Computed Properties Tests

    func testComputedProperty_TotalMoodBoards() async throws {
        // Given
        let boards = [
            MoodBoard.makeTest(tenantId: tenantId),
            MoodBoard.makeTest(tenantId: tenantId),
            MoodBoard.makeTest(tenantId: tenantId)
        ]
        mockRepository.moodBoards = boards

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadMoodBoards()

        // Then
        XCTAssertEqual(store.moodBoards.count, 3)
    }

    func testComputedProperty_TotalPalettes() async throws {
        // Given
        let palettes = [
            ColorPalette.makeTest(),
            ColorPalette.makeTest(),
            ColorPalette.makeTest()
        ]
        mockRepository.colorPalettes = palettes

        // When
        let store = await withDependencies {
            $0.visualPlanningRepository = mockRepository
        } operation: {
            VisualPlanningStoreV2()
        }

        await store.loadColorPalettes()

        // Then
        XCTAssertEqual(store.colorPalettes.count, 3)
    }
}
