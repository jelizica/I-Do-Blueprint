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
    var mockRepository: MockVendorRepository!
    var coupleId: UUID!

    override func setUp() async throws {
        mockRepository = MockVendorRepository()
        coupleId = UUID()
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
    }

    // MARK: - Load Tests

    func testLoadVendors_Success() async throws {
        // Given
        let testVendors = [
            Vendor.makeTest(id: 1, coupleId: coupleId, vendorName: "Photographer John"),
            Vendor.makeTest(id: 2, coupleId: coupleId, vendorName: "Caterer Sarah")
        ]
        mockRepository.vendors = testVendors

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.vendors.count, 2)
        XCTAssertEqual(store.vendors[0].vendorName, "Photographer John")
    }

    func testLoadVendors_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.vendors.count, 0)
    }

    func testLoadVendors_Empty() async throws {
        // Given
        mockRepository.vendors = []

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.vendors.count, 0)
    }

    // MARK: - Create Tests

    func testCreateVendor_OptimisticUpdate() async throws {
        // Given
        let existingVendor = Vendor.makeTest(id: 1, coupleId: coupleId, vendorName: "Existing Vendor")
        mockRepository.vendors = [existingVendor]

        let newVendor = Vendor.makeTest(id: 2, coupleId: coupleId, vendorName: "New Vendor")

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()
        await store.addVendor(newVendor)

        // Then
        XCTAssertEqual(store.vendors.count, 2)
        XCTAssertTrue(store.vendors.contains(where: { $0.vendorName == "New Vendor" }))
    }

    // MARK: - Update Tests

    func testUpdateVendor_Success() async throws {
        // Given
        let vendor = Vendor.makeTest(id: 1, coupleId: coupleId, vendorName: "Original Name", isBooked: false)
        mockRepository.vendors = [vendor]

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        var updatedVendor = vendor
        updatedVendor.isBooked = true
        await store.updateVendor(updatedVendor)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.vendors.first?.isBooked, true)
    }

    func testUpdateVendor_Failure_RollsBack() async throws {
        // Given
        let vendor = Vendor.makeTest(id: 1, coupleId: coupleId, vendorName: "Vendor", isBooked: false)
        mockRepository.vendors = [vendor]

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        var updatedVendor = vendor
        updatedVendor.isBooked = true

        mockRepository.shouldThrowError = true
        await store.updateVendor(updatedVendor)

        // Then - Should rollback to original
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.vendors.first?.isBooked, false)
    }

    // MARK: - Delete Tests

    func testDeleteVendor_Success() async throws {
        // Given
        let vendor1 = Vendor.makeTest(id: 1, coupleId: coupleId, vendorName: "Vendor 1")
        let vendor2 = Vendor.makeTest(id: 2, coupleId: coupleId, vendorName: "Vendor 2")
        mockRepository.vendors = [vendor1, vendor2]

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()
        await store.deleteVendor(vendor1)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.vendors.count, 1)
        XCTAssertEqual(store.vendors.first?.vendorName, "Vendor 2")
    }

    func testDeleteVendor_Failure_RollsBack() async throws {
        // Given
        let vendor = Vendor.makeTest(id: 1, coupleId: coupleId, vendorName: "Vendor")
        mockRepository.vendors = [vendor]

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        mockRepository.shouldThrowError = true
        await store.deleteVendor(vendor)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.vendors.count, 1)
    }

    func testToggleBooked() async throws {
        // Given
        let vendor = Vendor.makeTest(id: 1, coupleId: coupleId, vendorName: "Vendor", isBooked: false)
        mockRepository.vendors = [vendor]

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()
        await store.toggleBookingStatus(vendor)

        // Then
        XCTAssertEqual(store.vendors.first?.isBooked, true)
    }

    func testArchiveVendor() async throws {
        // Given
        let vendor = Vendor.makeTest(id: 1, coupleId: coupleId, vendorName: "Vendor", isArchived: false)
        mockRepository.vendors = [vendor]

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        var archivedVendor = vendor
        archivedVendor.isArchived = true
        await store.updateVendor(archivedVendor)

        // Then
        XCTAssertEqual(store.vendors.first?.isArchived, true)
    }

    // MARK: - Computed Properties Tests

    func testComputedProperty_TotalVendors() async throws {
        // Given
        let vendors = [
            Vendor.makeTest(id: 1, coupleId: coupleId),
            Vendor.makeTest(id: 2, coupleId: coupleId),
            Vendor.makeTest(id: 3, coupleId: coupleId)
        ]
        mockRepository.vendors = vendors

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        // Then
        XCTAssertEqual(store.vendors.count, 3)
    }

    func testComputedProperty_BookedVendors() async throws {
        // Given
        let vendors = [
            Vendor.makeTest(id: 1, coupleId: coupleId, isBooked: true),
            Vendor.makeTest(id: 2, coupleId: coupleId, isBooked: false),
            Vendor.makeTest(id: 3, coupleId: coupleId, isBooked: true)
        ]
        mockRepository.vendors = vendors

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        // Then
        let bookedCount = store.vendors.filter { $0.isBooked == true }.count
        XCTAssertEqual(bookedCount, 2)
    }

    func testComputedProperty_TotalQuoted() async throws {
        // Given
        let vendors = [
            Vendor.makeTest(id: 1, coupleId: coupleId, vendorName: "Vendor 1"),
            Vendor.makeTest(id: 2, coupleId: coupleId, vendorName: "Vendor 2"),
            Vendor.makeTest(id: 3, coupleId: coupleId, vendorName: "Vendor 3")
        ]
        mockRepository.vendors = vendors

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()

        // Then
        XCTAssertEqual(store.vendors.count, 3)
    }

    func testFilterByType() async throws {
        // Given
        let vendors = [
            Vendor.makeTest(id: 1, coupleId: coupleId, vendorType: "Photography"),
            Vendor.makeTest(id: 2, coupleId: coupleId, vendorType: "Catering"),
            Vendor.makeTest(id: 3, coupleId: coupleId, vendorType: "Photography")
        ]
        mockRepository.vendors = vendors

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()
        let filtered = store.vendors.filter { $0.vendorType == "Photography" }

        // Then
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.vendorType == "Photography" })
    }

    func testFilterByBookedStatus() async throws {
        // Given
        let vendors = [
            Vendor.makeTest(id: 1, coupleId: coupleId, isBooked: true),
            Vendor.makeTest(id: 2, coupleId: coupleId, isBooked: false),
            Vendor.makeTest(id: 3, coupleId: coupleId, isBooked: true)
        ]
        mockRepository.vendors = vendors

        // When
        let store = await withDependencies {
            $0.vendorRepository = mockRepository
        } operation: {
            VendorStoreV2()
        }

        await store.loadVendors()
        let booked = store.vendors.filter { $0.isBooked == true }

        // Then
        XCTAssertEqual(booked.count, 2)
        XCTAssertTrue(booked.allSatisfy { $0.isBooked == true })
    }
}
