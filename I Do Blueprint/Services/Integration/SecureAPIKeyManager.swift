//
//  SecureAPIKeyManager.swift
//  I Do Blueprint
//
//  Secure API key management using macOS Keychain
//

import Combine
import Foundation
import Security

@MainActor
class SecureAPIKeyManager: ObservableObject {
    static let shared = SecureAPIKeyManager()

    private let keychainService = "Jelizica.I-Do-Blueprint.apikeys"
    private let logger = AppLogger.auth

    // Published state for UI
    @Published var hasUnsplashKey = false
    @Published var hasPinterestKey = false
    @Published var hasVendorKey = false
    @Published var hasResendKey = false

    // API Key identifiers
    enum APIKeyType: String, CaseIterable {
        case unsplash = "unsplash-api-key"
        case pinterest = "pinterest-api-key"
        case vendor = "vendor-api-key"
        case resend = "resend-api-key"

        var displayName: String {
            switch self {
            case .unsplash: return "Unsplash"
            case .pinterest: return "Pinterest"
            case .vendor: return "Vendor API"
            case .resend: return "Resend Email"
            }
        }

        var helpURL: String {
            switch self {
            case .unsplash: return "https://unsplash.com/developers"
            case .pinterest: return "https://developers.pinterest.com"
            case .vendor: return "https://example.com/vendor-api" // Update with actual URL
            case .resend: return "https://resend.com/api-keys"
            }
        }

        var description: String {
            switch self {
            case .unsplash: return "For searching wedding inspiration images"
            case .pinterest: return "For discovering wedding ideas and themes"
            case .vendor: return "For vendor directory integration"
            case .resend: return "For sending collaboration invitation emails"
            }
        }
    }

    init() {
        checkAvailableKeys()
    }

    // MARK: - Check Available Keys

    private func checkAvailableKeys() {
        hasUnsplashKey = hasKey(for: .unsplash)
        hasPinterestKey = hasKey(for: .pinterest)
        hasVendorKey = hasKey(for: .vendor)
        hasResendKey = hasKey(for: .resend)
    }

    private func hasKey(for type: APIKeyType) -> Bool {
        return getAPIKey(for: type) != nil
    }

    // MARK: - Get API Key

    func getAPIKey(for type: APIKeyType) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: type.rawValue,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                logger.error("Failed to retrieve \(type.displayName) API key", error: KeychainError.retrievalFailed(status: status))
            }
            return nil
        }

        logger.debug("Retrieved \(type.displayName) API key from Keychain")
        return key
    }

    // MARK: - Store API Key

    func storeAPIKey(_ key: String, for type: APIKeyType) throws {
        guard !key.isEmpty else {
            throw APIKeyError.invalidKey
        }

        guard let data = key.data(using: .utf8) else {
            throw APIKeyError.invalidKey
        }

        // Try to delete existing key first
        deleteAPIKey(for: type)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: type.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            logger.error("Failed to store \(type.displayName) API key", error: KeychainError.storeFailed(status: status))
            throw APIKeyError.storeFailed(status: status)
        }

        logger.info("\(type.displayName) API key stored successfully in Keychain")
        checkAvailableKeys()
    }

    // MARK: - Delete API Key

    func deleteAPIKey(for type: APIKeyType) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: type.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            logger.info("\(type.displayName) API key deleted from Keychain")
            checkAvailableKeys()
        } else if status != errSecItemNotFound {
            logger.warning("Failed to delete \(type.displayName) API key: \(status)")
        }
    }

    // MARK: - Validate API Key

    func validateAPIKey(_ key: String, for type: APIKeyType) async throws -> Bool {
        guard !key.isEmpty else {
            throw APIKeyError.invalidKey
        }

        logger.info("Validating \(type.displayName) API key...")

        // Implement validation logic for each API
        switch type {
        case .unsplash:
            return try await validateUnsplashKey(key)
        case .pinterest:
            return try await validatePinterestKey(key)
        case .vendor:
            return try await validateVendorKey(key)
        case .resend:
            return try await validateResendKey(key)
        }
    }

    private func validateUnsplashKey(_ key: String) async throws -> Bool {
        // Make test API call to Unsplash
        guard let url = URL(string: "https://api.unsplash.com/photos/random") else {
            throw APIKeyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Client-ID \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIKeyError.invalidResponse
            }

            let isValid = httpResponse.statusCode == 200

            if isValid {
                logger.info("Unsplash API key validated successfully")
            } else {
                logger.warning("Unsplash API key validation failed with status: \(httpResponse.statusCode)")
            }

            return isValid
        } catch {
            logger.error("Unsplash API key validation error", error: error)
            throw APIKeyError.validationFailed(underlying: error)
        }
    }

    private func validatePinterestKey(_ key: String) async throws -> Bool {
        // Pinterest API validation would go here
        // For now, just check if key is not empty and has reasonable length
        let isValid = key.count >= 20

        if isValid {
            logger.info("Pinterest API key format validated")
        } else {
            logger.warning("Pinterest API key format validation failed")
        }

        return isValid
    }

    private func validateVendorKey(_ key: String) async throws -> Bool {
        // Vendor API validation would go here
        // For now, just check if key is not empty and has reasonable length
        let isValid = key.count >= 20

        if isValid {
            logger.info("Vendor API key format validated")
        } else {
            logger.warning("Vendor API key format validation failed")
        }

        return isValid
    }

    private func validateResendKey(_ key: String) async throws -> Bool {
        // Validate Resend API key by making a test API call
        guard key.starts(with: "re_") else {
            logger.warning("Resend API key format validation failed - must start with 're_'")
            return false
        }

        guard let url = URL(string: "https://api.resend.com/emails") else {
            throw APIKeyError.invalidURL
        }

        // Make a test request to verify the key (this will fail but confirms auth works)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        // Minimal invalid payload to test auth
        let testPayload = #"{"from":"test@test.com","to":["test@test.com"],"subject":"test","html":"test"}"#
        request.httpBody = testPayload.data(using: .utf8)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIKeyError.invalidResponse
            }

            // 400 = bad request but auth worked
            // 401 = unauthorized (bad key)
            // 422 = validation error but auth worked
            let isValid = httpResponse.statusCode != 401

            if isValid {
                logger.info("Resend API key validated successfully")
            } else {
                logger.warning("Resend API key validation failed - unauthorized")
            }

            return isValid
        } catch {
            logger.error("Resend API key validation error", error: error)
            throw APIKeyError.validationFailed(underlying: error)
        }
    }
}

// MARK: - Errors

enum APIKeyError: LocalizedError {
    case invalidKey
    case storeFailed(status: OSStatus)
    case invalidURL
    case invalidResponse
    case validationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "The API key is invalid or empty"
        case .storeFailed(let status):
            return "Failed to store API key in Keychain (status: \(status))"
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .validationFailed(let error):
            return "API key validation failed: \(error.localizedDescription)"
        }
    }
}

enum KeychainError: LocalizedError {
    case retrievalFailed(status: OSStatus)
    case storeFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .retrievalFailed(let status):
            return "Failed to retrieve from Keychain (status: \(status))"
        case .storeFailed(let status):
            return "Failed to store in Keychain (status: \(status))"
        }
    }
}
