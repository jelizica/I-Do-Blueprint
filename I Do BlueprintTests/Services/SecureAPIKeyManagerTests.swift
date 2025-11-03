//
//  SecureAPIKeyManagerTests.swift
//  I Do BlueprintTests
//
//  Unit tests for secure API key management
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class SecureAPIKeyManagerTests: XCTestCase {
    var manager: SecureAPIKeyManager!

    override func setUp() async throws {
        try await super.setUp()
        manager = SecureAPIKeyManager.shared

        // Clean up any existing test keys
        for keyType in SecureAPIKeyManager.APIKeyType.allCases {
            manager.deleteAPIKey(for: keyType)
        }
    }

    override func tearDown() async throws {
        // Clean up test keys after each test
        for keyType in SecureAPIKeyManager.APIKeyType.allCases {
            manager.deleteAPIKey(for: keyType)
        }
        manager = nil
        try await super.tearDown()
    }

    // MARK: - Store and Retrieve Tests

    func test_storeAndRetrieveAPIKey_success() throws {
        // Given
        let testKey = "test-api-key-12345"
        let keyType = SecureAPIKeyManager.APIKeyType.unsplash

        // When
        try manager.storeAPIKey(testKey, for: keyType)
        let retrieved = manager.getAPIKey(for: keyType)

        // Then
        XCTAssertEqual(retrieved, testKey, "Retrieved key should match stored key")
        XCTAssertTrue(manager.hasUnsplashKey, "Manager should report key as present")
    }

    func test_storeAPIKey_emptyKey_throwsError() {
        // Given
        let emptyKey = ""
        let keyType = SecureAPIKeyManager.APIKeyType.pinterest

        // When/Then
        XCTAssertThrowsError(try manager.storeAPIKey(emptyKey, for: keyType)) { error in
            XCTAssertTrue(error is APIKeyError, "Should throw APIKeyError")
            if let apiKeyError = error as? APIKeyError {
                XCTAssertEqual(apiKeyError.localizedDescription, "The API key is invalid or empty")
            }
        }
    }

    func test_storeAPIKey_overwritesExisting() throws {
        // Given
        let firstKey = "first-key-12345"
        let secondKey = "second-key-67890"
        let keyType = SecureAPIKeyManager.APIKeyType.vendor

        // When
        try manager.storeAPIKey(firstKey, for: keyType)
        try manager.storeAPIKey(secondKey, for: keyType)
        let retrieved = manager.getAPIKey(for: keyType)

        // Then
        XCTAssertEqual(retrieved, secondKey, "Second key should overwrite first key")
        XCTAssertNotEqual(retrieved, firstKey, "First key should be replaced")
    }

    // MARK: - Delete Tests

    func test_deleteAPIKey_success() throws {
        // Given
        let testKey = "test-api-key-12345"
        let keyType = SecureAPIKeyManager.APIKeyType.unsplash
        try manager.storeAPIKey(testKey, for: keyType)

        // When
        manager.deleteAPIKey(for: keyType)
        let retrieved = manager.getAPIKey(for: keyType)

        // Then
        XCTAssertNil(retrieved, "Key should be deleted")
        XCTAssertFalse(manager.hasUnsplashKey, "Manager should report key as absent")
    }

    func test_deleteAPIKey_nonExistent_doesNotThrow() {
        // Given
        let keyType = SecureAPIKeyManager.APIKeyType.pinterest

        // When/Then - should not throw
        manager.deleteAPIKey(for: keyType)

        // Verify key is still not present
        XCTAssertNil(manager.getAPIKey(for: keyType))
        XCTAssertFalse(manager.hasPinterestKey)
    }

    // MARK: - Multiple Keys Tests

    func test_storeMultipleKeys_independently() throws {
        // Given
        let unsplashKey = "unsplash-key-12345"
        let pinterestKey = "pinterest-key-67890"
        let vendorKey = "vendor-key-abcde"

        // When
        try manager.storeAPIKey(unsplashKey, for: .unsplash)
        try manager.storeAPIKey(pinterestKey, for: .pinterest)
        try manager.storeAPIKey(vendorKey, for: .vendor)

        // Then
        XCTAssertEqual(manager.getAPIKey(for: .unsplash), unsplashKey)
        XCTAssertEqual(manager.getAPIKey(for: .pinterest), pinterestKey)
        XCTAssertEqual(manager.getAPIKey(for: .vendor), vendorKey)

        XCTAssertTrue(manager.hasUnsplashKey)
        XCTAssertTrue(manager.hasPinterestKey)
        XCTAssertTrue(manager.hasVendorKey)
    }

    func test_deleteOneKey_doesNotAffectOthers() throws {
        // Given
        let unsplashKey = "unsplash-key-12345"
        let pinterestKey = "pinterest-key-67890"
        try manager.storeAPIKey(unsplashKey, for: .unsplash)
        try manager.storeAPIKey(pinterestKey, for: .pinterest)

        // When
        manager.deleteAPIKey(for: .unsplash)

        // Then
        XCTAssertNil(manager.getAPIKey(for: .unsplash))
        XCTAssertEqual(manager.getAPIKey(for: .pinterest), pinterestKey)

        XCTAssertFalse(manager.hasUnsplashKey)
        XCTAssertTrue(manager.hasPinterestKey)
    }

    // MARK: - Validation Tests

    func test_validateAPIKey_emptyKey_throwsError() async {
        // Given
        let emptyKey = ""
        let keyType = SecureAPIKeyManager.APIKeyType.unsplash

        // When/Then
        do {
            _ = try await manager.validateAPIKey(emptyKey, for: keyType)
            XCTFail("Should throw error for empty key")
        } catch {
            XCTAssertTrue(error is APIKeyError)
        }
    }

    func test_validatePinterestKey_validFormat_returnsTrue() async throws {
        // Given
        let validKey = "pinterest-valid-key-12345678901234567890"

        // When
        let isValid = try await manager.validateAPIKey(validKey, for: .pinterest)

        // Then
        XCTAssertTrue(isValid, "Valid format Pinterest key should pass validation")
    }

    func test_validatePinterestKey_invalidFormat_returnsFalse() async throws {
        // Given
        let invalidKey = "short"

        // When
        let isValid = try await manager.validateAPIKey(invalidKey, for: .pinterest)

        // Then
        XCTAssertFalse(isValid, "Short Pinterest key should fail validation")
    }

    func test_validateVendorKey_validFormat_returnsTrue() async throws {
        // Given
        let validKey = "vendor-valid-key-12345678901234567890"

        // When
        let isValid = try await manager.validateAPIKey(validKey, for: .vendor)

        // Then
        XCTAssertTrue(isValid, "Valid format Vendor key should pass validation")
    }

    // MARK: - Published State Tests

    func test_publishedState_updatesOnStore() throws {
        // Given
        let testKey = "test-key-12345"
        XCTAssertFalse(manager.hasUnsplashKey, "Initially should not have key")

        // When
        try manager.storeAPIKey(testKey, for: .unsplash)

        // Then
        XCTAssertTrue(manager.hasUnsplashKey, "Should update published state after storing")
    }

    func test_publishedState_updatesOnDelete() throws {
        // Given
        let testKey = "test-key-12345"
        try manager.storeAPIKey(testKey, for: .pinterest)
        XCTAssertTrue(manager.hasPinterestKey, "Should have key after storing")

        // When
        manager.deleteAPIKey(for: .pinterest)

        // Then
        XCTAssertFalse(manager.hasPinterestKey, "Should update published state after deleting")
    }

    // MARK: - APIKeyType Tests

    func test_apiKeyType_displayNames() {
        XCTAssertEqual(SecureAPIKeyManager.APIKeyType.unsplash.displayName, "Unsplash")
        XCTAssertEqual(SecureAPIKeyManager.APIKeyType.pinterest.displayName, "Pinterest")
        XCTAssertEqual(SecureAPIKeyManager.APIKeyType.vendor.displayName, "Vendor API")
    }

    func test_apiKeyType_helpURLs() {
        XCTAssertEqual(SecureAPIKeyManager.APIKeyType.unsplash.helpURL, "https://unsplash.com/developers")
        XCTAssertEqual(SecureAPIKeyManager.APIKeyType.pinterest.helpURL, "https://developers.pinterest.com")
        XCTAssertFalse(SecureAPIKeyManager.APIKeyType.vendor.helpURL.isEmpty)
    }

    // MARK: - Error Tests

    func test_apiKeyError_descriptions() {
        let invalidKeyError = APIKeyError.invalidKey
        XCTAssertEqual(invalidKeyError.localizedDescription, "The API key is invalid or empty")

        let storeFailedError = APIKeyError.storeFailed(status: -25300)
        XCTAssertTrue(storeFailedError.localizedDescription.contains("Failed to store"))

        let invalidURLError = APIKeyError.invalidURL
        XCTAssertEqual(invalidURLError.localizedDescription, "Invalid API endpoint URL")

        let invalidResponseError = APIKeyError.invalidResponse
        XCTAssertEqual(invalidResponseError.localizedDescription, "Invalid response from API")
    }
}
