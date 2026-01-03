---
title: Services Architecture - Complete Reference
type: note
permalink: architecture/services/services-architecture-complete-reference
tags:
- architecture
- services
- complete
- reference
- phone-formatting
---

# Services Architecture - Complete Reference

**Last Updated**: 2025-12-31  
**Status**: Production Architecture

## Overview

I Do Blueprint uses a layered service architecture with **100+ specialized services** organized into distinct categories. Services handle everything from business logic and data access to UI coordination and external integrations.

---

## Service Layer Organization

```
I Do Blueprint/Services/
├── Domain/Services/          # Business logic actors (6 services)
├── Analytics/                # Monitoring and performance (10 services)
├── API/                      # API clients and data access (20+ services)
├── Auth/                     # Authentication (1 service)
├── Avatar/                   # Avatar generation (2 services)
├── Collaboration/            # Multi-user features (1 service)
├── Email/                    # Email integration (1 service)
├── Export/                   # Data export (10+ services)
├── Import/                   # Data import (9 services)
├── Integration/              # External integrations (5 services)
├── Loaders/                  # Data preloading (1 service)
├── Navigation/               # App coordination (1 service)
├── PhoneNumberService.swift  # Phone formatting (1 service)
├── Realtime/                 # Real-time collaboration (1 service)
├── Storage/                  # Supabase client (1 service)
├── UI/                       # UI helpers (7 services)
└── VisualPlanning/           # Visual planning features (30+ services)
```

---

## 1. Domain Services (Business Logic Layer)

**Location**: `Domain/Services/`  
**Pattern**: Actor-based, thread-safe business logic  
**Count**: 6 services

### Services

1. **BudgetAggregationService** - Budget overview aggregation
2. **BudgetAllocationService** - Expense allocation logic
3. **BudgetDevelopmentService** - Budget scenario development
4. **ExpensePaymentStatusService** - Payment status calculations
5. **CollaborationPermissionService** - Permission checks
6. **CollaborationInvitationService** - Invitation workflows

### Pattern

```swift
actor {Feature}Service: {Feature}ServiceProtocol {
    private let repository: {Feature}RepositoryProtocol
    private nonisolated let logger = AppLogger.repository
    
    func performComplexOperation() async throws -> Result {
        // Parallel data fetching
        async let data1 = repository.fetch1()
        async let data2 = repository.fetch2()
        
        // Business logic
        let result = complexCalculation(try await data1, try await data2)
        
        // Performance tracking
        await PerformanceMonitor.shared.recordOperation("op", duration: elapsed)
        
        return result
    }
}
```

**See**: `architecture/services/Domain Services Layer - Business Logic Separation.md`

---

## 2. PhoneNumberService (Utility Service)

**Location**: `I Do Blueprint/Services/PhoneNumberService.swift`  
**Pattern**: Actor-based, thread-safe formatting utility  
**Library**: PhoneNumberKit

### Purpose

Centralized phone number formatting, validation, and parsing using E.164 international standard.

### Key Methods

```swift
actor PhoneNumberService {
    // Format to E.164 international standard
    func formatPhoneNumber(_ input: String, defaultRegion: String = "US") -> String?
    
    // Validate phone number
    func isValid(_ input: String, region: String = "US") -> Bool
    
    // Parse into components
    func parsePhoneNumber(_ input: String, region: String = "US") -> PhoneNumber?
    
    // Format to E.164 (no spaces)
    func formatToE164(_ input: String, defaultRegion: String = "US") -> String?
    
    // Format to national (display-friendly)
    func formatToNational(_ input: String, defaultRegion: String = "US") -> String?
    
    // Get phone number type (mobile, landline)
    func getType(_ input: String, region: String = "US") -> PhoneNumberType?
    
    // Batch format (for imports)
    func batchFormat(_ inputs: [String], defaultRegion: String = "US") async -> [String?]
}
```

### Usage

