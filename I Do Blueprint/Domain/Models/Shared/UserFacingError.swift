//
//  UserFacingError.swift
//  I Do Blueprint
//
//  Maps technical errors to user-friendly messages with recovery suggestions
//

import Foundation

/// Maps technical errors to user-friendly messages with recovery suggestions
enum UserFacingError: LocalizedError {
    case networkUnavailable
    case serverError
    case timeout
    case validationFailed([String])
    case notFound(String)
    case unauthorized
    case rateLimited
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        case .serverError:
            return "Server error. Please try again in a few moments."
        case .timeout:
            return "Request timed out. Please check your connection and try again."
        case .validationFailed(let errors):
            return "Please fix the following:\n• \(errors.joined(separator: "\n• "))"
        case .notFound(let item):
            return "\(item) not found. It may have been deleted."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your Wi-Fi or cellular connection, then tap 'Retry'."
        case .serverError:
            return "Wait a moment and try again. If the problem persists, contact support."
        case .timeout:
            return "Try again with a better internet connection."
        case .validationFailed:
            return "Correct the errors and try again."
        case .notFound:
            return "Refresh the list and try again."
        case .unauthorized:
            return "Sign in again to continue."
        case .rateLimited:
            return "Wait a moment before making more requests."
        case .unknown:
            return "Try again or contact support if the problem persists."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .serverError, .timeout, .rateLimited:
            return true
        case .validationFailed, .notFound, .unauthorized, .unknown:
            return false
        }
    }

    /// Maps any error to a user-facing error
    static func from(_ error: Error) -> UserFacingError {
        // Check for NetworkError (already exists)
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noConnection:
                return .networkUnavailable
            case .timeout:
                return .timeout
            case .serverError:
                return .serverError
            case .rateLimited:
                return .rateLimited
            case .unauthorized:
                return .unauthorized
            case .notFound:
                return .notFound("Resource")
            case .badRequest, .forbidden, .invalidResponse, .decodingFailed:
                return .serverError
            }
        }

        // Check for URLError
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .timeout
            default:
                return .serverError
            }
        }

        // Check for domain errors (BudgetError, GuestError, etc.)
        // These are already wrapped, so treat as server errors
        let errorString = String(describing: error)
        if errorString.contains("BudgetError") ||
           errorString.contains("GuestError") ||
           errorString.contains("VendorError") ||
           errorString.contains("TaskError") {
            return .serverError
        }

        return .unknown(error)
    }
}
