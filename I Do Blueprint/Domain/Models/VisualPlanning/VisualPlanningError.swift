//
//  VisualPlanningError.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/9/25.
//

import Foundation

enum VisualPlanningError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound(id: UUID)
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized
    case imageUploadFailed(underlying: Error)
    case imageTooLarge(maxSize: Int)
    case unsupportedImageFormat(format: String)
    case invalidLayout(reason: String)
    case seatingConflict(reason: String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load visual planning data. Please check your connection and try again."
        case .createFailed:
            return "Couldn't create the visual planning item. Please try again."
        case .updateFailed:
            return "Couldn't save your visual planning changes. Please try again."
        case .deleteFailed:
            return "Couldn't delete the visual planning item. Please try again."
        case .notFound:
            return "This visual planning item no longer exists."
        case .validationFailed(let reason):
            return "Invalid visual planning data: \(reason)"
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .unauthorized:
            return "You don't have permission to modify visual planning."
        case .imageUploadFailed:
            return "Couldn't upload the image. Please try again."
        case .imageTooLarge(let maxSize):
            return "Image is too large. Maximum size is \(maxSize) MB."
        case .unsupportedImageFormat(let format):
            return "Image format '\(format)' is not supported."
        case .invalidLayout(let reason):
            return "Invalid layout configuration: \(reason)"
        case .seatingConflict(let reason):
            return "Seating conflict detected: \(reason)"
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
        case .imageUploadFailed:
            return "Check your internet connection and try uploading again."
        case .imageTooLarge:
            return "Please compress the image or use a smaller version."
        case .unsupportedImageFormat:
            return "Please convert the image to JPG or PNG format."
        case .invalidLayout:
            return "Please review the layout configuration and fix any errors."
        case .seatingConflict:
            return "Review the seating arrangement and resolve conflicts."
        default:
            return nil
        }
    }
}
