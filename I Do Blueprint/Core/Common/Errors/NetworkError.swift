//
//  NetworkError.swift
//  I Do Blueprint
//
//  Centralized network error handling with retry detection
//

import Foundation

/// Network-specific errors with retry detection and user-friendly messages
enum NetworkError: LocalizedError, Equatable {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case rateLimited(retryAfter: TimeInterval?)
    case badRequest(message: String)
    case unauthorized
    case forbidden
    case notFound
    case invalidResponse
    case decodingFailed(underlying: Error)

    // Manual Equatable implementation for case with Error associated value
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.noConnection, .noConnection),
             (.timeout, .timeout),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.invalidResponse, .invalidResponse):
            return true
        case (.serverError(let lCode), .serverError(let rCode)):
            return lCode == rCode
        case (.rateLimited(let lRetry), .rateLimited(let rRetry)):
            return lRetry == rRetry
        case (.badRequest(let lMsg), .badRequest(let rMsg)):
            return lMsg == rMsg
        case (.decodingFailed, .decodingFailed):
            // Compare only the case, not the underlying error (not Equatable)
            return true
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again."
        case .serverError(let statusCode):
            return "The server encountered an error (\(statusCode)). Please try again later."
        case .rateLimited(let retryAfter):
            if let retry = retryAfter {
                return "Too many requests. Please wait \(Int(retry)) seconds before trying again."
            }
            return "Too many requests. Please try again in a moment."
        case .badRequest(let message):
            return "Invalid request: \(message)"
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .decodingFailed:
            return "Failed to process the server response."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your Wi-Fi or cellular connection, then tap 'Retry'."
        case .timeout:
            return "Try again with a better internet connection."
        case .serverError:
            return "Wait a moment and try again. If the issue persists, contact support."
        case .rateLimited:
            return "Wait a moment before making more requests."
        case .badRequest:
            return "Please check your input and try again."
        case .unauthorized:
            return "Please sign in again to continue."
        case .forbidden:
            return "Contact support if you believe you should have access."
        case .notFound:
            return "The item may have been deleted. Try refreshing."
        case .invalidResponse, .decodingFailed:
            return "If the problem persists, please contact support."
        }
    }

    /// Indicates whether this error is transient and can be retried
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .rateLimited:
            return true
        case .serverError(let code):
            // Retry on 5xx server errors, but not on 4xx client errors
            return code >= 500
        case .badRequest, .unauthorized, .forbidden, .notFound, .invalidResponse, .decodingFailed:
            return false
        }
    }

    /// Maps URLError to NetworkError
    static func from(urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        case .cannotFindHost, .cannotConnectToHost:
            return .noConnection
        default:
            return .serverError(statusCode: urlError.errorCode)
        }
    }

    /// Maps HTTP status code to NetworkError
    static func from(statusCode: Int, message: String? = nil) -> NetworkError {
        switch statusCode {
        case 400:
            return .badRequest(message: message ?? "Bad request")
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimited(retryAfter: nil)
        case 500...599:
            return .serverError(statusCode: statusCode)
        default:
            return .invalidResponse
        }
    }
}

// MARK: - AppError Conformance
extension NetworkError: AppError {
    var errorCode: String {
        switch self {
        case .noConnection: return "NETWORK_NO_CONNECTION"
        case .timeout: return "NETWORK_TIMEOUT"
        case .serverError(let code): return "NETWORK_SERVER_\(code)"
        case .rateLimited: return "NETWORK_RATE_LIMITED"
        case .badRequest: return "NETWORK_BAD_REQUEST"
        case .unauthorized: return "NETWORK_UNAUTHORIZED"
        case .forbidden: return "NETWORK_FORBIDDEN"
        case .notFound: return "NETWORK_NOT_FOUND"
        case .invalidResponse: return "NETWORK_INVALID_RESPONSE"
        case .decodingFailed: return "NETWORK_DECODING_FAILED"
        }
    }

    var userMessage: String { errorDescription ?? "A network error occurred." }

    var technicalDetails: String {
        switch self {
        case .noConnection: return "No connection"
        case .timeout: return "Timeout"
        case .serverError(let code): return "Server error code=\(code)"
        case .rateLimited(let retry): return "Rate limited retryAfter=\(String(describing: retry))"
        case .badRequest(let message): return "Bad request: \(message)"
        case .unauthorized: return "Unauthorized"
        case .forbidden: return "Forbidden"
        case .notFound: return "Not found"
        case .invalidResponse: return "Invalid response"
        case .decodingFailed(let err): return "Decoding failed: \(err.localizedDescription)"
        }
    }

    var recoveryOptions: [ErrorRecoveryOption] {
        switch self {
        case .noConnection: return [.checkConnection, .retry, .viewOfflineData]
        case .timeout: return [.retry, .checkConnection]
        case .rateLimited(let retry):
            if let seconds = retry { return [.tryAgainLater] }
            return [.tryAgainLater]
        case .serverError: return [.tryAgainLater, .retry]
        case .badRequest: return [.cancel]
        case .unauthorized: return [.cancel, .contactSupport]
        case .forbidden: return [.contactSupport]
        case .notFound: return [.cancel]
        case .invalidResponse, .decodingFailed: return [.tryAgainLater]
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .noConnection, .timeout, .rateLimited: return .warning
        case .serverError: return .error
        case .badRequest, .invalidResponse, .decodingFailed: return .error
        case .unauthorized, .forbidden: return .critical
        case .notFound: return .warning
        }
    }

    var shouldReport: Bool {
        switch self {
        case .badRequest: return false
        default: return true
        }
    }
}
