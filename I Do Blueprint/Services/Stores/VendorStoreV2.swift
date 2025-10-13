//
//  VendorStoreV2.swift
//  My Wedding Planning App
//
//  New architecture version of vendor management using repository pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// New architecture version using repositories and dependency injection
@MainActor
class VendorStoreV2: ObservableObject {
    @Published private(set) var vendors: [Vendor] = []
    @Published private(set) var vendorStats: VendorStats?

    @Published var isLoading = false
    @Published var error: VendorError?
    @Published var showSuccessToast = false
    @Published var successMessage = ""

    @Dependency(\.vendorRepository) var repository

    // MARK: - Public Interface

    func loadVendors() async {
        isLoading = true
        error = nil
        let startTime = Date()

        do {
            async let vendorsResult = repository.fetchVendors()
            async let statsResult = repository.fetchVendorStats()

            // Parallel fetch
            vendors = try await vendorsResult
            vendorStats = try await statsResult

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.debug("Loaded vendors in \(duration)s")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.error("Failed to load vendors after \(duration)s", error: error)
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func refreshVendors() async {
        await loadVendors()
    }

    func addVendor(_ vendor: Vendor) async {
        isLoading = true
        error = nil
        let startTime = Date()

        do {
            let created = try await repository.createVendor(vendor)
            vendors.append(created)

            // Refresh stats
            vendorStats = try await repository.fetchVendorStats()

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.info("Added vendor '\(vendor.vendorName)' in \(duration)s")

            // Show success toast
            HapticFeedback.itemAdded()
            successMessage = "Vendor added successfully!"
            showSuccessToast = true
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.error("Failed to add vendor after \(duration)s", error: error)
            self.error = .createFailed(underlying: error)
        }

        isLoading = false
    }

    func updateVendor(_ vendor: Vendor) async {
        // Optimistic update
        if let index = vendors.firstIndex(where: { $0.id == vendor.id }) {
            let original = vendors[index]
            vendors[index] = vendor
            let startTime = Date()

            do {
                let updated = try await repository.updateVendor(vendor)
                vendors[index] = updated

                // Refresh stats
                vendorStats = try await repository.fetchVendorStats()

                let duration = Date().timeIntervalSince(startTime)
                AppLogger.repository.info("Updated vendor '\(vendor.vendorName)' in \(duration)s")
            } catch {
                // Rollback on error
                vendors[index] = original
                let duration = Date().timeIntervalSince(startTime)
                AppLogger.repository.error("Failed to update vendor after \(duration)s", error: error)
                self.error = .updateFailed(underlying: error)
            }
        }
    }

    func deleteVendor(_ vendor: Vendor) async {
        // Optimistic delete
        guard let index = vendors.firstIndex(where: { $0.id == vendor.id }) else { return }
        let removed = vendors.remove(at: index)
        let startTime = Date()

        do {
            try await repository.deleteVendor(id: vendor.id)

            // Refresh stats after successful delete
            vendorStats = try await repository.fetchVendorStats()

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.info("Deleted vendor '\(vendor.vendorName)' in \(duration)s")
        } catch {
            // Rollback on error
            vendors.insert(removed, at: index)
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.error("Failed to delete vendor after \(duration)s", error: error)
            self.error = .deleteFailed(underlying: error)
        }
    }

    func toggleBookingStatus(_ vendor: Vendor) async {
        var updatedVendor = vendor
        let newBookedStatus = !(vendor.isBooked ?? false)
        updatedVendor.isBooked = newBookedStatus

        // Set dateBooked to current date when marking as booked
        if newBookedStatus {
            updatedVendor.dateBooked = Date()
        }

        await updateVendor(updatedVendor)
    }

    // MARK: - Computed Properties

    var stats: VendorStats {
        vendorStats ?? VendorStats(
            total: 0,
            booked: 0,
            available: 0,
            archived: 0,
            totalCost: 0,
            averageRating: 0)
    }
}
