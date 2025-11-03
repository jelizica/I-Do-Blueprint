//
//  AlertPresenter.swift
//  I Do Blueprint
//
//  Centralized alert and toast presentation service
//

import AppKit
import Combine
import Foundation
import SwiftUI

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

// MARK: - Implementation

/// Service for presenting alerts and notifications to the user
@MainActor
class AlertPresenter: ObservableObject, AlertPresenterProtocol {
    static let shared = AlertPresenter()

    @Published var currentAlert: AlertConfig?
    @Published var currentToast: ToastConfig?

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

    /// Present a confirmation alert with Yes/No buttons asynchronously
    func showConfirmation(
        title: String,
        message: String,
        confirmButton: String = "Yes",
        cancelButton: String = "No",
        style: NSAlert.Style = .warning
    ) async -> Bool {
        let result = await showAlert(
            title: title,
            message: message,
            style: style,
            buttons: [confirmButton, cancelButton]
        )
        return result == confirmButton
    }

    /// Present a confirmation alert with callback-based completion (deprecated)
    @available(*, deprecated, message: "Use async version instead")
    func showConfirmation(
        title: String,
        message: String,
        confirmButton: String = "Yes",
        cancelButton: String = "No",
        style: NSAlert.Style = .warning,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        Task {
            let confirmed = await showConfirmation(
                title: title,
                message: message,
                confirmButton: confirmButton,
                cancelButton: cancelButton,
                style: style
            )
            if confirmed {
                onConfirm()
            } else {
                onCancel?()
            }
        }
    }

    /// Present an error alert asynchronously
    func showError(
        title: String = "Error",
        message: String,
        error: Error? = nil
    ) async {
        let fullMessage: String
        if let error = error {
            fullMessage = "\(message)\n\nDetails: \(error.localizedDescription)"
        } else {
            fullMessage = message
        }

        _ = await showAlert(
            title: title,
            message: fullMessage,
            style: .critical,
            buttons: ["OK"]
        )
    }

    /// Show an error with optional retry action
    func showError(
        title: String = "Error",
        message: String,
        retryAction: (() async -> Void)? = nil
    ) async {
        let buttons: [String]
        if retryAction != nil {
            buttons = ["Retry", "Cancel"]
        } else {
            buttons = ["OK"]
        }

        let result = await showAlert(
            title: title,
            message: message,
            style: .critical,
            buttons: buttons
        )

        if result == "Retry", let retry = retryAction {
            await retry()
        }
    }

    /// Show a network error with automatic retry
    func showNetworkError(
        operation: String,
        retry: @escaping () async -> Void
    ) async {
        await showError(
            title: "Network Error",
            message: "Unable to \(operation). Please check your internet connection.",
            retryAction: retry
        )
    }

    /// Show a user-facing error with optional retry
    func showUserFacingError(
        _ error: UserFacingError,
        retryAction: (() async -> Void)? = nil
    ) async {
        let title = error.isRetryable ? "Temporary Error" : "Error"
        let message = [
            error.errorDescription,
            error.recoverySuggestion
        ].compactMap { $0 }.joined(separator: "\n\n")

        if error.isRetryable, let retry = retryAction {
            await showError(title: title, message: message, retryAction: retry)
        } else {
            _ = await showAlert(title: title, message: message, style: .critical, buttons: ["OK"])
        }
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
        currentToast = ToastConfig(
            message: message,
            type: type,
            duration: duration
        )

        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if currentToast?.id == currentToast?.id {
                currentToast = nil
            }
        }
    }

    /// Show a success toast
    func showSuccessToast(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .success, duration: duration)
    }

    /// Show an error toast
    func showErrorToast(_ message: String, duration: TimeInterval = 4.0) {
        showToast(message: message, type: .error, duration: duration)
    }

    /// Show a warning toast
    func showWarningToast(_ message: String, duration: TimeInterval = 3.5) {
        showToast(message: message, type: .warning, duration: duration)
    }

    /// Show an info toast
    func showInfoToast(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .info, duration: duration)
    }

    // MARK: - Async Operations with Progress

    /// Show a progress alert for long-running operations
    func showProgress(
        title: String,
        message: String,
        operation: @escaping () async throws -> Void
    ) async {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational

            // Create custom accessory view with progress indicator
            let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
            let progressIndicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 300, height: 20))
            progressIndicator.style = .bar
            progressIndicator.isIndeterminate = true
            progressIndicator.startAnimation(nil)
            accessoryView.addSubview(progressIndicator)

            let statusLabel = NSTextField(frame: NSRect(x: 0, y: 22, width: 300, height: 18))
            statusLabel.stringValue = "Processing..."
            statusLabel.isEditable = false
            statusLabel.isBordered = false
            statusLabel.backgroundColor = .clear
            statusLabel.font = .systemFont(ofSize: 11)
            statusLabel.textColor = .secondaryLabelColor
            accessoryView.addSubview(statusLabel)

            alert.accessoryView = accessoryView

            // Show alert in a detached task so it doesn't block
            let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first

            Task { @MainActor in
                guard let window = window else {
                    // No window available, run operation without progress UI
                    do {
                        try await operation()
                        showSuccessToast("Operation completed")
                    } catch {
                        await showError(message: "Operation failed", error: error)
                    }
                    return
                }

                alert.beginSheetModal(for: window) { _ in
                    // Modal dismissed
                }
            }

            // Run the operation
            Task {
                do {
                    try await operation()
                    await MainActor.run {
                        window?.endSheet(alert.window)
                        showSuccessToast("Operation completed")
                    }
                } catch {
                    await MainActor.run {
                        window?.endSheet(alert.window)
                    }
                    await showError(message: "Operation failed", error: error)
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct AlertConfig: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let style: NSAlert.Style
    let buttons: [String]
    let completion: ((String) -> Void)?
}

struct ToastConfig: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
}

