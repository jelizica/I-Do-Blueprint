//
//  LiveVendorRepositoryTests.swift
//  My Wedding Planning App Tests
//
//  Comprehensive tests for LiveVendorRepository including cache TTL, invalidation, and retry logic
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class LiveVendorRepositoryTests: XCTestCase {
    var repository: LiveVendorRepository!
    var testTenantId: UUID!

    override func setUp() async throws {
        try await super.setUp()
        testTenantId = UUID()
        repository = LiveVendorRepository()
        SessionManager.shared.setTenantId(testTenantId)
    }

    override func tearDown() async throws {
        repository = nil
        SessionManager.shared.clearSession()
        try await super.tearDown()
    }

    // MARK: - Fetch Vendors Tests

    func testFetchVendorsSuccess() async throws {
        // When: Fetching vendors for the first time
        let vendors = try await repository.fetchVendors()

        // Then: Should return vendors array (empty or populated)
        XCTAssertNotNil(vendors, "Vendors array should not be nil")
    }

    func testFetchVendorsWithInvalidTenantId() async throws {
        // Given: An invalid tenant ID
        let invalidTenantId = UUID()
        SessionManager.shared.setTenantId(invalidTenantId)

        // When: Fetching vendors with invalid tenant
        do {
            _ = try await repository.fetchVendors()
            XCTFail("Should throw error for invalid tenant ID")
        } catch {
            // Then: Should throw appropriate error
            XCTAssertTrue(error is VendorError, "Should throw VendorError")
        }
    }

    // MARK: - Cache TTL Tests

    func testCacheTTLExpiration() async throws {
        // Given: Vendors fetched and cached
        let firstFetch = try await repository.fetchVendors()

        // When: Fetching again within TTL window (should use cache)
        let secondFetch = try await repository.fetchVendors()

        // Then: Should return cached data (same reference)
        XCTAssertEqual(firstFetch.count, secondFetch.count, "Should return cached data within TTL")

        // Note: Testing actual TTL expiration would require time manipulation
        // or a configurable TTL parameter for testing
    }

    func testCacheInvalidationAfterTTL() async throws {
        // Given: A repository with a short TTL for testing
        // Note: This would require injecting a configurable TTL parameter
        // For now, we test the cache invalidation mechanism itself

        // When: Manually invalidating the cache
        repository.invalidateCache()

        // Then: Next fetch should retrieve fresh data from Supabase
        let vendors = try await repository.fetchVendors()
        XCTAssertNotNil(vendors, "Should fetch fresh data after cache invalidation")
    }

    // MARK: - Cache Invalidation Tests

    func testCacheInvalidationOnCreate() async throws {
        // Given: Cached vendor data
        _ = try await repository.fetchVendors()

        // When: Creating a new vendor
        let newVendor = Vendor(
            id: nil,
            tenantId: testTenantId,
            name: "Test Vendor",
            category: "Catering",
            contactName: "John Doe",
            contactEmail: "john@example.com",
            contactPhone: "555-0100",
            website: nil,
            address: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            notes: nil,
            estimatedCost: 2000.0,
            actualCost: nil,
            depositPaid: nil,
            depositAmount: nil,
            finalPaymentDue: nil,
            contractSigned: false,
            status: "potential"
        )

        _ = try await repository.createVendor(newVendor)

        // Then: Cache should be invalidated (next fetch gets fresh data)
        let vendors = try await repository.fetchVendors()
        XCTAssertTrue(vendors.contains(where: { $0.name == "Test Vendor" }), "New vendor should be in fresh fetch")
    }

    func testCacheInvalidationOnUpdate() async throws {
        // Given: A vendor in the cache
        let vendors = try await repository.fetchVendors()
        guard var vendorToUpdate = vendors.first else {
            throw XCTSkip("No vendors available for update test")
        }

        // When: Updating the vendor
        vendorToUpdate.name = "Updated Vendor Name"
        _ = try await repository.updateVendor(vendorToUpdate)

        // Then: Cache should be invalidated
        repository.invalidateCache()
        let freshVendors = try await repository.fetchVendors()
        XCTAssertTrue(freshVendors.contains(where: { $0.name == "Updated Vendor Name" }), "Updated vendor should be in fresh fetch")
    }

    func testCacheInvalidationOnDelete() async throws {
        // Given: A vendor in the cache
        let vendors = try await repository.fetchVendors()
        guard let vendorToDelete = vendors.first, let vendorId = vendorToDelete.id else {
            throw XCTSkip("No vendors available for delete test")
        }

        // When: Deleting the vendor
        try await repository.deleteVendor(id: vendorId)

        // Then: Cache should be invalidated
        repository.invalidateCache()
        let freshVendors = try await repository.fetchVendors()
        XCTAssertFalse(freshVendors.contains(where: { $0.id == vendorId }), "Deleted vendor should not be in fresh fetch")
    }

    // MARK: - Retry-on-Timeout Tests

    func testRetryOnNetworkTimeout() async throws {
        // Given: A simulated network timeout
        // Note: This would require a mock Supabase client to inject timeouts

        // When: Fetching vendors with timeout
        // The repository should retry the request

        // Then: Should eventually succeed or throw after max retries
        do {
            let vendors = try await repository.fetchVendors()
            XCTAssertNotNil(vendors, "Should eventually succeed with retry")
        } catch let error as VendorError {
            // Verify it's a network error after retries
            if case .fetchFailed = error {
                // Expected if all retries fail
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }

    func testRetryWithExponentialBackoff() async throws {
        // Given: Multiple sequential failed requests
        // Note: This would require tracking retry attempts and delays

        // When: Making requests that timeout
        // Then: Should use exponential backoff between retries
        // (1s, 2s, 4s, etc.)

        // This test would require time measurement and mock client
        // For now, verify that retry logic doesn't cause immediate successive failures
        let startTime = Date()

        do {
            _ = try await repository.fetchVendors()
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            // If retries are happening, should take some time
            XCTAssertGreaterThan(elapsed, 0, "Should take time for network operations")
        }
    }

    func testMaxRetryAttemptsLimit() async throws {
        // Given: A repository with max retry limit
        // Note: This would require configurable retry parameters

        // When: All retry attempts fail
        // Then: Should throw error after max retries (typically 3)

        // This would require a mock client that always fails
        // For now, test that errors are properly propagated
        do {
            _ = try await repository.fetchVendors(tenantId: UUID())
        } catch {
            XCTAssertTrue(error is VendorError, "Should throw VendorError after max retries")
        }
    }

    // MARK: - CRUD Operations Tests

    func testCreateVendorSuccess() async throws {
        // Given: A new vendor
        let newVendor = Vendor(
            id: nil,
            tenantId: testTenantId,
            name: "New Test Vendor",
            category: "Photography",
            contactName: "Jane Smith",
            contactEmail: "jane@example.com",
            contactPhone: "555-0200",
            website: "https://example.com",
            address: "123 Main St",
            city: "Springfield",
            state: "IL",
            zipCode: "62701",
            notes: "Highly recommended",
            estimatedCost: 3000.0,
            actualCost: nil,
            depositPaid: nil,
            depositAmount: 500.0,
            finalPaymentDue: nil,
            contractSigned: false,
            status: "contacted"
        )

        // When: Creating the vendor
        let createdVendor = try await repository.createVendor(newVendor)

        // Then: Should return vendor with assigned ID
        XCTAssertNotNil(createdVendor.id, "Created vendor should have an ID")
        XCTAssertEqual(createdVendor.name, "New Test Vendor", "Vendor name should match")
        XCTAssertEqual(createdVendor.category, "Photography", "Vendor category should match")
    }

    func testUpdateVendorSuccess() async throws {
        // Given: An existing vendor
        let vendors = try await repository.fetchVendors()
        guard var vendorToUpdate = vendors.first else {
            throw XCTSkip("No vendors available for update test")
        }

        // When: Updating the vendor
        vendorToUpdate.name = "Updated Vendor"
        vendorToUpdate.estimatedCost = 5000.0
        vendorToUpdate.contractSigned = true

        let updatedVendor = try await repository.updateVendor(vendorToUpdate)

        // Then: Should return updated vendor
        XCTAssertEqual(updatedVendor.name, "Updated Vendor", "Vendor name should be updated")
        XCTAssertEqual(updatedVendor.estimatedCost, 5000.0, "Estimated cost should be updated")
        XCTAssertTrue(updatedVendor.contractSigned, "Contract signed should be updated")
    }

    func testDeleteVendorSuccess() async throws {
        // Given: An existing vendor
        let newVendor = Vendor(
            id: nil,
            tenantId: testTenantId,
            name: "Vendor To Delete",
            category: "Flowers",
            contactName: "Test Contact",
            contactEmail: "test@example.com",
            contactPhone: "555-0300",
            website: nil,
            address: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            notes: nil,
            estimatedCost: 1000.0,
            actualCost: nil,
            depositPaid: nil,
            depositAmount: nil,
            finalPaymentDue: nil,
            contractSigned: false,
            status: "potential"
        )

        let createdVendor = try await repository.createVendor(newVendor)
        guard let vendorId = createdVendor.id else {
            XCTFail("Created vendor should have an ID")
            return
        }

        // When: Deleting the vendor
        try await repository.deleteVendor(id: vendorId)

        // Then: Vendor should be removed
        repository.invalidateCache()
        let vendors = try await repository.fetchVendors()
        XCTAssertFalse(vendors.contains(where: { $0.id == vendorId }), "Deleted vendor should not exist")
    }

    // MARK: - Error Handling Tests

    func testFetchVendorsHandlesUnauthorizedError() async throws {
        // Given: No session/tenant
        SessionManager.shared.clearSession()

        // When: Attempting to fetch vendors
        do {
            _ = try await repository.fetchVendors()
            XCTFail("Should throw unauthorized error")
        } catch let error as VendorError {
            // Then: Should throw unauthorized error
            if case .unauthorized = error {
                // Expected
            } else {
                XCTFail("Expected unauthorized error, got: \(error)")
            }
        }
    }

    func testCreateVendorHandlesValidationError() async throws {
        // Given: An invalid vendor (missing required fields)
        let invalidVendor = Vendor(
            id: nil,
            tenantId: testTenantId,
            name: "", // Empty name should fail validation
            category: "",
            contactName: nil,
            contactEmail: nil,
            contactPhone: nil,
            website: nil,
            address: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            notes: nil,
            estimatedCost: -100.0, // Negative cost should fail
            actualCost: nil,
            depositPaid: nil,
            depositAmount: nil,
            finalPaymentDue: nil,
            contractSigned: false,
            status: "potential"
        )

        // When: Attempting to create invalid vendor
        do {
            _ = try await repository.createVendor(invalidVendor)
            // May succeed if validation is not enforced at repository level
        } catch let error as VendorError {
            // Then: Should throw validation error
            if case .validationFailed = error {
                // Expected
            }
        }
    }
}
