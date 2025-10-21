//
//  StoreErrorHandling.swift
//  I Do Blueprint
//
//  Extension to provide consistent error handling across all stores
//

import Foundation
import SwiftUI

/// Extension to provide consistent error handling across all stores
extension ObservableObject where Self: AnyObject {
    
    /// Handle an error with user-facing feedback and optional retry
    @MainActor
    func handleError(
        _ error: Error,
        operation: String,
        retry: (() async -> Void)? = nil
    ) async {
        let userError = UserFacingError.from(error)
        
        // Log the technical error
        AppLogger.database.error("Error in \(operation)", error: error)
        
        // Show user-facing error with retry option
        await AlertPresenter.shared.showUserFacingError(userError, retryAction: retry)
    }
    
    /// Show success feedback for an operation
    @MainActor
    func showSuccess(_ message: String) {
        AlertPresenter.shared.showSuccessToast(message)
    }
}
