//
//  SupabaseClient.swift
//  My Wedding Planning App
//
//  Created by Jessica Clark on 9/26/25.
//

import Auth
import Combine
import Foundation
import Functions
import PostgREST
import Realtime
import Supabase
import SwiftUI

// Helper struct for type-erased encoding
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: some Encodable) {
        _encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    private(set) var client: SupabaseClient?

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var configurationError: ConfigurationError?

    private let logger = AppLogger.api

    // Channel registry for tracking active realtime subscriptions
    @MainActor
    private var activeChannels: [RealtimeChannelV2] = []

    // Intent registry for resilient resubscription
    @MainActor
    private var intendedTopics: Set<String> = [] // e.g., "guest_changes", "vendor_changes"

    // Track initialization state
    private var initializationTask: Task<Void, Never>?
    private var isInitialized = false

    private init() {
        // IMPORTANT: Do NOT access file system during init() to avoid sandbox crashes
        // Defer client creation until first access via lazy initialization
        self.client = nil
        self.configurationError = nil

        // Observe tenant changes to re-scope realtime channels
        NotificationCenter.default.addObserver(forName: .tenantDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.handleTenantChange()
            }
        }

        // Schedule initialization for next run loop after sandbox is ready
        initializationTask = Task { @MainActor in
            await initializeClient()
            isInitialized = true
        }
    }

    @MainActor
    private func initializeClient() async {
        // Try to initialize, but don't crash on failure
        do {
            let newClient = try Self.createSupabaseClient()
            self.client = newClient
            self.configurationError = nil

            // First check auth state, then setup listener to avoid race conditions
            await checkAuthState()
            await setupAuthListener()

            logger.info("Supabase client initialized successfully")
        } catch let error as ConfigurationError {
            logger.error("Configuration error during initialization", error: error)
            self.configurationError = error
        } catch {
            logger.error("Unexpected error during initialization", error: error)
            self.configurationError = .configFileUnreadable
        }
    }

    // MARK: - Client Access with Initialization Wait

    /// Wait for a ready Supabase client.
    /// Fast-path returns immediately if a client already exists. Otherwise, race initialization with a timeout.
    /// Can be called from any isolation context
    func waitForClient(timeout: TimeInterval = 3.0) async throws -> SupabaseClient {
        // Fast-path: if a client already exists and no config error, return it without waiting
        if let fastClient = await MainActor.run(resultType: SupabaseClient?.self, body: {
            if self.configurationError != nil { return nil }
            return self.client
        }) {
            return fastClient
        }

        // Race the initialization task against a timeout; if timed out but client becomes available, use it
        let deadline = UInt64(max(0, timeout) * 1_000_000_000)

        // Local timeout error
        struct _WaitTimeout: Error {}

        do {
            return try await withThrowingTaskGroup(of: SupabaseClient.self) { group in
                // Initialization completion path
                group.addTask { [weak self] in
                    guard let self else { throw ConfigurationError.configFileUnreadable }
                    await self.initializationTask?.value
                    return try await MainActor.run(resultType: SupabaseClient.self, body: {
                        if let error = self.configurationError { throw error }
                        guard let client = self.client else { throw ConfigurationError.configFileUnreadable }
                        return client
                    })
                }
                // Timeout path
                group.addTask { [weak self] in
                    guard let self else { throw ConfigurationError.configFileUnreadable }
                    try await Task.sleep(nanoseconds: deadline)
                    return try await MainActor.run(resultType: SupabaseClient.self, body: {
                        if let client = self.client { return client }
                        throw _WaitTimeout()
                    })
                }

                // Return whichever finishes first
                let client = try await group.next()!
                group.cancelAll()
                return client
            }
        } catch {
            // If timed out or failed, but a client now exists, return it; otherwise propagate
            if let fallback = await MainActor.run(resultType: SupabaseClient?.self, body: { self.client }) { return fallback }
            if let configErr = await MainActor.run(resultType: ConfigurationError?.self, body: { self.configurationError }) { throw configErr }
            throw error
        }
    }

    // MARK: - Client Creation (Throwing)

    private static func createSupabaseClient() throws -> SupabaseClient {
        let logger = AppLogger.api

        // Use AppConfig with plist fallback
        let supabaseURLString = AppConfig.getSupabaseURL()
        let supabaseAnonKey = AppConfig.getSupabaseAnonKey()

        logger.debug("Loading Supabase configuration...")

        #if DEBUG
        // Check if we're using hardcoded config or plist fallback
        let usingHardcodedConfig = (AppConfig.loadFromPlist(key: "SUPABASE_URL") == nil)
        if usingHardcodedConfig {
            logger.debug("Using hardcoded AppConfig values")
        } else {
            logger.debug("Using Config.plist fallback values")
        }
        logger.logPrivate("SUPABASE_URL: \(supabaseURLString)", level: .debug)
        logger.logPrivate("url present: true, anonKey present: true, serviceKey present: false", level: .debug)
        #endif

        // SECURITY: Check if service-role key is present in the bundle (plist only)
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: configPath),
           let _ = config["SUPABASE_SERVICE_ROLE_KEY"] as? String {
            logger.error("CRITICAL SECURITY VIOLATION: Service-role key found in Config.plist")
            throw ConfigurationError.securityViolation(
                "Service-role key must not be included in the app bundle"
            )
        }

        guard let supabaseURL = URL(string: supabaseURLString) else {
            logger.error("Invalid URL format")
            throw ConfigurationError.invalidURLFormat(supabaseURLString)
        }

        #if DEBUG
        logger.logPrivate("Created Supabase URL: \(supabaseURL)", level: .debug)
        #endif
        logger.debug("Initializing Supabase client...")

        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey,
            options: SupabaseClientOptions(
                db: .init(schema: "public"),
                auth: .init(flowType: .pkce),
                global: .init(
                    headers: ["x-client-info": "wedding-app-macos/1.0.0"])))
    }

    // MARK: - Safe Client Access

    var safeClient: SupabaseClient? {
        if let error = configurationError {
            logger.error("Cannot access Supabase client due to configuration error", error: error)
            return nil
        }
        return client
    }

    @MainActor
    private func setupAuthListener() async {
        guard let client = client else { return }

        for await authState in client.auth.authStateChanges {
            let session = authState.session

            if let session {
                isAuthenticated = true
                currentUser = session.user

                // Set Sentry user context on login
                SentryService.shared.setUser(
                    userId: session.user.id.uuidString,
                    email: session.user.email,
                    username: session.user.email
                )

                logger.info("User authenticated and Sentry context set")
            } else {
                isAuthenticated = false
                currentUser = nil

                // Clear Sentry user context on logout
                SentryService.shared.clearUser()

                // Clean up channels when user signs out
                await cleanupChannels()

                logger.info("User signed out and Sentry context cleared")
            }
        }
    }

    @MainActor
    private func checkAuthState() async {
        guard let client = client else {
            isAuthenticated = false
            currentUser = nil
            return
        }

        do {
            let session = try await client.auth.session
            isAuthenticated = true
            currentUser = session.user

            // Set Sentry user context if already logged in
            SentryService.shared.setUser(
                userId: session.user.id.uuidString,
                email: session.user.email,
                username: session.user.email
            )

            logger.info("Existing session found, Sentry context set")
        } catch {
            isAuthenticated = false
            currentUser = nil

            // Clear Sentry user context if no session
            SentryService.shared.clearUser()
        }
    }

    // MARK: - Authentication Methods

    func signIn(email: String, password: String) async throws {
        guard let client = client else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        do {
            try await client.auth.signIn(email: email, password: password)
            logger.infoWithRedactedEmail("auth_login_success for", email: email)
        } catch {
            logger.error("auth_login_failure", error: error)
            throw error
        }
    }

    func signUp(email: String, password: String) async throws {
        guard let client = client else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        do {
            try await client.auth.signUp(email: email, password: password)
            logger.infoWithRedactedEmail("auth_signup_success for", email: email)
        } catch {
            logger.error("auth_signup_failure", error: error)
            throw error
        }
    }

    func signOut() async throws {
        guard let client = client else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        do {
            // Clean up all tracked channels
            await cleanupChannels()
            logger.info("Cleaned up all realtime channels")

            // Clear session manager (tenant ID and keychain)
            await SessionManager.shared.clearSession()
            logger.info("Cleared session manager and keychain")

            // Reset all store loaded states
            await MainActor.run {
                AppStores.shared.resetAllStores()
            }
            logger.info("Reset all store loaded states")

            try await client.auth.signOut()

            // Clear all repository caches
            do {
                await RepositoryCache.shared.clearAll()
                logger.info("Cleared all repository caches")
            } catch {
                logger.warning("Failed to clear repository caches: \(error.localizedDescription)")
            }

            logger.info("auth_signout_success")
        } catch {
            logger.error("auth_signout_failure", error: error)
            throw error
        }
    }

    /// Clean up all active realtime channels (idempotent)
    @MainActor
    private func cleanupChannels() async {
        // Close each tracked channel
        for channel in activeChannels {
            do {
                try await channel.unsubscribe()
            } catch {
                logger.warning("Failed to unsubscribe from channel: \(error.localizedDescription)")
            }
        }
        // Clear the registry
        activeChannels.removeAll()
        // Remove all channels from the client
        if let client = client {
            await client.realtimeV2.removeAllChannels()
        }
        logger.debug("All realtime channels cleaned up")
    }

    /// Unsubscribe from all active realtime channels (public API for compatibility)
    @MainActor
    func unsubscribeAllChannels() async {
        await cleanupChannels()
    }

    func resetPassword(email: String) async throws {
        guard let client = client else {
            throw configurationError ?? ConfigurationError.configFileUnreadable
        }

        do {
            try await client.auth.resetPasswordForEmail(email)
            logger.infoWithRedactedEmail("auth_password_reset_requested for", email: email)
        } catch {
            logger.error("auth_password_reset_failure", error: error)
            throw error
        }
    }
}

