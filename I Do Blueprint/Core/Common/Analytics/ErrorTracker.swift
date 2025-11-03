//
//  ErrorTracker.swift
//  I Do Blueprint
//
//  Error tracking and analytics for monitoring error patterns
//

import Foundation
import Sentry

/// Error tracking and analytics for monitoring error patterns and trends
actor ErrorTracker {

    // MARK: - Singleton

    static let shared = ErrorTracker()

    // MARK: - Properties

    private var errorHistory: [ErrorEvent] = []
    private let maxHistorySize = 100
    private let logger = AppLogger.analytics

    // MARK: - Error Event

    struct ErrorEvent: Codable {
        let id: UUID
        let timestamp: Date
        let errorType: String
        let operation: String
        let isRetryable: Bool
        let attemptNumber: Int
        let wasRetried: Bool
        let finalOutcome: ErrorOutcome
        let errorDescription: String
        let contextInfo: [String: String]

        enum ErrorOutcome: String, Codable {
            case resolved = "resolved"    // Error was retried and succeeded
            case failed = "failed"        // Error was not retryable or all retries failed
            case cached = "cached"        // Used cached data as fallback
        }
    }

    // MARK: - Analytics Metrics

    struct ErrorMetrics {
        let totalErrors: Int
        let retryableErrors: Int
        let nonRetryableErrors: Int
        let resolvedViaRetry: Int
        let resolvedViaCache: Int
        let failedErrors: Int
        let errorsByType: [String: Int]
        let errorsByOperation: [String: Int]
        let averageRetriesBeforeSuccess: Double
        let retrySuccessRate: Double
    }

    // MARK: - Initialization

    private init() {
        logger.info("ErrorTracker initialized")
    }

    // MARK: - Public Methods

    /// Track an error occurrence
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - operation: The operation that failed (e.g., "fetchVendors", "createGuest")
    ///   - attemptNumber: The attempt number (1 for first attempt)
    ///   - wasRetried: Whether this error will be retried
    ///   - outcome: The final outcome of the error
    ///   - context: Additional context information
    func trackError(
        _ error: Error,
        operation: String,
        attemptNumber: Int = 1,
        wasRetried: Bool = false,
        outcome: ErrorEvent.ErrorOutcome = .failed,
        context: [String: String] = [:]
    ) async {
        let errorType = String(describing: type(of: error))
        let isRetryable = determineIfRetryable(error)

        let event = ErrorEvent(
            id: UUID(),
            timestamp: Date(),
            errorType: errorType,
            operation: operation,
            isRetryable: isRetryable,
            attemptNumber: attemptNumber,
            wasRetried: wasRetried,
            finalOutcome: outcome,
            errorDescription: error.localizedDescription,
            contextInfo: context
        )

        // Add to history
        errorHistory.append(event)

        // Maintain max history size
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst(errorHistory.count - maxHistorySize)
        }

        // Log the error
        logger.info("Error tracked: \(errorType) in \(operation) (attempt \(attemptNumber), outcome: \(outcome.rawValue))")

        // Send to Sentry for remote monitoring
        await sendToSentry(event: event, error: error)
    }

    /// Send error event to Sentry for prevention monitoring
    private func sendToSentry(event: ErrorEvent, error: Error) async {
        await MainActor.run {
            var sentryContext: [String: Any] = [
                "operation": event.operation,
                "attempt_number": event.attemptNumber,
                "is_retryable": event.isRetryable,
                "was_retried": event.wasRetried,
                "outcome": event.finalOutcome.rawValue,
                "error_type": event.errorType
            ]

            // Add custom context
            for (key, value) in event.contextInfo {
                sentryContext[key] = value
            }

            // Determine Sentry level based on outcome
            let sentryLevel: SentryLevel = switch event.finalOutcome {
            case .resolved: .info
            case .cached: .warning
            case .failed: .error
            }

            // Add breadcrumb for error pattern tracking
            SentryService.shared.addBreadcrumb(
                message: "Error in \(event.operation)",
                category: "error_pattern",
                level: sentryLevel,
                data: [
                    "error_type": event.errorType,
                    "retryable": event.isRetryable,
                    "attempt": event.attemptNumber
                ]
            )

            // Capture error to Sentry
            SentryService.shared.captureError(
                error,
                context: sentryContext,
                level: sentryLevel
            )
        }
    }

    /// Track a successful retry
    /// - Parameters:
    ///   - error: The error that was retried
    ///   - operation: The operation that was retried
    ///   - attemptNumber: The attempt number that succeeded
    func trackRetrySuccess(
        _ error: Error,
        operation: String,
        attemptNumber: Int
    ) async {
        await trackError(
            error,
            operation: operation,
            attemptNumber: attemptNumber,
            wasRetried: true,
            outcome: .resolved,
            context: ["recovery": "retry"]
        )
    }

    /// Track fallback to cached data
    /// - Parameters:
    ///   - error: The error that caused the fallback
    ///   - operation: The operation that fell back to cache
    func trackCacheFallback(
        _ error: Error,
        operation: String
    ) async {
        await trackError(
            error,
            operation: operation,
            attemptNumber: 1,
            wasRetried: false,
            outcome: .cached,
            context: ["recovery": "cache"]
        )
    }

    /// Get error metrics for analysis
    /// - Parameter timeframe: Optional timeframe to analyze (nil for all history)
    /// - Returns: Error metrics
    func getMetrics(since: Date? = nil) async -> ErrorMetrics {
        let events = since.map { cutoff in
            errorHistory.filter { $0.timestamp >= cutoff }
        } ?? errorHistory

        guard !events.isEmpty else {
            return ErrorMetrics(
                totalErrors: 0,
                retryableErrors: 0,
                nonRetryableErrors: 0,
                resolvedViaRetry: 0,
                resolvedViaCache: 0,
                failedErrors: 0,
                errorsByType: [:],
                errorsByOperation: [:],
                averageRetriesBeforeSuccess: 0,
                retrySuccessRate: 0
            )
        }

        let totalErrors = events.count
        let retryableErrors = events.filter { $0.isRetryable }.count
        let nonRetryableErrors = totalErrors - retryableErrors
        let resolvedViaRetry = events.filter { $0.finalOutcome == .resolved }.count
        let resolvedViaCache = events.filter { $0.finalOutcome == .cached }.count
        let failedErrors = events.filter { $0.finalOutcome == .failed }.count

        // Group by error type
        var errorsByType: [String: Int] = [:]
        for event in events {
            errorsByType[event.errorType, default: 0] += 1
        }

        // Group by operation
        var errorsByOperation: [String: Int] = [:]
        for event in events {
            errorsByOperation[event.operation, default: 0] += 1
        }

        // Calculate average retries before success
        let resolvedEvents = events.filter { $0.finalOutcome == .resolved }
        let averageRetries = resolvedEvents.isEmpty ? 0 :
            Double(resolvedEvents.map { $0.attemptNumber }.reduce(0, +)) / Double(resolvedEvents.count)

        // Calculate retry success rate
        let retriedErrors = events.filter { $0.wasRetried || $0.attemptNumber > 1 }
        let retrySuccessRate = retriedErrors.isEmpty ? 0 :
            Double(resolvedViaRetry) / Double(retriedErrors.count) * 100

        return ErrorMetrics(
            totalErrors: totalErrors,
            retryableErrors: retryableErrors,
            nonRetryableErrors: nonRetryableErrors,
            resolvedViaRetry: resolvedViaRetry,
            resolvedViaCache: resolvedViaCache,
            failedErrors: failedErrors,
            errorsByType: errorsByType,
            errorsByOperation: errorsByOperation,
            averageRetriesBeforeSuccess: averageRetries,
            retrySuccessRate: retrySuccessRate
        )
    }

    /// Get recent error events
    /// - Parameter limit: Maximum number of events to return
    /// - Returns: Recent error events
    func getRecentErrors(limit: Int = 10) async -> [ErrorEvent] {
        Array(errorHistory.suffix(limit).reversed())
    }

    /// Clear error history
    func clearHistory() async {
        errorHistory.removeAll()
        logger.info("Error history cleared")
    }

    // MARK: - Private Helpers

    private func determineIfRetryable(_ error: Error) -> Bool {
        // Check if error conforms to domain error with isRetryable
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

        // URLError fallback
        if let urlError = error as? URLError {
            return NetworkError.from(urlError: urlError).isRetryable
        }

        return false
    }
}
