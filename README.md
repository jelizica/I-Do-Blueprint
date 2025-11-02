# I Do Blueprint

A macOS SwiftUI app backed by Supabase.

## Setup

### Quick Start (Recommended)

The app now includes **hardcoded configuration** for Supabase and Sentry in `AppConfig.swift`, so it works out-of-the-box! Simply clone and build:

```bash
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -resolvePackageDependencies
xcodebuild build -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
```

### Configuration Details

**Backend Services (Pre-configured):**
- ✅ **Supabase**: Backend database and authentication - hardcoded in `AppConfig.swift`
- ✅ **Sentry**: Error tracking and performance monitoring - hardcoded in `AppConfig.swift`

**Optional User Configuration:**
- **Google OAuth** (Optional): For Google Drive/Sheets integration
  - Users can configure their own Google OAuth credentials via Settings > API Keys
  - Stored securely in macOS Keychain per-user
- **Third-party API Keys** (Optional): Unsplash, Pinterest, Resend
  - Optional features, can be configured in Settings > API Keys

### Advanced: Custom Configuration Override

If you need to override the hardcoded values (e.g., for testing against a different Supabase instance), create `I Do Blueprint/Config.plist` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://your-custom-project.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>your-custom-anon-key</string>
    <key>SENTRY_DSN</key>
    <string>https://your-custom-sentry-dsn@sentry.io/project</string>
</dict>
</plist>
```

The app will automatically use `Config.plist` values if present, otherwise fallback to `AppConfig.swift` hardcoded values.

## Architecture

### Configuration Priority
1. **Config.plist** (if present) - highest priority
2. **AppConfig.swift** (hardcoded) - fallback

This allows the app to work out-of-the-box while still supporting custom configurations for development/testing.

### Domain Services
We use a Domain Services layer to keep repositories focused on CRUD, caching, and tenant/network concerns, and move complex business logic into testable services.
- BudgetAggregationService: builds BudgetOverview data
- BudgetAllocationService: recalculates proportional allocations

See docs/DOMAIN_SERVICES_ARCHITECTURE.md for details and examples.

### Keychain Usage
The app uses macOS Keychain for storing:
- User-specific session data (tenant/couple selection)
- Optional Google OAuth credentials (user-provided)
- Optional third-party API keys (user-provided)
- Authentication tokens (managed by Supabase SDK)

**Note**: Keychain is user-specific and not shared between users.

## Security

- ✅ Supabase anon key is **safe for client-side use** (protected by Row Level Security policies)
- ✅ Sentry DSN is **safe for client applications**
- ❌ Never include service_role keys in the app (security check enforced in code)
- ✅ User secrets (Google OAuth, API keys) stored securely in macOS Keychain

## CI
- GitHub Actions can run builds without additional configuration
- No secrets required in CI environment (uses hardcoded AppConfig)

## Notes
- `Config.plist` is gitignored (for custom overrides)
- `AppConfig.swift` is committed (contains shared backend config)
