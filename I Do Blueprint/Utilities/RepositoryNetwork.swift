//
//  RepositoryNetwork.swift
//  My Wedding Planning App
//
//  Centralized network configuration for repositories
//

import Foundation

/// Centralized network configuration for repository operations
enum RepositoryNetwork {
    /// Default timeout for standard repository operations (10 seconds)
    static let defaultTimeout: TimeInterval = 10

    /// Extended timeout for complex queries (15 seconds)
    static let extendedTimeout: TimeInterval = 15

    /// Default retry policy using new RetryPolicy infrastructure
    static let defaultRetryPolicy = RetryPolicy.network

    /// Shared offline cache for repository operations
    static let offlineCache = OfflineCache()

    /// Execute a repository operation with standard retry and timeout
    static func withRetry<T>(
        timeout: TimeInterval = defaultTimeout,
        policy: RetryPolicy = defaultRetryPolicy,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Use the global withRetry function with timeout handling
        try await I_Do_Blueprint.withRetry(policy: policy, operationName: "RepositoryNetwork") {
            // Wrap operation with timeout using TaskGroup
            try await withThrowingTaskGroup(of: T.self) { group in
                // Add the main operation
                group.addTask {
                    try await operation()
                }

                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    throw NetworkError.timeout
                }

                // Return first result (either success or timeout)
                guard let result = try await group.next() else {
                    throw NetworkError.timeout
                }

                // Cancel remaining tasks
                group.cancelAll()

                return result
            }
        }
    }

    /// Fetch with offline cache fallback
    static func fetchWithCache<T: Codable>(
        cacheKey: String,
        operationName: String = "fetchWithCache",
        ttl: TimeInterval = 300,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        do {
            // Try network fetch with retry (use global function explicitly)
            let result = try await I_Do_Blueprint.withRetry(operationName: operationName, operation: operation)

            // Cache successful result
            try await offlineCache.save(result, forKey: cacheKey, ttl: ttl)

            return result
        } catch {
            // On network failure, try offline cache
            if let cached = await offlineCache.load(T.self, forKey: cacheKey) {
                AppLogger.repository.info("Using cached data for \(cacheKey) due to network error")

                // Track cache fallback
                await ErrorTracker.shared.trackCacheFallback(error, operation: operationName)

                return cached
            }

            // No cache available, rethrow error
            throw error
        }
    }
}
