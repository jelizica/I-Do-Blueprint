# Configuration Migration Guide

## Overview

This document describes the migration from Config.plist-only configuration to hardcoded AppConfig with plist fallback.

## What Changed?

### Before (Config.plist-only)
- App required `Config.plist` to exist with Supabase and Sentry credentials
- Users had to create their own `Config.plist` file before running the app
- App would fail to launch without `Config.plist`

### After (Hardcoded AppConfig)
- ✅ Supabase URL and anon key are hardcoded in `AppConfig.swift`
- ✅ Sentry DSN is hardcoded in `AppConfig.swift`
- ✅ App works out-of-the-box without any configuration
- ✅ `Config.plist` can optionally override hardcoded values (for testing)

## Files Modified

### New Files
1. **`I Do Blueprint/Core/Configuration/AppConfig.swift`**
   - Contains hardcoded Supabase and Sentry configuration
   - Provides fallback methods that check `Config.plist` first
   - Safe to commit to git (contains only public/client-safe keys)

### Modified Files
1. **`SupabaseClient.swift`**
   - Now uses `AppConfig.getSupabaseURL()` and `AppConfig.getSupabaseAnonKey()`
   - Falls back to hardcoded values if `Config.plist` doesn't exist
   - Maintains security check for service_role key

2. **`ConfigValidator.swift`**
   - Updated to validate `AppConfig` values instead of reading plist directly
   - Still supports plist fallback through `AppConfig` methods

3. **`SentryService.swift`**
   - Now uses `AppConfig.getSentryDSN()` instead of loading from plist
   - Simplified initialization (no need to check if plist exists)

4. **`README.md`**
   - Updated to reflect new configuration approach
   - Added documentation about optional `Config.plist` override

## Configuration Priority

The app now follows this configuration priority:

1. **Config.plist** (if present) - highest priority
2. **AppConfig.swift** (hardcoded) - fallback

This is implemented in the `AppConfig.get*()` methods:

```swift
static func getSupabaseURL() -> String {
    return loadFromPlist(key: "SUPABASE_URL") ?? supabaseURL
}
```

## Security Considerations

### What's Safe to Hardcode? ✅

- **Supabase URL**: Public endpoint, safe to expose
- **Supabase Anon Key**: Designed for client-side use, protected by Row Level Security (RLS)
- **Sentry DSN**: Public key for error reporting, safe in client apps

### What Should NEVER be Hardcoded? ❌

- **Supabase Service Role Key**: Admin access, bypasses RLS
- **User credentials**: Passwords, personal tokens
- **Private API keys**: Keys that grant write access to third-party services

### Keychain Usage (User-Specific)

The following are stored in macOS Keychain (per-user, not shared):

- **Session data**: Current tenant/couple ID
- **Google OAuth credentials**: User's own Google Cloud credentials (optional)
- **Third-party API keys**: Unsplash, Pinterest, Resend (optional)
- **Auth tokens**: Supabase auth session tokens

## Developer Workflow

### For End Users (Production)
1. Clone the repository
2. Build and run - **no configuration needed!**
3. Optionally add Google OAuth credentials via Settings if needed

### For Developers (Testing/Development)
1. Clone the repository
2. App works with production Supabase by default
3. To test against a different Supabase instance:
   - Create `I Do Blueprint/Config.plist` with custom values
   - Values will override hardcoded AppConfig
4. Delete `Config.plist` to return to hardcoded config

### For CI/CD
- No secrets required in CI environment
- Builds use hardcoded AppConfig values
- Tests run against production Supabase (or create test Config.plist)

## Rollback Plan

If you need to revert to the old Config.plist-only approach:

1. Keep the existing `Config.plist` in place
2. The app will automatically use it (higher priority than AppConfig)
3. If needed, modify code to remove hardcoded fallbacks

However, there's no reason to rollback - the new approach is strictly better:
- ✅ Works out-of-the-box
- ✅ Still supports custom configurations
- ✅ No breaking changes for existing users
- ✅ Safer for end users (no manual config required)

## Testing Checklist

- [x] App builds successfully
- [x] App initializes with hardcoded config (no Config.plist)
- [x] App respects Config.plist if present (override behavior)
- [x] Supabase client initializes correctly
- [x] Sentry initializes correctly
- [x] Security check for service_role key still works
- [x] README documentation updated

## Questions?

If you have questions about this migration, refer to:
- `AppConfig.swift` - Centralized configuration
- `README.md` - User-facing documentation
- This file - Migration details and rationale
