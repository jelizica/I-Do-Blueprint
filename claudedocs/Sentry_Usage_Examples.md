# Sentry Usage Examples

Quick copy-paste examples for common Sentry usage patterns in I Do Blueprint.

## 🎯 View Tracking

### Basic View Tracking
```swift
struct VendorListView: View {
    var body: some View {
        List {
            // content
        }
        .trackView("VendorListView")
    }
}
```

### View with Performance Monitoring
```swift
struct DashboardView: View {
    var body: some View {
        ScrollView {
            // expensive content
        }
        .trackView("DashboardView")
        .measureViewLoad("DashboardView")
    }
}
```

## 🔧 Repository Error Tracking

### Standard Repository Pattern
```swift
func createVendor(_ vendor: Vendor) async throws -> Vendor {
    do {
        let created = try await repository.create(vendor)

        // Track success
        SentryService.shared.trackDataOperation(
            "create",
            entity: "vendor",
            success: true,
            metadata: ["category": vendor.category.rawValue]
        )

        return created
    } catch {
        // Automatic Sentry reporting via ErrorTracker
        await ErrorTracker.shared.trackError(
            error,
            operation: "createVendor",
            context: [
                "category": vendor.category.rawValue,
                "payment_status": vendor.paymentStatus.rawValue
            ]
        )
        throw error
    }
}
```

### With Retry Logic
```swift
func fetchVendors() async throws -> [Vendor] {
    var lastError: Error?

    for attempt in 1...3 {
        do {
            let vendors = try await repository.fetchAll()

            if attempt > 1 {
                // Track successful retry
                await ErrorTracker.shared.trackRetrySuccess(
                    lastError!,
                    operation: "fetchVendors",
                    attemptNumber: attempt
                )
            }

            return vendors
        } catch {
            lastError = error
            await ErrorTracker.shared.trackError(
                error,
                operation: "fetchVendors",
                attemptNumber: attempt,
                wasRetried: attempt < 3,
                outcome: attempt < 3 ? .failed : .failed
            )

            if attempt < 3 {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
            }
        }
    }

    throw lastError!
}
```

## 📊 Performance Monitoring

### Simple Transaction
```swift
func loadDashboardData() async {
    let transaction = SentryService.shared.startTransaction(
        name: "load_dashboard",
        operation: "ui.load"
    )

    // Load data
    await loadVendors()
    await loadTasks()
    await loadBudget()

    SentryService.shared.finishTransaction(
        name: "load_dashboard",
        status: .ok
    )
}
```

### Auto-Measured Operation
```swift
let result = await SentryService.shared.measureAsync(
    name: "calculate_budget_summary",
    operation: "compute"
) {
    return await budgetStore.calculateSummary()
}
```

### Complex Transaction with Spans
```swift
func importVendorsFromCSV(_ url: URL) async throws {
    let transaction = SentryService.shared.startTransaction(
        name: "vendor_csv_import",
        operation: "io.import"
    )

    // Parse CSV
    let parseSpan = transaction?.startChild(operation: "parse.csv")
    let csvData = try parseCSV(url)
    parseSpan?.finish()

    // Validate data
    let validateSpan = transaction?.startChild(operation: "validate")
    let validVendors = try validateVendorData(csvData)
    validateSpan?.finish()

    // Save to database
    let saveSpan = transaction?.startChild(operation: "db.save")
    try await saveVendors(validVendors)
    saveSpan?.finish()

    transaction?.finish()

    SentryService.shared.captureMessage(
        "CSV import completed",
        context: [
            "total_rows": csvData.count,
            "valid_vendors": validVendors.count,
            "skipped": csvData.count - validVendors.count
        ],
        level: .info
    )
}
```

## 🔍 User Actions & Breadcrumbs

### Button Tap
```swift
Button("Delete Vendor") {
    SentryService.shared.trackAction(
        "delete_vendor",
        category: "vendors",
        metadata: [
            "vendor_id": vendor.id,
            "category": vendor.category.rawValue
        ]
    )

    deleteVendor()
}
```

### Form Submission
```swift
func submitVendorForm() async {
    SentryService.shared.trackAction(
        "submit_vendor_form",
        category: "vendors",
        metadata: [
            "is_new": isNewVendor,
            "has_payment_schedule": vendor.paymentSchedule != nil
        ]
    )

    do {
        try await saveVendor()
    } catch {
        SentryService.shared.captureError(error)
    }
}
```

