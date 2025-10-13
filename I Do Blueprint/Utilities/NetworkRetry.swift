//
//  NetworkRetry.swift
//  My Wedding Planning App
//
//  Network retry utilities with exponential backoff and jitter
//

import Foundation

/// Configuration for network retry behavior
struct RetryConfiguration {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let jitterFactor: Double

    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        baseDelay: 0.5,
        maxDelay: 5.0,
        jitterFactor: 0.2
    )
}

/// Network retry utility with exponential backoff and jitter
enum NetworkRetry {
    /// Execute an async operation with retry logic
    static func withRetry<T>(
        config: RetryConfiguration = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<config.maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Don't retry on last attempt
                if attempt == config.maxAttempts - 1 {
                    break
                }

                // Calculate delay with exponential backoff and jitter
                let baseDelay = config.baseDelay * pow(2.0, Double(attempt))
                let jitter = baseDelay * config.jitterFactor * Double.random(in: -1...1)
                let delay = min(baseDelay + jitter, config.maxDelay)

                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError ?? NSError(
            domain: "NetworkRetry",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "All retry attempts failed"]
        )
    }

    /// Execute an async operation with timeout
    static func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NetworkError.timeout
            }

            // Return first result (either success or timeout)
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    /// Execute an async operation with both retry and timeout
    static func withRetryAndTimeout<T>(
        retryConfig: RetryConfiguration = .default,
        timeoutSeconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withRetry(config: retryConfig) {
            try await withTimeout(seconds: timeoutSeconds, operation: operation)
        }
    }
}

/// Network-related errors
enum NetworkError: Error, LocalizedError {
    case timeout
    case maxRetriesExceeded

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Network request timed out"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}
