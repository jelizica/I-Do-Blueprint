import Foundation

/// Structured error type for the application
public enum AppError: Error, Equatable, Sendable {
    case network(NetworkError)
    case validation(ValidationError)
    case business(BusinessError)
    case unknown(String)

    public enum NetworkError: Equatable, Sendable {
        case noInternet
        case timeout
        case serverError(statusCode: Int, message: String)
        case invalidResponse
        case requestFailed(String)
    }

    public enum ValidationError: Equatable, Sendable {
        case invalidEmail
        case invalidPhoneNumber
        case requiredFieldMissing(field: String)
        case invalidDateRange
        case invalidAmount(reason: String)
        case duplicateEntry(String)
    }

    public enum BusinessError: Equatable, Sendable {
        case budgetExceeded(amount: Double, limit: Double)
        case guestCapacityReached(current: Int, max: Int)
        case invalidRSVPStatus
        case vendorNotFound(id: String)
        case insufficientPermissions
        case recordNotFound(type: String, id: String)
    }

    /// User-friendly error message
    public var userMessage: String {
        switch self {
        case .network(let error):
            return error.userMessage
        case .validation(let error):
            return error.userMessage
        case .business(let error):
            return error.userMessage
        case .unknown(let message):
            return message
        }
    }

    /// Whether this error should be retried
    public var isRetryable: Bool {
        switch self {
        case .network(let error):
            return error.isRetryable
        case .validation:
            return false
        case .business:
            return false
        case .unknown:
            return false
        }
    }

    /// Recovery suggestion for the user
    public var recoverySuggestion: String? {
        switch self {
        case .network(let error):
            return error.recoverySuggestion
        case .validation(let error):
            return error.recoverySuggestion
        case .business(let error):
            return error.recoverySuggestion
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// MARK: - NetworkError Extensions
extension AppError.NetworkError {
    var userMessage: String {
        switch self {
        case .noInternet:
            return "No internet connection available"
        case .timeout:
            return "Request timed out"
        case .serverError(_, let message):
            return message
        case .invalidResponse:
            return "Invalid server response"
        case .requestFailed(let message):
            return message
        }
    }

    var isRetryable: Bool {
        switch self {
        case .noInternet, .timeout, .serverError:
            return true
        case .invalidResponse, .requestFailed:
            return false
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noInternet:
            return "Check your internet connection and try again."
        case .timeout:
            return "The server is taking too long to respond. Try again in a moment."
        case .serverError:
            return "Our servers are experiencing issues. Please try again later."
        case .invalidResponse:
            return "Please update to the latest version of the app."
        case .requestFailed:
            return nil
        }
    }
}

// MARK: - ValidationError Extensions
extension AppError.ValidationError {
    var userMessage: String {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .requiredFieldMissing(let field):
            return "\(field) is required"
        case .invalidDateRange:
            return "Please select a valid date range"
        case .invalidAmount(let reason):
            return "Invalid amount: \(reason)"
        case .duplicateEntry(let item):
            return "\(item) already exists"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Use format: example@email.com"
        case .invalidPhoneNumber:
            return "Include area code and phone number"
        case .requiredFieldMissing:
            return "This field cannot be empty"
        case .invalidDateRange:
            return "End date must be after start date"
        case .invalidAmount:
            return "Enter a positive number"
        case .duplicateEntry:
            return "Try a different name or value"
        }
    }
}

// MARK: - BusinessError Extensions
extension AppError.BusinessError {
    var userMessage: String {
        switch self {
        case .budgetExceeded(let amount, let limit):
            return "Budget exceeded: $\(amount) over limit of $\(limit)"
        case .guestCapacityReached(let current, let max):
            return "Guest capacity reached: \(current)/\(max) guests"
        case .invalidRSVPStatus:
            return "Invalid RSVP status"
        case .vendorNotFound(let id):
            return "Vendor not found (ID: \(id))"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .recordNotFound(let type, let id):
            return "\(type) not found (ID: \(id))"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .budgetExceeded:
            return "Adjust your budget or reduce expenses to continue."
        case .guestCapacityReached:
            return "Remove guests or increase venue capacity."
        case .invalidRSVPStatus:
            return "Select a valid RSVP status (Pending, Accepted, Declined)."
        case .vendorNotFound:
            return "The vendor may have been deleted. Try refreshing."
        case .insufficientPermissions:
            return "Contact your wedding planner for access."
        case .recordNotFound:
            return "The item may have been deleted. Try refreshing."
        }
    }
}

// MARK: - Convenience Initializers
extension AppError {
    public static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }
}
