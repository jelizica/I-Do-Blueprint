# 🧪 Sentry Test Instructions

## ✅ You're Ready to Test!

Your Sentry integration is complete and the app builds successfully. Here's how to verify it's working:

## Step 1: Run the App

1. Open the project in Xcode
2. Press **⌘R** to run the app
3. Log in to your account

## Step 2: Check Console for Initialization

Look for this message in the Xcode console:

```
✅ Sentry initialized successfully
```

If you see this, Sentry is configured correctly! 🎉

## Step 3: Send a Test Error

1. Navigate to the **Dashboard** view
2. You'll see a blue button at the top: **"Test Sentry Integration"**
3. Click the button
4. You'll see an alert confirming the test was sent

## Step 4: Verify in Sentry Dashboard

1. Open your browser and go to: https://jelizica.sentry.io/issues/
2. Wait 1-2 minutes for the error to appear
3. You should see a new issue: **"This is a test error to verify Sentry integration"**
4. Click on it to see:
   - Full stack trace
   - Breadcrumb showing you clicked the test button
   - Device and environment information
   - Timestamp and context

## Step 5: Remove the Test Button (After Verification)

Once you've confirmed Sentry is working, remove the test button:

1. Open `DashboardViewV2.swift`
2. Find and delete these lines:

```swift
// TEMPORARY: Sentry Test Button - Remove after verification
SentryTestButton()
    .padding(.top)
```

3. Delete the file: `Views/Shared/SentryTestButton.swift`

## 🎯 What's Happening Behind the Scenes

When you click the test button:

1. **Error Capture**: A test NSError is sent to Sentry
2. **Breadcrumb**: A breadcrumb is added showing the button click
3. **Context**: Additional context (timestamp, test flag) is attached
4. **Logging**: The event is logged to console
5. **Sentry Upload**: The error is sent to Sentry's servers

## 📊 What You'll See in Sentry

### Issue Details
- **Title**: "This is a test error to verify Sentry integration"
- **Level**: Warning (yellow)
- **Environment**: development
- **Platform**: macOS

### Stack Trace
- Full Swift stack trace showing where the error was captured
- File names and line numbers

### Breadcrumbs
- "User clicked Sentry test button" with timestamp
- Any navigation events before the error

### Context
- App name: "I Do Blueprint"
- Platform: macOS
- Device model and OS version
- Test flag: true
- Timestamp

## ✅ Success Checklist

- [ ] App runs without errors
- [ ] Console shows "Sentry initialized successfully"
- [ ] Test button appears on dashboard
- [ ] Clicking button shows success alert
- [ ] Error appears in Sentry dashboard within 2 minutes
- [ ] Error details show full context and breadcrumbs

## 🚀 Next Steps (Optional)

### 1. Add User Context

In your authentication flow (e.g., `SessionManager.swift` or `AuthContext.swift`):

```swift
// After successful login
SentryService.shared.setUser(
    userId: user.id.uuidString,
    email: user.email,
    username: "\(user.firstName) \(user.lastName)"
)

// On logout
SentryService.shared.clearUser()
```

### 2. Enhance Repository Error Handling

Update your repository error handlers to use Sentry:

```swift
// Before
catch {
    logger.error("Failed to fetch guests", error: error)
    throw error
}

// After
catch {
    logger.repositoryError(
        operation: "fetchGuests",
        error: error,
        additionalContext: ["tenantId": tenantId.uuidString]
    )
    throw error
}
```

### 3. Add Navigation Breadcrumbs

Track user navigation for better debugging:

```swift
.onAppear {
    SentryService.shared.addBreadcrumb(
        message: "Navigated to Budget",
        category: "navigation"
    )
}
```

### 4. Set Up Sentry Alerts

1. Go to https://jelizica.sentry.io/alerts/
2. Create alert rules for:
   - New issues
   - High-frequency errors
   - Performance degradation

## 🐛 Troubleshooting

### Console Shows "Sentry DSN not found"

**Problem**: DSN not configured correctly

**Solution**:
1. Open `Config.plist`
2. Verify `SENTRY_DSN` key exists
3. Ensure value is your actual DSN (not placeholder)
4. Clean build (⌘⇧K) and rebuild

### Test Button Doesn't Appear

**Problem**: Dashboard view not loading test button

**Solution**:
1. Verify `SentryTestButton.swift` exists in `Views/Shared/`
2. Check it's added to the Xcode target
3. Clean build and rebuild

### Error Doesn't Appear in Sentry

**Problem**: Network or configuration issue

**Solution**:
1. Wait 2-3 minutes (Sentry has delay)
2. Check network connectivity
3. Verify DSN is correct
4. Check console for Sentry error messages
5. Try sending another test error

### Build Errors

**Problem**: Compilation issues

**Solution**:
1. Clean build folder (⌘⇧K)
2. File → Packages → Resolve Package Versions
3. Restart Xcode
4. Verify Sentry package is installed

## 📚 Documentation

For more information, see:

- **SENTRY_SETUP_GUIDE.md** - Complete setup guide
- **SENTRY_INTEGRATION_EXAMPLES.md** - Code examples
- **SENTRY_QUICK_REFERENCE.md** - Quick reference
- **SENTRY_IMPLEMENTATION_SUMMARY.md** - Architecture details

## 🎉 You're All Set!

Once you see the test error in Sentry, your integration is complete and working perfectly. Sentry will now automatically capture:

- ✅ Crashes
- ✅ Uncaught exceptions
- ✅ Errors you explicitly capture
- ✅ Performance metrics (when you add transactions)
- ✅ User context (when you set it)
- ✅ Breadcrumbs (when you add them)

Happy debugging! 🐛🔍

---

**Need Help?**
- Check the troubleshooting section above
- Review the documentation files
- Check Sentry status: https://status.sentry.io/
