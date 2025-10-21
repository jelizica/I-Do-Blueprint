//
//  AffordabilityStoreTests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for AffordabilityStore
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class AffordabilityStoreTests: XCTestCase {
    var mockRepository: MockBudgetRepository!
    var coupleId: UUID!
    var store: AffordabilityStore!

    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
        coupleId = UUID()
        
        // Initialize store with mock repository and payment schedules provider
        store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            AffordabilityStore(paymentSchedulesProvider: { [] })
        }
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
        store = nil
    }

    // MARK: - Scenario Tests

    func testLoadScenarios_Success() async throws {
        // Given
        let scenario1 = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Primary",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: Date(),
            isPrimary: true,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        let scenario2 = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Conservative",
            partner1Monthly: 1500,
            partner2Monthly: 1000,
            calculationStartDate: Date(),
            isPrimary: false,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [scenario1, scenario2]

        // When
        await store.loadScenarios()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.scenarios.count, 2)
        XCTAssertEqual(store.scenarios[0].scenarioName, "Primary")
        XCTAssertEqual(store.selectedScenarioId, scenario1.id) // Should auto-select primary
    }

    func testLoadScenarios_Empty() async throws {
        // Given
        mockRepository.affordabilityScenarios = []

        // When
        await store.loadScenarios()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.scenarios.count, 0)
        XCTAssertNil(store.selectedScenarioId)
    }

    func testLoadScenarios_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        await store.loadScenarios()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    func testSaveScenario_Success() async throws {
        // Given
        let newScenario = AffordabilityScenario(
            scenarioName: "Optimistic",
            partner1Monthly: 3000,
            partner2Monthly: 2500,
            calculationStartDate: Date(),
            isPrimary: false,
            coupleId: coupleId
        )

        // When
        await store.saveScenario(newScenario)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.scenarios.count, 1)
        XCTAssertEqual(store.scenarios[0].scenarioName, "Optimistic")
    }

    func testDeleteScenario_Success() async throws {
        // Given
        let scenario = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Test",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: Date(),
            isPrimary: false,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [scenario]
        await store.loadScenarios()

        // When
        await store.deleteScenario(id: scenario.id)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.scenarios.count, 0)
    }

    func testSelectScenario_UpdatesState() async throws {
        // Given
        let scenario = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Test",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: Date(),
            isPrimary: true,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [scenario]
        await store.loadScenarios()

        // When
        store.selectScenario(scenario)

        // Then
        XCTAssertEqual(store.selectedScenarioId, scenario.id)
        XCTAssertEqual(store.editedPartner1Monthly, 2000)
        XCTAssertEqual(store.editedPartner2Monthly, 1500)
    }

    // MARK: - Contribution Tests

    func testLoadContributions_Success() async throws {
        // Given
        let scenarioId = UUID()
        let contribution1 = ContributionItem(
            id: UUID(),
            scenarioId: scenarioId,
            contributorName: "Parents",
            amount: 5000,
            contributionDate: Date(),
            contributionType: .external,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        let contribution2 = ContributionItem(
            id: UUID(),
            scenarioId: scenarioId,
            contributorName: "Gift",
            amount: 1000,
            contributionDate: Date(),
            contributionType: .gift,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityContributions = [contribution1, contribution2]

        // When
        await store.loadContributions(scenarioId: scenarioId)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.contributions.count, 2)
    }

    func testSaveContribution_Success() async throws {
        // Given
        let scenarioId = UUID()
        let contribution = ContributionItem(
            scenarioId: scenarioId,
            contributorName: "Parents",
            amount: 5000,
            contributionDate: Date(),
            contributionType: .external,
            coupleId: coupleId
        )

        // When
        await store.saveContribution(contribution)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.contributions.count, 1)
    }

    func testDeleteContribution_Success() async throws {
        // Given
        let scenarioId = UUID()
        let contribution = ContributionItem(
            id: UUID(),
            scenarioId: scenarioId,
            contributorName: "Parents",
            amount: 5000,
            contributionDate: Date(),
            contributionType: .external,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityContributions = [contribution]
        await store.loadContributions(scenarioId: scenarioId)

        // When
        await store.deleteContribution(id: contribution.id, scenarioId: scenarioId)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.contributions.count, 0)
    }

    // MARK: - Computed Properties Tests

    func testTotalContributions_Calculation() async throws {
        // Given
        let scenarioId = UUID()
        let contributions = [
            ContributionItem(
                scenarioId: scenarioId,
                contributorName: "Parents",
                amount: 5000,
                contributionDate: Date(),
                contributionType: .external,
                coupleId: coupleId
            ),
            ContributionItem(
                scenarioId: scenarioId,
                contributorName: "Gift",
                amount: 1000,
                contributionDate: Date(),
                contributionType: .gift,
                coupleId: coupleId
            )
        ]
        mockRepository.affordabilityContributions = contributions
        await store.loadContributions(scenarioId: scenarioId)

        // Then
        XCTAssertEqual(store.totalContributions, 6000)
    }

    func testTotalGifts_Calculation() async throws {
        // Given
        let scenarioId = UUID()
        let contributions = [
            ContributionItem(
                scenarioId: scenarioId,
                contributorName: "Gift 1",
                amount: 1000,
                contributionDate: Date(),
                contributionType: .gift,
                coupleId: coupleId
            ),
            ContributionItem(
                scenarioId: scenarioId,
                contributorName: "Parents",
                amount: 5000,
                contributionDate: Date(),
                contributionType: .external,
                coupleId: coupleId
            ),
            ContributionItem(
                scenarioId: scenarioId,
                contributorName: "Gift 2",
                amount: 500,
                contributionDate: Date(),
                contributionType: .gift,
                coupleId: coupleId
            )
        ]
        mockRepository.affordabilityContributions = contributions
        await store.loadContributions(scenarioId: scenarioId)

        // Then
        XCTAssertEqual(store.totalGifts, 1500)
    }

    func testTotalExternal_Calculation() async throws {
        // Given
        let scenarioId = UUID()
        let contributions = [
            ContributionItem(
                scenarioId: scenarioId,
                contributorName: "Parents",
                amount: 5000,
                contributionDate: Date(),
                contributionType: .external,
                coupleId: coupleId
            ),
            ContributionItem(
                scenarioId: scenarioId,
                contributorName: "Gift",
                amount: 1000,
                contributionDate: Date(),
                contributionType: .gift,
                coupleId: coupleId
            )
        ]
        mockRepository.affordabilityContributions = contributions
        await store.loadContributions(scenarioId: scenarioId)

        // Then
        XCTAssertEqual(store.totalExternal, 5000)
    }

    func testTotalSaved_Calculation() async throws {
        // Given
        let startDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        let scenario = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Test",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: startDate,
            isPrimary: true,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [scenario]
        await store.loadScenarios()

        // Then - Should calculate 6 months of savings
        XCTAssertEqual(store.totalSaved, 21000) // (2000 + 1500) * 6
    }

    func testProjectedSavings_Calculation() async throws {
        // Given
        let weddingDate = Calendar.current.date(byAdding: .month, value: 12, to: Date())!
        let scenario = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Test",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: Date(),
            isPrimary: true,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [scenario]
        await store.loadScenarios()
        store.editedWeddingDate = weddingDate

        // Then - Should calculate 12 months of future savings
        XCTAssertEqual(store.projectedSavings, 42000) // (2000 + 1500) * 12
    }

    func testHasUnsavedChanges_DetectsChanges() async throws {
        // Given
        let scenario = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Test",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: Date(),
            isPrimary: true,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [scenario]
        await store.loadScenarios()

        // When - No changes
        XCTAssertFalse(store.hasUnsavedChanges)

        // When - Change partner 1 monthly
        store.editedPartner1Monthly = 2500
        XCTAssertTrue(store.hasUnsavedChanges)
    }

    // MARK: - Gift Linking Tests

    func testLoadAvailableGifts_Success() async throws {
        // Given
        let gift1 = GiftOrOwed.makeTest(
            coupleId: coupleId,
            title: "John Doe Gift",
            amount: 500,
            status: .pending,
            scenarioId: nil
        )
        let gift2 = GiftOrOwed.makeTest(
            coupleId: coupleId,
            title: "Jane Smith Gift",
            amount: 1000,
            status: .confirmed,
            scenarioId: nil
        )
        mockRepository.giftsAndOwed = [gift1, gift2]

        // When
        await store.loadAvailableGifts()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.availableGifts.count, 2)
    }

    func testLinkGiftsToScenario_Success() async throws {
        // Given
        let scenarioId = UUID()
        let giftIds = [UUID(), UUID()]

        // When
        await store.linkGiftsToScenario(giftIds: giftIds, scenarioId: scenarioId)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testUnlinkGiftFromScenario_Success() async throws {
        // Given
        let scenarioId = UUID()
        let giftId = UUID()

        // When
        await store.unlinkGiftFromScenario(giftId: giftId, scenarioId: scenarioId)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    // MARK: - Helper Method Tests

    func testSetWeddingDate_ParsesDateCorrectly() async throws {
        // Given
        let dateString = "2025-06-15"

        // When
        store.setWeddingDate(dateString)

        // Then
        XCTAssertNotNil(store.editedWeddingDate)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: store.editedWeddingDate!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
    }

    func testResetEditingState_RestoresScenarioValues() async throws {
        // Given
        let scenario = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Test",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: Date(),
            isPrimary: true,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [scenario]
        await store.loadScenarios()

        // Modify values
        store.editedPartner1Monthly = 3000
        store.editedPartner2Monthly = 2500

        // When
        store.resetEditingState()

        // Then
        XCTAssertEqual(store.editedPartner1Monthly, 2000)
        XCTAssertEqual(store.editedPartner2Monthly, 1500)
    }

    func testCreateScenario_Success() async throws {
        // Given
        let existingScenario = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Primary",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: Date(),
            isPrimary: true,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [existingScenario]
        await store.loadScenarios()

        // When
        await store.createScenario(name: "Conservative")

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.scenarios.count, 2)
        XCTAssertTrue(store.scenarios.contains(where: { $0.scenarioName == "Conservative" }))
    }

    func testDeleteScenario_CannotDeletePrimary() async throws {
        // Given
        let primaryScenario = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Primary",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: Date(),
            isPrimary: true,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [primaryScenario]
        await store.loadScenarios()

        // When
        await store.deleteScenario(primaryScenario)

        // Then
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.scenarios.count, 1) // Should not be deleted
    }

    func testAddContribution_Success() async throws {
        // Given
        let scenario = AffordabilityScenario(
            id: UUID(),
            scenarioName: "Test",
            partner1Monthly: 2000,
            partner2Monthly: 1500,
            calculationStartDate: Date(),
            isPrimary: true,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.affordabilityScenarios = [scenario]
        await store.loadScenarios()

        // When
        await store.addContribution(name: "Parents", amount: 5000, type: .external, date: Date())

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.contributions.count, 1)
        XCTAssertEqual(store.contributions[0].contributorName, "Parents")
        XCTAssertEqual(store.contributions[0].amount, 5000)
    }
}
