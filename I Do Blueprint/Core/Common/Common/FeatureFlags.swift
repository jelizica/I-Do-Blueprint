import Foundation
import Supabase
import PostgREST

// MARK: - Security Note
//
// UserDefaults is intentionally used for feature flag storage.
// This is a SAFE and APPROPRIATE use of UserDefaults because:
//
// 1. **Non-Sensitive Data**: Feature flags are boolean configuration values,
//    not credentials, tokens, or personally identifiable information (PII).
//
// 2. **No Security Impact**: Knowing which features are enabled/disabled
//    does not compromise user security or data privacy.
//
// 3. **Performance**: UserDefaults provides fast, synchronous access which
//    is critical for feature flag checks that happen frequently.
//
// 4. **Persistence**: Feature flags need to persist across app launches
//    without requiring authentication or network access.
//
// 5. **Debug Override**: Developers need to easily toggle flags during testing.
//
// For sensitive data (API keys, tokens, credentials), use:
// - Keychain (see SecureAPIKeyManager.swift)
// - Supabase Auth (for session tokens)
//
// Reference: OWASP MASVS-STORAGE-1 - "Sensitive data is stored securely"
// Feature flags are NOT sensitive data per OWASP classification.

/// Response model for feature flags from Supabase
struct FeatureFlagsResponse: Codable {
    let flags: [String: Bool]
    let version: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case flags = "flags"
        case version = "version"
        case updatedAt = "updated_at"
    }
}

/// Protocol for feature flag providers
protocol FeatureFlagProvider {
    func isEnabled(_ key: String) -> Bool
    func setEnabled(_ key: String, value: Bool)
}

/// UserDefaults-based feature flag provider (for Debug/Preview)
struct UserDefaultsFeatureFlagProvider: FeatureFlagProvider {
    private let logger = AppLogger.general

    func isEnabled(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    func setEnabled(_ key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
        logger.debug("Feature flag '\(key)' set to \(value)")
    }
}

/// Remote config-based feature flag provider (for Release)
struct RemoteFeatureFlagProvider: FeatureFlagProvider {
    private let logger = AppLogger.general
    private static let cacheKey = "remoteFeatureFlagsCache"
    private static let cacheTimestampKey = "remoteFeatureFlagsCacheTimestamp"
    private static let cacheTTL: TimeInterval = 3600 // 1 hour

    func isEnabled(_ key: String) -> Bool {
        // Check UserDefaults override first
        if UserDefaults.standard.object(forKey: key) != nil {
            return UserDefaults.standard.bool(forKey: key)
        }

        // Check cached remote config
        if let cachedFlags = loadCachedFlags() {
            return cachedFlags[key] as? Bool ?? false
        }

        // If no cache, return false
        return false
    }

    func setEnabled(_ key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
        logger.info("Feature flag '\(key)' overridden to \(value)")
    }

    // MARK: - Remote Config Methods

    /// Fetches remote feature flags from Supabase
    /// Requires 'feature_flags' table with 'flags' JSONB column
    static func fetchRemoteFlags() async {
        let logger = AppLogger.general

        do {
            guard let client = SupabaseManager.shared.client else {
                logger.warning("Supabase client not available - using cached/default feature flags")
                return
            }

            // Query the current_feature_flags view for the active flags
            let response: FeatureFlagsResponse = try await client
                .from("current_feature_flags")
                .select()
                .single()
                .execute()
                .value

            // Cache the flags dictionary
            cacheFlags(response.flags)
            logger.info("Remote feature flags fetched and cached successfully (version: \(response.version))")

        } catch {
            logger.error("Failed to fetch remote feature flags - using cached/default values", error: error)
            // Gracefully degrade to cached values - don't crash the app
        }
    }

    /// Loads flags from UserDefaults cache
    private func loadCachedFlags() -> [String: Bool]? {
        // Check if cache is still valid
        if let cacheTimestamp = UserDefaults.standard.object(forKey: Self.cacheTimestampKey) as? Date {
            let age = Date().timeIntervalSince(cacheTimestamp)
            if age > Self.cacheTTL {
                logger.debug("Remote flags cache expired")
                return nil
            }
        } else {
            return nil
        }

        // Load cached flags
        if let dict = UserDefaults.standard.dictionary(forKey: Self.cacheKey) as? [String: Bool] {
            return dict
        }
        return nil
    }

