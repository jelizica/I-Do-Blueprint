//
//  CacheWarmer.swift
//  I Do Blueprint
//
//  Cache warming service for preloading frequently accessed data
//  Part of JES-60: Performance Optimization
//

import Foundation
import Dependencies

/// Service for warming caches on app launch
///
/// This service preloads frequently accessed data into the cache to improve
/// initial load times and reduce perceived latency. It runs in the background
/// with low priority to avoid blocking the main thread.
///
/// ## Usage Example
/// ```swift
/// // In app initialization
/// Task.detached(priority: .utility) {
///     await CacheWarmer.shared.warmCaches()
/// }
/// ```
@MainActor
class CacheWarmer {

    // MARK: - Singleton

    static let shared = CacheWarmer()

    // MARK: - Private Properties

    private let logger = AppLogger.analytics
    private var isWarming = false

    // MARK: - Public Interface

    /// Warms all caches by preloading frequently accessed data
    ///
    /// This method runs asynchronously and can be called on app launch.
    /// It will skip warming if already in progress.
    func warmCaches() async {
        guard !isWarming else {
            logger.info("Cache warming already in progress, skipping")
            return
        }

        isWarming = true
        let startTime = Date()

        logger.info("🔥 Starting cache warming...")

        // Warm caches in parallel for better performance
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.warmGuestCache() }
            group.addTask { await self.warmBudgetCache() }
            group.addTask { await self.warmVendorCache() }
            group.addTask { await self.warmTaskCache() }
        }

        let duration = Date().timeIntervalSince(startTime)
        logger.info("✅ Cache warming complete in \(String(format: "%.2f", duration))s")

        isWarming = false
    }

    /// Warms a specific cache by name
    ///
    /// - Parameter cacheName: The name of the cache to warm ("guests", "budget", "vendors", "tasks")
    func warmCache(_ cacheName: String) async {
        logger.info("Warming \(cacheName) cache...")

        switch cacheName.lowercased() {
        case "guests":
            await warmGuestCache()
        case "budget":
            await warmBudgetCache()
        case "vendors":
            await warmVendorCache()
        case "tasks":
            await warmTaskCache()
        default:
            logger.warning("Unknown cache name: \(cacheName)")
        }
    }

    // MARK: - Private Cache Warming Methods

    /// Warms the guest cache
    private func warmGuestCache() async {
        do {
            @Dependency(\.guestRepository) var repository

            // Fetch first page of guests (most commonly accessed)
            _ = try await repository.fetchGuests()

            // Fetch guest stats (shown on dashboard)
            _ = try await repository.fetchGuestStats()

            logger.info("✓ Guest cache warmed")
        } catch {
            logger.error("Failed to warm guest cache", error: error)
        }
    }

    /// Warms the budget cache
    private func warmBudgetCache() async {
        do {
            @Dependency(\.budgetRepository) var repository

            // Fetch budget summary (shown on dashboard)
            _ = try await repository.fetchBudgetSummary()

            // Fetch categories (commonly accessed)
            _ = try await repository.fetchCategories()

            // Fetch recent expenses (shown on dashboard)
            _ = try await repository.fetchExpenses()

            logger.info("✓ Budget cache warmed")
        } catch {
            logger.error("Failed to warm budget cache", error: error)
        }
    }

    /// Warms the vendor cache
    private func warmVendorCache() async {
        do {
            @Dependency(\.vendorRepository) var repository

            // Fetch vendors (commonly accessed)
            _ = try await repository.fetchVendors()

            // Fetch vendor stats (shown on dashboard)
            _ = try await repository.fetchVendorStats()

            logger.info("✓ Vendor cache warmed")
        } catch {
            logger.error("Failed to warm vendor cache", error: error)
        }
    }

    /// Warms the task cache
    private func warmTaskCache() async {
        do {
            @Dependency(\.taskRepository) var repository

            // Fetch tasks (commonly accessed)
            _ = try await repository.fetchTasks()

            // Fetch task stats (shown on dashboard)
            _ = try await repository.fetchTaskStats()

            logger.info("✓ Task cache warmed")
        } catch {
            logger.error("Failed to warm task cache", error: error)
        }
    }
}
