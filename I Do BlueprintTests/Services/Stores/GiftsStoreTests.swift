//
//  GiftsStoreTests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for GiftsStore
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class GiftsStoreTests: XCTestCase {
    var mockRepository: MockBudgetRepository!
    var coupleId: UUID!
    var store: GiftsStore!

    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
        coupleId = UUID()
        
        // Initialize store with mock repository
        store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            GiftsStore()
        }
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
        store = nil
    }

    // MARK: - Load Tests

    func testLoadGiftsData_Success() async throws {
        // Given
        let gift1 = GiftOrOwed.makeTest(
            coupleId: coupleId,
            title: "John Doe Gift",
            amount: 500,
            status: .pending
        )
        let gift2 = GiftOrOwed.makeTest(
            coupleId: coupleId,
            title: "Jane Smith Gift",
            amount: 1000,
            status: .confirmed
        )
        mockRepository.giftsAndOwed = [gift1, gift2]

        // When
        await store.loadGiftsData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.giftsAndOwed.count, 2)
    }

    func testLoadGiftsData_Empty() async throws {
        // Given
        mockRepository.giftsAndOwed = []

        // When
        await store.loadGiftsData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.giftsAndOwed.count, 0)
    }

    func testLoadGiftsData_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        await store.loadGiftsData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Gifts And Owed Tests

    func testAddGiftOrOwed_Success() async throws {
        // Given
        let newGift = GiftOrOwed.makeTest(
            coupleId: coupleId,
            title: "Bob Johnson Gift",
            amount: 750,
            status: .pending
        )

        // When
        await store.addGiftOrOwed(newGift)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.giftsAndOwed.count, 1)
        XCTAssertEqual(store.giftsAndOwed[0].title, "Bob Johnson Gift")
    }

    func testUpdateGiftOrOwed_Success() async throws {
        // Given
        let gift = GiftOrOwed.makeTest(
            id: UUID(),
            coupleId: coupleId,
            title: "John Doe Gift",
            amount: 500,
            status: .pending
        )
        mockRepository.giftsAndOwed = [gift]
        await store.loadGiftsData()

        // When
        var updatedGift = gift
        updatedGift = GiftOrOwed.makeTest(
            id: gift.id,
            coupleId: gift.coupleId,
            title: gift.title,
            amount: 750,
            status: .confirmed
        )
        await store.updateGiftOrOwed(updatedGift)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.giftsAndOwed.first?.amount, 750)
        XCTAssertEqual(store.giftsAndOwed.first?.status, .confirmed)
    }

    func testDeleteGiftOrOwed_Success() async throws {
        // Given
        let gift1 = GiftOrOwed.makeTest(
            id: UUID(),
            coupleId: coupleId,
            title: "John Doe Gift",
            amount: 500,
            status: .pending
        )
        let gift2 = GiftOrOwed.makeTest(
            id: UUID(),
            coupleId: coupleId,
            title: "Jane Smith Gift",
            amount: 1000,
            status: .confirmed
        )
        mockRepository.giftsAndOwed = [gift1, gift2]
        await store.loadGiftsData()

        // When
        await store.deleteGiftOrOwed(id: gift1.id)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.giftsAndOwed.count, 1)
        XCTAssertEqual(store.giftsAndOwed.first?.title, "Jane Smith Gift")
    }

    // MARK: - Gifts Received Tests

    func testAddGiftReceived_Success() async throws {
        // Given
        let newGift = GiftReceived.makeTest(
            fromPerson: "Alice Brown",
            amount: 600
        )

        // When
        await store.addGiftReceived(newGift)

        // Then
        XCTAssertEqual(store.giftsReceived.count, 1)
        XCTAssertEqual(store.giftsReceived[0].fromPerson, "Alice Brown")
    }

    func testUpdateGiftReceived_Success() async throws {
        // Given
        let gift = GiftReceived.makeTest(
            id: UUID(),
            fromPerson: "Alice Brown",
            amount: 600
        )
        await store.addGiftReceived(gift)

        // When
        var updatedGift = gift
        updatedGift = GiftReceived.makeTest(
            id: gift.id,
            fromPerson: gift.fromPerson,
            amount: 800
        )
        await store.updateGiftReceived(updatedGift)

        // Then
        XCTAssertEqual(store.giftsReceived.first?.amount, 800)
    }

    func testDeleteGiftReceived_Success() async throws {
        // Given
        let gift = GiftReceived.makeTest(
            id: UUID(),
            fromPerson: "Alice Brown",
            amount: 600
        )
        await store.addGiftReceived(gift)

        // When
        await store.deleteGiftReceived(id: gift.id)

        // Then
        XCTAssertEqual(store.giftsReceived.count, 0)
    }

    // MARK: - Money Owed Tests

    func testAddMoneyOwed_Success() async throws {
        // Given
        let newMoney = MoneyOwed.makeTest(
            toPerson: "Charlie Davis",
            amount: 300,
            reason: "Deposit"
        )

        // When
        await store.addMoneyOwed(newMoney)

        // Then
        XCTAssertEqual(store.moneyOwed.count, 1)
        XCTAssertEqual(store.moneyOwed[0].toPerson, "Charlie Davis")
    }

    func testUpdateMoneyOwed_Success() async throws {
        // Given
        let money = MoneyOwed.makeTest(
            id: UUID(),
            toPerson: "Charlie Davis",
            amount: 300,
            reason: "Deposit"
        )
        await store.addMoneyOwed(money)

        // When
        var updatedMoney = money
        updatedMoney = MoneyOwed.makeTest(
            id: money.id,
            toPerson: money.toPerson,
            amount: 400,
            reason: money.reason
        )
        await store.updateMoneyOwed(updatedMoney)

        // Then
        XCTAssertEqual(store.moneyOwed.first?.amount, 400)
    }

    func testDeleteMoneyOwed_Success() async throws {
        // Given
        let money = MoneyOwed.makeTest(
            id: UUID(),
            toPerson: "Charlie Davis",
            amount: 300,
            reason: "Deposit"
        )
        await store.addMoneyOwed(money)

        // When
        await store.deleteMoneyOwed(id: money.id)

        // Then
        XCTAssertEqual(store.moneyOwed.count, 0)
    }

    // MARK: - Computed Properties Tests

    func testTotalPending_Calculation() async throws {
        // Given
        let gifts = [
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "John Doe Gift",
                amount: 500,
                status: .pending
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Jane Smith Gift",
                amount: 1000,
                status: .confirmed
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Bob Johnson Gift",
                amount: 750,
                status: .pending
            )
        ]
        mockRepository.giftsAndOwed = gifts
        await store.loadGiftsData()

        // Then
        // totalPending sums ALL giftsAndOwed regardless of status
        XCTAssertEqual(store.totalPending, 2250) // 500 + 1000 + 750
    }

    func testTotalReceived_Calculation() async throws {
        // Given
        let gift1 = GiftReceived.makeTest(
            fromPerson: "Alice Brown",
            amount: 600
        )
        let gift2 = GiftReceived.makeTest(
            fromPerson: "Charlie Davis",
            amount: 400
        )
        await store.addGiftReceived(gift1)
        await store.addGiftReceived(gift2)

        // Then
        XCTAssertEqual(store.totalReceived, 1000) // 600 + 400
    }

    func testTotalConfirmed_Calculation() async throws {
        // Given
        let gifts = [
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "John Doe Gift",
                amount: 500,
                status: .pending
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Jane Smith Gift",
                amount: 1000,
                status: .confirmed
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Bob Johnson Gift",
                amount: 750,
                status: .confirmed
            )
        ]
        mockRepository.giftsAndOwed = gifts
        await store.loadGiftsData()

        // Then
        XCTAssertEqual(store.totalConfirmed, 1750) // 1000 + 750
    }

    func testTotalBudgetAddition_Calculation() async throws {
        // Given
        let gifts = [
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "John Doe Gift",
                amount: 500,
                status: .pending
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Jane Smith Gift",
                amount: 1000,
                status: .confirmed
            )
        ]
        let giftReceived = GiftReceived.makeTest(
            fromPerson: "Alice Brown",
            amount: 600
        )
        mockRepository.giftsAndOwed = gifts
        await store.loadGiftsData()
        await store.addGiftReceived(giftReceived)

        // Then
        // totalBudgetAddition = totalReceived + totalConfirmed
        // = 600 + 1000 = 1600
        XCTAssertEqual(store.totalBudgetAddition, 1600)
    }

    func testPendingGifts_FiltersCorrectly() async throws {
        // Given
        let gifts = [
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "John Doe Gift",
                amount: 500,
                status: .pending
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Jane Smith Gift",
                amount: 1000,
                status: .confirmed
            )
        ]
        mockRepository.giftsAndOwed = gifts
        await store.loadGiftsData()

        // Then
        XCTAssertEqual(store.pendingGifts.count, 1)
        XCTAssertEqual(store.pendingGifts.first?.title, "John Doe Gift")
    }

    func testConfirmedGifts_FiltersCorrectly() async throws {
        // Given
        let gifts = [
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "John Doe Gift",
                amount: 500,
                status: .pending
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Jane Smith Gift",
                amount: 1000,
                status: .confirmed
            )
        ]
        mockRepository.giftsAndOwed = gifts
        await store.loadGiftsData()

        // Then
        XCTAssertEqual(store.confirmedGifts.count, 1)
        XCTAssertEqual(store.confirmedGifts.first?.title, "Jane Smith Gift")
    }

    func testUnlinkedGifts_FiltersCorrectly() async throws {
        // Given
        let scenarioId = UUID()
        let gifts = [
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "John Doe Gift",
                amount: 500,
                status: .pending,
                scenarioId: nil // Unlinked
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Jane Smith Gift",
                amount: 1000,
                status: .confirmed,
                scenarioId: scenarioId // Linked
            )
        ]
        mockRepository.giftsAndOwed = gifts
        await store.loadGiftsData()

        // Then
        XCTAssertEqual(store.unlinkedGifts.count, 1)
        XCTAssertEqual(store.unlinkedGifts.first?.title, "John Doe Gift")
    }

    // MARK: - Helper Method Tests

    func testGiftsLinkedToScenario_FiltersCorrectly() async throws {
        // Given
        let scenarioId = UUID()
        let gifts = [
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "John Doe Gift",
                amount: 500,
                status: .pending,
                scenarioId: scenarioId
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Jane Smith Gift",
                amount: 1000,
                status: .confirmed,
                scenarioId: nil
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Bob Johnson Gift",
                amount: 750,
                status: .pending,
                scenarioId: scenarioId
            )
        ]
        mockRepository.giftsAndOwed = gifts
        await store.loadGiftsData()

        // When
        let linkedGifts = store.giftsLinkedToScenario(scenarioId)

        // Then
        XCTAssertEqual(linkedGifts.count, 2)
        XCTAssertTrue(linkedGifts.contains(where: { $0.title == "John Doe Gift" }))
        XCTAssertTrue(linkedGifts.contains(where: { $0.title == "Bob Johnson Gift" }))
    }

    func testTotalGiftsForScenario_Calculation() async throws {
        // Given
        let scenarioId = UUID()
        let gifts = [
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "John Doe Gift",
                amount: 500,
                status: .pending,
                scenarioId: scenarioId
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Jane Smith Gift",
                amount: 1000,
                status: .confirmed,
                scenarioId: nil
            ),
            GiftOrOwed.makeTest(
                coupleId: coupleId,
                title: "Bob Johnson Gift",
                amount: 750,
                status: .pending,
                scenarioId: scenarioId
            )
        ]
        mockRepository.giftsAndOwed = gifts
        await store.loadGiftsData()

        // When
        let total = store.totalGiftsForScenario(scenarioId)

        // Then
        XCTAssertEqual(total, 1250) // 500 + 750
    }
}
