//
//  RetryPolicy.swift
//  I Do Blueprint
//
//  Retry policy with exponential backoff for transient failures
//

import Foundation

/// Retry policy configuration with exponential backoff
struct RetryPolicy {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let shouldRetry: (Error) -> Bool

    /// Network-specific retry policy with 3 attempts
    /// Delays: 1s, 2s, 4s (+ jitter)
    static let network = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 10.0,
        shouldRetry: { error in
            // Retry network errors
            if let networkError = error as? NetworkError {
                return networkError.isRetryable
            }
            // Retry URL errors
            if let urlError = error as? URLError {
                return NetworkError.from(urlError: urlError).isRetryable
            }
            return false
        }
    )

    /// Standard retry policy for general operations with 2 attempts
    /// Delays: 0.5s, 1s (+ jitter)
    static let standard = RetryPolicy(
        maxAttempts: 2,
        baseDelay: 0.5,
        maxDelay: 5.0,
        shouldRetry: { error in
            // Check if any AppError-like error is retryable
            if let vendorError = error as? VendorError {
                return vendorError.isRetryable
            }
            if let budgetError = error as? BudgetError {
                return budgetError.isRetryable
            }
            if let guestError = error as? GuestError {
                return guestError.isRetryable
            }
            if let taskError = error as? TaskError {
                return taskError.isRetryable
            }
            if let timelineError = error as? TimelineError {
                return timelineError.isRetryable
            }
            if let documentError = error as? DocumentError {
                return documentError.isRetryable
            }
            if let notesError = error as? NotesError {
                return notesError.isRetryable
            }
            if let settingsError = error as? SettingsError {
                return settingsError.isRetryable
            }
            if let visualPlanningError = error as? VisualPlanningError {
                return visualPlanningError.isRetryable
            }
            if let networkError = error as? NetworkError {
                return networkError.isRetryable
            }
            return false
        }
    )

    /// Calculates the delay for a given retry attempt with exponential backoff and jitter
    /// - Parameter attempt: The attempt number (1-based)
    /// - Returns: The delay in seconds
    func delay(for attempt: Int) -> TimeInterval {
        // Exponential backoff: baseDelay * 2^(attempt-1)
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))

        // Add jitter (0-10% of the delay) to prevent thundering herd
        let jitter = Double.random(in: 0...(exponentialDelay * 0.1))

        // Cap at maxDelay
        return min(exponentialDelay + jitter, maxDelay)
    }
}

/// Executes an operation with automatic retry using the specified policy
/// - Parameters:
///   - policy: The retry policy to use (default: .standard)
///   - operation: The async operation to retry
///   - operationName: Optional name for error tracking (e.g., "fetchVendors")
/// - Returns: The result of the operation
/// - Throws: The last error if all retry attempts fail
func withRetry<T>(
    policy: RetryPolicy = .standard,
    operationName: String = "unknown",
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    var attempt = 1

    while attempt <= policy.maxAttempts {
        do {
            let result = try await operation()

            // Success! Track if we retried
            if attempt > 1, let error = lastError {
                AppLogger.network.info("Operation succeeded on attempt \(attempt)/\(policy.maxAttempts)")
                await ErrorTracker.shared.trackRetrySuccess(error, operation: operationName, attemptNumber: attempt)
            }

            return result
        } catch {
            lastError = error

            // Check if we should retry this error
            guard policy.shouldRetry(error) else {
                AppLogger.network.debug("Error not retryable, failing immediately: \(error.localizedDescription)")
                await ErrorTracker.shared.trackError(
                    error,
                    operation: operationName,
                    attemptNumber: attempt,
                    wasRetried: false,
                    outcome: .failed
                )
                throw error
            }

            // Check if we have more attempts
            if attempt < policy.maxAttempts {
                let delay = policy.delay(for: attempt)
                AppLogger.network.debug("Retry attempt \(attempt)/\(policy.maxAttempts) after \(delay)s due to: \(error.localizedDescription)")

                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                attempt += 1
            } else {
                // No more attempts
                AppLogger.network.error("All \(policy.maxAttempts) retry attempts failed", error: error)
                await ErrorTracker.shared.trackError(
                    error,
                    operation: operationName,
                    attemptNumber: attempt,
                    wasRetried: true,
                    outcome: .failed
                )
                throw error
            }
        }
    }

    // Should never reach here, but throw the last error just in case
    throw lastError ?? NetworkError.serverError(statusCode: 500)
}

/// Executes an operation with retry and provides progress updates
/// - Parameters:
///   - policy: The retry policy to use
///   - onRetry: Callback invoked before each retry with attempt number and delay
///   - operation: The async operation to retry
/// - Returns: The result of the operation
/// - Throws: The last error if all retry attempts fail
func withRetry<T>(
    policy: RetryPolicy = .standard,
    onRetry: @escaping (Int, TimeInterval) -> Void,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    var attempt = 1

    while attempt <= policy.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error

            guard policy.shouldRetry(error) else {
                throw error
            }

            if attempt < policy.maxAttempts {
                let delay = policy.delay(for: attempt)
                onRetry(attempt, delay)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                attempt += 1
            } else {
                throw error
            }
        }
    }

    throw lastError ?? NetworkError.serverError(statusCode: 500)
}
