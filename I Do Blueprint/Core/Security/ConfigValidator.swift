//
//  ConfigValidator.swift
//  I Do Blueprint
//
//  Validates presence and basic format of critical configuration values.
//  IMPORTANT: Never log or expose secret values.
//

import Foundation

struct ConfigValidationSummary: Sendable {
    let supabaseURLPresent: Bool
    let supabaseURLValid: Bool
    let supabaseAnonKeyPresent: Bool
    // We do not validate anon key format beyond presence to avoid false negatives

    let sentryDSNPresent: Bool
    let sentryDSNValid: Bool
}

enum ConfigValidator {
    /// Load Config.plist as dictionary (read-only)
    private static func loadConfigPlist() -> NSDictionary? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else { return nil }
        return NSDictionary(contentsOfFile: path)
    }

    /// Returns a summary of configuration validation (no secrets exposed)
    static func validateAll() -> ConfigValidationSummary {
        let config = loadConfigPlist()

        // SUPABASE_URL
        let supabaseURLString = config?["SUPABASE_URL"] as? String
        let supabaseURLPresent = !(supabaseURLString?.isEmpty ?? true)
        let supabaseURLValid: Bool = {
            guard let s = supabaseURLString, let url = URL(string: s) else { return false }
            // Basic scheme/host check
            return (url.scheme == "http" || url.scheme == "https") && url.host != nil
        }()

        // SUPABASE_ANON_KEY (presence only)
        let supabaseAnonKeyString = config?["SUPABASE_ANON_KEY"] as? String
        let supabaseAnonKeyPresent = !(supabaseAnonKeyString?.isEmpty ?? true)

        // SENTRY_DSN
        let sentryDSNString = config?["SENTRY_DSN"] as? String
        let sentryDSNPresent = !(sentryDSNString?.isEmpty ?? true)
        let sentryDSNValid: Bool = {
            guard let dsn = sentryDSNString, !dsn.isEmpty else { return false }
            // Very lightweight format validation: must look like a URL with scheme and host
            return URL(string: dsn)?.host != nil
        }()

        return ConfigValidationSummary(
            supabaseURLPresent: supabaseURLPresent,
            supabaseURLValid: supabaseURLValid,
            supabaseAnonKeyPresent: supabaseAnonKeyPresent,
            sentryDSNPresent: sentryDSNPresent,
            sentryDSNValid: sentryDSNValid
        )
    }

    /// If there is a blocking configuration error, map to ConfigurationError for UI
    static func blockingErrorForUI(summary: ConfigValidationSummary) -> ConfigurationError? {
        // Supabase issues will also surface via SupabaseManager, but we expose here for preflight when possible
        if !summary.supabaseURLPresent { return .missingSupabaseURL }
        if !summary.supabaseURLValid { return .invalidURLFormat("(redacted)") }
        if !summary.supabaseAnonKeyPresent { return .missingSupabaseAnonKey }

        // Sentry DSN: treat missing/invalid as non-blocking in production, but we surface during preflight for clarity
        if !summary.sentryDSNPresent { return .missingSentryDSN }
        if !summary.sentryDSNValid { return .invalidSentryDSN }

        return nil
    }
}