//
//  URLValidatorTests.swift
//  I Do BlueprintTests
//
//  Tests for URL security validation
//

import XCTest
@testable import I_Do_Blueprint

final class URLValidatorTests: XCTestCase {

    // MARK: - Valid URL Tests

    func testValidHTTPSURLsAccepted() throws {
        let validURLs = [
            "https://example.com/image.jpg",
            "https://cdn.example.com/file.pdf",
            "https://supabase.co/storage/v1/object/public/images/test.jpg",
            "https://www.google.com",
            "https://api.example.com:443/endpoint"
        ]

        for urlString in validURLs {
            let url = URL(string: urlString)!
            XCTAssertNoThrow(
                try URLValidator.validate(url),
                "Valid HTTPS URL should be accepted: \(urlString)")
        }
    }

    func testValidHTTPURLsAccepted() throws {
        let validURLs = [
            "http://example.com/image.jpg",
            "http://cdn.example.com/file.pdf",
            "http://api.example.com:80/endpoint"
        ]

        for urlString in validURLs {
            let url = URL(string: urlString)!
            XCTAssertNoThrow(
                try URLValidator.validate(url),
                "Valid HTTP URL should be accepted: \(urlString)")
        }
    }

    func testValidURLWithStandardPorts() throws {
        let validURLs = [
            "https://example.com:443/path",
            "http://example.com:80/path",
            "http://example.com:8080/path",
            "https://example.com:8443/path"
        ]

        for urlString in validURLs {
            let url = URL(string: urlString)!
            XCTAssertNoThrow(
                try URLValidator.validate(url),
                "URL with standard port should be accepted: \(urlString)")
        }
    }

    // MARK: - Blocked Scheme Tests

    func testFileProtocolRejected() {
        let fileURLs = [
            "file:///etc/passwd",
            "file:///Users/test/document.pdf",
            "file://localhost/etc/hosts"
        ]

        for urlString in fileURLs {
            let url = URL(string: urlString)!
            XCTAssertThrowsError(
                try URLValidator.validate(url),
                "File protocol should be rejected: \(urlString)"
            ) { error in
                guard let validationError = error as? URLValidationError else {
                    XCTFail("Expected URLValidationError")
                    return
                }
                if case .blockedScheme(let scheme) = validationError {
                    XCTAssertEqual(scheme, "file")
                } else {
                    XCTFail("Expected blockedScheme error")
                }
            }
        }
    }

    func testDangerousProtocolsRejected() {
        let dangerousURLs = [
            "ftp://example.com/file.txt",
            "sftp://example.com/file.txt",
            "ssh://example.com",
            "telnet://example.com",
            "gopher://example.com",
            "ldap://example.com",
            "dict://example.com",
            "data:text/html,<script>alert('xss')</script>",
            "javascript:alert('xss')"
        ]

        for urlString in dangerousURLs {
            guard let url = URL(string: urlString) else { continue }
            XCTAssertThrowsError(
                try URLValidator.validate(url),
                "Dangerous protocol should be rejected: \(urlString)"
            ) { error in
                XCTAssertTrue(error is URLValidationError)
            }
        }
    }

    // MARK: - SSRF Prevention Tests

    func testLocalhostRejected() {
        let localhostURLs = [
            "http://localhost:8080",
            "http://127.0.0.1:3000",
            "http://0.0.0.0",
            "http://[::1]/path"
        ]

        for urlString in localhostURLs {
            guard let url = URL(string: urlString) else { continue }
            XCTAssertThrowsError(
                try URLValidator.validate(url),
                "Localhost URL should be rejected: \(urlString)"
            ) { error in
                guard let validationError = error as? URLValidationError else {
                    XCTFail("Expected URLValidationError")
                    return
                }
                if case .blockedHost = validationError {
                    // Success
                } else {
                    XCTFail("Expected blockedHost error, got: \(validationError)")
                }
            }
        }
    }

