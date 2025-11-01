//
//  StoreErrorHandling.swift
//  I Do Blueprint
//
//  Extension to provide consistent error handling across all stores
//

import Foundation
import Sentry
import SwiftUI

/// Extension to provide consistent error handling across all stores
extension ObservableObject where Self: AnyObject {
    
    /// Handle an error with user-facing feedback, Sentry tracking, and optional retry
    @MainActor
    func handleError(
        _ error: Error,
        operation: String,
        context: [String: Any]? = nil,
        retry: (() async -> Void)? = nil
    ) async {
        let userError = UserFacingError.from(error)
        
        // Log the technical error
        AppLogger.database.error("Error in \(operation)", error: error)
        
        // Capture error to Sentry with context
        var sentryContext = context ?? [:]
        sentryContext["operation"] = operation
        sentryContext["timestamp"] = Date().ISO8601Format()
        sentryContext["errorType"] = String(describing: type(of: error))
        
        SentryService.shared.captureError(error, context: sentryContext)
        
        // Add breadcrumb for debugging
        SentryService.shared.addBreadcrumb(
            message: "Error in \(operation): \(error.localizedDescription)",
            category: "error",
            level: .error,
            data: sentryContext
        )
        
        // Show user-facing error with retry option
        await AlertPresenter.shared.showUserFacingError(userError, retryAction: retry)
    }
    
    /// Show success feedback for an operation
    @MainActor
    func showSuccess(_ message: String) {
        AlertPresenter.shared.showSuccessToast(message)
    }
    
    /// Add a breadcrumb before starting an operation (for debugging context)
    @MainActor
    func addOperationBreadcrumb(
        _ operation: String,
        category: String,
        data: [String: Any]? = nil
    ) {
        SentryService.shared.addBreadcrumb(
            message: "Starting: \(operation)",
            category: category,
            level: .info,
            data: data
        )
    }
}
