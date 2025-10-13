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

    let client: SupabaseClient

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let logger = AppLogger.api

    // Channel registry for tracking active realtime subscriptions
    @MainActor
    private var activeChannels: [RealtimeChannelV2] = []

    private init() {
        logger.debug("Looking for Config.plist...")

        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            logger.error("Config.plist file not found in bundle")
            fatalError("Config.plist file not found in bundle")
        }

        #if DEBUG
        logger.logPrivate("Found Config.plist at: \(configPath)", level: .debug)
        #endif

        guard let config = NSDictionary(contentsOfFile: configPath) else {
            logger.error("Could not read Config.plist contents")
            fatalError("Could not read Config.plist contents")
        }

        #if DEBUG
        logger.logPrivate("Loaded Config.plist with keys: \(config.allKeys)", level: .debug)
        #endif

        guard let supabaseURLString = config["SUPABASE_URL"] as? String else {
            logger.error("SUPABASE_URL not found or not a string")
            fatalError("SUPABASE_URL not found in Config.plist")
        }

        guard let supabaseAnonKey = config["SUPABASE_ANON_KEY"] as? String else {
            logger.error("SUPABASE_ANON_KEY not found or not a string")
            fatalError("SUPABASE_ANON_KEY not found in Config.plist")
        }

        // SECURITY: Fail if service-role key is present in the bundle
        if let _ = config["SUPABASE_SERVICE_ROLE_KEY"] as? String {
            logger.error("CRITICAL SECURITY VIOLATION: Service-role key found in app bundle")
            fatalError("Service-role key must not be included in the app bundle. This is a critical security vulnerability.")
        }

        #if DEBUG
        logger.logPrivate("SUPABASE_URL: \(supabaseURLString)", level: .debug)
        logger.logPrivate("url present: true, anonKey present: true, serviceKey present: false", level: .debug)
        #endif

        guard let supabaseURL = URL(string: supabaseURLString) else {
            logger.error("Invalid URL format")
            fatalError("Invalid Supabase URL format")
        }

        #if DEBUG
        logger.logPrivate("Created Supabase URL: \(supabaseURL)", level: .debug)
        #endif
        logger.debug("Initializing Supabase client...")

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey,
            options: SupabaseClientOptions(
                db: .init(schema: "public"),
                auth: .init(flowType: .pkce),
                global: .init(
                    headers: ["x-client-info": "wedding-app-macos/1.0.0"])))

        Task {
            // First check auth state, then setup listener to avoid race conditions
            await checkAuthState()
            await setupAuthListener()

            // Test basic network connectivity after initialization
            await testNetworkConnectivity(url: supabaseURL)
        }
    }

    @MainActor
    private func setupAuthListener() async {
        for await authState in client.auth.authStateChanges {
            let session = authState.session

            if let session {
                isAuthenticated = true
                currentUser = session.user
            } else {
                isAuthenticated = false
                currentUser = nil
                // Clean up channels when user signs out
                await cleanupChannels()
            }
        }
    }

    @MainActor
    private func checkAuthState() async {
        do {
            let session = try await client.auth.session
            isAuthenticated = true
            currentUser = session.user
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }

    // MARK: - Authentication Methods

    func signIn(email: String, password: String) async throws {
        do {
            try await client.auth.signIn(email: email, password: password)
            logger.infoWithRedactedEmail("auth_login_success for", email: email)
        } catch {
            logger.error("auth_login_failure", error: error)
            throw error
        }
    }

    func signUp(email: String, password: String) async throws {
        do {
            try await client.auth.signUp(email: email, password: password)
            logger.infoWithRedactedEmail("auth_signup_success for", email: email)
        } catch {
            logger.error("auth_signup_failure", error: error)
            throw error
        }
    }

    func signOut() async throws {
        do {
            // Clean up all tracked channels
            await cleanupChannels()
            logger.info("Cleaned up all realtime channels")

            try await client.auth.signOut()

            // Clear all repository caches
            do {
                await RepositoryCache.clearAll()
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
        await client.realtimeV2.removeAllChannels()
        logger.debug("All realtime channels cleaned up")
    }

    /// Unsubscribe from all active realtime channels (public API for compatibility)
    @MainActor
    func unsubscribeAllChannels() async {
        await cleanupChannels()
    }

    func resetPassword(email: String) async throws {
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
    func subscribeToGuestChanges() -> RealtimeChannelV2 {
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

    func subscribeToVendorChanges() -> RealtimeChannelV2 {
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

// MARK: - Date Extensions

extension Date {
    func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