```swift
// In repositories
let phoneNumberService = PhoneNumberService()

if let phone = guest.phone, !phone.isEmpty {
    guest.phone = await phoneNumberService.formatPhoneNumber(phone, defaultRegion: "US")
    // Result: "+1 555-123-4567"
}
```

### Features

✅ E.164 international format (`+1 555-123-4567`)  
✅ Validation with libphonenumber rules  
✅ Type detection (mobile vs landline)  
✅ International support (200+ countries)  
✅ Batch operations for imports  
✅ Thread-safe actor isolation

**See**: `architecture/features/Phone Number Formatting - Complete Implementation Reference.md`

---

## 3. Analytics Services (Monitoring & Performance)

**Location**: `I Do Blueprint/Services/Analytics/`  
**Count**: 10 services

### Services

1. **SentryService** - Error tracking and crash reporting
2. **PerformanceMonitor** - Operation timing and metrics
3. **CacheWarmer** - Proactive cache population
4. **ErrorMetrics** - Error aggregation and analysis
5. **AnalyticsService** - Main analytics coordinator
6. **AnalyticsColorService** - Color palette analytics
7. **AnalyticsInsightsService** - AI-powered insights
8. **AnalyticsOverviewService** - Dashboard overview
9. **AnalyticsStyleService** - Style trend analysis
10. **AnalyticsUsageService** - Feature usage tracking
11. **PerformanceOptimizationService** - Performance tuning

### Key Patterns

#### Error Tracking
```swift
// Capture errors to Sentry
SentryService.shared.captureError(error, context: [
    "operation": "fetchGuests",
    "tenantId": tenantId.uuidString
])
```

#### Performance Monitoring
```swift
let startTime = Date()
// ... operation ...
let duration = Date().timeIntervalSince(startTime)
await PerformanceMonitor.shared.recordOperation("fetchGuests", duration: duration)
```

#### Cache Warming
```swift
await CacheWarmer.shared.warmCache(for: tenantId)
```

---

## 4. API Services (Data Access Layer)

**Location**: `I Do Blueprint/Services/API/`  
**Count**: 20+ services

### Main API Coordinators

1. **DocumentsAPI** - Document management
2. **NotesAPI** - Notes and annotations
3. **SettingsAPI** - User settings
4. **TasksAPI** - Task management
5. **TimelineAPI** - Timeline and milestones

### Document Services (Domain-Driven Decomposition)

**Location**: `I Do Blueprint/Services/API/Documents/`

1. **DocumentCRUDService** - Create, read, update, delete
2. **DocumentBatchService** - Bulk operations
3. **DocumentSearchService** - Full-text search
4. **DocumentStorageService** - File storage
5. **DocumentRelatedEntitiesService** - Related data fetching

### Timeline Services (Domain-Driven Decomposition)

**Location**: `I Do Blueprint/Services/API/Timeline/`

1. **TimelineItemService** - Timeline item CRUD
2. **MilestoneService** - Milestone management
3. **TimelineDateParser** - Date parsing utilities
4. **TimelineDataTransformer** - Data transformation

### Pattern

```swift
class DocumentsAPI {
    private let crudService: DocumentCRUDService
    private let batchService: DocumentBatchService
    private let searchService: DocumentSearchService
    
    func fetchDocument(id: UUID) async throws -> Document {
        try await crudService.fetchDocument(id: id)
    }
}
```

**See**: `architecture/services/TimelineAPI Service Decomposition.md`

---

## 5. Auth Service (Authentication)

**Location**: `I Do Blueprint/Services/Auth/SessionManager.swift`

### Purpose

Manages user authentication sessions, token storage, and session lifecycle.

### Key Features

- **Keychain Storage**: Session data stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Token Management**: Access token refresh and validation
- **Session Lifecycle**: Login, logout, session restoration
- **Multi-Tenancy**: Couple ID and tenant context

### Security

✅ Keychain-backed session storage  
✅ Device-locked accessibility  
✅ Automatic token refresh  
✅ Secure session cleanup on logout

