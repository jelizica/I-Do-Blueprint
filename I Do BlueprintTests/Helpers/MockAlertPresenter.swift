//
//  MockAlertPresenter.swift
//  I Do BlueprintTests
//
//  Mock implementation of AlertPresenterProtocol for testing
//

import AppKit
import Foundation
@testable import I_Do_Blueprint

// MARK: - Call Recording Types

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

// MARK: - Mock Alert Presenter

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
