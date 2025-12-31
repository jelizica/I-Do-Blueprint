//
//  AlertPresenterProtocol.swift
//  I Do Blueprint
//
//  Protocol for alert presentation services
//

import AppKit
import Foundation

// MARK: - Protocol

/// Protocol for alert presentation services
@MainActor
protocol AlertPresenterProtocol {
    func showAlert(
        title: String,
        message: String,
        style: NSAlert.Style,
        buttons: [String]
    ) async -> String

    func showConfirmation(
        title: String,
        message: String,
        confirmButton: String,
        cancelButton: String,
        style: NSAlert.Style
    ) async -> Bool

    func showError(
        title: String,
        message: String,
        error: Error?
    ) async

    func showSuccess(
        title: String,
        message: String
    ) async

    func showToast(
        message: String,
        type: ToastType,
        duration: TimeInterval
    )

    func showSuccessToast(_ message: String, duration: TimeInterval)
    func showErrorToast(_ message: String, duration: TimeInterval)
    func showWarningToast(_ message: String, duration: TimeInterval)
    func showInfoToast(_ message: String, duration: TimeInterval)
}

// MARK: - Toast Type

enum ToastType {
    case success
    case error
    case warning
    case info
}
