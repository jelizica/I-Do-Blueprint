//
//  SettingsError.swift
//  My Wedding Planning App
//
//  Domain-specific error types for settings operations
//

import Foundation

enum SettingsError: LocalizedError {
    case fetchFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case categoryCreateFailed(underlying: Error)
    case categoryUpdateFailed(underlying: Error)
    case categoryDeleteFailed(underlying: Error)
    case notFound
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load settings. Please check your connection and try again."

        case .updateFailed:
            return "Couldn't save your settings. Please try again."

        case .categoryCreateFailed:
            return "Couldn't create the vendor category. Please try again."

        case .categoryUpdateFailed:
            return "Couldn't update the vendor category. Please try again."

        case .categoryDeleteFailed:
            return "Couldn't delete the vendor category. Please try again."

        case .notFound:
            return "Settings not found. Please refresh and try again."

        case .validationFailed(let reason):
            return "Invalid input: \(reason)"

        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."

        case .unauthorized:
            return "You don't have permission to modify settings. Please sign in again."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."

        case .unauthorized:
            return "Please sign in again or contact support."

        case .fetchFailed, .updateFailed, .categoryCreateFailed, .categoryUpdateFailed, .categoryDeleteFailed:
            return "If the problem persists, please contact support."

        default:
            return nil
        }
    }

    /// Indicates whether this error is transient and can be retried
    var isRetryable: Bool {
        switch self {
        case .fetchFailed, .updateFailed, .categoryCreateFailed, .categoryUpdateFailed, .categoryDeleteFailed:
            return true
        case .networkUnavailable:
            return true
        case .notFound, .validationFailed, .unauthorized:
            return false
        }
    }
}
