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
    @Published var loadingState: LoadingState<[Vendor]> = .idle
    @Published private(set) var vendorStats: VendorStats?

    @Published var showSuccessToast = false
    @Published var successMessage = ""

    @Dependency(\.vendorRepository) var repository
    
    // MARK: - Computed Properties for Backward Compatibility
    
    var vendors: [Vendor] {
        loadingState.data ?? []
    }
    
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    var error: VendorError? {
        if case .error(let err) = loadingState {
            return err as? VendorError ?? .fetchFailed(underlying: err)
        }
        return nil
    }

    // MARK: - Public Interface

    func loadVendors() async {
        guard loadingState.isIdle || loadingState.hasError else { return }
        
        loadingState = .loading
        let startTime = Date()

        do {
            async let vendorsResult = repository.fetchVendors()
            async let statsResult = repository.fetchVendorStats()

            // Parallel fetch
            let fetchedVendors = try await vendorsResult
            vendorStats = try await statsResult
            
            loadingState = .loaded(fetchedVendors)

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.debug("Loaded vendors in \(duration)s")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.error("Failed to load vendors after \(duration)s", error: error)
            loadingState = .error(VendorError.fetchFailed(underlying: error))
        }
    }

    func refreshVendors() async {
        await loadVendors()
    }

    func addVendor(_ vendor: Vendor) async {
    let startTime = Date()
    
    do {
    let created = try await repository.createVendor(vendor)
    
    // Update loaded state with new vendor
    if case .loaded(var currentVendors) = loadingState {
    currentVendors.append(created)
    loadingState = .loaded(currentVendors)
    }
    
    // Refresh stats
    vendorStats = try await repository.fetchVendorStats()
    
    let duration = Date().timeIntervalSince(startTime)
    AppLogger.repository.info("Added vendor '\(vendor.vendorName)' in \(duration)s")
    
    // Show success feedback
    HapticFeedback.itemAdded()
    showSuccess("Vendor added successfully")
    } catch {
    let duration = Date().timeIntervalSince(startTime)
    AppLogger.repository.error("Failed to add vendor after \(duration)s", error: error)
    loadingState = .error(VendorError.createFailed(underlying: error))
    await handleError(error, operation: "add vendor") { [weak self] in
    await self?.addVendor(vendor)
    }
    }
    }

    func updateVendor(_ vendor: Vendor) async {
        // Optimistic update
        guard case .loaded(var currentVendors) = loadingState,
              let index = currentVendors.firstIndex(where: { $0.id == vendor.id }) else {
            return
        }
        
        let original = currentVendors[index]
        currentVendors[index] = vendor
        loadingState = .loaded(currentVendors)
        let startTime = Date()

        do {
            let updated = try await repository.updateVendor(vendor)
            
            if case .loaded(var vendors) = loadingState,
               let idx = vendors.firstIndex(where: { $0.id == vendor.id }) {
                vendors[idx] = updated
                loadingState = .loaded(vendors)
            }

            // Refresh stats
            vendorStats = try await repository.fetchVendorStats()

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.info("Updated vendor '\(vendor.vendorName)' in \(duration)s")
            
            showSuccess("Vendor updated successfully")
        } catch {
            // Rollback on error
            if case .loaded(var vendors) = loadingState,
               let idx = vendors.firstIndex(where: { $0.id == vendor.id }) {
                vendors[idx] = original
                loadingState = .loaded(vendors)
            }
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.error("Failed to update vendor after \(duration)s", error: error)
            loadingState = .error(VendorError.updateFailed(underlying: error))
            await handleError(error, operation: "update vendor") { [weak self] in
                await self?.updateVendor(vendor)
            }
        }
    }

    func deleteVendor(_ vendor: Vendor) async {
        // Optimistic delete
        guard case .loaded(var currentVendors) = loadingState,
              let index = currentVendors.firstIndex(where: { $0.id == vendor.id }) else {
            return
        }
        
        let removed = currentVendors.remove(at: index)
        loadingState = .loaded(currentVendors)
        let startTime = Date()

        do {
            try await repository.deleteVendor(id: vendor.id)

            // Refresh stats after successful delete
            vendorStats = try await repository.fetchVendorStats()

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.info("Deleted vendor '\(vendor.vendorName)' in \(duration)s")
            
            showSuccess("Vendor deleted successfully")
        } catch {
            // Rollback on error
            if case .loaded(var vendors) = loadingState {
                vendors.insert(removed, at: index)
                loadingState = .loaded(vendors)
            }
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.error("Failed to delete vendor after \(duration)s", error: error)
            loadingState = .error(VendorError.deleteFailed(underlying: error))
            await handleError(error, operation: "delete vendor") { [weak self] in
                await self?.deleteVendor(vendor)
            }
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
    
    // MARK: - Retry Helper
    
    func retryLoad() async {
        await loadVendors()
    }
    
    // MARK: - Private Helpers
    
    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessToast = true
        
        // Auto-hide after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showSuccessToast = false
        }
    }
    
    private func handleError(_ error: Error, operation: String, retry: @escaping () async -> Void) async {
        AppLogger.repository.error("Error during \(operation)", error: error)
        
        // For now, just log the error
        // In the future, could implement retry logic or show user-facing error messages
    }
}
