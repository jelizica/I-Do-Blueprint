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

    // Track initialization state
    private var initializationTask: Task<Void, Never>?
    private var isInitialized = false

    private init() {
        // IMPORTANT: Do NOT access file system during init() to avoid sandbox crashes
        // Defer client creation until first access via lazy initialization
        self.client = nil
        self.configurationError = nil

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

    /// Wait for initialization to complete and return the client
    /// Can be called from any isolation context
    func waitForClient() async throws -> SupabaseClient {
        // Wait for initialization task to complete
        await initializationTask?.value

        // Access properties on MainActor
        return try await MainActor.run {
            // Check if initialization failed
            if let error = self.configurationError {
                throw error
            }

            // Return the client
            guard let client = self.client else {
                throw ConfigurationError.configFileUnreadable
            }

            return client
        }
    }

    // MARK: - Client Creation (Throwing)
    
    private static func createSupabaseClient() throws -> SupabaseClient {
        let logger = AppLogger.api
        logger.debug("Looking for Config.plist...")

        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            logger.error("Config.plist file not found in bundle")
            throw ConfigurationError.configFileNotFound
        }

        #if DEBUG
        logger.logPrivate("Found Config.plist at: \(configPath)", level: .debug)
        #endif

        guard let config = NSDictionary(contentsOfFile: configPath) else {
            logger.error("Could not read Config.plist contents")
            throw ConfigurationError.configFileUnreadable
        }

        #if DEBUG
        logger.logPrivate("Loaded Config.plist with keys: \(config.allKeys)", level: .debug)
        #endif

        guard let supabaseURLString = config["SUPABASE_URL"] as? String else {
            logger.error("SUPABASE_URL not found or not a string")
            throw ConfigurationError.missingSupabaseURL
        }

        guard let supabaseAnonKey = config["SUPABASE_ANON_KEY"] as? String else {
            logger.error("SUPABASE_ANON_KEY not found or not a string")
            throw ConfigurationError.missingSupabaseAnonKey
        }

        // SECURITY: Check if service-role key is present in the bundle
        if let _ = config["SUPABASE_SERVICE_ROLE_KEY"] as? String {
            logger.error("CRITICAL SECURITY VIOLATION: Service-role key found in app bundle")
            throw ConfigurationError.securityViolation(
                "Service-role key must not be included in the app bundle"
            )
        }

        #if DEBUG
        logger.logPrivate("SUPABASE_URL: \(supabaseURLString)", level: .debug)
        logger.logPrivate("url present: true, anonKey present: true, serviceKey present: false", level: .debug)
        #endif

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

// MARK: - Real-time Subscriptions

extension SupabaseManager {
    func subscribeToGuestChanges() -> RealtimeChannelV2? {
        guard let client = client else {
            logger.error("Cannot subscribe to guest changes: client not initialized")
            return nil
        }
        
        let channel = client.realtimeV2.channel("guest_changes")

        Task { @MainActor in
            do {
                try await channel.subscribeWithError()
                // Add to registry after successful subscription
                activeChannels.append(channel)
            } catch {
                logger.error("Failed to subscribe to guest changes", error: error)
            }
        }

        return channel
    }

    func subscribeToVendorChanges() -> RealtimeChannelV2? {
        guard let client = client else {
            logger.error("Cannot subscribe to vendor changes: client not initialized")
            return nil
        }
        
        let channel = client.realtimeV2.channel("vendor_changes")

        Task { @MainActor in
            do {
                try await channel.subscribeWithError()
                // Add to registry after successful subscription
                activeChannels.append(channel)
            } catch {
                logger.error("Failed to subscribe to vendor changes", error: error)
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
