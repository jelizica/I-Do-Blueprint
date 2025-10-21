# Sentry Setup Guide for I Do Blueprint

This guide will help you complete the Sentry integration for error tracking and performance monitoring in your macOS wedding planning app.

## 📋 Overview

Sentry has been integrated into the project with the following components:

1. **SentryService** - Core service for error tracking and performance monitoring
2. **AppLogger+Sentry Extension** - Seamless integration with existing logging
3. **Configuration** - DSN stored in Config.plist
4. **Initialization** - Automatic startup in app entry point

## 🚀 Setup Steps

### Step 1: Get Your Sentry DSN

1. Log in to your Sentry account at https://jelizica.sentry.io
2. Navigate to your **apple-macos** project
3. Go to **Settings** → **Projects** → **apple-macos** → **Client Keys (DSN)**
4. Copy your DSN (it looks like: `https://[key]@o[org].ingest.sentry.io/[project]`)

### Step 2: Add DSN to Config.plist

1. Open `I Do Blueprint/Config.plist`
2. Replace `YOUR_SENTRY_DSN_HERE` with your actual Sentry DSN:

```xml
<key>SENTRY_DSN</key>
<string>https://your-actual-dsn@o0.ingest.sentry.io/0</string>
```

### Step 3: Verify the Package is Added

Since you mentioned you've already added the Sentry package to Xcode:

1. Open your project in Xcode
2. Go to **File** → **Packages** → **Resolve Package Versions**
3. Verify `sentry-cocoa` appears in the package dependencies
4. If not, add it via **File** → **Add Packages** using: `https://github.com/getsentry/sentry-cocoa.git`

### Step 4: Build and Test

1. Build the project (⌘B)
2. Run the app (⌘R)
3. Check the console for: `"Sentry initialized successfully"`

### Step 5: Send a Test Error

To verify Sentry is working, you can send a test error in two ways:

#### Option A: Using the Test Method

Add this code temporarily to any view or button action:

```swift
SentryService.shared.captureTestError()
```

#### Option B: Trigger a Real Error

Add this code to trigger an intentional error:

```swift
do {
    throw NSError(
        domain: "com.idoblueprint.test",
        code: 999,
        userInfo: [NSLocalizedDescriptionKey: "Test error for Sentry"]
    )
} catch {
    SentryService.shared.captureError(error)
}
```

### Step 6: Verify in Sentry Dashboard

1. Go to https://jelizica.sentry.io/issues/
2. You should see your test error appear within a few seconds
3. Click on it to see the full stack trace and context

## 📚 Usage Guide

### Basic Error Capture

```swift
// Capture any error
do {
    try await someOperation()
} catch {
    SentryService.shared.captureError(error)
}

// Capture with additional context
SentryService.shared.captureError(
    error,
    context: [
        "userId": userId,
        "operation": "createGuest"
    ]
)
```

### Using AppLogger Integration

The easiest way to use Sentry is through the AppLogger extensions:

```swift
// In your repositories
do {
    let guests = try await fetchGuests()
    return guests
} catch {
    // This logs AND sends to Sentry
    logger.repositoryError(
        operation: "fetchGuests",
        error: error,
        additionalContext: ["coupleId": coupleId]
    )
    throw error
}

// For network errors
logger.networkError(
    endpoint: "/api/guests",
    error: error,
    statusCode: 500
)

// For parsing errors
logger.parsingError(
    dataType: "Guest",
    error: error
)
```

### User Context

Set user context when a user logs in:

```swift
// After successful authentication
SentryService.shared.setUser(
    userId: user.id.uuidString,
    email: user.email,
    username: user.fullName
)

// Clear on logout
SentryService.shared.clearUser()
```

### Breadcrumbs

Add breadcrumbs for debugging context:

```swift
SentryService.shared.addBreadcrumb(
    message: "User navigated to Budget screen",
    category: "navigation",
    level: .info
)

SentryService.shared.addBreadcrumb(
    message: "Creating new expense",
    category: "ui",
    level: .info,
    data: ["categoryId": categoryId]
)
```

### Performance Monitoring

Track performance of critical operations:

```swift
let transaction = SentryService.shared.startTransaction(
    name: "Load Budget Data",
    operation: "task"
)

// Perform your operation
await loadBudgetData()

// Finish the transaction
transaction?.finish()
```

## 🎯 Best Practices

### 1. Use AppLogger Extensions

Instead of calling SentryService directly, use the AppLogger extensions:

```swift
// ✅ Good - Uses AppLogger + Sentry
logger.repositoryError(operation: "fetchGuests", error: error)

// ❌ Less ideal - Direct Sentry call
SentryService.shared.captureError(error)
```

### 2. Add Context to Errors

Always provide context to help debug issues:

```swift
logger.errorWithSentry(
    "Failed to create expense",
    error: error,
    context: [
        "categoryId": category.id.uuidString,
        "amount": expense.amount,
        "vendorId": expense.vendorId?.uuidString ?? "none"
    ]
)
```