    /// Caches flags to UserDefaults
    private static func cacheFlags(_ flags: [String: Bool]) {
        UserDefaults.standard.set(flags, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
    }

    /// Clears the remote flags cache
    static func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        AppLogger.general.info("Remote feature flags cache cleared")
    }
}

/// Feature flags infrastructure for gradual feature rollout
/// Currently no active flags - add flags here when implementing new experimental features
/// See Beads issue I Do Blueprint-6ym for implementation guide
enum FeatureFlags {
    // MARK: - Feature Flag Keys
    // Add new feature flag keys here when needed
    
    // Example:
    // private static let enableNewFeatureKey = "enableNewFeature"

    // MARK: - Provider Selection

    private static var provider: FeatureFlagProvider {
        #if DEBUG
        return UserDefaultsFeatureFlagProvider()
        #else
        return RemoteFeatureFlagProvider()
        #endif
    }

    // MARK: - Feature Flag Definitions
    // Add new feature flags here following this pattern:
    //
    // static var enableNewFeature: Bool {
    //     #if DEBUG
    //     return UserDefaults.standard.object(forKey: enableNewFeatureKey) as? Bool ?? false
    //     #else
    //     return isEnabledWithRollout(key: enableNewFeatureKey, rolloutPercentage: 0)
    //     #endif
    // }
    //
    // static func setNewFeature(enabled: Bool) {
    //     provider.setEnabled(enableNewFeatureKey, value: enabled)
    // }

    // MARK: - Rollout Strategy

    /// Implements gradual percentage-based rollout
    /// - Parameters:
    ///   - key: Feature flag key
    ///   - rolloutPercentage: Percentage of users to enable (0-100)
    /// - Returns: Whether feature is enabled for this user
    private static func isEnabledWithRollout(key: String, rolloutPercentage: Int) -> Bool {
        // Check for manual override
        if UserDefaults.standard.object(forKey: key) != nil {
            return UserDefaults.standard.bool(forKey: key)
        }

        // If no override, use rollout percentage
        guard rolloutPercentage > 0 else { return false }
        guard rolloutPercentage < 100 else { return true }

        // Get stable user identifier for consistent rollout
        let userId = getUserIdentifier()
        let userHash = abs(userId.hashValue) % 100

        return userHash < rolloutPercentage
    }

    /// Get a stable user identifier for rollout
    private static func getUserIdentifier() -> String {
        // Use a stable device/user identifier
        // For macOS, we can use a UUID stored in UserDefaults
        let key = "deviceIdentifier"

        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    // MARK: - Feature Status

    /// Get status of all feature flags
    static func status() -> [String: Bool] {
        // Return empty dictionary when no flags are active
        // Add flags here as they're implemented
        [:]
    }

    /// Reset all feature flags to their defaults
    static func resetAll() {
        // Add flag reset logic here as flags are implemented
        AppLogger.general.info("Reset all feature flags to defaults")
    }

    /// Refreshes remote feature flags in the background
    static func refreshRemoteFlags() {
        #if !DEBUG
        Task.detached(priority: .background) {
            await RemoteFeatureFlagProvider.fetchRemoteFlags()
        }
        #endif
    }
}

// MARK: - Usage Examples

/*

 // When adding a new feature flag:
 
 // 1. Add key constant
 private static let enableNewFeatureKey = "enableNewFeature"
 
 // 2. Add getter (defaults to false for new features)
 static var enableNewFeature: Bool {
     #if DEBUG
     return UserDefaults.standard.object(forKey: enableNewFeatureKey) as? Bool ?? false
     #else
     return isEnabledWithRollout(key: enableNewFeatureKey, rolloutPercentage: 0)
     #endif
 }
 
 // 3. Add setter
 static func setNewFeature(enabled: Bool) {
     provider.setEnabled(enableNewFeatureKey, value: enabled)
 }
 
 // 4. Add to status() dictionary
 // 5. Add to resetAll() cleanup
 // 6. Add to FeatureFlagsSettingsView.swift UI
 // 7. Use in views with conditional rendering:
 
 if FeatureFlags.enableNewFeature {
     NewFeatureView()
 }
 
 // See Beads issue I Do Blueprint-6ym for complete implementation guide

 */
