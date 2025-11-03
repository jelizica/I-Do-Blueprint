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
class VendorStoreV2: ObservableObject, CacheableStore {
    @Published var loadingState: LoadingState<[Vendor]> = .idle
    @Published private(set) var vendorStats: VendorStats?

    @Published var showSuccessToast = false
    @Published var successMessage = ""

    @Dependency(\.vendorRepository) var repository

    // MARK: - Cache Management
    var lastLoadTime: Date?
    let cacheValidityDuration: TimeInterval = 600 // 10 minutes (slow-changing)

    // Task tracking for cancellation handling
    private var loadTask: Task<Void, Never>?
    private var addTask: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?
    private var deleteTask: Task<Void, Never>?

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

    func loadVendors(force: Bool = false) async {
        // Cancel any previous load task
        loadTask?.cancel()

        // Create new load task
        loadTask = Task { @MainActor in
            // Use cached data if still valid
            if !force && isCacheValid() {
                AppLogger.ui.debug("Using cached vendor data (age: \(Int(cacheAge()))s)")
                return
            }

            guard loadingState.isIdle || loadingState.hasError || force else { return }

            loadingState = .loading
            let startTime = Date()

            do {
                try Task.checkCancellation()

                async let vendorsResult = repository.fetchVendors()
                async let statsResult = repository.fetchVendorStats()

                // Parallel fetch
                let fetchedVendors = try await vendorsResult
                let fetchedStats = try await statsResult

                try Task.checkCancellation()

                vendorStats = fetchedStats
                loadingState = .loaded(fetchedVendors)
                lastLoadTime = Date()

                let duration = Date().timeIntervalSince(startTime)
                AppLogger.repository.debug("Loaded vendors in \(duration)s")
            } catch is CancellationError {
                AppLogger.ui.debug("VendorStoreV2.loadVendors: Load cancelled (expected during tenant switch)")
                loadingState = .idle
            } catch let error as URLError where error.code == .cancelled {
                AppLogger.ui.debug("VendorStoreV2.loadVendors: Load cancelled (URLError)")
                loadingState = .idle
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                AppLogger.repository.error("Failed to load vendors after \(duration)s", error: error)
                loadingState = .error(VendorError.fetchFailed(underlying: error))
            }
        }

        await loadTask?.value
    }

    func refreshVendors() async {
        await loadVendors(force: true)
    }

    func addVendor(_ vendor: Vendor) async {
        // Add breadcrumb for debugging
        addOperationBreadcrumb(
            "addVendor",
            category: "vendor",
            data: ["vendorName": vendor.vendorName]
        )

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

            // Invalidate cache due to mutation
            invalidateCache()

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.info("Added vendor '\(vendor.vendorName)' in \(duration)s")

            // Show success feedback
            HapticFeedback.itemAdded()
            showSuccess("Vendor added successfully")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.error("Failed to add vendor after \(duration)s", error: error)
            loadingState = .error(VendorError.createFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "addVendor", feature: "vendor", metadata: ["vendorName": vendor.vendorName])
            )
        }
    }

    func updateVendor(_ vendor: Vendor) async {
        // Add breadcrumb for debugging
        addOperationBreadcrumb(
            "updateVendor",
            category: "vendor",
            data: [
                "vendorId": String(vendor.id),
                "vendorName": vendor.vendorName
            ]
        )

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

            // Invalidate cache due to mutation
            invalidateCache()

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.info("Updated vendor '\(vendor.vendorName)' in \(duration)s")

            showSuccess("Vendor updated successfully")
        } catch {
            // Rollback on error
            if case .loaded(var vendors) = loadingState,
               let idx = vendors.firstIndex(where: { $0.id == vendor.id }) {
                vendors[idx] = original
                loadingState = .loaded(vendors)
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.error("Failed to update vendor after \(duration)s", error: error)
            loadingState = .error(VendorError.updateFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "updateVendor",
                    feature: "vendor",
                    metadata: ["vendorId": String(vendor.id), "vendorName": vendor.vendorName]
                )
            )
            }
        }
    }

    func deleteVendor(_ vendor: Vendor) async {
        // Add breadcrumb for debugging
        addOperationBreadcrumb(
            "deleteVendor",
            category: "vendor",
            data: [
                "vendorId": String(vendor.id),
                "vendorName": vendor.vendorName
            ]
        )

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

            // Invalidate cache due to mutation
            invalidateCache()

            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.info("Deleted vendor '\(vendor.vendorName)' in \(duration)s")

            showSuccess("Vendor deleted successfully")
        } catch {
            // Rollback on error
            if case .loaded(var vendors) = loadingState {
                vendors.insert(removed, at: index)
                loadingState = .loaded(vendors)
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.repository.error("Failed to delete vendor after \(duration)s", error: error)
            loadingState = .error(VendorError.deleteFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "deleteVendor",
                    feature: "vendor",
                    metadata: ["vendorId": String(vendor.id), "vendorName": vendor.vendorName]
                )
            )
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

    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        // Cancel in-flight tasks to avoid race conditions during tenant switch
        loadTask?.cancel()
        addTask?.cancel()
        updateTask?.cancel()
        deleteTask?.cancel()

        // Reset state and invalidate cache
        loadingState = .idle
        vendorStats = nil
        lastLoadTime = nil
    }
}