### 3. Set User Context

Set user context after authentication:

```swift
// In your AuthContext or SessionManager
func handleSuccessfulLogin(user: User) {
    SentryService.shared.setUser(
        userId: user.id.uuidString,
        email: user.email
    )
}

func handleLogout() {
    SentryService.shared.clearUser()
}
```

### 4. Use Breadcrumbs for User Flow

Add breadcrumbs for important user actions:

```swift
// In navigation
SentryService.shared.addBreadcrumb(
    message: "Navigated to \(screen)",
    category: "navigation"
)

// Before critical operations
SentryService.shared.addBreadcrumb(
    message: "Starting budget calculation",
    category: "task",
    data: ["totalCategories": categories.count]
)
```

### 5. Don't Log Sensitive Data

Never send sensitive information to Sentry:

```swift
// ❌ Bad - Contains sensitive data
logger.errorWithSentry(
    "Payment failed",
    error: error,
    context: ["creditCard": cardNumber] // Don't do this!
)

// ✅ Good - No sensitive data
logger.errorWithSentry(
    "Payment failed",
    error: error,
    context: ["paymentMethod": "card", "last4": last4Digits]
)
```

## 🔧 Configuration Options

The SentryService is configured in `SentryService.swift`. Key settings:

### Debug Mode
- **Development**: `debug = true` (verbose logging)
- **Production**: `debug = false`

### Sample Rates
- **Traces (Development)**: 100% of transactions
- **Traces (Production)**: 10% of transactions
- **Profiles**: 100% of transactions

### Features Enabled
- ✅ Uncaught NSException reporting (macOS specific)
- ✅ Automatic breadcrumb tracking
- ✅ Automatic session tracking
- ✅ Stack trace attachment
- ✅ Performance monitoring

## 📊 Monitoring in Sentry

### Issues Dashboard
- View all errors at: https://jelizica.sentry.io/issues/
- Filter by environment (development/production)
- See error frequency, affected users, and stack traces

### Performance Dashboard
- View performance metrics at: https://jelizica.sentry.io/performance/
- Track slow operations and bottlenecks
- Monitor transaction durations

### Releases
- Track errors by app version
- See which version introduced issues
- Monitor adoption of new releases

## 🐛 Troubleshooting

### Sentry Not Initializing

**Problem**: Console shows "Sentry DSN not found in Config.plist"

**Solution**: 
1. Verify `SENTRY_DSN` key exists in Config.plist
2. Ensure the DSN value is not empty
3. Clean build folder (⌘⇧K) and rebuild

### Errors Not Appearing in Dashboard

**Problem**: Test errors don't show up in Sentry

**Solution**:
1. Check console for "Sentry initialized successfully"
2. Verify DSN is correct
3. Check network connectivity
4. Wait 1-2 minutes (Sentry has slight delay)
5. Verify you're looking at the correct project in Sentry

### Build Errors

**Problem**: "Cannot find 'SentrySDK' in scope"

**Solution**:
1. Verify Sentry package is added to Xcode
2. Go to **File** → **Packages** → **Resolve Package Versions**
3. Clean build folder and rebuild
4. Restart Xcode if needed

### Debug Mode Too Verbose

**Problem**: Too many Sentry logs in console

**Solution**: The service automatically disables debug mode in production builds. For development, you can temporarily disable it in `SentryService.swift`:

```swift
options.debug = false // Change to false
```

## 🔐 Security Notes

1. **DSN is Public**: The Sentry DSN is safe to include in your app - it's designed to be public
2. **Rate Limiting**: Sentry automatically rate-limits events to prevent abuse
3. **Data Scrubbing**: Sentry automatically scrubs sensitive data patterns
4. **PII**: The service does NOT send PII by default (sendDefaultPii = false)

## 📝 Next Steps

1. ✅ Complete the setup steps above
2. ✅ Send a test error to verify integration
3. ✅ Add user context setting to your auth flow
4. ✅ Review existing error handling in repositories
5. ✅ Consider adding breadcrumbs to key user flows
6. ✅ Set up Sentry alerts for critical errors
7. ✅ Configure release tracking in Sentry

## 📖 Additional Resources

- [Sentry macOS Documentation](https://docs.sentry.io/platforms/apple/guides/macos/)
- [Sentry Swift SDK GitHub](https://github.com/getsentry/sentry-cocoa)
- [Sentry Best Practices](https://docs.sentry.io/platforms/apple/best-practices/)
- [Performance Monitoring Guide](https://docs.sentry.io/platforms/apple/performance/)

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Sentry logs in Xcode console
3. Check Sentry status page: https://status.sentry.io/
4. Contact Sentry support: https://sentry.zendesk.com/

---

**Last Updated**: January 2025  
**Sentry SDK Version**: Latest (via SPM)  
**Platform**: macOS 13.0+