---

## 6. Import Services (Data Import)

**Location**: `I Do Blueprint/Services/Import/`  
**Count**: 9 services

### Services

1. **FileImportService** - Main import coordinator
2. **CSVImportService** - CSV parsing
3. **XLSXImportService** - Excel parsing
4. **ImportCoordinator** - Multi-format coordinator
5. **ColumnMappingService** - Column mapping inference
6. **ImportValidationService** - Data validation
7. **GuestConversionService** - CSV → Guest conversion
8. **VendorConversionService** - CSV → Vendor conversion
9. **DateParsingHelpers**, **RSVPStatusParsingHelpers**, **StringValidationHelpers**

### Import Pipeline

```
File Upload
    ↓
FileImportService (detect format)
    ↓
CSVImportService / XLSXImportService (parse)
    ↓
ColumnMappingService (infer mappings)
    ↓
ImportValidationService (validate data)
    ↓
GuestConversionService / VendorConversionService (convert to models)
    ↓
Repository (save to database)
```

---

## 7. Export Services (Data Export)

**Location**: `I Do Blueprint/Services/Export/`  
**Count**: 10+ services

### Core Services

1. **GuestExportService** - Guest list export
2. **VendorExportService** - Vendor list export
3. **BudgetExportService** - Budget export
4. **AdvancedExportTemplateService** - Template management

### Export Generators

**Location**: `I Do Blueprint/Services/Export/Generators/`

1. **PDFExportGenerator** - PDF generation
2. **ImageExportGenerator** - Image export
3. **SVGExportGenerator** - SVG export

### Export Managers

1. **ExportTemplateManager** - Template CRUD
2. **BrandingSettingsManager** - Branding configuration

### Export Formats

- ✅ CSV (guest lists, vendor lists, budgets)
- ✅ XLSX (Excel spreadsheets)
- ✅ PDF (printable documents)
- ✅ Images (PNG, JPEG for visual planning)
- ✅ SVG (scalable graphics)

---

## 8. Integration Services (External APIs)

**Location**: `I Do Blueprint/Services/Integration/`  
**Count**: 5 services

### Services

1. **GoogleIntegrationManager** - Main Google coordinator
2. **GoogleAuthManager** - OAuth authentication
3. **GoogleSheetsManager** - Sheets API integration
4. **GoogleDriveManager** - Drive API integration
5. **SecureAPIKeyManager** - API key management
6. **ExternalIntegrationsService** - Third-party integrations

### Google Integration Pattern

```swift
// Authenticate
await GoogleAuthManager.shared.authenticate()

// Export to Sheets
await GoogleSheetsManager.shared.exportGuests(guests, to: spreadsheetId)

// Access Drive
await GoogleDriveManager.shared.uploadFile(data, filename: "guests.csv")
```

---

## 9. UI Services (User Interface Helpers)

**Location**: `I Do Blueprint/Services/UI/`  
**Count**: 7 services

### Services

1. **AlertPresenter** - Main alert coordinator
2. **AlertPresenterProtocol** - Protocol for dependency injection
3. **PreviewAlertPresenter** - SwiftUI preview implementation
4. **ErrorAlertService** - Error alert presentation
5. **ConfirmationAlertService** - Confirmation dialogs
6. **ProgressAlertService** - Progress indicators
7. **ToastService** - Toast notifications

### Pattern

```swift
// Present error
await AlertPresenter.shared.presentError(
    title: "Failed to Save",
    message: error.localizedDescription
)

// Confirmation
let confirmed = await AlertPresenter.shared.presentConfirmation(
    title: "Delete Guest?",
    message: "This action cannot be undone."
)

// Progress
await AlertPresenter.shared.showProgress("Importing guests...")
```

**See**: `architecture/services/AlertPresenter Service Decomposition.md`

---

## 10. Visual Planning Services (Visual Features)

**Location**: `I Do Blueprint/Services/VisualPlanning/`  
**Count**: 30+ services

