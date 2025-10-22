# Sentry Quick Reference Card

Quick copy-paste snippets for common Sentry operations.

## 🚀 Quick Start

```swift
// Already initialized in App init()
// Just start using SentryService.shared
```

## 📝 Common Operations

### Track Error
```swift
SentryService.shared.captureError(error)
```

### Track Error with Context
```swift
SentryService.shared.captureError(
    error,
    context: ["operation": "fetchVendors", "count": 42]
)
```

### Track View
```swift
.trackView("VendorListView")
```

### Measure Performance
```swift
.measureViewLoad("DashboardView")
```

### Track User Action
```swift
SentryService.shared.trackAction(
    "create_vendor",
    category: "vendors"
)
```

### Measure Code Block
```swift
await SentryService.shared.measureAsync(
    name: "load_data",
    operation: "data.fetch"
) {
    return await fetchData()
}
```

## 🎯 ErrorTracker Integration

### Track Error (Auto-sends to Sentry)
```swift
await ErrorTracker.shared.trackError(
    error,
    operation: "createVendor",
    context: ["vendor_id": id]
)
```

### Track Retry Success
```swift
await ErrorTracker.shared.trackRetrySuccess(
    error,
    operation: "fetchData",
    attemptNumber: 2
)
```

### Track Cache Fallback
```swift
await ErrorTracker.shared.trackCacheFallback(
    error,
    operation: "fetchVendors"
)
```

## 📊 Performance Monitoring

### Start/Finish Transaction
```swift
// Start
SentryService.shared.startTransaction(
    name: "load_dashboard",
    operation: "ui.load"
)

// Finish
SentryService.shared.finishTransaction(
    name: "load_dashboard",
    status: .ok
)
```

### Auto-Measure
```swift
let result = await SentryService.shared.measureAsync(
    name: "operation_name",
    operation: "type"
) {
    // your async code
}
```

## 🔍 Breadcrumbs

### Navigation
```swift
SentryService.shared.trackNavigation(
    to: "ViewName",
    metadata: ["id": "123"]
)
```

### Data Operation
```swift
SentryService.shared.trackDataOperation(
    "create",
    entity: "vendor",
    success: true
)
```

### Network Request
```swift
SentryService.shared.trackNetworkRequest(
    url: url.string,
    method: "POST",
    statusCode: 201,
    duration: 0.5
)
```

## 👤 User Context

### Set User
```swift
SentryService.shared.setUser(
    userId: user.id,
    email: user.email,
    username: user.name
)
```

### Clear User
```swift
SentryService.shared.clearUser()
```

## 🧪 Testing

```swift
SentryService.shared.captureTestError()
```

## 📱 SwiftUI Modifiers

### Track + Measure
```swift
MyView()
    .trackView("MyView")
    .measureViewLoad("MyView")
```

## ⚠️ Error Levels

```swift
.info     // Information
.warning  // Warnings
.error    // Errors (default)
.fatal    // Critical failures
```

## 🎯 Transaction Operations

```swift
"ui.load"       // View loading
"ui.action"     // User action
"data.fetch"    // Data fetching
"data.save"     // Data saving
"compute"       // Calculations
"io.import"     // Import operations
"io.export"     // Export operations
"network"       // Network calls
```

## 📚 Full Documentation

- [Sentry_Integration_Guide.md](Sentry_Integration_Guide.md) - Complete guide
- [Sentry_Usage_Examples.md](Sentry_Usage_Examples.md) - Copy-paste examples
- [SentryService.swift](I Do Blueprint/Services/Analytics/SentryService.swift) - Implementation
