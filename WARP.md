# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project overview
- Platform: macOS app (SwiftUI) with Supabase backend; local Swift package(s) under Packages/
- Architecture: MVVM with Repository pattern, dependency injection (swift-dependencies), strict unidirectional data flow
- Multi-tenancy: All data scoped by couple_id in repositories

Core commands
- Build (Debug/Release)
  ```bash
  xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -configuration Debug build
  xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -configuration Release build
  ```
- Clean and resolve packages
  ```bash
  xcodebuild clean -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint"
  xcodebuild -resolvePackageDependencies -project "I Do Blueprint.xcodeproj"
  ```
- Run all tests (macOS destination)
  ```bash
  xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
  ```
- Run a single test class or method
  ```bash
  # Single class
  xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' \
    -only-testing:I\ Do\ BlueprintTests/GuestStoreV2Tests

  # Single method
  xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' \
    -only-testing:I\ Do\ BlueprintTests/GuestStoreV2Tests/test_loadGuests_success
  ```
- UI, integration, performance, accessibility test subsets (targets used in CI)
  ```bash
  # UI tests
  xcodebuild test -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:I_Do_BlueprintUITests

  # Integration tests
  xcodebuild test -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:I_Do_BlueprintTests/Integration

  # Performance tests
  xcodebuild test -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:I_Do_BlueprintTests/Performance

  # Accessibility tests
  xcodebuild test -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:I_Do_BlueprintTests/Accessibility
  ```
- Code coverage (matches CI behavior)
  ```bash
  # Enable coverage during tests
  xcodebuild test -scheme "I Do Blueprint" -destination 'platform=macOS' -enableCodeCoverage YES -derivedDataPath .build

  # Generate JSON report
  xcrun xccov view --report --json .build/Logs/Test/*.xcresult > coverage.json
  ```
- Accessibility audit utilities
  ```bash
  # Generate color contrast audit from Design/
  (cd "I Do Blueprint/Design" && swift GenerateAccessibilityReport.swift)
  ```

Supabase Edge Function (delete-auth-user)
- Location: supabase/functions/delete-auth-user/
- Deploy and local serve
  ```bash
  # One-time setup
  brew install supabase/tap/supabase
  supabase login
  supabase link --project-ref YOUR_PROJECT_REF

  # Deploy
  supabase functions deploy delete-auth-user

  # Serve locally
  supabase start
  supabase functions serve delete-auth-user
  ```
- Local request example
  ```bash
  curl -i --location --request POST 'http://localhost:54321/functions/v1/delete-auth-user' \
    --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
    --header 'Content-Type: application/json' \
    --data '{"userId":"USER_UUID_HERE"}'
  ```

Configuration essentials
- Config.plist contains Supabase credentials used by the macOS app:
  - SUPABASE_URL
  - SUPABASE_ANON_KEY
- Google OAuth (GTMAppAuth/AppAuth) must be configured in Google Cloud; redirect URI for macOS

High-level architecture
- Layers and roles
  - App: Entry point and root navigation based on auth/tenant context
  - Core: Common infra (analytics, auth context, DI setup, errors, Supabase client, extensions, utilities)
  - Domain: Models per feature and repository protocols; Live and Mock implementations
  - Services: Stores (V2) as stateful view models; API/Auth/Storage/Analytics/Navigation/UI helpers
  - Views: SwiftUI feature folders; Shared includes reusable components and loading/error UIs
  - Design: Design system and accessibility tooling; audit artifacts and scripts
  - Utilities: Logging (OSLog wrappers), validation, retry, calculators
  - Tests: Unit/integration under I Do BlueprintTests; UI tests under I Do BlueprintUITests
- Core patterns
  - Repository pattern mandatory for all data access; repositories enforce tenant scoping (couple_id) and handle Supabase I/O
  - Stores (e.g., BudgetStoreV2, GuestStoreV2) depend on repositories via @Dependency; expose @Published state
  - LoadingState<T> governs async UI states (idle/loading/loaded/error)
  - Store composition to break complex domains into focused sub-stores
- Dependency injection via swift-dependencies for testability (withDependencies in tests)
- Composition root via AppContainer: App instantiates AppContainer.live and injects coordinator, stores, supabaseManager, sessionManager using Environment/Object. Views must not access `.shared`.

Testing structure and expectations
- Primary focus on Services/Stores with mocked repositories; tests run on @MainActor
- Targets: I Do BlueprintTests (unit/integration/perf/accessibility), I Do BlueprintUITests (UI flows)
- CI runs on macOS with xcodebuild; coverage threshold enforced at 80%

Design system and components
- Design/DesignSystem.swift defines colors/typography/spacing; adhere to semantic constants
- Views/Shared/Components contains unified component library (Empty states, Stats, Forms, Loading, Lists, Cards) with accessibility support; see COMPONENTS_README.md for usage
- Accessibility audit docs and scripts live under I Do Blueprint/Design (see DESIGN_README.md)

Alerts and toasts (UI guidance)
- Prefer non-blocking toasts for minor notices; use modal alerts for destructive/critical confirmations or significant decisions.
- Use the shared AlertPresenter and store helpers for consistency.

Examples
```swift
// Success toast (preferred for minor confirmations)
AlertPresenter.shared.showSuccessToast("Saved changes")

// From stores (convenience in StoreErrorHandling.swift)
await showSuccess("Guest imported successfully")

// Info/Warning toasts
AlertPresenter.shared.showInfoToast("Sync complete")
AlertPresenter.shared.showWarningToast("Network is unstable")

// Export success with actions (includes "Reveal in Finder")
// AppCoordinator handles: Open File, Reveal in Finder, OK
await coordinator.showExportSuccess(fileURL: exportedURL)

// Destructive confirmation (use modal alert)
let confirmed = await coordinator.showDeleteConfirmation(item: "Vendor")
if confirmed {
    // proceed with deletion
}
```

Conventions (project-specific)
- Stores use V2 suffix; repositories split into Protocols/Live/Mock
- File naming: Feature{Purpose}View.swift, {Feature}StoreV2.swift, {Entity}.swift, {Type}+{Purpose}.swift
- Logging via AppLogger categories; use info/error/warning/debug appropriately