### Core Services

1. **SupabaseVisualPlanningService** - Main data access
2. **ColorExtractionService** - Image color analysis
3. **ImageProcessingService** - Image manipulation
4. **VisualPlanningSearchService** - Search coordinator
5. **ExportService** - Visual planning export

### Color Extraction Algorithms

**Location**: `I Do Blueprint/Services/VisualPlanning/Algorithms/`

1. **DominantColorAlgorithm** - k-means clustering
2. **VibrantColorAlgorithm** - Vibrant color detection
3. **QuantizationAlgorithm** - Color quantization
4. **ClusteringAlgorithm** - Generic clustering
5. **ColorExtractionAlgorithmProtocol** - Algorithm abstraction

### Analysis Services

**Location**: `I Do Blueprint/Services/VisualPlanning/Analysis/`

1. **ColorQualityAnalyzer** - Color palette quality scoring
2. **AccessibilityAnalyzer** - WCAG contrast checking

### Search Services

**Location**: `I Do Blueprint/Services/VisualPlanning/Search/`

1. **ColorPaletteSearchService** - Color palette search
2. **MoodBoardSearchService** - Mood board search
3. **SeatingChartSearchService** - Seating chart search
4. **StylePreferencesSearchService** - Style search
5. **SearchSuggestionService** - Search suggestions
6. **SavedSearchManager** - Saved searches
7. **ColorComparisonHelper** - Color similarity
8. **SearchResultTransformer** - Result transformation

### Export Renderers

**Location**: `I Do Blueprint/Services/VisualPlanning/Export/`

1. **ColorPaletteExportRenderer** - Color palette PDFs
2. **MoodBoardExportRenderer** - Mood board PDFs
3. **SeatingChartExportRenderer** - Seating chart PDFs
4. **ImageExportService** - Image export
5. **PDFExportService** - PDF generation
6. **FileExportHelper** - File system utilities

---

## 11. Other Services

### Avatar Services
**Location**: `I Do Blueprint/Services/Avatar/`

1. **MultiAvatarService** - Avatar generation
2. **MultiAvatarJSService** - JavaScript-based avatars

### Collaboration Services
**Location**: `I Do Blueprint/Services/Collaboration/`

1. **InvitationService** - Collaboration invitations

### Email Services
**Location**: `I Do Blueprint/Services/Email/`

1. **ResendEmailService** - Email sending via Resend

### Realtime Services
**Location**: `I Do Blueprint/Services/Realtime/`

1. **CollaborationRealtimeManager** - Real-time collaboration

### Navigation Services
**Location**: `I Do Blueprint/Services/Navigation/`

1. **AppCoordinator** - App-level navigation

### Loader Services
**Location**: `I Do Blueprint/Services/Loaders/`

1. **PostOnboardingLoader** - Post-onboarding data loading

### Storage Services
**Location**: `I Do Blueprint/Services/Storage/`

1. **SupabaseClient** - Supabase client wrapper

---

## Service Architecture Principles

### 1. Separation of Concerns

- **Domain Services**: Business logic only
- **API Services**: Data access and transformation
- **UI Services**: User interface coordination
- **Integration Services**: External API communication

### 2. Actor Isolation

All services that handle shared mutable state use `actor`:

```swift
actor PhoneNumberService { }
actor BudgetAggregationService { }
```

### 3. Nonisolated Loggers

Loggers use `nonisolated` for synchronous access:

```swift
private nonisolated let logger = AppLogger.service
```

### 4. Dependency Injection

Services receive dependencies via initialization:

```swift
init(repository: RepositoryProtocol, service: ServiceProtocol) {
    self.repository = repository
    self.service = service
}
```

### 5. Protocol-Based Design

Services implement protocols for testability:

```swift
protocol DocumentServiceProtocol {
    func fetchDocument(id: UUID) async throws -> Document
}

actor DocumentService: DocumentServiceProtocol { }
```

### 6. Performance Monitoring

Critical operations tracked:

