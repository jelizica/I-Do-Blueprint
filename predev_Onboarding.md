## Executive Summary

I Do Blueprint is a macOS (SwiftUI) wedding planning app for couples, using Supabase (Postgres + RLS) backend, MVVM with Repository pattern, Point-Free Dependencies, and actor-based RepositoryCache. This project will add a comprehensive, skippable, resumable onboarding flow guiding users through welcome, wedding details, default settings, optional guest/vendor imports with CSV/XLSX validation, budget wizard, and completion screen. Onboarding integrates with existing auth/session flow, persists progress in couple_settings, supports guided and express modes, adheres to design system and accessibility, uses Sentry, AppLogger, NetworkRetry, caching, and follows UUID and security best practices. Expected outcomes: faster time-to-value, reduced setup friction, higher import accuracy, and consistent tenant-scoped data. Complexity 6.2/10; high integration and business logic. Roles: User (primary) and Partner (secondary).

## Core Functionalities

- **Onboarding Flow**: Guided and express onboarding for initial wedding setup including details, defaults, imports, and budget wizard with resumable/skippable progress. (Priority: **High**)
- **Guest & Vendor Import**: CSV/XLSX import with header mapping, validation, duplicate handling, preview, progress tracking, and rollback integrated with Supabase tenant scoping. (Priority: **High**)
- **Budget Management**: Budget setup wizard, category management, expense tracking, and payment preferences with caching and sync to backend. (Priority: **High**)
- **Settings & Tenant Management**: Manage CoupleSettings (currency, timezone, notifications, themes) with RLS-backed Supabase storage, caching, and repository pattern. (Priority: **Medium**)
- **Data Integrity & Observability**: Error handling, Sentry integration, structured logging, caching, and network retry to ensure reliable imports and app operations. (Priority: **Medium**)

## Tech Stack

- **Frontend**: SwiftUI, Swift 5.9
- **Backend**: Supabase, Repository Pattern, RepositoryCache
- **Dependency**: Point-Free Dependencies
- **Architecture**: MVVM
- **Error Monitoring**: Sentry
- **Observability**: AppLogger
- **Networking**: NetworkRetry, Alamofire
- **Parsing**: CSVImporterKit
- **Library**: CoreXLSX
- **Data Management**: Combine
- **Database**: GRDB
- **Utility**: SwiftDate
- **Tooling**: SwiftLint
- **Testing**: XCTest, Mockingbird

## Development Guidelines & Best Practices

Follow these guidelines while implementing the project:

