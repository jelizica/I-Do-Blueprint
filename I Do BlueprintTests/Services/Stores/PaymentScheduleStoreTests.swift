//
//  PaymentScheduleStoreTests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for PaymentScheduleStore
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class PaymentScheduleStoreTests: XCTestCase {
    var mockRepository: MockBudgetRepository!
    var coupleId: UUID!
    var store: PaymentScheduleStore!

    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
        coupleId = UUID()
        
        // Initialize store with mock repository
        store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            PaymentScheduleStore()
        }
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
        store = nil
    }

    // MARK: - Load Tests

    func testLoadPaymentSchedules_Success() async throws {
        // Given
        let payment1 = PaymentSchedule.makeTest(
            id: 1,
            coupleId: coupleId,
            vendor: "Venue",
            paymentAmount: 5000,
            paid: false
        )
        let payment2 = PaymentSchedule.makeTest(
            id: 2,
            coupleId: coupleId,
            vendor: "Catering",
            paymentAmount: 3000,
            paid: true
        )
        mockRepository.paymentSchedules = [payment1, payment2]

        // When
        await store.loadPaymentSchedules()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.paymentSchedules.count, 2)
    }

    func testLoadPaymentSchedules_Empty() async throws {
        // Given
        mockRepository.paymentSchedules = []

        // When
        await store.loadPaymentSchedules()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.paymentSchedules.count, 0)
    }

    func testLoadPaymentSchedules_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        await store.loadPaymentSchedules()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Create Tests

    func testAddPayment_Success() async throws {
        // Given
        let newPayment = PaymentSchedule.makeTest(
            coupleId: coupleId,
            vendor: "Photographer",
            paymentAmount: 2000,
            paid: false
        )

        // When
        await store.addPayment(newPayment)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.paymentSchedules.count, 1)
        XCTAssertEqual(store.paymentSchedules[0].vendor, "Photographer")
    }

    func testAddPayment_OptimisticUpdate() async throws {
        // Given
        let existingPayment = PaymentSchedule.makeTest(
            id: 1,
            coupleId: coupleId,
            vendor: "Venue",
            paymentAmount: 5000,
            paid: false
        )
        mockRepository.paymentSchedules = [existingPayment]
        await store.loadPaymentSchedules()

        let newPayment = PaymentSchedule.makeTest(
            coupleId: coupleId,
            vendor: "Catering",
            paymentAmount: 3000,
            paid: false
        )

        // When
        await store.addPayment(newPayment)

        // Then - Optimistic update should show immediately
        XCTAssertEqual(store.paymentSchedules.count, 2)
        XCTAssertTrue(store.paymentSchedules.contains(where: { $0.vendor == "Catering" }))
    }

    // MARK: - Update Tests

    func testUpdatePayment_Success() async throws {
        // Given
        let payment = PaymentSchedule.makeTest(
            id: 1,
            coupleId: coupleId,
            vendor: "Venue",
            paymentAmount: 5000,
            paid: false
        )
        mockRepository.paymentSchedules = [payment]
        await store.loadPaymentSchedules()

        // When
        var updatedPayment = payment
        updatedPayment = PaymentSchedule.makeTest(
            id: payment.id,
            coupleId: payment.coupleId,
            vendor: payment.vendor,
            paymentAmount: 6000,
            paid: false
        )
        await store.updatePayment(updatedPayment)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.paymentSchedules.first?.paymentAmount, 6000)
    }

    func testUpdatePayment_Failure_RollsBack() async throws {
        // Given
        let payment = PaymentSchedule.makeTest(
            id: 1,
            coupleId: coupleId,
            vendor: "Venue",
            paymentAmount: 5000,
            paid: false
        )
        mockRepository.paymentSchedules = [payment]
        await store.loadPaymentSchedules()

        // When
        var updatedPayment = payment
        updatedPayment = PaymentSchedule.makeTest(
            id: payment.id,
            coupleId: payment.coupleId,
            vendor: payment.vendor,
            paymentAmount: 6000,
            paid: false
        )

        mockRepository.shouldThrowError = true
        await store.updatePayment(updatedPayment)

        // Then - Should rollback to original
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.paymentSchedules.first?.paymentAmount, 5000)
    }

    // MARK: - Delete Tests

    func testDeletePayment_Success() async throws {
        // Given
        let payment1 = PaymentSchedule.makeTest(
            id: 1,
            coupleId: coupleId,
            vendor: "Venue",
            paymentAmount: 5000,
            paid: false
        )
        let payment2 = PaymentSchedule.makeTest(
            id: 2,
            coupleId: coupleId,
            vendor: "Catering",
            paymentAmount: 3000,
            paid: false
        )
        mockRepository.paymentSchedules = [payment1, payment2]
        await store.loadPaymentSchedules()

        // When
        await store.deletePayment(payment1)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.paymentSchedules.count, 1)
        XCTAssertEqual(store.paymentSchedules.first?.vendor, "Catering")
    }

    func testDeletePayment_ById_Success() async throws {
        // Given
        let payment = PaymentSchedule.makeTest(
            id: 1,
            coupleId: coupleId,
            vendor: "Venue",
            paymentAmount: 5000,
            paid: false
        )
        mockRepository.paymentSchedules = [payment]
        await store.loadPaymentSchedules()

        // When
        await store.deletePayment(id: 1)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.paymentSchedules.count, 0)
    }

    func testDeletePayment_Failure_RollsBack() async throws {
        // Given
        let payment = PaymentSchedule.makeTest(
            id: 1,
            coupleId: coupleId,
            vendor: "Venue",
            paymentAmount: 5000,
            paid: false
        )
        mockRepository.paymentSchedules = [payment]
        await store.loadPaymentSchedules()

        // When
        mockRepository.shouldThrowError = true
        await store.deletePayment(payment)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.paymentSchedules.count, 1)
    }

    // MARK: - Computed Properties Tests

    func testPendingPayments_FiltersCorrectly() async throws {
        // Given
        let payments = [
            PaymentSchedule.makeTest(
                id: 1,
                coupleId: coupleId,
                vendor: "Venue",
                paymentAmount: 5000,
                paid: false
            ),
            PaymentSchedule.makeTest(
                id: 2,
                coupleId: coupleId,
                vendor: "Catering",
                paymentAmount: 3000,
                paid: true
            ),
            PaymentSchedule.makeTest(
                id: 3,
                coupleId: coupleId,
                vendor: "Photographer",
                paymentAmount: 2000,
                paid: false
            )
        ]
        mockRepository.paymentSchedules = payments
        await store.loadPaymentSchedules()

        // Then
        XCTAssertEqual(store.pendingPayments.count, 2)
        XCTAssertTrue(store.pendingPayments.allSatisfy { $0.paymentStatus == .pending })
    }

    func testPaidPayments_FiltersCorrectly() async throws {
        // Given
        let payments = [
            PaymentSchedule.makeTest(
                id: 1,
                coupleId: coupleId,
                vendor: "Venue",
                paymentAmount: 5000,
                paid: false
            ),
            PaymentSchedule.makeTest(
                id: 2,
                coupleId: coupleId,
                vendor: "Catering",
                paymentAmount: 3000,
                paid: true
            )
        ]
        mockRepository.paymentSchedules = payments
        await store.loadPaymentSchedules()

        // Then
        XCTAssertEqual(store.paidPayments.count, 1)
        XCTAssertTrue(store.paidPayments.allSatisfy { $0.paymentStatus == .paid })
    }

    func testTotalPending_Calculation() async throws {
        // Given
        let payments = [
            PaymentSchedule.makeTest(
                id: 1,
                coupleId: coupleId,
                vendor: "Venue",
                paymentAmount: 5000,
                paid: false
            ),
            PaymentSchedule.makeTest(
                id: 2,
                coupleId: coupleId,
                vendor: "Photographer",
                paymentAmount: 2000,
                paid: false
            ),
            PaymentSchedule.makeTest(
                id: 3,
                coupleId: coupleId,
                vendor: "Catering",
                paymentAmount: 3000,
                paid: true
            )
        ]
        mockRepository.paymentSchedules = payments
        await store.loadPaymentSchedules()

        // Then
        XCTAssertEqual(store.totalPending, 7000) // 5000 + 2000
    }

    func testTotalPaid_Calculation() async throws {
        // Given
        let payments = [
            PaymentSchedule.makeTest(
                id: 1,
                coupleId: coupleId,
                vendor: "Venue",
                paymentAmount: 5000,
                paid: true
            ),
            PaymentSchedule.makeTest(
                id: 2,
                coupleId: coupleId,
                vendor: "Catering",
                paymentAmount: 3000,
                paid: true
            ),
            PaymentSchedule.makeTest(
                id: 3,
                coupleId: coupleId,
                vendor: "Photographer",
                paymentAmount: 2000,
                paid: false
            )
        ]
        mockRepository.paymentSchedules = payments
        await store.loadPaymentSchedules()

        // Then
        XCTAssertEqual(store.totalPaid, 8000) // 5000 + 3000
    }

    func testTotalAmount_Calculation() async throws {
        // Given
        let payments = [
            PaymentSchedule.makeTest(
                id: 1,
                coupleId: coupleId,
                vendor: "Venue",
                paymentAmount: 5000,
                paid: false
            ),
            PaymentSchedule.makeTest(
                id: 2,
                coupleId: coupleId,
                vendor: "Catering",
                paymentAmount: 3000,
                paid: true
            )
        ]
        mockRepository.paymentSchedules = payments
        await store.loadPaymentSchedules()

        // Then
        XCTAssertEqual(store.totalAmount, 8000) // 5000 + 3000
    }

    func testUpcomingPayments_FiltersCorrectly() async throws {
        // Given
        let today = Date()
        let in5Days = Calendar.current.date(byAdding: .day, value: 5, to: today)!
        let in20Days = Calendar.current.date(byAdding: .day, value: 20, to: today)!
        let in40Days = Calendar.current.date(byAdding: .day, value: 40, to: today)!

        let payments = [
            PaymentSchedule.makeTest(
                id: 1,
                coupleId: coupleId,
                vendor: "Venue",
                paymentDate: in5Days,
                paymentAmount: 5000,
                paid: false
            ),
            PaymentSchedule.makeTest(
                id: 2,
                coupleId: coupleId,
                vendor: "Catering",
                paymentDate: in20Days,
                paymentAmount: 3000,
                paid: false
            ),
            PaymentSchedule.makeTest(
                id: 3,
                coupleId: coupleId,
                vendor: "Photographer",
                paymentDate: in40Days,
                paymentAmount: 2000,
                paid: false
            )
        ]
        mockRepository.paymentSchedules = payments
        await store.loadPaymentSchedules()

        // Then - Should only include payments due within 30 days
        XCTAssertEqual(store.upcomingPayments.count, 2)
        XCTAssertTrue(store.upcomingPayments.contains(where: { $0.vendor == "Venue" }))
        XCTAssertTrue(store.upcomingPayments.contains(where: { $0.vendor == "Catering" }))
        XCTAssertFalse(store.upcomingPayments.contains(where: { $0.vendor == "Photographer" }))
    }

    // MARK: - Convenience Method Tests

    func testMarkAsPaid_Success() async throws {
        // Given
        let payment = PaymentSchedule.makeTest(
            id: 1,
            coupleId: coupleId,
            vendor: "Venue",
            paymentAmount: 5000,
            paid: false
        )
        mockRepository.paymentSchedules = [payment]
        await store.loadPaymentSchedules()

        // When
        await store.markAsPaid(payment)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.paymentSchedules.first?.paymentStatus, .paid)
        XCTAssertTrue(store.paymentSchedules.first?.paid ?? false)
    }

    func testTogglePaidStatus_Success() async throws {
        // Given
        let payment = PaymentSchedule.makeTest(
            id: 1,
            coupleId: coupleId,
            vendor: "Venue",
            paymentAmount: 5000,
            paid: false
        )
        mockRepository.paymentSchedules = [payment]
        await store.loadPaymentSchedules()

        // When - Toggle to paid
        await store.togglePaidStatus(payment)

        // Then
        XCTAssertEqual(store.paymentSchedules.first?.paymentStatus, .paid)

        // When - Toggle back to pending
        if let updatedPayment = store.paymentSchedules.first {
            await store.togglePaidStatus(updatedPayment)
        }

        // Then
        XCTAssertEqual(store.paymentSchedules.first?.paymentStatus, .pending)
    }
}
