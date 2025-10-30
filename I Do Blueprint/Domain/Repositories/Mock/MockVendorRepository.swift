//
//  MockVendorRepository.swift
//  My Wedding Planning App
//
//  Mock implementation of VendorRepositoryProtocol for testing
//

import Foundation

/// Mock implementation for testing
@MainActor
class MockVendorRepository: VendorRepositoryProtocol, @unchecked Sendable {
    // Storage
    var vendors: [Vendor] = []
    var vendorStats: VendorStats?

    // Call tracking
    var fetchVendorsCalled = false
    var fetchStatsCalled = false
    var createVendorCalled = false
    var updateVendorCalled = false
    var deleteVendorCalled = false

    // Error control
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1)

    // Delay simulation
    var delay: TimeInterval = 0

    init() {}

    func fetchVendors() async throws -> [Vendor] {
        fetchVendorsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return vendors
    }

    func fetchVendorStats() async throws -> VendorStats {
        fetchStatsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }

        if let vendorStats {
            return vendorStats
        }

        // Calculate stats from vendors array
        let total = vendors.count
        let booked = vendors.filter { $0.isBooked == true }.count
        let available = vendors.filter { $0.isBooked == false }.count
        let archived = vendors.filter { $0.isArchived }.count
        let totalCost = vendors.reduce(0.0) { $0 + ($1.quotedAmount ?? 0) }

        // avgRating is no longer on Vendor model - would need to fetch from reviews
        let averageRating: Double = 0

        return VendorStats(
            total: total,
            booked: booked,
            available: available,
            archived: archived,
            totalCost: totalCost,
            averageRating: averageRating)
    }

    func createVendor(_ vendor: Vendor) async throws -> Vendor {
        createVendorCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        vendors.append(vendor)
        return vendor
    }

    func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        updateVendorCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = vendors.firstIndex(where: { $0.id == vendor.id }) {
            vendors[index] = vendor
        }
        return vendor
    }

    func deleteVendor(id: Int64) async throws {
        deleteVendorCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        vendors.removeAll { $0.id == id }
    }

    // MARK: - Extended Vendor Data

    func fetchVendorReviews(vendorId: Int64) async throws -> [VendorReview] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return []
    }

    func fetchVendorReviewStats(vendorId: Int64) async throws -> VendorReviewStats? {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return nil
    }

    func fetchVendorPaymentSummary(vendorId: Int64) async throws -> VendorPaymentSummary? {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return nil
    }

    func fetchVendorContractSummary(vendorId: Int64) async throws -> VendorContract? {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return nil
    }

    func fetchVendorDetails(id: Int64) async throws -> VendorDetails {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }

        guard let vendor = vendors.first(where: { $0.id == id }) else {
            throw NSError(domain: "test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Vendor not found"])
        }

        var details = VendorDetails(vendor: vendor)
        details.reviewStats = try? await fetchVendorReviewStats(vendorId: id)
        details.paymentSummary = try? await fetchVendorPaymentSummary(vendorId: id)
        details.contractInfo = try? await fetchVendorContractSummary(vendorId: id)
        return details
    }
    
    // MARK: - Vendor Types
    
    var vendorTypes: [VendorType] = []
    
    func fetchVendorTypes() async throws -> [VendorType] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return vendorTypes
    }
    
    // MARK: - Bulk Import Operations
    
    var importVendorsCalled = false
    var importedVendors: [Vendor] = []
    
    func importVendors(_ vendors: [VendorImportData]) async throws -> [Vendor] {
        importVendorsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        
        // Convert VendorImportData to Vendor objects with mock IDs
        let now = Date()
        let imported = vendors.enumerated().map { index, importData in
            Vendor(
                id: Int64(self.vendors.count + index + 1), // Generate mock ID
                createdAt: now,
                updatedAt: now,
                vendorName: importData.vendorName,
                vendorType: importData.vendorType,
                vendorCategoryId: importData.vendorCategoryId,
                contactName: importData.contactName,
                phoneNumber: importData.phoneNumber,
                email: importData.email,
                website: importData.website,
                notes: importData.notes,
                quotedAmount: importData.quotedAmount,
                imageUrl: importData.imageUrl,
                isBooked: importData.isBooked,
                dateBooked: importData.dateBooked,
                budgetCategoryId: importData.budgetCategoryId,
                coupleId: importData.coupleId,
                isArchived: importData.isArchived,
                archivedAt: nil,
                includeInExport: importData.includeInExport,
                streetAddress: importData.streetAddress,
                streetAddress2: importData.streetAddress2,
                city: importData.city,
                state: importData.state,
                postalCode: importData.postalCode,
                country: importData.country,
                latitude: importData.latitude,
                longitude: importData.longitude
            )
        }
        
        // Add to vendors array
        self.vendors.append(contentsOf: imported)
        self.importedVendors = imported
        
        return imported
    }

    // MARK: - Testing Utilities

    /// Reset all call tracking flags
    func resetFlags() {
        fetchVendorsCalled = false
        fetchStatsCalled = false
        createVendorCalled = false
        updateVendorCalled = false
        deleteVendorCalled = false
    }

    /// Reset all data to defaults
    func resetData() {
        vendors = []
        vendorStats = nil
        resetFlags()
    }
}