### Navigation
```swift
NavigationLink(destination: VendorDetailView(vendor: vendor)) {
    VendorRow(vendor: vendor)
}
.onTapGesture {
    SentryService.shared.trackNavigation(
        to: "VendorDetailView",
        metadata: ["vendor_id": vendor.id]
    )
}
```

## 🌐 Network Tracking

### Manual Network Tracking
```swift
func makeAPIRequest() async throws -> Response {
    let startTime = Date()

    do {
        let response = try await URLSession.shared.data(from: url)
        let duration = Date().timeIntervalSince(startTime)

        SentryService.shared.trackNetworkRequest(
            url: url.absoluteString,
            method: "GET",
            statusCode: (response.1 as? HTTPURLResponse)?.statusCode,
            duration: duration
        )

        return response
    } catch {
        let duration = Date().timeIntervalSince(startTime)

        SentryService.shared.trackNetworkRequest(
            url: url.absoluteString,
            method: "GET",
            statusCode: nil,
            duration: duration
        )

        throw error
    }
}
```

## 👤 User Context

### Set After Login
```swift
func handleSuccessfulLogin(_ user: User) {
    SentryService.shared.setUser(
        userId: user.id,
        email: user.email,
        username: user.displayName
    )

    SentryService.shared.captureMessage(
        "User logged in",
        context: [
            "login_method": "email",
            "is_first_login": user.isFirstLogin
        ],
        level: .info
    )
}
```

### Clear on Logout
```swift
func handleLogout() {
    SentryService.shared.clearUser()

    SentryService.shared.captureMessage(
        "User logged out",
        level: .info
    )
}
```

## 🎨 Custom Error Context

### Enriched Error Reporting
```swift
func processPayment(_ payment: Payment) async throws {
    do {
        try await paymentService.process(payment)
    } catch {
        SentryService.shared.captureError(
            error,
            context: [
                "payment_id": payment.id,
                "amount": payment.amount,
                "vendor_id": payment.vendorId,
                "payment_method": payment.method.rawValue,
                "due_date": payment.dueDate.ISO8601Format(),
                "is_overdue": payment.isOverdue,
                "retry_count": payment.retryCount
            ],
            level: .error
        )
        throw error
    }
}
```

## 📱 App State Tracking

### Background/Foreground Transitions
```swift
class AppStateManager: ObservableObject {
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc func appDidEnterBackground() {
        SentryService.shared.addBreadcrumb(
            message: "App entered background",
            category: "app.lifecycle",
            level: .info
        )
    }

    @objc func appDidBecomeActive() {
        SentryService.shared.addBreadcrumb(
            message: "App became active",
            category: "app.lifecycle",
            level: .info
        )
    }
}
```

## 🧪 Testing

### Send Test Error
```swift
// In developer settings or debug menu
Button("Test Sentry") {
    SentryService.shared.captureTestError()
}
```

### Custom Test Scenario
```swift
func testSentryIntegration() {
    // Simulate error
    let testError = NSError(
        domain: "com.idoblueprint.test",
        code: 500,
        userInfo: [
            NSLocalizedDescriptionKey: "Test error for Sentry verification"
        ]
    )

    SentryService.shared.captureError(
        testError,
        context: [
            "test_type": "integration_test",
            "timestamp": Date().ISO8601Format(),
            "environment": "development"
        ],
        level: .warning
    )
}
```

## 🎯 Prevention Monitoring Patterns

### Track Error Patterns
```swift
// ErrorTracker automatically sends to Sentry for pattern analysis
Task {
    await ErrorTracker.shared.trackError(
        error,
        operation: "syncToCloud",
        attemptNumber: retryCount,
        wasRetried: retryCount > 1,
        outcome: retryCount < maxRetries ? .failed : .failed,
        context: [
            "sync_type": "full",
            "data_size": "\(dataSize)",
            "network_type": "wifi"
        ]
    )
}
```

### Cache Fallback Tracking
```swift
do {
    return try await fetchFromNetwork()
} catch {
    await ErrorTracker.shared.trackCacheFallback(
        error,
        operation: "fetchVendors"
    )
    return fetchFromCache()
}
```

## 📊 Query Examples for Sentry Dashboard

### Custom Queries

**High Error Rate Alert:**
```
is:unresolved error.type:NetworkError timeframe:1h count:>10
```

**Slow Operations:**
```
transaction.duration:>3s transaction.op:ui.load
```

**Failed Retry Attempts:**
```
is_retryable:true outcome:failed attempt_number:>2
```

**Cache Dependency:**
```
outcome:cached timeframe:24h
```

---

See [Sentry_Integration_Guide.md](Sentry_Integration_Guide.md) for complete documentation.
