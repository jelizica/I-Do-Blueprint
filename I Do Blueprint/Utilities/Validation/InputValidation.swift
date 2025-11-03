//
//  InputValidation.swift
//  I Do Blueprint
//
//  Provides safe input validation utilities to prevent force unwrapping
//

import Foundation

/// Validation errors that can occur during input validation
enum ValidationError: LocalizedError {
    case invalidAmount(String)
    case invalidURL(String)
    case missingRequiredField(String)
    case amountTooLarge
    case amountNegative

    var errorDescription: String? {
        switch self {
        case .invalidAmount(let value):
            return "'\(value)' is not a valid amount"
        case .invalidURL(let value):
            return "'\(value)' is not a valid URL"
        case .missingRequiredField(let field):
            return "\(field) is required"
        case .amountTooLarge:
            return "Amount exceeds maximum allowed value"
        case .amountNegative:
            return "Amount must be positive"
        }
    }
}

/// Provides safe input validation methods
struct InputValidator {

    // MARK: - Amount Validation

    /// Validates a string input as a monetary amount
    /// - Parameter input: The string to validate
    /// - Returns: Result containing the validated Double or a ValidationError
    static func validateAmount(_ input: String) -> Result<Double, ValidationError> {
        // Trim whitespace
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if empty
        guard !trimmed.isEmpty else {
            return .failure(.invalidAmount(input))
        }

        // Try to convert to Double
        guard let value = Double(trimmed) else {
            return .failure(.invalidAmount(input))
        }

        // Check if positive
        guard value > 0 else {
            return .failure(.amountNegative)
        }

        // Check maximum (1 million)
        guard value <= 1_000_000 else {
            return .failure(.amountTooLarge)
        }

        return .success(value)
    }

    /// Safely converts a string to a Double, returning nil if invalid
    /// - Parameter input: The string to convert
    /// - Returns: Optional Double value
    static func safeDoubleConversion(_ input: String) -> Double? {
        if case .success(let value) = validateAmount(input) {
            return value
        }
        return nil
    }

    // MARK: - URL Validation

    /// Validates a string input as a URL
    /// - Parameter input: The string to validate
    /// - Returns: Result containing the validated URL or a ValidationError
    static func validateURL(_ input: String) -> Result<URL, ValidationError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.invalidURL(input))
        }

        guard let url = URL(string: trimmed) else {
            return .failure(.invalidURL(input))
        }

        return .success(url)
    }

    /// Safely converts a string to a URL, returning nil if invalid
    /// - Parameter input: The string to convert
    /// - Returns: Optional URL value
    static func safeURLConversion(_ input: String) -> URL? {
        if case .success(let url) = validateURL(input) {
            return url
        }
        return nil
    }

    // MARK: - String Validation

    /// Validates that a string is not empty after trimming whitespace
    /// - Parameters:
    ///   - input: The string to validate
    ///   - fieldName: The name of the field for error messages
    /// - Returns: Result containing the trimmed string or a ValidationError
    static func validateNonEmpty(_ input: String, fieldName: String) -> Result<String, ValidationError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.missingRequiredField(fieldName))
        }

        return .success(trimmed)
    }
}
