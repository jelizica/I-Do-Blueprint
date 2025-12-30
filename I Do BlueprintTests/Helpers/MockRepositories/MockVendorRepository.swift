//
//  MockVendorRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of VendorRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockVendorRepository: VendorRepositoryProtocol {
    var vendors: [Vendor] = []
    var vendorStats: VendorStats = VendorStats(total: 0, booked: 0, available: 0, archived: 0, totalCost: 0.0, averageRating: 0.0)
    var reviews: [VendorReview] = []
    var vendorTypes: [VendorType] = []
    var shouldThrowError = false
    var errorToThrow: VendorError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchVendors() async throws -> [Vendor] {
        if shouldThrowError { throw errorToThrow }
        return vendors
    }

    func fetchVendorStats() async throws -> VendorStats {
        if shouldThrowError { throw errorToThrow }
        return vendorStats
    }

    func createVendor(_ vendor: Vendor) async throws -> Vendor {
        if shouldThrowError { throw errorToThrow }
        vendors.append(vendor)
        return vendor
    }

    func updateVendor(_ vendor: Vendor) async throws -> Vendor {
        if shouldThrowError { throw errorToThrow }
        if let index = vendors.firstIndex(where: { $0.id == vendor.id }) {
            vendors[index] = vendor
        }
        return vendor
    }

    func deleteVendor(id: Int64) async throws {
        if shouldThrowError { throw errorToThrow }
        vendors.removeAll(where: { $0.id == id })
    }

    func fetchVendorReviews(vendorId: Int64) async throws -> [VendorReview] {
        if shouldThrowError { throw errorToThrow }
        return reviews.filter { $0.vendorId == vendorId }
    }

    func fetchVendorReviewStats(vendorId: Int64) async throws -> VendorReviewStats? {
        if shouldThrowError { throw errorToThrow }
        return nil
    }

    func fetchVendorPaymentSummary(vendorId: Int64) async throws -> VendorPaymentSummary? {
        if shouldThrowError { throw errorToThrow }
        return nil
    }

    func fetchVendorContractSummary(vendorId: Int64) async throws -> VendorContract? {
        if shouldThrowError { throw errorToThrow }
        return nil
    }

    func fetchVendorDetails(id: Int64) async throws -> VendorDetails {
        if shouldThrowError { throw errorToThrow }
        return VendorDetails(
            vendor: vendors.first(where: { $0.id == id })!
        )
    }

    func fetchVendorTypes() async throws -> [VendorType] {
        if shouldThrowError { throw errorToThrow }
        return vendorTypes
    }
}
