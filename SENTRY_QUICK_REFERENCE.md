# Sentry Quick Reference Card

Quick reference for common Sentry operations in I Do Blueprint.

## 🚀 Initial Setup

```swift
// Already done in My_Wedding_Planning_AppApp.swift
init() {
    SentryService.shared.configure()
}
```

## 🔑 Configuration

**Location**: `I Do Blueprint/Config.plist`

```xml
<key>SENTRY_DSN</key>
<string>YOUR_SENTRY_DSN_HERE</string>
```

Get your DSN from: https://jelizica.sentry.io/settings/projects/apple-macos/keys/

---

## 📝 Common Operations

### Capture Error

```swift
// Simple error capture
SentryService.shared.captureError(error)

// With context
SentryService.shared.captureError(
    error,
    context: ["userId": userId, "operation": "createGuest"]
)
```

### Capture Message

```swift
SentryService.shared.captureMessage(
    "Something important happened",
    level: .info
)
```

### Using AppLogger (Recommended)

```swift
// Repository error
logger.repositoryError(
    operation: "fetchGuests",
    error: error,
    additionalContext: ["tenantId": tenantId]
)

// Network error
logger.networkError(
    endpoint: "/api/guests",
    error: error,
    statusCode: 500
)

// Parsing error
logger.parsingError(
    dataType: "Guest",
    error: error
)

// Generic error with Sentry
logger.errorWithSentry(
    "Operation failed",
    error: error,
    context: ["key": "value"]
)
```

---

## 👤 User Context

### Set User (on login)

```swift
SentryService.shared.setUser(
    userId: user.id.uuidString,
    email: user.email,
    username: user.fullName
)
```

### Clear User (on logout)

```swift
SentryService.shared.clearUser()
```

---

## 🍞 Breadcrumbs

### Navigation

```swift
SentryService.shared.addBreadcrumb(
    message: "Navigated to Budget",
    category: "navigation",
    level: .info
)
```

### User Action

```swift
SentryService.shared.addBreadcrumb(
    message: "User clicked Save button",
    category: "ui",
    level: .info,
    data: ["screen": "BudgetForm"]
)
```

### Data Operation

```swift
SentryService.shared.addBreadcrumb(
    message: "Loading budget data",
    category: "data",
    level: .info,
    data: ["categoriesCount": 5]
)
```

### Network Request

```swift
SentryService.shared.addBreadcrumb(
    message: "API request started",
    category: "network",
    level: .info,
    data: ["endpoint": "/api/guests"]
)
```

---

## ⚡ Performance Monitoring

### Track Operation

```swift
let transaction = SentryService.shared.startTransaction(
    name: "Load Dashboard Data",
    operation: "task"
)

// ... perform operation ...

transaction?.finish()
```

### Common Operations to Track

- Dashboard loading
- Data exports
- Complex calculations
- Batch operations
- File uploads/downloads

---

## 🎯 Error Severity Levels

```swift
.debug    // Development debugging
.info     // Informational messages
.warning  // Warning conditions
.error    // Error conditions (default)
.fatal    // Fatal errors
```

### Usage

```swift
SentryService.shared.captureError(error, level: .warning)
SentryService.shared.captureMessage("Info", level: .info)
```

---

## 📊 Where to Add Sentry

### ✅ Always Add

- [ ] Repository error handlers
- [ ] Network request failures
- [ ] Data parsing errors
- [ ] User authentication errors
- [ ] Critical business logic failures

### ✅ Consider Adding

- [ ] Navigation events (breadcrumbs)
- [ ] User actions (breadcrumbs)
- [ ] Performance tracking for slow operations
- [ ] Warning conditions

### ❌ Don't Add

- [ ] Expected errors (validation failures)
- [ ] Errors in tight loops
- [ ] Sensitive data (passwords, tokens, PII)
- [ ] Debug-only information

---

## 🔍 Testing

### Send Test Error

```swift
SentryService.shared.captureTestError()
```

### Verify in Console

Look for:
```
✅ Sentry initialized successfully
✅ Error captured with Sentry
```

### Check Dashboard

https://jelizica.sentry.io/issues/

---

## 🛠️ Common Patterns

### Repository Pattern

```swift
func fetchData() async throws -> [Data] {
    do {
        let data = try await client.fetch()
        return data
    } catch {
        logger.repositoryError(
            operation: "fetchData",
            error: error
        )
        throw error
    }
}
```

### Store Pattern

```swift
func loadData() async {
    SentryService.shared.addBreadcrumb(
        message: "Loading data",
        category: "data"
    )
    
    do {
        let data = try await repository.fetchData()
        self.data = data
    } catch {
        logger.errorWithSentry(
            "Failed to load data",
            error: error,
            context: ["store": "DataStore"]
        )
    }
}
```

### View Pattern

```swift
.onAppear {
    SentryService.shared.addBreadcrumb(
        message: "Navigated to Screen",
        category: "navigation"
    )
}
```

---

## 🚨 Troubleshooting

### Not Initializing?

1. Check Config.plist has `SENTRY_DSN` key
2. Verify DSN is not empty
3. Clean build (⌘⇧K) and rebuild

### Errors Not Appearing?

1. Check console for "Sentry initialized successfully"
2. Verify DSN is correct
3. Wait 1-2 minutes
4. Check correct project in Sentry dashboard

### Too Many Logs?

```swift
// In SentryService.swift, change:
options.debug = false
```

---

## 📚 Quick Links

- **Dashboard**: https://jelizica.sentry.io/
- **Issues**: https://jelizica.sentry.io/issues/
- **Performance**: https://jelizica.sentry.io/performance/
- **Settings**: https://jelizica.sentry.io/settings/projects/apple-macos/
- **Docs**: https://docs.sentry.io/platforms/apple/guides/macos/

---

## 💡 Pro Tips

1. **Use AppLogger extensions** instead of calling SentryService directly
2. **Add breadcrumbs liberally** - they help debug issues
3. **Set user context** as soon as user logs in
4. **Track performance** of operations that feel slow
5. **Don't log sensitive data** - ever!
6. **Test in development** before deploying to production
7. **Review errors weekly** to catch patterns
8. **Set up alerts** for critical errors in Sentry

---

## 📞 Support

- **Setup Guide**: `SENTRY_SETUP_GUIDE.md`
- **Examples**: `SENTRY_INTEGRATION_EXAMPLES.md`
- **Sentry Support**: https://sentry.zendesk.com/

---

**Last Updated**: January 2025  
**Version**: 1.0