enum ToastType {
    case success
    case error
    case warning
    case info

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let config: ToastConfig

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: config.type.icon)
                .foregroundColor(config.type.color)
                .font(.title3)

            Text(config.message)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: AppColors.textPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding()
    }
}

// MARK: - Mock for Testing

/// Mock implementation of AlertPresenterProtocol for testing
struct AlertCall {
    let title: String
    let message: String
    let style: NSAlert.Style
    let buttons: [String]
}

struct ConfirmationCall {
    let title: String
    let message: String
    let confirmButton: String
    let cancelButton: String
    let style: NSAlert.Style
}

struct ErrorCall {
    let title: String
    let message: String
    let error: Error?
}

struct SuccessCall {
    let title: String
    let message: String
}

struct ToastCall {
    let message: String
    let type: ToastType
    let duration: TimeInterval
}

@MainActor
class MockAlertPresenter: ObservableObject, AlertPresenterProtocol {
    var alertCalls: [AlertCall] = []
    var confirmationCalls: [ConfirmationCall] = []
    var errorCalls: [ErrorCall] = []
    var successCalls: [SuccessCall] = []
    var toastCalls: [ToastCall] = []

    var alertResponse: String = "OK"
    var confirmationResponse: Bool = true

    func showAlert(
        title: String,
        message: String,
        style: NSAlert.Style,
        buttons: [String]
    ) async -> String {
        alertCalls.append(AlertCall(title: title, message: message, style: style, buttons: buttons))
        return alertResponse
    }

    func showConfirmation(
        title: String,
        message: String,
        confirmButton: String,
        cancelButton: String,
        style: NSAlert.Style
    ) async -> Bool {
        confirmationCalls.append(ConfirmationCall(
            title: title,
            message: message,
            confirmButton: confirmButton,
            cancelButton: cancelButton,
            style: style
        ))
        return confirmationResponse
    }

    func showError(
        title: String,
        message: String,
        error: Error?
    ) async {
        errorCalls.append(ErrorCall(title: title, message: message, error: error))
    }

    func showSuccess(
        title: String,
        message: String
    ) async {
        successCalls.append(SuccessCall(title: title, message: message))
    }

    func showToast(
        message: String,
        type: ToastType,
        duration: TimeInterval
    ) {
        toastCalls.append(ToastCall(message: message, type: type, duration: duration))
    }

    func showSuccessToast(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .success, duration: duration)
    }

    func showErrorToast(_ message: String, duration: TimeInterval = 4.0) {
        showToast(message: message, type: .error, duration: duration)
    }

    func showWarningToast(_ message: String, duration: TimeInterval = 3.5) {
        showToast(message: message, type: .warning, duration: duration)
    }

    func showInfoToast(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .info, duration: duration)
    }

    func reset() {
        alertCalls.removeAll()
        confirmationCalls.removeAll()
        errorCalls.removeAll()
        successCalls.removeAll()
        toastCalls.removeAll()
        alertResponse = "OK"
        confirmationResponse = true
    }
}
