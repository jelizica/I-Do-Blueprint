//
//  AppConfig.swift
//  I Do Blueprint
//
//  Centralized configuration for shared backend services
//  IMPORTANT: This file contains public/client-safe keys only.
//  - Supabase anon key is designed for client-side use (protected by RLS)
//  - Sentry DSN is safe to include in client applications
//  - Resend API key is for a shared email service (rate-limited, invitation-only)
//

import Foundation

/// Centralized configuration for all shared backend services
enum AppConfig {
    // MARK: - Supabase Configuration

    /// Supabase project URL
    /// This is the public endpoint for your Supabase backend
    static let supabaseURL = "https://pcmasfomyhqapaaaxzby.supabase.co"

    /// Supabase anonymous key (client-safe, intentionally public)
    ///
    /// SECURITY NOTE: This is NOT a secret. The anon key is designed to be public.
    ///
    /// Why this is safe:
    /// 1. **Row Level Security (RLS)**: All tables have RLS policies that restrict access
    ///    based on the authenticated user's `couple_id`. The anon key alone cannot access data.
    /// 2. **Authentication Required**: Most operations require a valid JWT from Supabase Auth.
    ///    The anon key only enables initial connection and auth flows.
    /// 3. **Rate Limiting**: Supabase applies rate limits to prevent abuse.
    /// 4. **No Service Role**: The `service_role` key (which bypasses RLS) is NEVER included
    ///    in client applications. It exists only in server-side/admin contexts.
    ///
    /// This follows Supabase's official security model:
    /// https://supabase.com/docs/guides/auth/row-level-security
    ///
    /// CRITICAL: Never include the service_role key in client applications!
    // swiftlint:disable:next line_length
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjbWFzZm9teWhxYXBhYWF4emJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk3NTQ3NzIsImV4cCI6MjA2NTMzMDc3Mn0.eghHJuLI_ria0YjXB0k421qNxajEWqwPsNgD3RwdM4A"

    // MARK: - Sentry Configuration

    /// Sentry DSN for error tracking and performance monitoring
    /// This is safe to include in client applications
    static let sentryDSN = "https://b697d282932a15f005a5b4497da7c691@o4510229109997568.ingest.us.sentry.io/4510229112619008"

    // MARK: - Resend Email Configuration

    /// Resend API key for shared email service (collaboration invitations)
    ///
    /// SECURITY NOTE: This is an intentionally embedded shared service key.
    /// - The key is rate-limited and restricted to invitation emails only
    /// - Users can override with their own key via Settings → API Keys
    /// - The key can be rotated without app updates via Config.plist
    /// - This pattern is acceptable for shared services with limited scope
    ///
    /// If you need to rotate this key:
    /// 1. Generate a new key at https://resend.com/api-keys
    /// 2. Update Config.plist with RESEND_API_KEY (preferred) or update this value
    /// 3. The old key should be revoked after deployment
    static let resendAPIKey = "re_5tuxAHLr_3LtMhuJ2de7d6Awh2aLyTjup"

    // MARK: - Debug Settings

    #if DEBUG
    /// Enable verbose debug logging in development builds
    static let enableDebugLogging = true
    #else
    /// Disable debug logging in production builds
    static let enableDebugLogging = false
    #endif

    // MARK: - Fallback Configuration

    /// Load configuration from Config.plist if it exists (fallback for development/testing)
    /// Returns nil if Config.plist is not available or value is not found
    static func loadFromPlist(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let value = config[key] as? String,
              !value.isEmpty else {
            return nil
        }
        return value
    }

    /// Get Supabase URL with fallback to Config.plist
    static func getSupabaseURL() -> String {
        loadFromPlist(key: "SUPABASE_URL") ?? supabaseURL
    }

    /// Get Supabase anon key with fallback to Config.plist
    static func getSupabaseAnonKey() -> String {
        loadFromPlist(key: "SUPABASE_ANON_KEY") ?? supabaseAnonKey
    }

    /// Get Sentry DSN with fallback to Config.plist
    static func getSentryDSN() -> String {
        loadFromPlist(key: "SENTRY_DSN") ?? sentryDSN
    }

    /// Get Resend API key with fallback to Config.plist
    /// Users can also override this via Settings → API Keys (stored in Keychain)
    static func getResendAPIKey() -> String {
        loadFromPlist(key: "RESEND_API_KEY") ?? resendAPIKey
    }
}