    func testMetadataServiceRejected() {
        let metadataURLs = [
            "http://169.254.169.254/latest/meta-data/",
            "http://metadata.google.internal/computeMetadata/v1/",
            "http://metadata/latest/meta-data/"
        ]

        for urlString in metadataURLs {
            let url = URL(string: urlString)!
            XCTAssertThrowsError(
                try URLValidator.validate(url),
                "Metadata service URL should be rejected: \(urlString)"
            ) { error in
                guard let validationError = error as? URLValidationError else {
                    XCTFail("Expected URLValidationError")
                    return
                }
                if case .blockedHost = validationError {
                    // Success
                } else {
                    XCTFail("Expected blockedHost error")
                }
            }
        }
    }

    func testPrivateIPRangesRejected() {
        let privateIPURLs = [
            "http://192.168.1.1/admin",
            "http://10.0.0.1/config",
            "http://172.16.0.1/api",
            "http://172.31.255.255/endpoint"
        ]

        for urlString in privateIPURLs {
            let url = URL(string: urlString)!
            XCTAssertThrowsError(
                try URLValidator.validate(url),
                "Private IP URL should be rejected: \(urlString)"
            ) { error in
                guard let validationError = error as? URLValidationError else {
                    XCTFail("Expected URLValidationError")
                    return
                }
                if case .privateIPRange = validationError {
                    // Success
                } else {
                    XCTFail("Expected privateIPRange error")
                }
            }
        }
    }

    // MARK: - Suspicious Pattern Tests

    func testUserCredentialsInURLRejected() {
        let urlsWithCredentials = [
            "http://user:password@example.com",
            "https://admin:secret@example.com/admin"
        ]

        for urlString in urlsWithCredentials {
            let url = URL(string: urlString)!
            XCTAssertThrowsError(
                try URLValidator.validate(url),
                "URL with credentials should be rejected: \(urlString)"
            ) { error in
                guard let validationError = error as? URLValidationError else {
                    XCTFail("Expected URLValidationError")
                    return
                }
                if case .suspiciousPattern = validationError {
                    // Success
                } else {
                    XCTFail("Expected suspiciousPattern error")
                }
            }
        }
    }

    func testNullByteEncodingRejected() {
        let urlString = "http://example.com/path%00/file.txt"
        let url = URL(string: urlString)!

        XCTAssertThrowsError(
            try URLValidator.validate(url),
            "URL with null byte encoding should be rejected"
        ) { error in
            guard let validationError = error as? URLValidationError else {
                XCTFail("Expected URLValidationError")
                return
            }
            if case .suspiciousPattern(let pattern) = validationError {
                XCTAssertTrue(pattern.contains("null byte"))
            } else {
                XCTFail("Expected suspiciousPattern error for null byte")
            }
        }
    }

    func testDoubleEncodingRejected() {
        let urlString = "http://example.com/path%252F/file.txt"
        let url = URL(string: urlString)!

        XCTAssertThrowsError(
            try URLValidator.validate(url),
            "URL with double encoding should be rejected"
        ) { error in
            guard let validationError = error as? URLValidationError else {
                XCTFail("Expected URLValidationError")
                return
            }
            if case .suspiciousPattern(let pattern) = validationError {
                XCTAssertTrue(pattern.contains("double encoding"))
            } else {
                XCTFail("Expected suspiciousPattern error for double encoding")
            }
        }
    }

    // MARK: - Port Validation Tests

    func testNonStandardPortsRejected() {
        let urlsWithBadPorts = [
            "http://example.com:22/ssh",
            "http://example.com:3306/mysql",
            "http://example.com:5432/postgres",
            "http://example.com:6379/redis"
        ]

        for urlString in urlsWithBadPorts {
            let url = URL(string: urlString)!
            XCTAssertThrowsError(
                try URLValidator.validate(url),
                "URL with non-standard port should be rejected: \(urlString)"
            ) { error in
                guard let validationError = error as? URLValidationError else {
                    XCTFail("Expected URLValidationError")
                    return
                }
                if case .blockedPort = validationError {
                    // Success
                } else {
                    XCTFail("Expected blockedPort error")
                }
            }
        }
    }

    // MARK: - Missing Components Tests

    func testMissingSchemeRejected() {
        // Note: URL(string:) will fail for URLs without scheme, so we test the error type
        let urlString = "example.com/path"
        if let url = URL(string: urlString) {
            // If URL is created, it should fail validation
            XCTAssertThrowsError(try URLValidator.validate(url))
        }
    }

