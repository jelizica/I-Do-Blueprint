//
//  PreviewAlertPresenter.swift
//  I Do Blueprint
//
//  Lightweight mock for SwiftUI previews
//

import AppKit
import Combine
import Foundation

// MARK: - Preview Alert Presenter

/// Lightweight mock implementation for SwiftUI previews
/// For full testing capabilities, use MockAlertPresenter in test target
@MainActor
class PreviewAlertPresenter: ObservableObject, AlertPresenterProtocol {
    var alertResponse: String = "OK"
    var confirmationResponse: Bool = true

    func showAlert(
        title: String,
        message: String,
        style: NSAlert.Style,
        buttons: [String]
    ) async -> String {
        return alertResponse
    }

    func showConfirmation(
        title: String,
        message: String,
        confirmButton: String,
        cancelButton: String,
        style: NSAlert.Style
    ) async -> Bool {
        return confirmationResponse
    }

    func showError(
        title: String,
        message: String,
        error: Error?
    ) async {
        // No-op for previews
    }

    func showSuccess(
        title: String,
        message: String
    ) async {
        // No-op for previews
    }

    func showToast(
        message: String,
        type: ToastType,
        duration: TimeInterval
    ) {
        // No-op for previews
    }

    func showSuccessToast(_ message: String, duration: TimeInterval = 3.0) {
        // No-op for previews
    }

    func showErrorToast(_ message: String, duration: TimeInterval = 4.0) {
        // No-op for previews
    }

    func showWarningToast(_ message: String, duration: TimeInterval = 3.5) {
        // No-op for previews
    }

    func showInfoToast(_ message: String, duration: TimeInterval = 3.0) {
        // No-op for previews
    }
}
