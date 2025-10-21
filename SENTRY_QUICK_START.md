# Sentry Quick Start Guide

## ⚡ 5-Minute Setup

### 1. Get Your DSN (2 minutes)

1. Go to https://jelizica.sentry.io
2. Click **Settings** → **Projects** → **apple-macos**
3. Click **Client Keys (DSN)**
4. Copy the DSN (looks like: `https://abc123@o456.ingest.sentry.io/789`)

### 2. Add DSN to Config (1 minute)

Open `I Do Blueprint/Config.plist` and replace:

```xml
<key>SENTRY_DSN</key>
<string>YOUR_SENTRY_DSN_HERE</string>
```

With your actual DSN:

```xml
<key>SENTRY_DSN</key>
<string>https://abc123@o456.ingest.sentry.io/789</string>
```

### 3. Test It (2 minutes)

1. Build and run the app (⌘R)
2. Check console for: `"Sentry initialized successfully"` ✅
3. Add this code temporarily to any button:

```swift
SentryService.shared.captureTestError()
```

4. Click the button
5. Go to https://jelizica.sentry.io/issues/
6. See your test error appear! 🎉

## ✅ That's It!

Sentry is now tracking:
- ✅ Crashes
- ✅ Errors
- ✅ Performance issues

## 🚀 Optional Enhancements

### Add User Context (Recommended)

In your auth flow:

```swift
// After login
SentryService.shared.setUser(
    userId: user.id.uuidString,
    email: user.email
)

// On logout
SentryService.shared.clearUser()
```

### Track Navigation (Optional)

In your views:

```swift
.onAppear {
    SentryService.shared.addBreadcrumb(
        message: "Navigated to Budget",
        category: "navigation"
    )
}
```

### Enhanced Error Logging (Optional)

In your repositories:

```swift
catch {
    logger.repositoryError(
        operation: "fetchGuests",
        error: error
    )
    throw error
}
```

## 📚 More Info

- **Full Setup Guide**: `SENTRY_SETUP_GUIDE.md`
- **Code Examples**: `SENTRY_INTEGRATION_EXAMPLES.md`
- **Quick Reference**: `SENTRY_QUICK_REFERENCE.md`
- **Sentry Dashboard**: https://jelizica.sentry.io

## 🆘 Problems?

### Not Initializing?
- Check DSN is correct in Config.plist
- Clean build (⌘⇧K) and rebuild

### Errors Not Showing?
- Wait 1-2 minutes
- Check you're in the right Sentry project
- Verify network connection

---

**That's all you need to get started!** 🎉

The rest is optional enhancements you can add over time.
