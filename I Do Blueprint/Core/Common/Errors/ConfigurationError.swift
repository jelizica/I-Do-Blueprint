//
//  ConfigurationError.swift
//  I Do Blueprint
//
//  Error types for configuration and initialization failures
//

import Foundation

/// Errors that can occur during app configuration and initialization
enum ConfigurationError: LocalizedError {
    case configFileNotFound
    case configFileUnreadable
    case missingSupabaseURL
    case missingSupabaseAnonKey
    case invalidURLFormat(String)
    case securityViolation(String)
    // JES-199 additions
    case missingSentryDSN
    case invalidSentryDSN

    var errorDescription: String? {
        switch self {
        case .configFileNotFound:
            return "Configuration file (Config.plist) not found in app bundle"
        case .configFileUnreadable:
            return "Configuration file exists but could not be read"
        case .missingSupabaseURL:
            return "SUPABASE_URL not found in configuration"
        case .missingSupabaseAnonKey:
            return "SUPABASE_ANON_KEY not found in configuration"
        case .invalidURLFormat(let url):
            return "Invalid Supabase URL format: \(url)"
        case .securityViolation(let message):
            return "Security violation: \(message)"
        case .missingSentryDSN:
            return "Sentry DSN not found in configuration"
        case .invalidSentryDSN:
            return "Invalid Sentry DSN format in configuration"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .configFileNotFound, .configFileUnreadable:
            return "Please reinstall the app or contact support"
        case .missingSupabaseURL, .missingSupabaseAnonKey:
            return "The app configuration is incomplete. Please contact support"
        case .invalidURLFormat:
            return "The Supabase URL in the configuration is invalid"
        case .securityViolation:
            return "This is a critical security issue. Please contact the developer immediately"
        case .missingSentryDSN:
            return "The SENTRY_DSN key is missing from Config.plist"
        case .invalidSentryDSN:
            return "The SENTRY_DSN value does not appear to be a valid URL"
        }
    }

    var failureReason: String? {
        switch self {
        case .configFileNotFound:
            return "The Config.plist file is missing from the application bundle"
        case .configFileUnreadable:
            return "The Config.plist file is corrupted or has invalid format"
        case .missingSupabaseURL:
            return "The SUPABASE_URL key is missing from Config.plist"
        case .missingSupabaseAnonKey:
            return "The SUPABASE_ANON_KEY key is missing from Config.plist"
        case .invalidURLFormat(let url):
            return "The URL '\(url)' is not a valid URL format"
        case .securityViolation(let message):
            return message
        case .missingSentryDSN:
            return "Sentry DSN not configured. Error reporting will not function."
        case .invalidSentryDSN:
            return "Sentry DSN does not conform to expected URL format."
        }
    }
}

/// Errors that can occur during data model conversion
enum ConversionError: LocalizedError {
    case invalidUUID(String)
    case missingRequiredField(String)
    case invalidDateFormat(String)
    case invalidEnumValue(String, expectedType: String)

    var errorDescription: String? {
        switch self {
        case .invalidUUID(let value):
            return "Invalid UUID format: \(value)"
        case .missingRequiredField(let field):
            return "Required field '\(field)' is missing"
        case .invalidDateFormat(let value):
            return "Invalid date format: \(value)"
        case .invalidEnumValue(let value, let type):
            return "Invalid value '\(value)' for type \(type)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidUUID:
            return "Ensure the UUID is in the correct format (e.g., 550e8400-e29b-41d4-a716-446655440000)"
        case .missingRequiredField(let field):
            return "Provide a value for the required field '\(field)'"
        case .invalidDateFormat:
            return "Use ISO8601 date format (e.g., 2025-01-18T12:00:00Z)"
        case .invalidEnumValue(_, let type):
            return "Use a valid value for \(type)"
        }
    }
}
