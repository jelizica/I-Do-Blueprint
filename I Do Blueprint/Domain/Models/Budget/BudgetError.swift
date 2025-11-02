//
//  BudgetError.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/9/25.
//

import Foundation

enum BudgetError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized
    case budgetExceeded(category: String, amount: Double)
    case invalidAmount(reason: String)
    case categoryNotFound(name: String)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load budget data. Please check your connection and try again."
        case .createFailed:
            return "Couldn't create the budget item. Please try again."
        case .updateFailed:
            return "Couldn't save your budget changes. Please try again."
        case .deleteFailed:
            return "Couldn't delete the budget item. Please try again."
        case .notFound:
            return "This budget item no longer exists."
        case .validationFailed(let reason):
            return "Invalid budget data: \(reason)"
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .unauthorized:
            return "You don't have permission to modify the budget."
        case .budgetExceeded(let category, let amount):
            return "Budget exceeded for \(category) by $\(String(format: "%.2f", amount))."
        case .invalidAmount(let reason):
            return "Invalid amount: \(reason)"
        case .categoryNotFound(let name):
            return "Category '\(name)' not found in your budget."
        case .notImplemented:
            return "This feature is not yet implemented."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .unauthorized:
            return "Please sign in again or contact support."
        case .fetchFailed, .createFailed, .updateFailed, .deleteFailed:
            return "If the problem persists, please contact support."
        case .budgetExceeded:
            return "Consider adjusting your budget allocation or reducing expenses in this category."
        case .invalidAmount:
            return "Please enter a valid dollar amount greater than zero."
        case .categoryNotFound:
            return "Please select a valid budget category."
        default:
            return nil
        }
    }

    /// Indicates whether this error is transient and can be retried
    var isRetryable: Bool {
        switch self {
        case .fetchFailed, .createFailed, .updateFailed, .deleteFailed:
            return true
        case .networkUnavailable:
            return true
        case .notFound, .validationFailed, .unauthorized, .budgetExceeded, .invalidAmount, .categoryNotFound, .notImplemented:
            return false
        }
    }
}

// MARK: - AppError Conformance
import Combine

extension BudgetError: AppError {
    var errorCode: String {
        switch self {
        case .fetchFailed: return "BUDGET_FETCH_FAILED"
        case .createFailed: return "BUDGET_CREATE_FAILED"
        case .updateFailed: return "BUDGET_UPDATE_FAILED"
        case .deleteFailed: return "BUDGET_DELETE_FAILED"
        case .notFound: return "BUDGET_NOT_FOUND"
        case .validationFailed: return "BUDGET_VALIDATION_FAILED"
        case .networkUnavailable: return "BUDGET_NETWORK_UNAVAILABLE"
        case .unauthorized: return "BUDGET_UNAUTHORIZED"
        case .budgetExceeded: return "BUDGET_EXCEEDED"
        case .invalidAmount: return "BUDGET_INVALID_AMOUNT"
        case .categoryNotFound: return "BUDGET_CATEGORY_NOT_FOUND"
        case .notImplemented: return "BUDGET_NOT_IMPLEMENTED"
        }
    }

    var userMessage: String { errorDescription ?? "An error occurred." }

    var technicalDetails: String {
        switch self {
        case .fetchFailed(let underlying): return "Fetch failed: \(underlying.localizedDescription)"
        case .createFailed(let underlying): return "Create failed: \(underlying.localizedDescription)"
        case .updateFailed(let underlying): return "Update failed: \(underlying.localizedDescription)"
        case .deleteFailed(let underlying): return "Delete failed: \(underlying.localizedDescription)"
        case .notFound: return "Budget item not found"
        case .validationFailed(let reason): return "Validation failed: \(reason)"
        case .networkUnavailable: return "No network connection"
        case .unauthorized: return "Unauthorized access"
        case .budgetExceeded(let category, let amount): return "Exceeded in \(category) by \(amount)"
        case .invalidAmount(let reason): return "Invalid amount: \(reason)"
        case .categoryNotFound(let name): return "Category not found: \(name)"
        case .notImplemented: return "Feature not implemented"
        }
    }

    var recoveryOptions: [ErrorRecoveryOption] {
        switch self {
        case .networkUnavailable: return [.checkConnection, .retry, .viewOfflineData]
        case .fetchFailed: return [.retry, .checkConnection, .viewOfflineData]
        case .createFailed, .updateFailed, .deleteFailed: return [.retry, .cancel]
        case .unauthorized: return [.cancel, .contactSupport]
        case .validationFailed, .invalidAmount, .categoryNotFound, .budgetExceeded: return [.cancel]
        case .notFound: return [.cancel]
        case .notImplemented: return [.tryAgainLater]
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .networkUnavailable: return .warning
        case .fetchFailed: return .warning
        case .createFailed, .updateFailed, .deleteFailed: return .error
        case .unauthorized: return .critical
        case .validationFailed, .invalidAmount, .categoryNotFound, .budgetExceeded: return .error
        case .notFound: return .warning
        case .notImplemented: return .info
        }
    }

    var shouldReport: Bool {
        switch self {
        case .validationFailed, .invalidAmount, .budgetExceeded, .categoryNotFound: return false
        default: return true
        }
    }
}
