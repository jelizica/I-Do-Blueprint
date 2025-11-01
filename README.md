# I Do Blueprint

A macOS SwiftUI app backed by Supabase.

## Setup

1) Copy configuration
- Duplicate `I Do Blueprint/Config.plist.sample` to `I Do Blueprint/Config.plist` and fill in:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SENTRY_DSN` (optional)

2) Build (macOS)

```bash
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -resolvePackageDependencies
xcodebuild build -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
```

## CI
- Add GitHub Actions to run build/tests on macOS (optional). Ensure secrets are stored in GitHub Secrets.

## Notes
- Do not commit real secrets. `.gitignore` excludes `I Do Blueprint/Config.plist` and `.env*`.