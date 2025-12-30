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

    // MARK: - Tenant Switching State (Phase 3.1)
    @Published private(set) var isSwitchingTenant = false
    @Published private(set) var switchingToCoupleName: String?

    // MARK: - Recently Viewed Couples (Phase 3.2)
    @Published private(set) var recentCouples: [RecentCouple] = []
    private let maxRecentCouples = 5
    private let recentCouplesKey = "recentCouples"

    private let keychainService = "com.jelizica.weddingplanning.session"
    private let tenantIdAccount = "tenant-id"

    private let logger = AppLogger.auth

    private init() {
        // IMPORTANT: Do NOT access Keychain during init() to avoid sandbox crashes
        // Defer session loading until first access via lazy initialization
        Task { @MainActor in
            loadSession()
            loadRecentCouples()
        }
    }

    // MARK: - Session Management

    /// Sets the tenant ID with optional couple name for visual feedback
    /// - Parameters:
    ///   - tenantId: The UUID of the couple/tenant to switch to
    ///   - coupleName: Optional couple name for loading overlay (Phase 3.1) and recent tracking (Phase 3.2)
    ///   - weddingDate: Optional wedding date for recent tracking (Phase 3.2)
    func setTenantId(_ tenantId: UUID, coupleName: String? = nil, weddingDate: Date? = nil) async {
        let previousTenantId = currentTenantId
        let tenantChanged = previousTenantId != nil && previousTenantId != tenantId

        // Set switching state for visual feedback (Phase 3.1)
        if let coupleName = coupleName {
            isSwitchingTenant = true
            switchingToCoupleName = coupleName
            logger.debug("Starting tenant switch to: \(coupleName)")
        }

        currentTenantId = tenantId
        saveTenantIdToKeychain(tenantId)

        // Update thread-safe tenant context for background consumers
        await TenantContextProvider.shared.setTenantId(tenantId)

        // Clear repository caches and reset ALL stores when tenant changes
        if tenantChanged {
            logger.info("Tenant changed from \(previousTenantId!.uuidString) to \(tenantId.uuidString)")

            // Clear repository caches
            await RepositoryCache.shared.clearAll()
            logger.info("Cleared repository caches on tenant change")

            // Reset ALL stores so they reload data for the new tenant
            AppStores.shared.resetAllStores()
            logger.info("Reset all store loaded states for new tenant")

            // Post notification for any observers
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .tenantDidChange,
                    object: nil,
                    userInfo: [
                        "previousId": previousTenantId!.uuidString,
                        "newId": tenantId.uuidString
                    ]
                )
            }
            logger.info("Posted tenant change notification")
        } else if previousTenantId == nil {
            logger.info("Initial tenant selection: \(tenantId.uuidString)")
        }

        logger.info("Session tenant ID set: \(tenantId.uuidString)")

        // Update recent couples list (Phase 3.2)
        if let coupleName = coupleName {
            updateRecentCouples(id: tenantId, name: coupleName, weddingDate: weddingDate)
        }

        // Clear switching state (Phase 3.1)
        if coupleName != nil {
            // Small delay to ensure UI updates are visible
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            isSwitchingTenant = false
            switchingToCoupleName = nil
            logger.debug("Tenant switch complete")
        }
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
        Task { await TenantContextProvider.shared.clear() }
        logger.info("Session cleared")
    }

    // MARK: - Keychain Storage

    private func loadSession() {
        if let tenantIdString = loadFromKeychain(account: tenantIdAccount),
           let tenantId = UUID(uuidString: tenantIdString) {
            currentTenantId = tenantId
            // Seed thread-safe context on load as well
            Task { await TenantContextProvider.shared.setTenantId(tenantId) }
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

    /// Saves a value to the Keychain with appropriate security settings.
    ///
    /// Security Model:
    /// - Uses `kSecAttrAccessibleAfterFirstUnlock` to protect data when device is locked
    /// - Does NOT require biometric/passcode for each access because:
    ///   1. Tenant ID is not a credential - it's a pointer to which data to load
    ///   2. Actual data security is enforced by Supabase Row Level Security (RLS)
    ///   3. Requiring biometric for every app launch would create poor UX
    ///   4. The Supabase auth token (managed separately) provides authentication
    ///
    /// For truly sensitive items (API keys, credentials), see `SecureAPIKeyManager`
    /// which uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
    private func saveToKeychain(value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else {
            logger.error("Failed to encode value for keychain account: \(account)")
            throw SessionError.keychainSaveFailed(errSecParam)
        }

        // Delete query (without accessibility attribute)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]

        // Delete existing item
        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            logger.warning("Failed to delete existing keychain item for account \(account): \(SessionError.keychainDeleteFailed(deleteStatus).localizedDescription)")
        }

        // Add query with security attributes
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            // Protect data when device is locked, but allow access after first unlock
            // This is appropriate for session state (not credentials)
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Add new item
        let status = SecItemAdd(addQuery as CFDictionary, nil)
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

    // MARK: - Recently Viewed Couples (Phase 3.2)

    /// Updates the recent couples list with a newly accessed couple
    /// - Parameters:
    ///   - id: The couple's UUID
    ///   - name: The couple's display name
    ///   - weddingDate: Optional wedding date
    func updateRecentCouples(id: UUID, name: String, weddingDate: Date?) {
        // Remove if already exists (to update position)
        recentCouples.removeAll { $0.id == id }

        // Add to front of list
        let recent = RecentCouple(
            id: id,
            displayName: name,
            weddingDate: weddingDate,
            lastAccessedAt: Date()
        )
        recentCouples.insert(recent, at: 0)

        // Keep only last N couples
        if recentCouples.count > maxRecentCouples {
            recentCouples = Array(recentCouples.prefix(maxRecentCouples))
        }

        // Persist to UserDefaults
        saveRecentCouples()

        logger.debug("Updated recent couples: \(name) added to top of list (\(recentCouples.count) total)")
    }

    /// Loads recent couples from UserDefaults
    private func loadRecentCouples() {
        guard let data = UserDefaults.standard.data(forKey: recentCouplesKey) else {
            logger.debug("No recent couples found in UserDefaults")
            return
        }

        do {
            let decoded = try JSONDecoder().decode([RecentCouple].self, from: data)
            recentCouples = decoded
            logger.info("Loaded \(recentCouples.count) recent couples from UserDefaults")
        } catch {
            logger.error("Failed to decode recent couples: \(error.localizedDescription)")
            recentCouples = []
        }
    }

    /// Saves recent couples to UserDefaults
    private func saveRecentCouples() {
        do {
            let encoded = try JSONEncoder().encode(recentCouples)
            UserDefaults.standard.set(encoded, forKey: recentCouplesKey)
            logger.debug("Saved \(recentCouples.count) recent couples to UserDefaults")
        } catch {
            logger.error("Failed to encode recent couples: \(error.localizedDescription)")
        }
    }

    /// Clears all recent couples
    func clearRecentCouples() {
        recentCouples = []
        UserDefaults.standard.removeObject(forKey: recentCouplesKey)
        logger.info("Cleared all recent couples")
    }
}
