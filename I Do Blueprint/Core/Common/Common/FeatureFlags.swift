import Foundation
import Supabase
import PostgREST

/// Response model for feature flags from Supabase
struct FeatureFlagsResponse: Codable {
    let flags: [String: Bool]
    let version: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case flags
        case version
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

/// Feature flags for gradual rollout of new architecture
/// Allows safe migration with instant rollback capability
enum FeatureFlags {
    // MARK: - Feature Flag Keys

    private static let budgetStoreV2Key = "useBudgetStoreV2"
    private static let guestStoreV2Key = "useGuestStoreV2"
    private static let vendorStoreV2Key = "useVendorStoreV2"

    // High-priority completed features
    private static let enableTimelineMilestonesKey = "enableTimelineMilestones"
    private static let enableAdvancedBudgetExportKey = "enableAdvancedBudgetExport"
    private static let enableVisualPlanningPasteKey = "enableVisualPlanningPaste"
    private static let enableImagePickerKey = "enableImagePicker"
    private static let enableTemplateApplicationKey = "enableTemplateApplication"
    private static let enableExpenseDetailsKey = "enableExpenseDetails"
    private static let enableBudgetAnalyticsActionsKey = "enableBudgetAnalyticsActions"

    // MARK: - Provider Selection

    private static var provider: FeatureFlagProvider {
        #if DEBUG
        return UserDefaultsFeatureFlagProvider()
        #else
        return RemoteFeatureFlagProvider()
        #endif
    }

    // MARK: - Budget Feature

    /// Whether to use the new BudgetStoreV2 with repository pattern
    static var useBudgetStoreV2: Bool {
        // For development/testing, you can hardcode this to true
        // For production, use UserDefaults or remote config
        #if DEBUG
        return UserDefaults.standard.bool(forKey: budgetStoreV2Key)
        #else
        // Production rollout strategy
        return isEnabledWithRollout(key: budgetStoreV2Key, rolloutPercentage: 0)
        #endif
    }

    static func enableBudgetStoreV2() {
        provider.setEnabled(budgetStoreV2Key, value: true)
    }

    static func disableBudgetStoreV2() {
        provider.setEnabled(budgetStoreV2Key, value: false)
    }

    // MARK: - Guest Feature (Future)

    static var useGuestStoreV2: Bool {
        UserDefaults.standard.bool(forKey: guestStoreV2Key)
    }

    static func enableGuestStoreV2() {
        UserDefaults.standard.set(true, forKey: guestStoreV2Key)
    }

    static func disableGuestStoreV2() {
        UserDefaults.standard.set(false, forKey: guestStoreV2Key)
    }

    // MARK: - Vendor Feature (Future)

    static var useVendorStoreV2: Bool {
        UserDefaults.standard.bool(forKey: vendorStoreV2Key)
    }

    static func enableVendorStoreV2() {
        UserDefaults.standard.set(true, forKey: vendorStoreV2Key)
    }

    static func disableVendorStoreV2() {
        UserDefaults.standard.set(false, forKey: vendorStoreV2Key)
    }

    // MARK: - Timeline Milestones Feature (✅ Completed)

