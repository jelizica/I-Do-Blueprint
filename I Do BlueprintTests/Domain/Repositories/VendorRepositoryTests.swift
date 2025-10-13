//
//  VendorRepositoryTests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for VendorRepository implementations
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class VendorRepositoryTests: XCTestCase {
    var mockRepository: MockVendorRepository!

    override func setUp() async throws {
        mockRepository = MockVendorRepository()
    }

    override func tearDown() async throws {
        mockRepository = nil
    }

    // MARK: - Fetch Vendors Tests

    func testFetchVendors_Success() async throws {
        // Given
        let vendor1 = createMockVendor(id: 1, name: "Venue A", isBooked: true)
        let vendor2 = createMockVendor(id: 2, name: "Caterer B", isBooked: false)
        mockRepository.vendors = [vendor1, vendor2]

        // When
        let result = try await mockRepository.fetchVendors()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(mockRepository.fetchVendorsCalled)
        XCTAssertEqual(result[0].vendorName, "Venue A")
        XCTAssertEqual(result[1].vendorName, "Caterer B")
    }

    func testFetchVendors_EmptyResult() async throws {
        // Given
        mockRepository.vendors = []

        // When
        let result = try await mockRepository.fetchVendors()

        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mockRepository.fetchVendorsCalled)
    }

    func testFetchVendors_ErrorHandling() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = NSError(domain: "test.vendor", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        // When/Then
        do {
            _ = try await mockRepository.fetchVendors()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(mockRepository.fetchVendorsCalled)
            XCTAssertEqual((error as NSError).domain, "test.vendor")
        }
    }

    // MARK: - Fetch Stats Tests

    func testFetchVendorStats_CalculatesCorrectly() async throws {
        // Given
        mockRepository.vendors = [
            createMockVendor(id: 1, name: "Venue", isBooked: true, quotedAmount: 5000),
            createMockVendor(id: 2, name: "Caterer", isBooked: true, quotedAmount: 3000),
            createMockVendor(id: 3, name: "DJ", isBooked: false, quotedAmount: 1500),
            createMockVendor(id: 4, name: "Florist", isBooked: false, quotedAmount: nil),
        ]

        // When
        let stats = try await mockRepository.fetchVendorStats()

        // Then
        XCTAssertEqual(stats.total, 4)
        XCTAssertEqual(stats.booked, 2)
        XCTAssertEqual(stats.available, 2)
        XCTAssertEqual(stats.totalCost, 9500)
        XCTAssertTrue(mockRepository.fetchStatsCalled)
    }

    func testFetchVendorStats_WithArchivedVendors() async throws {
        // Given
        let vendor1 = createMockVendor(id: 1, name: "Active", isBooked: true)
        let vendor2 = createMockVendor(id: 2, name: "Archived", isBooked: false, isArchived: true)
        mockRepository.vendors = [vendor1, vendor2]

        // When
        let stats = try await mockRepository.fetchVendorStats()

        // Then
        XCTAssertEqual(stats.total, 2)
        XCTAssertEqual(stats.archived, 1)
    }

    // MARK: - Create Vendor Tests

    func testCreateVendor_Success() async throws {
        // Given
        let newVendor = createMockVendor(id: 1, name: "New Venue")

        // When
        let created = try await mockRepository.createVendor(newVendor)

        // Then
        XCTAssertTrue(mockRepository.createVendorCalled)
        XCTAssertEqual(created.vendorName, "New Venue")
        XCTAssertEqual(mockRepository.vendors.count, 1)
        XCTAssertEqual(mockRepository.vendors.first?.vendorName, "New Venue")
    }

    func testCreateVendor_ErrorHandling() async throws {
        // Given
        mockRepository.shouldThrowError = true
        let newVendor = createMockVendor(id: 1, name: "New Venue")

        // When/Then
        do {
            _ = try await mockRepository.createVendor(newVendor)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(mockRepository.createVendorCalled)
            XCTAssertTrue(mockRepository.vendors.isEmpty)
        }
    }

    // MARK: - Update Vendor Tests

    func testUpdateVendor_Success() async throws {
        // Given
        let original = createMockVendor(id: 1, name: "Original Name", isBooked: false)
        mockRepository.vendors = [original]

        let updated = createMockVendor(id: 1, name: "Updated Name", isBooked: true, quotedAmount: 10000)

        // When
        let result = try await mockRepository.updateVendor(updated)

        // Then
        XCTAssertTrue(mockRepository.updateVendorCalled)
        XCTAssertEqual(result.vendorName, "Updated Name")
        XCTAssertEqual(result.isBooked, true)
        XCTAssertEqual(result.quotedAmount, 10000)
        XCTAssertEqual(mockRepository.vendors.first?.vendorName, "Updated Name")
    }

    func testUpdateVendor_NonexistentVendor() async throws {
        // Given
        mockRepository.vendors = [createMockVendor(id: 1, name: "Vendor 1")]
        let nonexistent = createMockVendor(id: 999, name: "Nonexistent")

        // When
        let result = try await mockRepository.updateVendor(nonexistent)

        // Then
        XCTAssertTrue(mockRepository.updateVendorCalled)
        XCTAssertEqual(mockRepository.vendors.count, 1) // Original vendor unchanged
        XCTAssertEqual(result.id, 999) // Returns the attempted update
    }

    // MARK: - Delete Vendor Tests

    func testDeleteVendor_Success() async throws {
        // Given
        let vendor1 = createMockVendor(id: 1, name: "Vendor 1")
        let vendor2 = createMockVendor(id: 2, name: "Vendor 2")
        mockRepository.vendors = [vendor1, vendor2]

        // When
        try await mockRepository.deleteVendor(id: 1)

        // Then
        XCTAssertTrue(mockRepository.deleteVendorCalled)
        XCTAssertEqual(mockRepository.vendors.count, 1)
        XCTAssertEqual(mockRepository.vendors.first?.id, 2)
    }

    func testDeleteVendor_NonexistentVendor() async throws {
        // Given
        mockRepository.vendors = [createMockVendor(id: 1, name: "Vendor 1")]

        // When
        try await mockRepository.deleteVendor(id: 999)

        // Then
        XCTAssertTrue(mockRepository.deleteVendorCalled)
        XCTAssertEqual(mockRepository.vendors.count, 1) // Original vendor still exists
    }

    func testDeleteVendor_ErrorHandling() async throws {
        // Given
        mockRepository.vendors = [createMockVendor(id: 1, name: "Vendor 1")]
        mockRepository.shouldThrowError = true

        // When/Then
        do {
            try await mockRepository.deleteVendor(id: 1)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(mockRepository.deleteVendorCalled)
            XCTAssertEqual(mockRepository.vendors.count, 1) // Vendor not deleted due to error
        }
    }

    // MARK: - Helper Methods

    private func createMockVendor(
        id: Int64,
        name: String,
        vendorType: String? = "Venue",
        isBooked: Bool = false,
        quotedAmount: Double? = nil,
        isArchived: Bool = false
    ) -> Vendor {
        Vendor(
            id: id,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: name,
            vendorType: vendorType,
            vendorCategoryId: nil,
            contactName: nil,
            phoneNumber: nil,
            email: nil,
            website: nil,
            notes: nil,
            quotedAmount: quotedAmount,
            imageUrl: nil,
            isBooked: isBooked,
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: isArchived,
            archivedAt: isArchived ? Date() : nil,
            includeInExport: false
        )
    }
}
