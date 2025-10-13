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

    /// Default retry configuration for repository operations
    static let defaultRetryConfig = RetryConfiguration.default

    /// Execute a repository operation with standard retry and timeout
    static func withRetry<T>(
        timeout: TimeInterval = defaultTimeout,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await NetworkRetry.withRetryAndTimeout(
            retryConfig: defaultRetryConfig,
            timeoutSeconds: timeout,
            operation: operation
        )
    }
}