    static var enableTimelineMilestones: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: enableTimelineMilestonesKey) as? Bool ?? true
        #else
        return isEnabledWithRollout(key: enableTimelineMilestonesKey, rolloutPercentage: 100)
        #endif
    }

    static func setTimelineMilestones(enabled: Bool) {
        provider.setEnabled(enableTimelineMilestonesKey, value: enabled)
    }

    // MARK: - Advanced Budget Export Feature (✅ Completed)

    static var enableAdvancedBudgetExport: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: enableAdvancedBudgetExportKey) as? Bool ?? true
        #else
        return isEnabledWithRollout(key: enableAdvancedBudgetExportKey, rolloutPercentage: 100)
        #endif
    }

    static func setAdvancedBudgetExport(enabled: Bool) {
        provider.setEnabled(enableAdvancedBudgetExportKey, value: enabled)
    }

    // MARK: - Visual Planning Paste Feature (✅ Completed)

    static var enableVisualPlanningPaste: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: enableVisualPlanningPasteKey) as? Bool ?? true
        #else
        return isEnabledWithRollout(key: enableVisualPlanningPasteKey, rolloutPercentage: 100)
        #endif
    }

    static func setVisualPlanningPaste(enabled: Bool) {
        provider.setEnabled(enableVisualPlanningPasteKey, value: enabled)
    }

    // MARK: - Image Picker Feature (✅ Completed)

    static var enableImagePicker: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: enableImagePickerKey) as? Bool ?? true
        #else
        return isEnabledWithRollout(key: enableImagePickerKey, rolloutPercentage: 100)
        #endif
    }

    static func setImagePicker(enabled: Bool) {
        provider.setEnabled(enableImagePickerKey, value: enabled)
    }

    // MARK: - Template Application Feature (✅ Completed)

    static var enableTemplateApplication: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: enableTemplateApplicationKey) as? Bool ?? true
        #else
        return isEnabledWithRollout(key: enableTemplateApplicationKey, rolloutPercentage: 100)
        #endif
    }

    static func setTemplateApplication(enabled: Bool) {
        provider.setEnabled(enableTemplateApplicationKey, value: enabled)
    }

    // MARK: - Expense Details Feature (✅ Completed)

    static var enableExpenseDetails: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: enableExpenseDetailsKey) as? Bool ?? true
        #else
        return isEnabledWithRollout(key: enableExpenseDetailsKey, rolloutPercentage: 100)
        #endif
    }

    static func setExpenseDetails(enabled: Bool) {
        provider.setEnabled(enableExpenseDetailsKey, value: enabled)
    }

    // MARK: - Budget Analytics Actions Feature (✅ Completed)

    static var enableBudgetAnalyticsActions: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: enableBudgetAnalyticsActionsKey) as? Bool ?? true
        #else
        return isEnabledWithRollout(key: enableBudgetAnalyticsActionsKey, rolloutPercentage: 100)
        #endif
    }

    static func setBudgetAnalyticsActions(enabled: Bool) {
        provider.setEnabled(enableBudgetAnalyticsActionsKey, value: enabled)
    }

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
        [
            "BudgetStoreV2": useBudgetStoreV2,
            "GuestStoreV2": useGuestStoreV2,
            "VendorStoreV2": useVendorStoreV2,
            "TimelineMilestones": enableTimelineMilestones,
            "AdvancedBudgetExport": enableAdvancedBudgetExport,
            "VisualPlanningPaste": enableVisualPlanningPaste,
            "ImagePicker": enableImagePicker,
            "TemplateApplication": enableTemplateApplication,
            "ExpenseDetails": enableExpenseDetails,
            "BudgetAnalyticsActions": enableBudgetAnalyticsActions
        ]
    }

    /// Reset all feature flags
    static func resetAll() {
        UserDefaults.standard.removeObject(forKey: budgetStoreV2Key)
        UserDefaults.standard.removeObject(forKey: guestStoreV2Key)
        UserDefaults.standard.removeObject(forKey: vendorStoreV2Key)
        UserDefaults.standard.removeObject(forKey: enableTimelineMilestonesKey)
        UserDefaults.standard.removeObject(forKey: enableAdvancedBudgetExportKey)
        UserDefaults.standard.removeObject(forKey: enableVisualPlanningPasteKey)
        UserDefaults.standard.removeObject(forKey: enableImagePickerKey)
        UserDefaults.standard.removeObject(forKey: enableTemplateApplicationKey)
        UserDefaults.standard.removeObject(forKey: enableExpenseDetailsKey)
        UserDefaults.standard.removeObject(forKey: enableBudgetAnalyticsActionsKey)
        AppLogger.general.info("Reset all feature flags")
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

 // Enable new architecture for testing:
 FeatureFlags.enableBudgetStoreV2()

 // Disable if issues are found:
 FeatureFlags.disableBudgetStoreV2()

 // Check status:
 print(FeatureFlags.status())

 // In production, gradually roll out:
 // 1. Start with 10% (change rolloutPercentage to 10)
 // 2. Monitor for issues
 // 3. Increase to 25%, 50%, 100%
 // 4. If issues occur, set to 0 for instant rollback

 */