```swift
let startTime = Date()
let result = try await operation()
let duration = Date().timeIntervalSince(startTime)
await PerformanceMonitor.shared.recordOperation("name", duration: duration)
```

---

## Service Testing Patterns

### Mock Services

```swift
class MockPhoneNumberService: PhoneNumberServiceProtocol {
    var formatResult: String?
    var isValidResult: Bool = true
    
    func formatPhoneNumber(_ input: String, defaultRegion: String) -> String? {
        return formatResult
    }
}
```

### Service Tests

```swift
@MainActor
final class PhoneNumberServiceTests: XCTestCase {
    var service: PhoneNumberService!
    
    override func setUp() async throws {
        service = PhoneNumberService()
    }
    
    func test_formatPhoneNumber_tenDigits_returnsE164() async {
        let formatted = await service.formatPhoneNumber("5551234567")
        XCTAssertEqual(formatted, "+1 555-123-4567")
    }
}
```

---

## Service Organization Best Practices

### ✅ Do's

1. **Group Related Services**: Export services together, import services together
2. **Use Actor for Shared State**: Thread safety without locks
3. **Monitor Performance**: Track critical operations
4. **Log Operations**: Use appropriate log levels
5. **Protocol-Based**: Enable testing and dependency injection
6. **Small, Focused Services**: Single responsibility principle

### ❌ Don'ts

1. **Don't Mix Concerns**: Keep business logic out of UI services
2. **Don't Create God Services**: Break large services into smaller ones
3. **Don't Skip Error Handling**: Always handle and log errors
4. **Don't Ignore Performance**: Monitor expensive operations
5. **Don't Hardcode Dependencies**: Use dependency injection

---

## Service Categories Summary

| Category | Count | Purpose |
|----------|-------|---------|
| **Domain Services** | 6 | Business logic actors |
| **Phone Formatting** | 1 | Phone number utilities |
| **Analytics** | 10 | Monitoring and performance |
| **API Services** | 20+ | Data access coordinators |
| **Import** | 9 | Data import pipeline |
| **Export** | 10+ | Data export formats |
| **Integration** | 5 | External API connections |
| **UI** | 7 | User interface helpers |
| **Visual Planning** | 30+ | Visual features |
| **Other** | 8 | Auth, realtime, navigation, etc. |
| **Total** | **100+** | Complete service layer |

---

## Related Documentation

- **Domain Services**: `architecture/services/Domain Services Layer - Business Logic Separation.md`
- **Phone Formatting**: `architecture/features/Phone Number Formatting - Complete Implementation Reference.md`
- **TimelineAPI Decomposition**: `architecture/services/TimelineAPI Service Decomposition.md`
- **AlertPresenter Decomposition**: `architecture/services/AlertPresenter Service Decomposition.md`
- **Repository Layer**: `architecture/repositories/Repository Layer Architecture - Protocol-Based Data Access.md`
- **Store Layer**: `architecture/stores/Store Layer Architecture - V2 Pattern.md`

---

## Quick Reference

### Find a Service

**By Category**:
```bash
# Domain services (business logic)
ls Domain/Services/

# Phone formatting
cat "I Do Blueprint/Services/PhoneNumberService.swift"

# Analytics
ls "I Do Blueprint/Services/Analytics/"

# Import/Export
ls "I Do Blueprint/Services/Import/"
ls "I Do Blueprint/Services/Export/"
```

### Common Service Patterns

**Format Phone Number**:
```swift
let formatted = await PhoneNumberService().formatPhoneNumber("5551234567")
```

**Track Error**:
```swift
SentryService.shared.captureError(error, context: ["operation": "save"])
```

**Show Alert**:
```swift
await AlertPresenter.shared.presentError(title: "Error", message: message)
```

**Monitor Performance**:
```swift
await PerformanceMonitor.shared.recordOperation("operation", duration: elapsed)
```

---

**Status**: Complete service architecture reference covering 100+ services across 10+ categories.