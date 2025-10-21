//
//  AppLogger+Sentry.swift
//  I Do Blueprint
//
//  Extension to integrate Sentry error tracking with AppLogger
//

import Foundation
import Sentry

extension AppLogger {
    
    /// Log an error and send it to Sentry
    /// - Parameters:
    ///   - message: Error message
    ///   - error: The error object
    ///   - context: Additional context for Sentry
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    func errorWithSentry(
        _ message: String,
        error: Error,
        context: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Log to AppLogger as usual
        self.error(message, error: error, file: file, function: function)
        
        // Also send to Sentry with additional context
        var sentryContext = context ?? [:]
        sentryContext["file"] = file
        sentryContext["function"] = function
        sentryContext["line"] = line
        sentryContext["message"] = message
        
        SentryService.shared.captureError(
            error,
            context: sentryContext,
            level: .error
        )
    }
    
    /// Log a warning and send it to Sentry
    /// - Parameters:
    ///   - message: Warning message
    ///   - context: Additional context for Sentry
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    func warningWithSentry(
        _ message: String,
        context: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Log to AppLogger as usual
        self.warning(message, file: file, function: function)
        
        // Also send to Sentry with additional context
        var sentryContext = context ?? [:]
        sentryContext["file"] = file
        sentryContext["function"] = function
        sentryContext["line"] = line
        
        SentryService.shared.captureMessage(
            message,
            context: sentryContext,
            level: .warning
        )
    }
}

// MARK: - Convenience Methods for Common Scenarios

extension AppLogger {
    
    /// Log a repository error with Sentry tracking
    /// - Parameters:
    ///   - operation: The operation that failed (e.g., "fetchGuests", "createExpense")
    ///   - error: The error object
    ///   - additionalContext: Any additional context
    func repositoryError(
        operation: String,
        error: Error,
        additionalContext: [String: Any]? = nil
    ) {
        var context = additionalContext ?? [:]
        context["operation"] = operation
        context["errorType"] = String(describing: type(of: error))
        
        errorWithSentry(
            "Repository operation '\(operation)' failed",
            error: error,
            context: context
        )
    }
    
    /// Log a network error with Sentry tracking
    /// - Parameters:
    ///   - endpoint: The API endpoint that failed
    ///   - error: The error object
    ///   - statusCode: HTTP status code if available
    func networkError(
        endpoint: String,
        error: Error,
        statusCode: Int? = nil
    ) {
        var context: [String: Any] = [
            "endpoint": endpoint,
            "errorType": String(describing: type(of: error))
        ]
        
        if let statusCode = statusCode {
            context["statusCode"] = statusCode
        }
        
        errorWithSentry(
            "Network request to '\(endpoint)' failed",
            error: error,
            context: context
        )
    }
    
    /// Log a data parsing error with Sentry tracking
    /// - Parameters:
    ///   - dataType: The type of data being parsed
    ///   - error: The error object
    func parsingError(
        dataType: String,
        error: Error
    ) {
        let context: [String: Any] = [
            "dataType": dataType,
            "errorType": String(describing: type(of: error))
        ]
        
        errorWithSentry(
            "Failed to parse \(dataType)",
            error: error,
            context: context
        )
    }
}
