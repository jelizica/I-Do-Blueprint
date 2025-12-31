//
//  AlertPresenter.swift
//  I Do Blueprint
//
//  Centralized alert and toast presentation service (coordinator)
//

import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - Alert Configuration

struct AlertConfig: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let style: NSAlert.Style
    let buttons: [String]
    let completion: ((String) -> Void)?
}

// MARK: - Alert Presenter (Coordinator)

/// Service for presenting alerts and notifications to the user
/// Coordinates specialized alert services for different alert types
@MainActor
class AlertPresenter: ObservableObject, AlertPresenterProtocol {
    static let shared = AlertPresenter()

    @Published var currentAlert: AlertConfig?
    
    var currentToast: ToastConfig? {
        get { ToastService.shared.currentToast }
        set { ToastService.shared.currentToast = newValue }
    }

    private let errorService = ErrorAlertService.shared
    private let confirmationService = ConfirmationAlertService.shared
    private let toastService = ToastService.shared
    private let progressService = ProgressAlertService.shared

    private init() {}

    // MARK: - Alert Presentation

    /// Present a standard alert dialog asynchronously with sheet-based presentation
    func showAlert(
        title: String,
        message: String,
        style: NSAlert.Style = .informational,
        buttons: [String] = ["OK"]
    ) async -> String {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style

        for buttonTitle in buttons {
            alert.addButton(withTitle: buttonTitle)
        }

        guard let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first else {
            return buttons.first ?? "OK"
        }

        return await withCheckedContinuation { continuation in
            alert.beginSheetModal(for: window) { response in
                let buttonIndex = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
                if buttonIndex >= 0 && buttonIndex < buttons.count {
                    continuation.resume(returning: buttons[buttonIndex])
                } else {
                    continuation.resume(returning: buttons.first ?? "OK")
                }
            }
        }
    }

    /// Present a standard alert dialog with callback-based completion (deprecated)
    @available(*, deprecated, message: "Use async version instead")
    func showAlert(
        title: String,
        message: String,
        style: NSAlert.Style = .informational,
        buttons: [String] = ["OK"],
        completion: ((String) -> Void)? = nil
    ) {
        Task {
            let result = await showAlert(title: title, message: message, style: style, buttons: buttons)
            completion?(result)
        }
    }

    // MARK: - Delegation to Specialized Services

    /// Present a confirmation alert with Yes/No buttons asynchronously
    func showConfirmation(
        title: String,
        message: String,
        confirmButton: String = "Yes",
        cancelButton: String = "No",
        style: NSAlert.Style = .warning
    ) async -> Bool {
        await confirmationService.showConfirmation(
            title: title,
            message: message,
            confirmButton: confirmButton,
            cancelButton: cancelButton,
            style: style
        )
    }

    /// Present an error alert asynchronously
    func showError(
        title: String = "Error",
        message: String,
        error: Error? = nil
    ) async {
        await errorService.showError(title: title, message: message, error: error)
    }

    /// Show an error with optional retry action
    func showError(
        title: String = "Error",
        message: String,
        retryAction: (() async -> Void)? = nil
    ) async {
        await errorService.showError(title: title, message: message, retryAction: retryAction)
    }

    /// Show a network error with automatic retry
    func showNetworkError(
        operation: String,
        retry: @escaping () async -> Void
    ) async {
        await errorService.showNetworkError(operation: operation, retry: retry)
    }

    /// Show a user-facing error with optional retry
    func showUserFacingError(
        _ error: UserFacingError,
        retryAction: (() async -> Void)? = nil
    ) async {
        await errorService.showUserFacingError(error, retryAction: retryAction)
    }

    /// Present a success alert asynchronously
    func showSuccess(
        title: String = "Success",
        message: String
    ) async {
        _ = await showAlert(
            title: title,
            message: message,
            style: .informational,
            buttons: ["OK"]
        )
    }

    // MARK: - Toast Notifications

    /// Show a non-blocking toast notification
    func showToast(
        message: String,
        type: ToastType = .info,
        duration: TimeInterval = 3.0
    ) {
        toastService.showToast(message: message, type: type, duration: duration)
    }

    /// Show a success toast
    func showSuccessToast(_ message: String, duration: TimeInterval = 3.0) {
        toastService.showSuccessToast(message, duration: duration)
    }

    /// Show an error toast
    func showErrorToast(_ message: String, duration: TimeInterval = 4.0) {
        toastService.showErrorToast(message, duration: duration)
    }

    /// Show a warning toast
    func showWarningToast(_ message: String, duration: TimeInterval = 3.5) {
        toastService.showWarningToast(message, duration: duration)
    }

    /// Show an info toast
    func showInfoToast(_ message: String, duration: TimeInterval = 3.0) {
        toastService.showInfoToast(message, duration: duration)
    }

    // MARK: - Progress Operations

    /// Show a progress alert for long-running operations
    func showProgress(
        title: String,
        message: String,
        operation: @escaping () async throws -> Void
    ) async {
        await progressService.showProgress(title: title, message: message, operation: operation)
    }
}
