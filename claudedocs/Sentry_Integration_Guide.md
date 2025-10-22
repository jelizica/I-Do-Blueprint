# Sentry Integration Guide

## Overview

This guide explains how to use Sentry for comprehensive error tracking, performance monitoring, and prevention in the I Do Blueprint macOS app.

## 📋 Table of Contents

1. [Setup & Configuration](#setup--configuration)
2. [Error Tracking](#error-tracking)
3. [Performance Monitoring](#performance-monitoring)
4. [Prevention Monitoring with ErrorTracker](#prevention-monitoring-with-errortracker)
5. [SwiftUI Integration](#swiftui-integration)
6. [Best Practices](#best-practices)

---

## Setup & Configuration

### DSN Configuration

Add your Sentry DSN to [Config.plist](I Do Blueprint/Core/Config/Config.plist):

```xml
<key>SENTRY_DSN</key>
<string>https://your-dsn@sentry.io/your-project-id</string>
```

### Initialization

Sentry is automatically initialized in [My_Wedding_Planning_AppApp.swift:14](I Do Blueprint/App/My_Wedding_Planning_AppApp.swift#L14):

```swift
init() {
    SentryService.shared.configure()
}
```

### Features Enabled

- ✅ **Crash Reporting**: Automatic crash detection and reporting
- ✅ **Error Tracking**: Manual and automatic error capture
- ✅ **Performance Monitoring**: Transaction and span tracking
- ✅ **Breadcrumbs**: Automatic navigation and action tracking
- ✅ **SwiftUI Instrumentation**: View rendering and lifecycle tracking
- ✅ **Network Tracking**: Automatic HTTP request monitoring
- ✅ **App Hang Detection**: 2-second timeout detection
- ✅ **File I/O Tracking**: Disk operation monitoring

---

## Error Tracking

### Basic Error Capture

```swift
do {
    try await someRiskyOperation()
} catch {
    SentryService.shared.captureError(
        error,
        context: [
            "operation": "fetchVendors",
            "vendor_count": 42
        ],
        level: .error
    )
}
```

### Error Severity Levels

```swift
// Information (for debugging)
SentryService.shared.captureError(error, level: .info)

// Warning (non-critical issues)
SentryService.shared.captureError(error, level: .warning)

// Error (failures that need attention)
SentryService.shared.captureError(error, level: .error)

// Fatal (critical failures)
SentryService.shared.captureError(error, level: .fatal)
```

### Message Tracking

```swift
SentryService.shared.captureMessage(
    "User exported vendor list",
    context: [
        "format": "CSV",
        "count": 15
    ],
    level: .info
)
```

---

## Performance Monitoring

### Manual Transaction Tracking

```swift
// Start transaction
let transaction = SentryService.shared.startTransaction(
    name: "load_vendors",
    operation: "data.fetch"
)

// Perform work
await loadVendors()

// Finish transaction
transaction?.finish()
```

### Automatic Transaction Tracking

```swift
// Synchronous operation
let result = SentryService.shared.measure(
    name: "calculate_budget",
    operation: "compute"
) {
    return calculateTotalBudget()
}

// Async operation
let vendors = await SentryService.shared.measureAsync(
    name: "fetch_vendors",
    operation: "data.fetch"
) {
    return await vendorStore.fetchAll()
}
```

### Transaction by Name

```swift
// Start named transaction
SentryService.shared.startTransaction(
    name: "vendor_export",
    operation: "io.export"
)

// Later, finish it
SentryService.shared.finishTransaction(
    name: "vendor_export",
    status: .ok
)
```

---

## Prevention Monitoring with ErrorTracker

### Integration Overview

`ErrorTracker` automatically sends all tracked errors to Sentry for prevention analysis. This enables you to:

- 🔍 **Identify patterns** before they become widespread issues
- 📊 **Track error trends** over time
- ⚡ **Monitor retry success rates**
- 🎯 **Focus on high-impact errors**

### How It Works

```swift
// ErrorTracker automatically sends to Sentry
await ErrorTracker.shared.trackError(
    error,
    operation: "createVendor",
    attemptNumber: 1,
    wasRetried: false,
    outcome: .failed,
    context: ["vendor_id": vendorId]
)
```

**What Gets Sent to Sentry:**

- Error type and description
- Operation name
- Retry information
- Outcome classification
- Custom context data

### Error Outcomes

```swift
// Resolved: Error was retried successfully
.resolved → Sentry Level: .info

// Cached: Fallback to cached data worked
.cached → Sentry Level: .warning

// Failed: Error could not be recovered
.failed → Sentry Level: .error
```

### Prevention Dashboard Queries

In Sentry, you can create custom queries to monitor prevention metrics:

**High Retry Rate Alert:**
```
is:unresolved is_retryable:true attempt_number:>3
```

**Failed Non-Retryable Errors:**
```
is:unresolved outcome:failed is_retryable:false
```

**Cache Fallback Frequency:**
```
outcome:cached timeframe:24h
```

---

## SwiftUI Integration

### View Tracking

```swift
struct VendorListView: View {
    var body: some View {
        List {
            // ... vendor list
        }
        .trackView("VendorListView")
    }
}
```

### Performance Measurement

```swift
struct DashboardView: View {
    var body: some View {
        ScrollView {
            // ... dashboard content
        }
        .measureViewLoad("DashboardView")
    }
}
```

### User Context

```swift
// Set user context after authentication
SentryService.shared.setUser(
    userId: user.id,
    email: user.email,
    username: user.displayName
)

// Clear on logout
SentryService.shared.clearUser()
```

---

## Best Practices

### 1. Breadcrumb Strategy

**Navigation Tracking:**
```swift
SentryService.shared.trackNavigation(
    to: "VendorDetailView",
    metadata: ["vendor_id": vendor.id]
)
```

**User Actions:**
```swift
SentryService.shared.trackAction(
    "create_vendor",
    category: "vendors",
    metadata: ["category": vendor.category]
)
```

**Data Operations:**
```swift
SentryService.shared.trackDataOperation(
    "update",
    entity: "vendor",
    success: true,
    metadata: ["fields_changed": 3]
)
```

**Network Requests:**
```swift
SentryService.shared.trackNetworkRequest(
    url: endpoint.url,
    method: "POST",
    statusCode: 201,
    duration: 0.45
)
```

### 2. Context Enrichment

Always add relevant context to errors:

```swift
SentryService.shared.captureError(
    error,
    context: [
        "vendor_id": vendor.id,
        "vendor_category": vendor.category.rawValue,
        "user_action": "delete",
        "app_state": "foreground"
    ]
)
```

### 3. Performance Budgets

Monitor critical paths:

```swift
// Critical: Initial app launch
.measureViewLoad("RootFlowView")

// Important: Main navigation
.measureViewLoad("DashboardView")

// Track data loading
await SentryService.shared.measureAsync(
    name: "initial_data_load",
    operation: "app.startup"
) {
    await loadInitialData()
}
```

### 4. Sampling Strategy

**Development:**
- 100% transactions captured
- 100% profiles captured
- Debug mode enabled

**Production:**
- 10% transactions sampled
- 10% profiles sampled
- Debug mode disabled

### 5. Error Prevention Flow

```
1. Error occurs
   ↓
2. ErrorTracker captures locally
   ↓
3. Sentry receives error + context
   ↓
4. Analyze patterns in Sentry dashboard
   ↓
5. Identify prevention opportunities
   ↓
6. Implement fixes before widespread impact
```

---

## Common Patterns

### Pattern 1: Repository Error Handling

```swift
func createVendor(_ vendor: Vendor) async throws -> Vendor {
    do {
        return try await repository.create(vendor)
    } catch {
        // Track error with context
        await ErrorTracker.shared.trackError(
            error,
            operation: "createVendor",
            context: ["category": vendor.category.rawValue]
        )
        throw error
    }
}
```

### Pattern 2: View Load Monitoring

```swift
struct ExpensiveView: View {
    var body: some View {
        ComplexContent()
            .trackView("ExpensiveView")
            .measureViewLoad("ExpensiveView_Load")
    }
}
```

### Pattern 3: Transaction Spans

```swift
let transaction = SentryService.shared.startTransaction(
    name: "vendor_import",
    operation: "io.import"
)

// Child span for parsing
let parseSpan = transaction?.startChild(operation: "parse.csv")
let parsedData = parseCSV(data)
parseSpan?.finish()

// Child span for validation
let validateSpan = transaction?.startChild(operation: "validate")
try validateVendors(parsedData)
validateSpan?.finish()

// Child span for saving
let saveSpan = transaction?.startChild(operation: "data.save")
await saveVendors(parsedData)
saveSpan?.finish()

transaction?.finish()
```

---

## Troubleshooting

### Testing Integration

```swift
// Send test error
SentryService.shared.captureTestError()
```

Check Sentry dashboard within 1-2 minutes for the test error.

### Debug Logging

In development builds, Sentry debug logging is enabled. Check Xcode console for:

```
[Sentry] Starting with DSN: 'https://...'
[Sentry] Initialization successful
[Sentry] Breadcrumb captured: ...
[Sentry] Event captured: ...
```

### Common Issues

**Issue: DSN not found**
- Solution: Add `SENTRY_DSN` to Config.plist

**Issue: Events not appearing**
- Check internet connection
- Verify DSN is correct
- Check Sentry project settings
- Look for debug logs in console

**Issue: Too many events**
- Adjust sample rates in production
- Filter unnecessary breadcrumbs
- Use event fingerprinting for grouping

---

## Related Files

- [SentryService.swift](I Do Blueprint/Services/Analytics/SentryService.swift) - Main Sentry integration
- [ErrorTracker.swift](I Do Blueprint/Core/Common/Analytics/ErrorTracker.swift) - Prevention monitoring
- [My_Wedding_Planning_AppApp.swift](I Do Blueprint/App/My_Wedding_Planning_AppApp.swift) - App initialization
- [Config.plist](I Do Blueprint/Core/Config/Config.plist) - Configuration

---

## Resources

- [Sentry macOS Documentation](https://docs.sentry.io/platforms/apple/guides/macos/)
- [SwiftUI Integration](https://docs.sentry.io/platforms/apple/guides/ios/tracing/instrumentation/swiftui-instrumentation/)
- [Performance Monitoring](https://docs.sentry.io/platforms/apple/tracing/)
- [Error Tracking Best Practices](https://docs.sentry.io/product/issues/)
