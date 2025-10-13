//
//  VendorStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for VendorStoreV2
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class VendorStoreV2Tests: XCTestCase {
    var store: VendorStoreV2!
    var mockRepository: MockVendorRepository!

    override func setUp() async throws {
        mockRepository = MockVendorRepository()
        store = withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }
    }

    override func tearDown() async throws {
        store = nil
        mockRepository = nil
    }

    // MARK: - Load Vendors Tests

    func testLoadVendors_Success() async throws {
        // Given
        let mockVendors = [
            createMockVendor(name: "Venue Provider"),
            createMockVendor(name: "Photographer"),
        ]
        let mockStats = VendorStats(
            total: 2,
            booked: 1,
            available: 1,
            archived: 0,
            totalCost: 5000,
            averageRating: 4.5
        )
        mockRepository.vendors = mockVendors
        mockRepository.vendorStats = mockStats

        // When
        await store.loadVendors()

        // Then
        XCTAssertEqual(store.vendors.count, 2)
        XCTAssertEqual(store.vendors[0].vendorName, "Venue Provider")
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertNotNil(store.vendorStats)
        XCTAssertEqual(store.vendorStats?.total, 2)
    }

    func testLoadVendors_EmptyResult() async throws {
        // Given
        mockRepository.vendors = []
        mockRepository.vendorStats = VendorStats(
            total: 0,
            booked: 0,
            available: 0,
            archived: 0,
            totalCost: 0,
            averageRating: 0
        )

        // When
        await store.loadVendors()

        // Then
        XCTAssertTrue(store.vendors.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadVendors_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await store.loadVendors()

        // Then
        XCTAssertTrue(store.vendors.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Add Vendor Tests

    func testAddVendor_Success() async throws {
        // Given
        let newVendor = createMockVendor(name: "Florist")
        mockRepository.vendors = []
        mockRepository.vendorStats = VendorStats(
            total: 1,
            booked: 0,
            available: 1,
            archived: 0,
            totalCost: 0,
            averageRating: 0
        )

        // When
        await store.addVendor(newVendor)

        // Then
        XCTAssertEqual(store.vendors.count, 1)
        XCTAssertEqual(store.vendors[0].vendorName, "Florist")
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertTrue(store.showSuccessToast)
        XCTAssertNotNil(store.vendorStats)
    }

    func testAddVendor_Error() async throws {
        // Given
        let newVendor = createMockVendor(name: "Caterer")
        mockRepository.shouldThrowError = true

        // When
        await store.addVendor(newVendor)

        // Then
        XCTAssertTrue(store.vendors.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
        XCTAssertFalse(store.showSuccessToast)
    }

    // MARK: - Update Vendor Tests

    func testUpdateVendor_Success() async throws {
        // Given
        let originalVendor = createMockVendor(name: "Original Name", id: UUID())
        mockRepository.vendors = [originalVendor]
        mockRepository.vendorStats = VendorStats(
            total: 1,
            booked: 1,
            available: 0,
            archived: 0,
            totalCost: 5000,
            averageRating: 5.0
        )

        await store.loadVendors()

        var updatedVendor = originalVendor
        updatedVendor.vendorName = "Updated Name"
        mockRepository.vendors = [updatedVendor]

        // When
        await store.updateVendor(updatedVendor)

        // Then
        XCTAssertEqual(store.vendors.count, 1)
        XCTAssertEqual(store.vendors[0].vendorName, "Updated Name")
        XCTAssertNil(store.error)
    }

    func testUpdateVendor_Rollback() async throws {
        // Given - Load initial vendor
        let originalVendor = createMockVendor(name: "Original Name", id: UUID())
        mockRepository.vendors = [originalVendor]
        await store.loadVendors()

        // Prepare updated vendor
        var updatedVendor = originalVendor
        updatedVendor.vendorName = "Failed Update"

        // Configure repository to fail update
        mockRepository.shouldThrowError = true

        // When
        await store.updateVendor(updatedVendor)

        // Then - Should rollback to original
        XCTAssertEqual(store.vendors.count, 1)
        XCTAssertEqual(store.vendors[0].vendorName, "Original Name")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Delete Vendor Tests

    func testDeleteVendor_Success() async throws {
        // Given
        let vendor1 = createMockVendor(name: "Vendor 1", id: UUID())
        let vendor2 = createMockVendor(name: "Vendor 2", id: UUID())
        mockRepository.vendors = [vendor1, vendor2]
        mockRepository.vendorStats = VendorStats(
            total: 1,
            booked: 0,
            available: 1,
            archived: 0,
            totalCost: 0,
            averageRating: 0
        )

        await store.loadVendors()

        // When
        await store.deleteVendor(vendor1)

        // Then
        XCTAssertEqual(store.vendors.count, 1)
        XCTAssertEqual(store.vendors[0].id, vendor2.id)
        XCTAssertNil(store.error)
        XCTAssertNotNil(store.vendorStats)
    }

    func testDeleteVendor_Rollback() async throws {
        // Given
        let vendor = createMockVendor(name: "Vendor", id: UUID())
        mockRepository.vendors = [vendor]
        await store.loadVendors()

        mockRepository.shouldThrowError = true

        // When
        await store.deleteVendor(vendor)

        // Then - Should rollback
        XCTAssertEqual(store.vendors.count, 1)
        XCTAssertEqual(store.vendors[0].id, vendor.id)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Refresh Tests

    func testRefreshVendors() async throws {
        // Given
        let initialVendors = [createMockVendor(name: "Vendor 1")]
        mockRepository.vendors = initialVendors
        mockRepository.vendorStats = VendorStats(
            total: 1,
            booked: 1,
            available: 0,
            archived: 0,
            totalCost: 5000,
            averageRating: 5.0
        )

        await store.loadVendors()

        // Update repository with new data
        let updatedVendors = [
            createMockVendor(name: "Vendor 1"),
            createMockVendor(name: "Vendor 2"),
        ]
        mockRepository.vendors = updatedVendors
        mockRepository.vendorStats = VendorStats(
            total: 2,
            booked: 1,
            available: 1,
            archived: 0,
            totalCost: 10000,
            averageRating: 4.5
        )

        // When
        await store.refreshVendors()

        // Then
        XCTAssertEqual(store.vendors.count, 2)
        XCTAssertEqual(store.vendorStats?.total, 2)
    }

    // MARK: - Helper Methods

    private func createMockVendor(
        name: String,
        id: UUID = UUID()
    ) -> Vendor {
        Vendor(
            id: Int64(abs(id.hashValue)),
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: name,
            vendorType: "Venue",
            vendorCategoryId: nil,
            contactName: nil,
            phoneNumber: nil,
            email: nil,
            website: nil,
            notes: nil,
            quotedAmount: nil,
            imageUrl: nil,
            isBooked: false,
            dateBooked: nil,
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true,
            streetAddress: nil,
            streetAddress2: nil,
            city: nil,
            state: nil,
            postalCode: nil,
            country: nil,
            latitude: nil,
            longitude: nil
        )
    }
}