- **Placeholder Images**: Use [Unsplash](https://unsplash.com) or [Picsum Photos](https://picsum.photos) for placeholder images
  - Example: `https://source.unsplash.com/random/800x600?nature`
  - Example: `https://picsum.photos/800/600`
- **Code Quality**: Write clean, maintainable code with proper comments and documentation
- **Testing**: Test each feature thoroughly before marking it as complete
- **Commit Messages**: Use clear, descriptive commit messages that reference the task/story ID
- **Error Handling**: Implement proper error handling and user-friendly error messages
- **Responsive Design**: Ensure all UI components work across mobile, tablet, and desktop devices
- **Accessibility**: Follow WCAG guidelines for accessible UI components
- **Performance**: Optimize images, minimize bundle sizes, and implement lazy loading where appropriate
- **Security**: Never commit API keys or sensitive credentials; use environment variables
- **API & Model Versions**: Always use the latest available APIs and models unless the user explicitly specifies a different version
- **Progress Updates**: Update task checkboxes in real-time as you work through the plan

## Project Timeline

This plan lays out your roadmap in **Milestones**, **Stories** with acceptance criteria, and **Subtasks**. Follow the plan task by task and update progress on milestones, stories, and subtasks immediately as you work on them based on the legend below.

**Progress Legend:**
- `- [ ]` = To-do (not started)
- `- [~]` = In progress (currently working on)
- `- [x]` = Completed (finished)
- `- [/]` = Skipped (not needed)

Tasks are categorized by complexity to guide time estimations: XS, S, M, L, XL, XXL.

### - [ ] **Milestone 1**: **User Onboarding: implement comprehensive onboarding flow (welcome, wedding details, default settings, optional imports, budget wizard, completion) with resumable/skippable flows, guided & express modes, MVVM, repositories, caching, Sentry, and auth integration**

- [ ] **Wedding Details** - (S): As a: user, I want to: enter wedding details, So that: onboarding can tailor settings to the couple
  - **Acceptance Criteria:**
    - [ ] Wedding details form validates required fields
Details save to onboarding progress
Progress persists across sessions
  - [ ] Frontend: Implement wedding details form validation and UI state (validate() logic) with React/Vue component state management, wire validation to OnboardingViewModel state. Preserve wedding_details form fields and validation rules to align with onboarding flow. - (S)
  - [ ] Frontend: Implement save() flow to call OnboardingViewModel/OnboardingStoreV2 to persist progress within the onboarding sequence, ensuring optimistic UI and proper error handling. - (S)
  - [ ] API: Add setupWeddingDetails(dto) handling in OnboardingService to save wedding details and cache progress, integrating with existing Onboarding domain and caching strategy. - (M)
  - [ ] API: Implement repository saveOnboardingProgress and fetchOnboardingProgress methods to persist and read onboarding progress state. - (M)
  - [ ] DB: Ensure Couple Settings Table schema supports wedding details and onboarding progress - (M)
  - [ ] Quality: Add unit tests for WeddingDetailsViewModel.validate() and save() and integration test for progress persistence - (M)
- [ ] **Import Vendors** - (M): As a: user, I want to: import vendors via CSV/XLSX, So that: vendors are populated in the system with proper couple scoping
  - **Acceptance Criteria:**
    - [ ] CSV/XLSX headers mapped to vendor fields
Validation for required fields
Progress tracking for large imports
Rollback on failure and preview before final import
  - [ ] Frontend: Add file picker and preview UI for vendor import (component: comp_welcome_screen) with drag-and-drop support, CSV/XLSX detection, and client-side preview rendering. - (XS)
  - [ ] Frontend: Implement header mapping UI and mapping persistence (api: comp_onboarding_container) to map CSV/XLSX headers to system fields and persist mappings via API. - (S)
  - [ ] Frontend: Show progress indicator and cancel action for large imports (component: comp_welcome_screen) to reflect parsing/upload progress and allow abort. - (S)
  - [ ] Frontend: Integrate parsing and preview using FileImportService.parseCSV/parseXLSX and VendorImportValidator (component: comp_onboarding_container) - (S)
  - [ ] API: Implement uploadFile endpoint to validate and return ImportPreview via ImportController (component: comp_onboarding_controller) - (M)
  - [ ] API: Implement storeImportPreview and return importId via IImportRepository/ImportService (component: api_onboarding_service) - (M)
  - [ ] API: Implement performImport with progress events and applyBulkInsert ensuring couple scoping (components: api_onboarding_service, comp_couple_settings_table) - (XL)
  - [ ] API: Implement rollbackImport and rollback endpoint (component: comp_onboarding_controller) - (L)
  - [ ] Integration: Wire frontend confirm flow to confirmImport endpoint and display final ImportResult (components: comp_welcome_screen, comp_onboarding_controller) - (M)
  - [ ] Testing: Add unit tests for parsing/mapping/validation and API integration tests for import flow (testing) - (S)
  - [ ] Docs: Document import CSV/XLSX headers, mapping rules, and rollback behavior (documentation) - (XS)
- [ ] **Default Settings** - (S): As a: user, I want to: apply default onboarding settings, So that: first-run experience is consistent
  - **Acceptance Criteria:**
    - [ ] Default settings applied on first run
User can modify defaults and save
Defaults persist in repository
  - [ ] DB: Add default settings columns and migration to Couple Settings table with defaults applied during migration and backward compatibility checks - (S)
  - [ ] API: Implement ISettingsRepository.getSettings and updateSettings defaults handling with caching layer per coupleId - (M)
  - [ ] API: Add OnboardingService.configureDefaults(coupleId, dto) to apply defaults and cache - (M)
  - [ ] Frontend: Expose defaults in SettingsViewModel.validate() and save() flow - (S)
  - [ ] Frontend: Add UI on Welcome Screen to modify and persist default onboarding settings - (S)
  - [ ] Frontend: Wire OnboardingStoreV2.saveProgress()/fetchProgress() to include default settings in OnboardingData - (M)
  - [ ] Testing: Add unit tests for configureDefaults, settings persistence, and SettingsViewModel save - (S)
  - [ ] Documentation: Document default settings behavior and repository contract - (M)
- [ ] **Budget Setup** - (M): As a: user, I want to: set up budget, So that: planning data is captured for the wedding
  - **Acceptance Criteria:**
    - [ ] Budget categories stored correctly
Validation of numeric values
Budget persistence across sessions
  - [ ] DB: Create budgets and budget_categories tables migration using existing migration framework to establish core budgeting entities. Ensure tables align with domain fields for budgets (id, user_id, total, currency, period) and budget_categories (id, budget_id, name, limit, color). Include foreign keys and indexing strategy for quick lookup by budget and user. Ensure rollback scripts are included. - (M)
  - [ ] API: Implement IBudgetRepository.createCategories and createBudget endpoints/methods to persist categories and budgets using repository pattern. Ensure transactional consistency when creating a budget and its default categories; expose repository methods for both category creation and budget creation with appropriate input validation. - (M)
  - [ ] Service: Implement BudgetWizardService.setupInitialBudget and createDefaultCategories to seed a new user's budget and starter categories using repository calls. Ensure idempotency for re-runs and proper defaults (e.g., "Wedding Fund", "Venue", "Catering"). - (M)
  - [ ] Frontend: Implement BudgetSetupViewModel.addCategory, removeCategory, and save with numeric validation using the app's state management (e.g., MVVM/Redux). Ensure category entries validate numeric budget values and reflect errors in UI state. - (S)
  - [ ] Frontend: Build BudgetSetup UI inputs and category list with validation feedback to ensure real-time validation and user-friendly error messages. - (S)
  - [ ] Infra: Configure Supabase client and migrations execution to enable database access and automatic migration application in dev/prod environments. - (M)
  - [ ] Quality: Add unit tests for numeric validation and service methods to cover boundary conditions, error paths, and successful flows. - (S)
  - [ ] Quality: Integration tests for persistence across sessions to ensure budgets and categories survive page reloads and user sessions. - (M)
- [ ] **Enter Date & Venue** - (S): As a: couple user, I want to: enter the wedding date and venue details, So that: I can schedule and plan the wedding logistics within the app
  - **Acceptance Criteria:**
    - [ ] Date field accepts valid calendar dates
Venue field accepts non-empty text with reasonable length
System validates date is not in the past
Data saves to couple_settings or relevant store and persists
Preview shows entered date and venue before final save
  - [ ] Foundation: Define WeddingDetailsDTO and validation rules (date, venue) preserving architectural references (WeddingDetailsDTO, validation) and using tech stack (e.g., DTO pattern in Java/Kotlin/TS backend). - (S)
  - [ ] API: Add submitWeddingDetails(userId, dto) method in OnboardingService preserving OnboardingService contract; integrates with WeddingDetailsDTO; update service layer to persist or pass to persistence layer. - (M)
  - [ ] API: Add controller handler saveWeddingDetails(req) to call OnboardingService.submitWeddingDetails, preserving route/controller architecture and authentication middleware. - (S)
  - [ ] Frontend: Implement WeddingDetailsViewModel.validateWeddingDetails() and preview state using existing MVVM pattern; ensure data binding to view for date and venue; verify validation errors surfaced in UI - (S)
  - [ ] Frontend: Build WeddingDetailsView with date picker, venue input, preview and save flow preserving architecture (MVVM) and calling API to submit data - (M)
  - [ ] DB: Ensure couple_settings table has wedding_date and venue columns and RLS policies preserving privacy and access controls - (M)
  - [ ] Testing: Unit tests for validation rules (date not past, venue non-empty) - (XS)
  - [ ] Testing: Integration test to verify submitWeddingDetails persists to DB and preview shows values - (L)
- [ ] **Configure Defaults** - (M): As a: couple user, I want to: configure default settings for the wedding flow (e.g., reminders, notifications), So that: new weddings auto-configure with sensible defaults
  - **Acceptance Criteria:**
    - [ ] Default settings are configurable
Defaults are saved per couple_id
System applies defaults to new weddings
Edge case: clearing defaults reverts to system defaults
Preview shows effective defaults before save
  - [ ] DB: Add/Update Couple Settings table to store per-couple defaults - (M)
  - [ ] API: Add fetchSettings(coupleId) and saveSettings(coupleId, settings) in SettingsRepository interface - (M)
  - [ ] API: Implement OnboardingService.configureDefaults(userId, dto) to validate and save defaults - (M)
  - [ ] API: Add controller endpoint to expose configureDefaults and fetch defaults to frontend - (S)
  - [ ] Frontend: Implement DefaultsViewModel methods to preview, validate, and save defaults - (S)
  - [ ] Frontend: Build UI preview that shows effective defaults before save - (S)
  - [ ] System: Apply couple defaults when creating new wedding (applyDefaults hook) - (M)
  - [ ] Edge Case: Implement clearDefaults to revert to system defaults and ensure persistence - (S)
  - [ ] Testing: Unit tests for SettingsRepository, OnboardingService.configureDefaults, and DefaultsViewModel preview - (XS)
- [ ] **Budget Setup Wizard** - (M): As a: couple user, I want to: walk through a budget setup wizard, So that: budgeting is structured and aligned with business goals
  - **Acceptance Criteria:**
    - [ ] Wizard steps guided with progress
Budget categories created and linked to couple_id
User can adjust allocations with validation
Progress persisted across sessions
Export/summary of budget at end
  - [ ] Frontend: Implement multi-step BudgetWizard UI with React components (ProgressBar, Stepper) and state management to guide couples through budget setup, preserving accessibility and responsive design. Integrate with BudgetWizardViewModel for bindings and validation hooks. - (M)
  - [ ] Frontend: Implement BudgetWizardViewModel with input validation, derived totalBudget property, and bindings to UI; ensure validation messages and edge-case handling (empty, negative, overflow) using project-standard validation framework. - (S)
  - [ ] API: Add setupInitialBudget(coupleId, dto) orchestration in BudgetService to initialize budget data for a new couple, coordinating with repository createCategories and calculateAllocations to seed initial allocations and categories. - (M)
  - [ ] API: Implement calculateAllocations(total, categories) in BudgetService to compute per-category allocations based on defined policy (e.g., 50/30/20 rule or custom weights) and return allocation map used by frontend and persistence layer. - (M)
  - [ ] API: Implement BudgetRepository.createCategories(coupleId, categories) and fetchCategories(coupleId) to manage category data in db_postgres, including schema interactions and optimistic concurrency handling. - (M)
  - [ ] DB: Add/verify Couple Settings and Budget categories linkage to couple_id in db_postgres, including necessary migrations and integrity constraints to support wizard flow. - (S)
  - [ ] Frontend: Persist wizard progress across sessions using onboarding progress store to resume BudgetWizard where left off, leveraging localStorage or equivalent persistence layer. - (S)
  - [ ] Frontend: Add export/summary generation (CSV/XLSX) and preview for budget data from wizard, with formatting and download capability; integrate with BudgetRepository or client-side generator as needed. - (M)
  - [ ] Quality: Add unit tests for view model validation and allocation calculations to ensure correctness and regressions are caught early. - (XS)
  - [ ] Quality: Add integration tests for end-to-end wizard flow to validate interaction between frontend, API, and DB for budget setup. - (L)
  - [ ] Documentation: Write README for Budget Setup Wizard and API usage to guide developers and users. - (XS)
- [ ] **Add Partner Names** - (S): As a: couple user, I want to: add partner names for wedding participants, So that: the guest list and invitations can reference both partners
  - **Acceptance Criteria:**
    - [ ] Both partner name fields accept non-empty strings
Names are stored with correct couple_id scope
System prevents duplicate partner entries
UI shows entered names in summary
Data persists to settings or related store
  - [ ] Frontend: Add partner name fields to WeddingDetailsView and summary UI - (M)
  - [ ] Frontend: Add validation to WeddingDetailsViewModel to require non-empty partner names and prevent duplicates - (M)
  - [ ] API: Extend OnboardingService.submitWeddingDetails to accept partner names and couple_id scope - (M)
  - [ ] DB: Add couple partner name columns to Couple Settings Table and migration - (M)
  - [ ] API: Add repository validation to prevent duplicate partner entries before persist - (M)
  - [ ] Integration: Wire WeddingDetailsViewModel saveWeddingDetails to call OnboardingService.submitWeddingDetails and handle responses - (M)
  - [ ] Testing: Add unit tests for ViewModel validation and duplicate prevention - (M)
  - [ ] Testing: Add integration test for submitWeddingDetails storing names with correct couple_id - (M)
- [ ] **Select Wedding Style** - (S): As a: couple user, I want to: select a wedding style from predefined templates, So that: the event theme is consistently configured across the app
  - **Acceptance Criteria:**
    - [ ] Style options are presented
User can select one style
Selection persists to settings
Invalid selections are rejected with user feedback
Preview reflects chosen style in summary
  - [ ] Frontend: Add StylePicker UI to WeddingDetailsView presenting style options - (M)
  - [ ] Frontend: Wire selection to WeddingDetailsViewModel and expose selectedStyle property - (M)
  - [ ] API: Add submitWeddingStyle endpoint in OnboardingController to accept style selection - (M)
  - [ ] Backend: Implement repository method to save couple style in persistence - (M)
  - [ ] DB: Add/modify Couple Settings record to store selectedStyle - (M)
  - [ ] Frontend: Add Preview summary component reflecting selected style - (M)
  - [ ] Validation: Implement client-side validation and user feedback for invalid selections - (M)
  - [ ] Testing: Add unit tests for ViewModel selection persistence and validation - (M)
  - [ ] Integration: Add end-to-end test saving style through API to DB and rendering preview - (M)
- [ ] **Completion & Next Steps** - (XS): As a: couple user, I want to: see completion screen and next steps, So that: users know what to do after onboarding and wedding details
  - **Acceptance Criteria:**
    - [ ] Completion state reached after final step
Next steps are contextually shown
Data persists post-completion
Navigation to dashboard is enabled
Error states gracefully handled
  - [ ] Frontend: Implement CompletionView component that renders a success state and contextual next steps after onboarding, wired into Onboarding flow and reacting to loading/error states from the backend (API contract: completeOnboarding flow). Use React/Vue/Angular depending on stack with state management; display progress indicators and accessible success messaging. - (S)
  - [ ] Frontend: Add navigation action from CompletionView to Dashboard, leveraging existing routing (e.g., /dashboard) and ensuring navigation is conditional on completion state and can be retried. - (S)
  - [ ] API: Implement completeOnboarding(userId) orchestration method that coordinates onboarding completion workflow across services (Frontend-coordinator -> API). This method should orchestrate saving completion, updating status, and returning a consolidated result. - (M)
  - [ ] API: Add saveOnboardingProgress(userId, progressData) and set completion flag in the repository, persisting onboarding progress and completion status. - (M)
  - [ ] DB: Ensure Couple Settings / onboarding completion persisted in couple_settings table, including index on completion flag and consistent transactional updates. - (M)
  - [ ] Frontend: Integrate OnboardingCoordinator.completeOnboarding() to call repository and show loading/error states and update UI based on API responses. - (M)
  - [ ] Testing: Add unit and integration tests for completion flow and error handling across frontend and API layers. - (M)
  - [ ] Documentation: Document Completion screen behavior and API contract, including UX interactions, loading/error states, and integration points. - (S)
- [ ] **Configure Budget Preferences** - (M): As a: user, I want to: configure budget preferences (categories, limits), So that: budgets align with userâ€™s spending goals
  - **Acceptance Criteria:**
    - [ ] User can add/edit budget categories and limits
Changes saved to settings with proper scoping
Preview of budget impact available
Validation of numeric inputs
Edge case: conflicting budget ranges handled gracefully
  - [ ] Backend: Extend couple settings table with budget_preferences columns (categories JSON, limits JSON, and JSON schema reference) and wire migrations. Maintain existing schema usage and ensure backward compatibility through default values and non-null handling. - (S)
  - [ ] API: Implement SettingsService.setBudgetPreferences and expose via SettingsController.saveDefaultSettings; ensure input passes JSON structure for categories/limits and triggers appropriate persistence. - (M)
  - [ ] API: Update SettingsRepository to persist budget_preferences to the new column(s) and expose retrieval for default settings; ensure transactional integrity. - (M)
  - [ ] Frontend: Add BudgetPreferences UI (add/edit categories and limits) in Default Settings view using React/Angular component with form validation and JSON structure feedback. - (M)
  - [ ] Frontend: Implement DefaultSettingsViewModel.validate() to validate numeric inputs and conflicting ranges for budget categories/limits; provide granular error messages. - (S)
  - [ ] Frontend: Implement preview calculation for budget impact in Default Settings view (estimates totals per category and overall variance) and show live preview as user edits. - (S)
  - [ ] Integration: Wire ViewModel.commit() to call DefaultSettingsRepository.saveSettings for budget prefs; ensure end-to-end path from UI to repo is exercised. - (M)
  - [ ] Backend: Add unit tests for SettingsService.setBudgetPreferences and the accompanying validation logic; cover happy path and invalid inputs. - (S)
  - [ ] Frontend: Add UI tests for budget preferences input validation and preview in Default Settings view using e2e framework; verify validation messages and preview accuracy. - (S)
- [ ] **Save Default Settings** - (XS): As a: user, I want to: save all changed default settings, So that: settings persist across sessions and devices
  - **Acceptance Criteria:**
    - [ ] All modified settings are saved in a single transaction
Settings persisted to database with RLS in effect
User receives confirmation after save
Rollback on failure in case of partial save
Audit log entry created for changes
  - [ ] DB: Add transactional upsert and audit fields to couple_settings table - (L)
  - [ ] API: Implement repository.save(coupleId, settings) to perform single-transaction upsert - (M)
  - [ ] API: Add audit logging in service when settings change - (S)
  - [ ] API: Implement SettingsService.applyDefaults to validate, begin transaction, call repository.save and create audit entry - (L)
  - [ ] API: Implement SettingsController.saveDefaultSettings endpoint to call service and return confirmation - (S)
  - [ ] Frontend: Implement DefaultSettingsViewController.save to send aggregated settings to save endpoint and show confirmation - (M)
  - [ ] API: Enforce RLS and permission checks for save operation - (M)
  - [ ] API: Add rollback behavior and error handling with Sentry logging for partial failures - (L)
  - [ ] Frontend: Invalidate DefaultSettingsRepository cache after successful save - (S)
  - [ ] QA: Add unit tests for SettingsService and repository save transaction - (M)
  - [ ] QA: Add integration test covering end-to-end save with RLS and audit log - (L)
  - [ ] DOC: Update API docs and UX copy for confirmation message and error states - (S)
- [ ] **Set Currency** - (S): As a: user, I want to: set the default display currency for my account, So that: monetary values are shown in the preferred currency across the app
  - **Acceptance Criteria:**
    - [ ] User can select a currency from a predefined list
Selected currency is saved to the user profile and applied system-wide
Validation prevents unsupported currencies
Data is persisted in database with couple_id scoping
Edge case: changing currency reflects immediately in current session
  - [ ] DB migration: Add currency column to couple_settings table and create rollback migration. Ensure DB schema supports storing ISO currency codes and default currency per couple_settings record. Include migration file and schema update, with index on currency_code. - (S)
  - [ ] API: Implement setCurrency(coupleId, currencyCode) in SettingsService to update default currency for a couple. Validate currencyCode against allowed ISO codes, handle missing couple gracefully, and ensure cache invalidation if in use. - (S)
  - [ ] API: Add saveDefaultSettings endpoint in SettingsController to accept currency. Wire controller to SettingsService.setCurrency, and return appropriate HTTP statuses. Ensure request model validates currencyCode and include error handling. - (S)
  - [ ] Frontend: Add Currency selector UI in Default Settings view with predefined list. Bind selection to SettingsService API, reflect current currency from API, and handle loading/error states. - (S)
  - [ ] Frontend: Implement validateCurrency in SettingsValidator and integrate into DefaultSettingsViewModel. Ensure local validation before API call and provide user feedback for invalid currency codes. - (S)
  - [ ] Frontend: Update DefaultSettingsViewModel.commit() to call save API and apply currency immediately in session. Ensure optimistic UI update or server-confirmed update, and persist in user session context. - (S)
  - [ ] Testing: Add integration tests for saving currency, validation, and immediate session update. Cover API, frontend, and session state interactions across components. - (M)
  - [ ] Docs: Update settings docs and add migration notes. Include DB change details, API usage, UI changes, validation rules, and rollback considerations. - (XS)
- [ ] **Set Timezone** - (S): As a: user, I want to: set the default timezone for my account, So that: timestamps and schedules display correctly for the user
  - **Acceptance Criteria:**
    - [ ] User can choose timezone from a comprehensive list
Timezone preference saved to user profile
Displayed times adjust across the app for the user
Validation ensures valid timezone identifiers
Data persisted with proper couple_id scope
  - [ ] DB: Add timezone field and couple_id scope to couple_settings table (migration) -> Implement schema migration to add timezone_id (string) and index on couple_id for efficient filtering; ensure existing migrations run in MVP. Update ORM models to reflect new fields. - (XS)
  - [ ] API: Implement SettingsService.setTimezone(coupleId, timezone) with validation and persistence -> Service validates timezone via SettingsValidator, persists to DB, and returns confirmation. Integrates with repository and transaction boundaries. - (S)
  - [ ] API: Add/save endpoint in SettingsController to handle timezone update requests -> Expose PUT /settings/{coupleId}/timezone (or similar) with body timezoneId; wire to SettingsService.setTimezone; include auth and input validation. - (S)
  - [ ] Frontend: Update DefaultSettingsViewModel.commit() to call save timezone via API and handle isSaving state -> Extend VM to call API.Settings.saveTimezone with coupleId and timezone, manage isSaving flag, and handle API errors by user notification. - (S)
  - [ ] Frontend: Build timezone selector UI in Default Settings View with comprehensive list and selection handling -> Implement dropdown/list of timezones, with search, proper aria labels, and binding to DefaultSettingsViewModel timezone property. - (M)
  - [ ] Frontend: Implement SettingsValidator.validateTimezone(timezoneId) to ensure valid identifiers -> Client-side validation against IANA timezone database or allowed list; used by API calls and UI validation. - (S)
  - [ ] Quality: Add integration tests for timezone save flow (DB -> API -> Frontend VM) including couple_id scope -> End-to-end tests covering DB migration, API SettingsService.setTimezone, and Frontend DefaultSettingsViewModel integration; ensure tz persists per couple, and error paths. - (XL)
  - [ ] Documentation: Add docs for timezone setting behavior and data model changes -> Update API docs, DB schema change notes, frontend usage with example payloads and UI flow. - (XS)
- [ ] **Configure Notifications** - (S): As a: user, I want to: configure notification preferences (types, channels), So that: users receive relevant alerts
  - **Acceptance Criteria:**
    - [ ] User can enable/disable notification types
Channel preferences stored per user
Preview of notification schedule
Validation of channels
Data persisted with couple_id scope
  - [ ] DB: Add notification_settings columns to Couple Settings table - (M)
  - [ ] API: Add setNotifications(coupleId, NotificationSettingsDTO) in SettingsService - (M)
  - [ ] API: Add saveDefaultSettings endpoint in SettingsController to accept notification DTO - (M)
  - [ ] Repo: Extend DefaultSettingsRepository to persist notification settings per coupleId - (M)
  - [ ] Frontend: Add NotificationPreferences UI with toggles and channel selectors in Default Settings view - (M)
  - [ ] Frontend: Implement DefaultSettingsViewModel.updateSetting() for notification prefs and preview generation - (M)
  - [ ] Validation: Implement validateSettings(dto) to validate channels and formats - (M)
  - [ ] Integration: Wire UI save action to call SettingsController.saveDefaultSettings and handle coupleId - (M)
  - [ ] Testing: Unit tests for SettingsService.validateSettings and setNotifications - (M)
  - [ ] Testing: UI tests for NotificationPreferences preview and toggles - (M)
  - [ ] Docs: Document notification preference options, channels, and persistence scope (couple_id) - (M)
- [ ] **Map Columns** - (S): As a: data administrator, I want to: Map CSV/Excel columns to guest import fields, So that: Imported data aligns with the guest model
  - **Acceptance Criteria:**
    - [ ] User can map each column to a guest field.
Invalid or unmapped columns are flagged before import.
Preview shows mapped fields for validation.
  - [ ] Frontend: Implement Mapping Editor UI in the Guest Import flow to allow mapping between CSV/XLSX headers and guest model fields using React components, stateful mapping model, and validation hooks. Integrates with ViewModel for real-time preview and keyboard accessibility. Preserve Guest Import flow route and component hierarchy. - (S)
  - [ ] Frontend: Implement ViewModel mapColumns(mapping: [string:string]) to store and expose the column mappings between CSV/XLSX headers and guest fields within the Guest Import flow. Use TypeScript interfaces and ensure two-way binding with Mapping Editor UI. Leverage existing Guest Import component architecture. - (XS)
  - [ ] API: Add mapHeaders endpoint to ImportController to accept HeaderMapping payload and return ValidationPreview. Endpoint should validate payload shape, enforce authentication, and return a structured preview of mapped columns against guest model. Uses existing API routing and validation middleware. - (M)
  - [ ] Backend: Implement MappingService.inferMapping(headers: string[]) to infer likely mapping between CSV/XLSX headers and guest model fields using heuristics and existing schema metadata. Expose results via service and integrate with ImportController mapHeaders flow for auto-mapping suggestions. - (M)
  - [ ] Backend: Add validateAndMap(fileData, mapping) in ImportValidationMiddleware to flag invalid/unmapped columns before import. Middleware should short-circuit on critical errors, attach ValidationResult to request for downstream processing, and be compatible with existing Import flow. - (M)
  - [ ] Worker: Enhance HeaderFieldMapper.mapHeaders and detectDelimiter to support common header heuristics (quotes, escapes, delimiter detection, and header row heuristics) in background processing. Ensure compatibility with 2_7 mapHeaders usage and large file scenarios. - (L)
  - [ ] Backend: Wire ImportPreviewGenerator.mapHeaders(sessionId, mapping) to produce preview rows and ValidationResult for the given session. Generates a sample of rows from the uploaded file with mapped fields and highlights validation flags. - (L)
  - [ ] Frontend: Add Preview pane rendering mapped fields and validation flags in GuestImportView. Show a tabular preview with mapped columns and visual indicators for validation status. Integrate with existing Guest Import UI state and actions. - (M)
  - [ ] Testing: Unit tests for MappingService, HeaderFieldMapper, and ImportValidationMiddleware (validation of unmapped/invalid columns). Include edge cases and regression tests to ensure stability across 2_3-2_7 flows. - (M)
  - [ ] Documentation: Add user-facing guide for mapping step and developer notes on mapping APIs, including API contracts, example payloads, and UI usage flow within Guest Import. Include architecture overview and troubleshooting tips. - (S)
- [ ] **Validate Preview** - (S): As a: data administrator, I want to: Validate a preview of imported data, So that: I can catch errors before committing to database
  - **Acceptance Criteria:**
    - [ ] Preview shows a sample of rows with validation status.
Invalid emails or phones are highlighted.
Preview can be refreshed after mapping changes.
  - [ ] Backend: Add preview generation API that returns sample rows with validation status - (M)
  - [ ] Backend: Implement email and phone validation rules in ValidationService - (S)
  - [ ] Backend: Add mapping refresh endpoint to re-run preview after mapping changes - (M)
  - [ ] Frontend: Update GuestImportViewModel to fetch and refresh preview - (S)
  - [ ] Frontend: Render preview sample with validation status and highlight invalid emails/phones - (S)
  - [ ] Testing: Add unit tests for ValidationService email/phone checks - (XS)
  - [ ] Testing: Add integration test for preview refresh after mapping change - (M)
  - [ ] Documentation: Document preview API and mapping refresh behavior - (S)
- [ ] **Resolve Duplicates** - (M): As a: data administrator, I want to: Resolve duplicates during import, So that: Data integrity is preserved
  - **Acceptance Criteria:**
    - [ ] Duplicates detected are presented to user.
User can choose skip/merge for duplicates.
System prevents duplicates in final import.
  - [ ] Backend: Add preview endpoint to generate import preview with duplicate detection (API) - (S)
  - [ ] Worker: Implement findDuplicates(rows) in DuplicateResolver to produce DuplicateReport - (M)
  - [ ] Backend: Implement resolveDuplicates(preview, strategy) in ImportValidationMiddleware to apply skip/merge logic - (L)
  - [ ] Frontend: Add duplicates UI in Guest Import View to present duplicates and allow skip/merge choices - (S)
  - [ ] Frontend: Update GuestImportViewModel to call preview API and submit user resolutions - (S)
  - [ ] Backend: Apply resolved results in Bulk DB Writer to commit import without duplicates - (L)
  - [ ] DB: Add/find DB checks and queries to prevent duplicates on commit and provide findDuplicates queries - (M)
  - [ ] Testing: Add unit tests for DuplicateResolver.resolve/merge/shouldSkip and integration tests for import preview->resolve->commit - (M)
- [ ] **Confirm Import** - (S): As a: data administrator, I want to: Confirm and execute the import, So that: Guest data is added to the system under the correct couple scope
  - **Acceptance Criteria:**
    - [ ] Import runs with couple_id scoping.
All inserted records have non-null required fields.
On success, a summary is shown with counts.
  - [ ] DB: Implement bulkInsert(coupleId, guests) with non-null checks and returns inserted/failed counts, ensuring that the operation respects the couple scope and uses existing DB writer patterns (transactional, batch insert) with proper error handling and return model. - (M)
  - [ ] API: Add confirmImport(importId, options) orchestration to ImportController to enforce couple_id scoping and trigger commit using ImportService; integrate with routing and validation layers. - (S)
  - [ ] Service: Implement ImportCommitService.commit(sessionId, tenantId, options) to validate rows, call Bulk DB Writer, and produce a summary; coordinates with transactional boundaries and error handling. - (M)
  - [ ] Worker: Ensure Bulk DB Writer performs transactional bulk insert and rollbackOnFailure when required fields are null, with retry/compensation strategy if needed. - (L)
  - [ ] Frontend: Implement GuestImportViewModel.confirmImport() to call API, pass couple scope, and surface summary counts; ensure proper error handling and user feedback. - (S)
  - [ ] Repo: Update GuestImportRepository.commit/commitTransaction to include couple_id scoping and return counts - (M)
  - [ ] Quality: Add tests for confirmImport flow (unit for service, integration for DB) and update docs - (S)
- [ ] **Track Import Progress** - (M): As a: data administrator, I want to: Track import progress in real-time, So that: I know when import completes or fails
  - **Acceptance Criteria:**
    - [ ] Progress indicator updates in real-time.
Handles 100+ row imports with percentage complete.
Fails provide error details with line numbers.
  - [ ] DB: Add GuestImportProgress schema & queries to record totalRows/processedRows/failedRows/status/startTime/endTime - (M)
  - [ ] API: Add trackProgress endpoint returning percent/status/errors for importId - (S)
  - [ ] Worker: Instrument ImportProgressTracker to persist updates (start/update/markComplete) and include line-numbered errors - (M)
  - [ ] Service: Implement ImportService.trackProgress to aggregate worker progress and errors - (M)
  - [ ] Frontend: Update GuestImportViewModel to poll/subscribe trackProgress and expose percentage + error lines - (S)
  - [ ] Frontend UI: Add real-time progress indicator and error list in Guest Import View - (S)
  - [ ] Testing: Add integration tests for 100+ row import progress updates and error reporting - (M)
  - [ ] Infra/Monitoring: Emit Sentry/AppLogger events for failures with line numbers and progress anomalies - (S)
- [ ] **Rollback On Failure** - (L): As a: data administrator, I want to: Rollback on failure during import, So that: System remains consistent and no partial data is saved
  - **Acceptance Criteria:**
    - [ ] Any failure cancels operation and rolls back all inserts.
Database shows consistent state after rollback.
Error is surfaced to user with line numbers and reason.
  - [ ] DB: Implement rollback and verification queries for import transactions, ensuring transactional isolation and idempotent verification of committed data for guest import flow. - (M)
  - [ ] API: Add rollbackImport(importId) endpoint in onboarding service to revert an import transaction on failure, coordinating with Worker and DB state. - (L)
  - [ ] Worker: Implement transactional bulk write and rollback support in BulkWriter to atomically persist guest import data and rollback on failures. - (L)
  - [ ] Worker: Enhance ImportOrchestratorService to call rollback on failure and coordinate transactions across BulkWriter and DB, ensuring end-to-end rollback. - (XL)
  - [ ] API: Improve ImportErrorHandler to capture line numbers and reasons to aid troubleshooting when imports fail. - (S)
  - [ ] Frontend: Surface import errors with line numbers in Guest Import View to assist users in fixing data issues. - (S)
  - [ ] Testing: Add integration tests verifying rollback leaves DB consistent across components (BulkWriter, Onboarding API, Orchestrator). - (XL)
  - [ ] Monitoring: Add Sentry logging and AppLogger hooks for rollback events to improve observability. - (S)