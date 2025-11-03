//
//  OnboardingError.swift
//  I Do Blueprint
//
//  Domain-specific errors for onboarding operations
//

import Foundation

enum OnboardingError: Error, LocalizedError {
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case tenantContextMissing
    case invalidStep(OnboardingStep)
    case progressNotFound
    case alreadyCompleted
    case validationFailed(String)
    case importFailed(underlying: Error)
    case fileReadFailed(underlying: Error)
    case unsupportedFileFormat(String)
    case parsingFailed(String)
    case duplicateDetectionFailed(underlying: Error)
    case rollbackFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch onboarding progress: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save onboarding progress: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update onboarding progress: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete onboarding progress: \(error.localizedDescription)"
        case .tenantContextMissing:
            return "No couple selected. Please sign in."
        case .invalidStep(let step):
            return "Invalid onboarding step: \(step.rawValue)"
        case .progressNotFound:
            return "Onboarding progress not found. Please start onboarding again."
        case .alreadyCompleted:
            return "Onboarding has already been completed."
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .importFailed(let error):
            return "Import failed: \(error.localizedDescription)"
        case .fileReadFailed(let error):
            return "Failed to read file: \(error.localizedDescription)"
        case .unsupportedFileFormat(let format):
            return "Unsupported file format: \(format). Please use CSV or XLSX files."
        case .parsingFailed(let message):
            return "Failed to parse file: \(message)"
        case .duplicateDetectionFailed(let error):
            return "Failed to detect duplicates: \(error.localizedDescription)"
        case .rollbackFailed(let error):
            return "Failed to rollback import: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed, .saveFailed, .updateFailed, .deleteFailed:
            return "Please check your internet connection and try again."
        case .tenantContextMissing:
            return "Please sign in to continue."
        case .invalidStep:
            return "Please restart the onboarding process."
        case .progressNotFound:
            return "Start onboarding from the beginning."
        case .alreadyCompleted:
            return "You can access settings to modify your preferences."
        case .validationFailed:
            return "Please correct the highlighted fields and try again."
        case .importFailed, .fileReadFailed:
            return "Please check the file and try again."
        case .unsupportedFileFormat:
            return "Please export your data as CSV or XLSX and try again."
        case .parsingFailed:
            return "Please check the file format and ensure it matches the expected structure."
        case .duplicateDetectionFailed:
            return "Please try the import again or contact support."
        case .rollbackFailed:
            return "Please contact support for assistance."
        }
    }
}
