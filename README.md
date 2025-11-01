# I Do Blueprint

A macOS app (SwiftUI) with a Supabase backend.

## Getting Started

1) Copy configuration

- Duplicate `I Do Blueprint/Config.plist.sample` to `I Do Blueprint/Config.plist` and fill in values:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SENTRY_DSN` (optional)

2) Build and test

```bash
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -resolvePackageDependencies
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
```

3) Supabase Edge Functions (optional)

- Edge function: `supabase/functions/delete-auth-user/`
- Deploy with Supabase CLI after linking your project.

## CI

GitHub Actions workflow in `.github/workflows/tests.yml` runs lint, build, and test jobs on macOS, with code coverage.

## Notes

- Real secrets should not be committed. `.gitignore` excludes `Config.plist` and `.env*`.
- See `WARP.md` for project conventions and architecture.
