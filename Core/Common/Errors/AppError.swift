import Foundation
import Combine

// Base protocol for all app errors
public protocol AppError: LocalizedError {
    // Unique error code for tracking and analytics
    var errorCode: String { get }
    // User-friendly message to present in UI
    var userMessage: String { get }
    // Technical details to aid debugging/logging
    var technicalDetails: String { get }
    // Suggested recovery options for the user
    var recoveryOptions: [ErrorRecoveryOption] { get }
    // Severity for prioritization and UI styling
    var severity: ErrorSeverity { get }
    // Whether to report to crash/error tracking
    var shouldReport: Bool { get }
}

// A generic wrapper for unknown errors conforming to AppError
public struct GenericError: AppError {
    public let underlying: Error
    public let context: ErrorContext

    public init(underlying: Error, context: ErrorContext) {
        self.underlying = underlying
        self.context = context
    }

    public var errorCode: String { "GENERIC_ERROR" }

    public var userMessage: String {
        "Something went wrong. Please try again."
    }

    public var technicalDetails: String {
        "Underlying: \(underlying.localizedDescription) | op=\(context.operation) feature=\(context.feature)"
    }

    public var recoveryOptions: [ErrorRecoveryOption] { [.retry, .tryAgainLater, .contactSupport] }

    public var severity: ErrorSeverity { .error }

    public var shouldReport: Bool { true }
}