//
//  SessionManager.swift
//  My Wedding Planning App
//
//  Central session management for current user/couple
//

import Combine
import Foundation
import SwiftUI

/// Session-related errors
enum SessionError: LocalizedError {
    case noTenantSelected
    case keychainLoadFailed(OSStatus)
    case keychainSaveFailed(OSStatus)
    case keychainDeleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .noTenantSelected:
            return "No couple selected. Please select your wedding couple to continue."
        case .keychainLoadFailed(let status):
            return "Failed to load session from keychain: \(friendlyKeychainMessage(status))"
        case .keychainSaveFailed(let status):
            return "Failed to save session to keychain: \(friendlyKeychainMessage(status))"
        case .keychainDeleteFailed(let status):
            return "Failed to delete session from keychain: \(friendlyKeychainMessage(status))"
        }
    }

    private func friendlyKeychainMessage(_ status: OSStatus) -> String {
        switch status {
        case errSecItemNotFound:
            return "Item not found"
        case errSecDuplicateItem:
            return "Item already exists"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecInteractionNotAllowed:
            return "User interaction not allowed"
        case errSecUnimplemented:
            return "Function not implemented"
        case errSecParam:
            return "Invalid parameters"
        case errSecAllocate:
            return "Failed to allocate memory"
        default:
            return "Error code \(status)"
        }
    }
}

/// Manages the current user session and couple/tenant ID
@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var currentTenantId: UUID?

    private let keychainService = "com.jelizica.weddingplanning.session"
    private let tenantIdAccount = "tenant-id"

    private let logger = AppLogger.auth

    private init() {
        loadSession()
    }

    // MARK: - Session Management

    func setTenantId(_ tenantId: UUID) {
        let tenantChanged = currentTenantId != tenantId
        currentTenantId = tenantId
        saveTenantIdToKeychain(tenantId)

        // Clear repository caches when tenant changes
        if tenantChanged {
            Task {
                do {
                    await RepositoryCache.clearAll()
                    logger.info("Cleared repository caches on tenant change")
                } catch {
                    logger.warning("Failed to clear repository caches on tenant change: \(error.localizedDescription)")
                }
            }
        }

        logger.info("Session tenant ID set: \(tenantId.uuidString)")
    }

    func getTenantId() -> UUID? {
        guard let tenantId = currentTenantId else {
            logger.warning("No tenant ID set in session - user needs to select a couple")
            return nil
        }
        return tenantId
    }

    func requireTenantId() throws -> UUID {
        guard let tenantId = currentTenantId else {
            logger.error("Attempted to access data without tenant selection")
            throw SessionError.noTenantSelected
        }
        return tenantId
    }

    func clearSession() {
        currentTenantId = nil
        deleteTenantIdFromKeychain()
        logger.info("Session cleared")
    }

    // MARK: - Keychain Storage

    private func loadSession() {
        if let tenantIdString = loadFromKeychain(account: tenantIdAccount),
           let tenantId = UUID(uuidString: tenantIdString) {
            currentTenantId = tenantId
            logger.info("Session loaded from keychain")
        } else {
            logger.debug("No saved session found, will use default on first access")
        }
    }

    private func saveTenantIdToKeychain(_ tenantId: UUID) {
        do {
            try saveToKeychain(value: tenantId.uuidString, account: tenantIdAccount)
        } catch {
            logger.error("Failed to save tenant ID to keychain: \(error.localizedDescription)")
        }
    }

    private func deleteTenantIdFromKeychain() {
        do {
            try deleteFromKeychain(account: tenantIdAccount)
        } catch {
            logger.error("Failed to delete tenant ID from keychain: \(error.localizedDescription)")
        }
    }

    private func loadFromKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        if status != errSecItemNotFound {
            logger.warning("Keychain load failed for account \(account): \(SessionError.keychainLoadFailed(status).localizedDescription)")
        }

        return nil
    }

    private func saveToKeychain(value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else {
            logger.error("Failed to encode value for keychain account: \(account)")
            throw SessionError.keychainSaveFailed(errSecParam)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        // Delete existing item
        let deleteStatus = SecItemDelete(query as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            logger.warning("Failed to delete existing keychain item for account \(account): \(SessionError.keychainDeleteFailed(deleteStatus).localizedDescription)")
        }

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            logger.debug("Session value saved to keychain for account: \(account)")
        } else {
            let error = SessionError.keychainSaveFailed(status)
            logger.error("Failed to save to keychain for account \(account): \(error.localizedDescription)")
            throw error
        }
    }

    private func deleteFromKeychain(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            let error = SessionError.keychainDeleteFailed(status)
            logger.error("Failed to delete from keychain for account \(account): \(error.localizedDescription)")
            throw error
        } else if status == errSecSuccess {
            logger.debug("Keychain item deleted for account: \(account)")
        }
    }
}