    func testMissingHostRejected() {
        // URLs without host should be rejected
        let urlString = "http:///path/to/file"
        if let url = URL(string: urlString) {
            XCTAssertThrowsError(
                try URLValidator.validate(url),
                "URL without host should be rejected"
            ) { error in
                guard let validationError = error as? URLValidationError else {
                    XCTFail("Expected URLValidationError")
                    return
                }
                if case .missingHost = validationError {
                    // Success
                } else {
                    XCTFail("Expected missingHost error")
                }
            }
        }
    }

    // MARK: - Convenience Method Tests

    func testValidateStringWithValidURL() throws {
        let urlString = "https://example.com/image.jpg"
        let url = try URLValidator.validateString(urlString)
        XCTAssertEqual(url.absoluteString, urlString)
    }

    func testValidateStringWithInvalidURL() {
        let urlString = "not a valid url"
        XCTAssertThrowsError(
            try URLValidator.validateString(urlString)
        ) { error in
            guard let validationError = error as? URLValidationError else {
                XCTFail("Expected URLValidationError")
                return
            }
            if case .invalidURLString = validationError {
                // Success
            } else {
                XCTFail("Expected invalidURLString error")
            }
        }
    }

    func testIsSafeMethod() {
        let safeURL = URL(string: "https://example.com")!
        XCTAssertTrue(URLValidator.isSafe(safeURL))

        let unsafeURL = URL(string: "file:///etc/passwd")!
        XCTAssertFalse(URLValidator.isSafe(unsafeURL))
    }

    // MARK: - URL Extension Tests

    func testURLExtensionIsSafe() {
        let safeURL = URL(string: "https://example.com")!
        XCTAssertTrue(safeURL.isSafe)

        let unsafeURL = URL(string: "http://localhost:8080")!
        XCTAssertFalse(unsafeURL.isSafe)
    }

    func testURLExtensionValidateSecurity() throws {
        let safeURL = URL(string: "https://example.com")!
        XCTAssertNoThrow(try safeURL.validateSecurity())

        let unsafeURL = URL(string: "file:///etc/passwd")!
        XCTAssertThrowsError(try unsafeURL.validateSecurity())
    }

    // MARK: - Error Description Tests

    func testErrorDescriptions() {
        let errors: [URLValidationError] = [
            .missingScheme,
            .missingHost,
            .blockedScheme("file"),
            .unsupportedScheme("ftp"),
            .blockedHost("localhost"),
            .privateIPRange("192.168.1.1"),
            .blockedPort(22),
            .suspiciousPattern("test"),
            .invalidURLString("invalid")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description")
            XCTAssertNotNil(error.recoverySuggestion, "Error should have recovery suggestion")
        }
    }

    // MARK: - Real-World Supabase URL Tests

    func testSupabaseStorageURLsAccepted() throws {
        let supabaseURLs = [
            "https://abcdefghijklmnop.supabase.co/storage/v1/object/public/images/photo.jpg",
            "https://project.supabase.co/storage/v1/object/sign/documents/contract.pdf?token=abc123"
        ]

        for urlString in supabaseURLs {
            let url = URL(string: urlString)!
            XCTAssertNoThrow(
                try URLValidator.validate(url),
                "Supabase storage URL should be accepted: \(urlString)")
        }
    }

    // MARK: - Edge Cases

    func testURLWithQueryParameters() throws {
        let url = URL(string: "https://example.com/path?param1=value1&param2=value2")!
        XCTAssertNoThrow(try URLValidator.validate(url))
    }

    func testURLWithFragment() throws {
        let url = URL(string: "https://example.com/path#section")!
        XCTAssertNoThrow(try URLValidator.validate(url))
    }

    func testURLWithEncodedCharacters() throws {
        let url = URL(string: "https://example.com/path%20with%20spaces")!
        XCTAssertNoThrow(try URLValidator.validate(url))
    }

    func testCaseSensitivity() throws {
        // Scheme and host should be case-insensitive
        let urls = [
            "HTTPS://EXAMPLE.COM/path",
            "https://EXAMPLE.com/path",
            "HtTpS://example.COM/path"
        ]

        for urlString in urls {
            let url = URL(string: urlString)!
            XCTAssertNoThrow(
                try URLValidator.validate(url),
                "URL should be case-insensitive: \(urlString)")
        }
    }
}
