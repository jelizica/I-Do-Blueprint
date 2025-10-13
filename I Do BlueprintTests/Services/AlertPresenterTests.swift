//
//  AlertPresenterTests.swift
//  I Do BlueprintTests
//
//  Tests for alert presentation including login error handling
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class AlertPresenterTests: XCTestCase {
    var mockPresenter: MockAlertPresenter!

    override func setUp() async throws {
        try await super.setUp()
        mockPresenter = MockAlertPresenter()
    }

    override func tearDown() async throws {
        mockPresenter = nil
        try await super.tearDown()
    }

    // MARK: - Basic Alert Tests

    func testShowAlertDoesNotBlockMainThread() async {
        // Given
        let title = "Test Alert"
        let message = "This is a test message"

        // When
        let result = await mockPresenter.showAlert(
            title: title,
            message: message,
            style: .informational,
            buttons: ["OK", "Cancel"]
        )

        // Then
        XCTAssertEqual(mockPresenter.alertCalls.count, 1)
        XCTAssertEqual(mockPresenter.alertCalls[0].title, title)
        XCTAssertEqual(mockPresenter.alertCalls[0].message, message)
        XCTAssertEqual(result, "OK")
    }

    func testShowErrorAlert() async {
        // Given
        let title = "Login Error"
        let message = "Invalid credentials"
        let error = NSError(domain: "TestError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])

        // When
        await mockPresenter.showError(title: title, message: message, error: error)

        // Then
        XCTAssertEqual(mockPresenter.errorCalls.count, 1)
        XCTAssertEqual(mockPresenter.errorCalls[0].title, title)
        XCTAssertEqual(mockPresenter.errorCalls[0].message, message)
        XCTAssertNotNil(mockPresenter.errorCalls[0].error)
    }

    func testShowConfirmation() async {
        // Given
        let title = "Delete Item"
        let message = "Are you sure?"
        mockPresenter.confirmationResponse = true

        // When
        let result = await mockPresenter.showConfirmation(
            title: title,
            message: message,
            confirmButton: "Yes",
            cancelButton: "No",
            style: .warning
        )

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockPresenter.confirmationCalls.count, 1)
        XCTAssertEqual(mockPresenter.confirmationCalls[0].title, title)
        XCTAssertEqual(mockPresenter.confirmationCalls[0].message, message)
    }

    func testShowSuccess() async {
        // Given
        let title = "Success"
        let message = "Operation completed"

        // When
        await mockPresenter.showSuccess(title: title, message: message)

        // Then
        XCTAssertEqual(mockPresenter.successCalls.count, 1)
        XCTAssertEqual(mockPresenter.successCalls[0].title, title)
        XCTAssertEqual(mockPresenter.successCalls[0].message, message)
    }

    // MARK: - Login Error Presentation Tests

    func testLoginErrorPresentation() async {
        // Given: Simulating a login error scenario
        let loginError = NSError(
            domain: "AuthError",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"]
        )

        // When: Presenting login error
        await mockPresenter.showError(
            title: "Login Failed",
            message: "Please check your credentials",
            error: loginError
        )

        // Then: Verify error was presented without blocking
        XCTAssertEqual(mockPresenter.errorCalls.count, 1)
        XCTAssertEqual(mockPresenter.errorCalls[0].title, "Login Failed")
        XCTAssertEqual(mockPresenter.errorCalls[0].message, "Please check your credentials")

        // Verify the error details are preserved
        if let capturedError = mockPresenter.errorCalls[0].error as? NSError {
            XCTAssertEqual(capturedError.code, 401)
            XCTAssertEqual(capturedError.localizedDescription, "Invalid email or password")
        } else {
            XCTFail("Error was not captured correctly")
        }
    }

    func testMultipleLoginErrorsDontBlock() async {
        // Given: Multiple login errors
        let errors = [
            NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"]),
            NSError(domain: "AuthError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Account locked"]),
            NSError(domain: "AuthError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        ]

        // When: Presenting multiple errors in sequence
        for (index, error) in errors.enumerated() {
            await mockPresenter.showError(
                title: "Error \(index + 1)",
                message: "Login failed",
                error: error
            )
        }

        // Then: All errors should be captured
        XCTAssertEqual(mockPresenter.errorCalls.count, 3)
        XCTAssertEqual((mockPresenter.errorCalls[0].error as? NSError)?.code, 401)
        XCTAssertEqual((mockPresenter.errorCalls[1].error as? NSError)?.code, 403)
        XCTAssertEqual((mockPresenter.errorCalls[2].error as? NSError)?.code, 500)
    }

    // MARK: - Toast Notification Tests

    func testShowToastNotification() {
        // Given
        let message = "Operation successful"

        // When
        mockPresenter.showSuccessToast(message)

        // Then
        XCTAssertEqual(mockPresenter.toastCalls.count, 1)
        XCTAssertEqual(mockPresenter.toastCalls[0].message, message)
        XCTAssertEqual(mockPresenter.toastCalls[0].type, .success)
    }

    func testShowErrorToast() {
        // Given
        let message = "Login failed"

        // When
        mockPresenter.showErrorToast(message)

        // Then
        XCTAssertEqual(mockPresenter.toastCalls.count, 1)
        XCTAssertEqual(mockPresenter.toastCalls[0].message, message)
        XCTAssertEqual(mockPresenter.toastCalls[0].type, .error)
    }

    // MARK: - Dependency Injection Tests

    func testAlertPresenterDependencyInjection() async {
        await withDependencies {
            $0.alertPresenter = mockPresenter
        } operation: {
            @Dependency(\.alertPresenter) var presenter

            Task { @MainActor in
                await presenter.showError(
                    title: "Test",
                    message: "Dependency injection test",
                    error: nil
                )

                XCTAssertEqual(mockPresenter.errorCalls.count, 1)
            }
        }
    }

    func testResetMockPresenter() {
        // Given: Mock with some calls
        mockPresenter.showSuccessToast("Test")
        mockPresenter.alertResponse = "Custom"
        mockPresenter.confirmationResponse = false

        XCTAssertEqual(mockPresenter.toastCalls.count, 1)

        // When: Reset
        mockPresenter.reset()

        // Then: All state cleared
        XCTAssertEqual(mockPresenter.toastCalls.count, 0)
        XCTAssertEqual(mockPresenter.alertCalls.count, 0)
        XCTAssertEqual(mockPresenter.errorCalls.count, 0)
        XCTAssertEqual(mockPresenter.successCalls.count, 0)
        XCTAssertEqual(mockPresenter.confirmationCalls.count, 0)
        XCTAssertEqual(mockPresenter.alertResponse, "OK")
        XCTAssertTrue(mockPresenter.confirmationResponse)
    }
}
