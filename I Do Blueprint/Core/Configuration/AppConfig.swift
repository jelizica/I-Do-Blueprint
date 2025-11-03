//
//  AppConfig.swift
//  I Do Blueprint
//
//  Centralized configuration for shared backend services
//  IMPORTANT: This file contains public/client-safe keys only.
//  - Supabase anon key is designed for client-side use (protected by RLS)
//  - Sentry DSN is safe to include in client applications
//

import Foundation

/// Centralized configuration for all shared backend services
enum AppConfig {
    // MARK: - Supabase Configuration

    /// Supabase project URL
    /// This is the public endpoint for your Supabase backend
    static let supabaseURL = "https://pcmasfomyhqapaaaxzby.supabase.co"

    /// Supabase anonymous key (client-safe)
    /// This key is designed for client-side use and is protected by Row Level Security (RLS) policies
    /// IMPORTANT: Never include the service_role key in client applications
    // swiftlint:disable:next line_length
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjbWFzZm9teWhxYXBhYWF4emJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk3NTQ3NzIsImV4cCI6MjA2NTMzMDc3Mn0.eghHJuLI_ria0YjXB0k421qNxajEWqwPsNgD3RwdM4A"

    // MARK: - Sentry Configuration

    /// Sentry DSN for error tracking and performance monitoring
    /// This is safe to include in client applications
    static let sentryDSN = "https://b697d282932a15f005a5b4497da7c691@o4510229109997568.ingest.us.sentry.io/4510229112619008"

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
}