// MARK: - Tenant/Realtime Helpers

extension SupabaseManager {
    @MainActor
    private func namespacedChannelName(base: String) -> String {
        if let tenantId = SessionManager.shared.getTenantId() {
            return "\(base)_\(tenantId.uuidString)"
        }
        return base
    }

    @MainActor
    fileprivate func handleTenantChange() async {
        logger.info("Tenant changed - cleaning up and re-subscribing realtime channels")
        await cleanupChannels()
        for topic in intendedTopics {
            _ = await ensureSubscription(forBaseTopic: topic)
        }
    }

    @discardableResult
    func subscribeToGuestChanges() async -> RealtimeChannelV2? {
        await MainActor.run { intendedTopics.insert("guest_changes") }
        return await ensureSubscription(forBaseTopic: "guest_changes")
    }

    @discardableResult
    func subscribeToVendorChanges() async -> RealtimeChannelV2? {
        await MainActor.run { intendedTopics.insert("vendor_changes") }
        return await ensureSubscription(forBaseTopic: "vendor_changes")
    }

    // Ensures subscription for a base topic with retry/backoff and tenant namespacing
    @discardableResult
    func ensureSubscription(forBaseTopic base: String) async -> RealtimeChannelV2? {
        guard let client = client else {
            logger.error("Cannot ensure subscription for \(base): client not initialized")
            return nil
        }

        let channelName = await MainActor.run { self.namespacedChannelName(base: base) }
        let channel = client.realtimeV2.channel(channelName)

        do {
            let _: Void = try await withRetry(policy: .network, operationName: "realtime_subscribe_\(channelName)") {
                Task { @MainActor in
                    AppLogger.network.debug("Subscribing to realtime channel: \(channelName)")
                }
                try await channel.subscribeWithError()
                return ()
            }
            await MainActor.run {
                self.activeChannels.append(channel)
                AppLogger.network.info("Subscribed to realtime channel: \(channelName)")
            }
        } catch {
            await MainActor.run {
                AppLogger.network.error("Failed to subscribe after retries: \(channelName)", error: error)
            }
        }
        return channel
    }
}

// MARK: - Network Testing

extension SupabaseManager {
    private func testNetworkConnectivity(url: URL) async {
        logger.debug("Testing network connectivity to: \(url)")

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                logger.info("Network test successful - Status: \(httpResponse.statusCode)")
            } else {
                logger.warning("Network test - Non-HTTP response")
            }
        } catch {
            logger.error("Network test failed", error: error)
            if let urlError = error as? URLError {
                logger.error("Error code: \(urlError.code.rawValue)")
                logger.error("Description: \(urlError.localizedDescription)")
            }
        }
    }
}

// MARK: - Auth Context Extensions

extension SupabaseManager {
    var currentUserId: UUID? {
        guard let client = client,
              let user = client.auth.currentUser else { return nil }
        return UUID(uuidString: user.id.uuidString)
    }

    var currentUserEmail: String? {
        guard let client = client else { return nil }
        return client.auth.currentUser?.email
    }
}

// MARK: - Date Extensions

extension Date {
    func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
