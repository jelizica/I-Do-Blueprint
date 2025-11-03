//
//  InputValidationTests.swift
//  I Do BlueprintTests
//
//  Unit tests for InputValidation utility
//

import XCTest
@testable import I_Do_Blueprint

final class InputValidationTests: XCTestCase {

    // MARK: - Amount Validation Tests

    func testValidateAmount_ValidInput() {
        let result = InputValidator.validateAmount("100.50")

        if case .success(let value) = result {
            XCTAssertEqual(value, 100.50, accuracy: 0.01)
        } else {
            XCTFail("Should succeed with valid amount")
        }
    }

    func testValidateAmount_ValidWholeNumber() {
        let result = InputValidator.validateAmount("500")

        if case .success(let value) = result {
            XCTAssertEqual(value, 500.0, accuracy: 0.01)
        } else {
            XCTFail("Should succeed with valid whole number")
        }
    }

    func testValidateAmount_ValidWithWhitespace() {
        let result = InputValidator.validateAmount("  250.75  ")

        if case .success(let value) = result {
            XCTAssertEqual(value, 250.75, accuracy: 0.01)
        } else {
            XCTFail("Should succeed with valid amount after trimming whitespace")
        }
    }

    func testValidateAmount_InvalidInput() {
        let result = InputValidator.validateAmount("abc")

        if case .failure(let error) = result {
            XCTAssertTrue(error.localizedDescription.contains("not a valid amount"))
        } else {
            XCTFail("Should fail with invalid amount")
        }
    }

    func testValidateAmount_EmptyString() {
        let result = InputValidator.validateAmount("")

        if case .failure = result {
            // Expected
        } else {
            XCTFail("Should fail with empty string")
        }
    }

    func testValidateAmount_NegativeInput() {
        let result = InputValidator.validateAmount("-50")

        if case .failure(let error) = result {
            XCTAssertEqual(error as? ValidationError, .amountNegative)
        } else {
            XCTFail("Should fail with negative amount")
        }
    }

    func testValidateAmount_Zero() {
        let result = InputValidator.validateAmount("0")

        if case .failure(let error) = result {
            XCTAssertEqual(error as? ValidationError, .amountNegative)
        } else {
            XCTFail("Should fail with zero amount")
        }
    }

    func testValidateAmount_TooLarge() {
        let result = InputValidator.validateAmount("2000000")

        if case .failure(let error) = result {
            XCTAssertEqual(error as? ValidationError, .amountTooLarge)
        } else {
            XCTFail("Should fail with amount exceeding maximum")
        }
    }

    func testValidateAmount_MaximumAllowed() {
        let result = InputValidator.validateAmount("1000000")

        if case .success(let value) = result {
            XCTAssertEqual(value, 1_000_000.0, accuracy: 0.01)
        } else {
            XCTFail("Should succeed with maximum allowed amount")
        }
    }

    func testSafeDoubleConversion_ValidInput() {
        let value = InputValidator.safeDoubleConversion("123.45")
        XCTAssertNotNil(value)
        if let value = value {
            XCTAssertEqual(value, 123.45, accuracy: 0.01)
        }
    }

    func testSafeDoubleConversion_InvalidInput() {
        let value = InputValidator.safeDoubleConversion("invalid")
        XCTAssertNil(value)
    }

    // MARK: - URL Validation Tests

    func testValidateURL_ValidHTTPS() {
        let result = InputValidator.validateURL("https://example.com")

        if case .success(let url) = result {
            XCTAssertEqual(url.absoluteString, "https://example.com")
        } else {
            XCTFail("Should succeed with valid HTTPS URL")
        }
    }

    func testValidateURL_ValidHTTP() {
        let result = InputValidator.validateURL("http://example.com")

        if case .success(let url) = result {
            XCTAssertEqual(url.absoluteString, "http://example.com")
        } else {
            XCTFail("Should succeed with valid HTTP URL")
        }
    }

    func testValidateURL_ValidWithPath() {
        let result = InputValidator.validateURL("https://example.com/path/to/page")

        if case .success(let url) = result {
            XCTAssertEqual(url.absoluteString, "https://example.com/path/to/page")
        } else {
            XCTFail("Should succeed with valid URL with path")
        }
    }

    func testValidateURL_ValidWithQueryParameters() {
        let result = InputValidator.validateURL("https://example.com?param=value")

        if case .success(let url) = result {
            XCTAssertEqual(url.absoluteString, "https://example.com?param=value")
        } else {
            XCTFail("Should succeed with valid URL with query parameters")
        }
    }

    func testValidateURL_ValidWithWhitespace() {
        let result = InputValidator.validateURL("  https://example.com  ")

        if case .success(let url) = result {
            XCTAssertEqual(url.absoluteString, "https://example.com")
        } else {
            XCTFail("Should succeed with valid URL after trimming whitespace")
        }
    }

    func testValidateURL_InvalidInput() {
        let result = InputValidator.validateURL("not a url")

        if case .failure = result {
            // Expected
        } else {
            XCTFail("Should fail with invalid URL")
        }
    }

    func testValidateURL_EmptyString() {
        let result = InputValidator.validateURL("")

        if case .failure = result {
            // Expected
        } else {
            XCTFail("Should fail with empty string")
        }
    }

    func testSafeURLConversion_ValidInput() {
        let url = InputValidator.safeURLConversion("https://example.com")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://example.com")
    }

    func testSafeURLConversion_InvalidInput() {
        let url = InputValidator.safeURLConversion("not a url")
        XCTAssertNil(url)
    }

    // MARK: - String Validation Tests

    func testValidateNonEmpty_ValidInput() {
        let result = InputValidator.validateNonEmpty("Hello", fieldName: "Name")

        if case .success(let value) = result {
            XCTAssertEqual(value, "Hello")
        } else {
            XCTFail("Should succeed with non-empty string")
        }
    }

    func testValidateNonEmpty_ValidWithWhitespace() {
        let result = InputValidator.validateNonEmpty("  Hello  ", fieldName: "Name")

        if case .success(let value) = result {
            XCTAssertEqual(value, "Hello")
        } else {
            XCTFail("Should succeed and trim whitespace")
        }
    }

    func testValidateNonEmpty_EmptyString() {
        let result = InputValidator.validateNonEmpty("", fieldName: "Name")

        if case .failure(let error) = result {
            XCTAssertTrue(error.localizedDescription.contains("Name"))
            XCTAssertTrue(error.localizedDescription.contains("required"))
        } else {
            XCTFail("Should fail with empty string")
        }
    }

    func testValidateNonEmpty_OnlyWhitespace() {
        let result = InputValidator.validateNonEmpty("   ", fieldName: "Name")

        if case .failure(let error) = result {
            XCTAssertTrue(error.localizedDescription.contains("Name"))
            XCTAssertTrue(error.localizedDescription.contains("required"))
        } else {
            XCTFail("Should fail with only whitespace")
        }
    }
}

// MARK: - ValidationError Equatable Conformance

extension ValidationError: Equatable {
    public static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidAmount(let a), .invalidAmount(let b)):
            return a == b
        case (.invalidURL(let a), .invalidURL(let b)):
            return a == b
        case (.missingRequiredField(let a), .missingRequiredField(let b)):
            return a == b
        case (.amountTooLarge, .amountTooLarge):
            return true
        case (.amountNegative, .amountNegative):
            return true
        default:
            return false
        }
    }
}
