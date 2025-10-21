# Sentry Integration Examples

This document shows practical examples of how to integrate Sentry error tracking into your existing code.

## 📝 Table of Contents

1. [Repository Error Handling](#repository-error-handling)
2. [Store Error Handling](#store-error-handling)
3. [User Context Management](#user-context-management)
4. [Breadcrumb Tracking](#breadcrumb-tracking)
5. [Performance Monitoring](#performance-monitoring)

---

## Repository Error Handling

### Example: Enhanced Guest Repository

Here's how to add Sentry tracking to your existing repository error handling:

```swift
// In LiveGuestRepository.swift

func fetchGuests() async throws -> [Guest] {
    let client = try getClient()
    let tenantId = try await getTenantId()
    let cacheKey = "guests_\(tenantId.uuidString)"
    let startTime = Date()

    // Check cache first
    if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
        logger.info("Cache hit: guests (\(cached.count) items)")
        return cached
    }

    logger.info("Cache miss: fetching guests from database")

    do {
        let guests: [Guest] = try await RepositoryNetwork.withRetry {
            try await client
                .from("guest_list")
                .select()
                .eq("couple_id", value: tenantId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
        }

        let duration = Date().timeIntervalSince(startTime)
        await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
        await PerformanceMonitor.shared.recordOperation("fetchGuests", duration: duration)

        logger.info("Fetched \(guests.count) guests in \(String(format: "%.2f", duration))s")
        AnalyticsService.trackNetwork(operation: "fetchGuests", outcome: .success, duration: duration)

        return guests
    } catch {
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("fetchGuests", duration: duration)
        
        // ✅ ADD THIS: Enhanced error logging with Sentry
        logger.repositoryError(
            operation: "fetchGuests",
            error: error,
            additionalContext: [
                "tenantId": tenantId.uuidString,
                "duration": duration,
                "cacheKey": cacheKey
            ]
        )
        
        AnalyticsService.trackNetwork(operation: "fetchGuests", outcome: .failure(code: nil), duration: duration)
        throw error
    }
}
```

### Example: Create Operation with Context

```swift
func createGuest(_ guest: Guest) async throws -> Guest {
    let client = try getClient()
    let tenantId = try await getTenantId()
    let startTime = Date()

    do {
        let created: Guest = try await RepositoryNetwork.withRetry {
            try await client
                .from("guest_list")
                .insert(guest)
                .select()
                .single()
                .execute()
                .value
        }

        await RepositoryCache.shared.remove("guests_\(tenantId.uuidString)")
        await RepositoryCache.shared.remove("guest_stats_\(tenantId.uuidString)")

        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("createGuest", duration: duration)
        
        logger.info("Created guest in \(String(format: "%.2f", duration))s")
        AnalyticsService.trackNetwork(operation: "createGuest", outcome: .success, duration: duration)

        return created
    } catch {
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("createGuest", duration: duration)
        
        // ✅ ADD THIS: Detailed error context for debugging
        logger.repositoryError(
            operation: "createGuest",
            error: error,
            additionalContext: [
                "tenantId": tenantId.uuidString,
                "guestName": guest.fullName,
                "rsvpStatus": guest.rsvpStatus.rawValue,
                "duration": duration
            ]
        )
        
        AnalyticsService.trackNetwork(operation: "createGuest", outcome: .failure(code: nil), duration: duration)
        throw error
    }
}
```

---

## Store Error Handling

### Example: Budget Store with Sentry

```swift
// In BudgetStoreV2.swift

@MainActor
class BudgetStoreV2: ObservableObject {
    @Dependency(\.budgetRepository) var repository
    @Published var loadingState: LoadingState<BudgetData> = .idle
    
    private let logger = AppLogger.budget
    
    func loadBudgetData() async {
        loadingState = .loading
        
        // Add breadcrumb for user flow tracking
        SentryService.shared.addBreadcrumb(
            message: "Loading budget data",
            category: "data",
            level: .info
        )
        
        do {
            async let summary = repository.fetchBudgetSummary()
            async let categories = repository.fetchCategories()
            async let expenses = repository.fetchExpenses()
            
            let summaryResult = try await summary
            let categoriesResult = try await categories
            let expensesResult = try await expenses
            
            let budgetData = BudgetData(
                summary: summaryResult,
                categories: categoriesResult,
                expenses: expensesResult
            )
            
            loadingState = .loaded(budgetData)
            logger.info("Budget data loaded successfully")
            
            // Add success breadcrumb
            SentryService.shared.addBreadcrumb(
                message: "Budget data loaded",
                category: "data",
                level: .info,
                data: [
                    "categoriesCount": categoriesResult.count,
                    "expensesCount": expensesResult.count
                ]
            )
            
        } catch {
            loadingState = .error(error)
            
            // ✅ ADD THIS: Log error with Sentry
            logger.errorWithSentry(
                "Failed to load budget data",
                error: error,
                context: [
                    "operation": "loadBudgetData",
                    "store": "BudgetStoreV2"
                ]
            )
        }
    }
    
    func addCategory(_ category: BudgetCategory) async {
        guard case .loaded(var budgetData) = loadingState else { return }
        
        // Add breadcrumb for user action
        SentryService.shared.addBreadcrumb(
            message: "Adding budget category",
            category: "ui",
            level: .info,
            data: ["categoryName": category.categoryName]
        )
        
        do {
            let created = try await repository.createCategory(category)
            budgetData.categories.append(created)
            loadingState = .loaded(budgetData)
            
            logger.info("Added category: \(created.categoryName)")
            
        } catch {
            // ✅ ADD THIS: Capture error with context
            logger.errorWithSentry(
                "Failed to add category",
                error: error,
                context: [
                    "categoryName": category.categoryName,
                    "budgetAmount": category.budgetAmount,
                    "operation": "addCategory"
                ]
            )
            
            loadingState = .error(error)
        }
    }
}
```

---

## User Context Management

### Example: Set User Context on Login

```swift
// In AuthContext.swift or SessionManager.swift

func handleSuccessfulLogin(user: User, couple: Couple) async {
    // Set session data
    self.currentUser = user
    self.currentCouple = couple
    
    // ✅ ADD THIS: Set Sentry user context
    SentryService.shared.setUser(
        userId: user.id.uuidString,
        email: user.email,
        username: "\(user.firstName) \(user.lastName)"
    )
    
    // Add breadcrumb for login event
    SentryService.shared.addBreadcrumb(
        message: "User logged in",
        category: "auth",
        level: .info,
        data: [
            "userId": user.id.uuidString,
            "coupleId": couple.id.uuidString
        ]
    )
    
    logger.info("User logged in successfully")
}

func logout() async {
    // Clear session data
    self.currentUser = nil
    self.currentCouple = nil
    
    // ✅ ADD THIS: Clear Sentry user context
    SentryService.shared.clearUser()
    
    // Add breadcrumb for logout event
    SentryService.shared.addBreadcrumb(
        message: "User logged out",
        category: "auth",
        level: .info
    )
    
    logger.info("User logged out")
}
```

---

## Breadcrumb Tracking

### Example: Navigation Breadcrumbs

```swift
// In your navigation views or coordinators

struct DashboardView: View {
    var body: some View {
        VStack {
            // Your dashboard content
        }
        .onAppear {
            // ✅ ADD THIS: Track navigation
            SentryService.shared.addBreadcrumb(
                message: "Navigated to Dashboard",
                category: "navigation",
                level: .info
            )
        }
    }
}

struct BudgetView: View {
    var body: some View {
        VStack {
            // Your budget content
        }
        .onAppear {
            // ✅ ADD THIS: Track navigation with data
            SentryService.shared.addBreadcrumb(
                message: "Navigated to Budget",
                category: "navigation",
                level: .info,
                data: ["source": "dashboard"]
            )
        }
    }
}
```

### Example: User Action Breadcrumbs

```swift
// In your view models or stores

func deleteExpense(_ expense: Expense) async {
    // ✅ ADD THIS: Track user action before operation
    SentryService.shared.addBreadcrumb(
        message: "User initiated expense deletion",
        category: "ui",
        level: .info,
        data: [
            "expenseId": expense.id.uuidString,
            "amount": expense.amount,
            "categoryId": expense.categoryId.uuidString
        ]
    )
    
    do {
        try await repository.deleteExpense(id: expense.id)
        logger.info("Expense deleted successfully")
        
        // Add success breadcrumb
        SentryService.shared.addBreadcrumb(
            message: "Expense deleted successfully",
            category: "data",
            level: .info
        )
        
    } catch {
        logger.errorWithSentry(
            "Failed to delete expense",
            error: error,
            context: ["expenseId": expense.id.uuidString]
        )
    }
}
```

---

## Performance Monitoring

### Example: Track Critical Operations

```swift
// In your stores or repositories

func loadDashboardData() async {
    // ✅ ADD THIS: Start performance transaction
    let transaction = SentryService.shared.startTransaction(
        name: "Load Dashboard Data",
        operation: "task"
    )
    
    do {
        // Load all dashboard data in parallel
        async let budgetSummary = budgetRepository.fetchBudgetSummary()
        async let guestStats = guestRepository.fetchGuestStats()
        async let upcomingTasks = taskRepository.fetchUpcomingTasks()
        async let recentActivity = activityRepository.fetchRecentActivity()
        
        let summary = try await budgetSummary
        let guests = try await guestStats
        let tasks = try await upcomingTasks
        let activity = try await recentActivity
        
        // Update state with loaded data
        self.dashboardData = DashboardData(
            budgetSummary: summary,
            guestStats: guests,
            upcomingTasks: tasks,
            recentActivity: activity
        )
        
        logger.info("Dashboard data loaded successfully")
        
    } catch {
        logger.errorWithSentry(
            "Failed to load dashboard data",
            error: error,
            context: ["operation": "loadDashboardData"]
        )
    }
    
    // ✅ ADD THIS: Finish transaction
    transaction?.finish()
}
```

### Example: Track Specific Operations

```swift
func exportBudgetToExcel() async {
    let transaction = SentryService.shared.startTransaction(
        name: "Export Budget to Excel",
        operation: "export"
    )
    
    SentryService.shared.addBreadcrumb(
        message: "Starting budget export",
        category: "export",
        level: .info
    )
    
    do {
        let budgetData = try await repository.fetchBudgetData()
        let excelFile = try await exportService.createExcelFile(from: budgetData)
        
        logger.info("Budget exported successfully")
        
        SentryService.shared.addBreadcrumb(
            message: "Budget export completed",
            category: "export",
            level: .info,
            data: ["fileSize": excelFile.size]
        )
        
    } catch {
        logger.errorWithSentry(
            "Failed to export budget",
            error: error,
            context: ["operation": "exportBudgetToExcel"]
        )
    }
    
    transaction?.finish()
}
```

---

## Network Error Handling

### Example: API Error with Status Code

```swift
// In your API clients

func fetchVendorReviews(vendorId: UUID) async throws -> [VendorReview] {
    do {
        let response = try await client
            .from("vendor_reviews")
            .select()
            .eq("vendor_id", value: vendorId)
            .execute()
        
        return response.value
        
    } catch let error as URLError {
        // ✅ ADD THIS: Network-specific error handling
        logger.networkError(
            endpoint: "vendor_reviews",
            error: error,
            statusCode: error.errorCode
        )
        throw error
        
    } catch {
        // ✅ ADD THIS: Generic error handling
        logger.repositoryError(
            operation: "fetchVendorReviews",
            error: error,
            additionalContext: ["vendorId": vendorId.uuidString]
        )
        throw error
    }
}
```

---

## Data Parsing Error Handling

### Example: Decoding Error

```swift
func parseGuestData(_ data: Data) throws -> [Guest] {
    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Guest].self, from: data)
        
    } catch {
        // ✅ ADD THIS: Parsing error with context
        logger.parsingError(
            dataType: "Guest",
            error: error
        )
        
        // Add additional context if it's a decoding error
        if let decodingError = error as? DecodingError {
            logger.errorWithSentry(
                "Failed to decode guest data",
                error: decodingError,
                context: [
                    "dataSize": data.count,
                    "errorType": "DecodingError"
                ]
            )
        }
        
        throw error
    }
}
```

---

## Best Practices Summary

### ✅ Do's

1. **Add breadcrumbs before critical operations**
   ```swift
   SentryService.shared.addBreadcrumb(
       message: "Starting operation",
       category: "task"
   )
   ```

2. **Include relevant context in errors**
   ```swift
   logger.errorWithSentry(
       "Operation failed",
       error: error,
       context: ["userId": userId, "operation": "createGuest"]
   )
   ```

3. **Set user context on login**
   ```swift
   SentryService.shared.setUser(userId: user.id.uuidString)
   ```

4. **Track performance of slow operations**
   ```swift
   let transaction = SentryService.shared.startTransaction(
       name: "Heavy Operation",
       operation: "task"
   )
   // ... do work ...
   transaction?.finish()
   ```

5. **Use AppLogger extensions for consistency**
   ```swift
   logger.repositoryError(operation: "fetchData", error: error)
   ```

### ❌ Don'ts

1. **Don't log sensitive data**
   ```swift
   // ❌ Bad
   context: ["password": password, "creditCard": cardNumber]
   
   // ✅ Good
   context: ["hasPassword": true, "paymentMethod": "card"]
   ```

2. **Don't capture errors in tight loops**
   ```swift
   // ❌ Bad - will spam Sentry
   for item in items {
       do {
           try process(item)
       } catch {
           SentryService.shared.captureError(error) // Don't do this!
       }
   }
   
   // ✅ Good - aggregate errors
   var errors: [Error] = []
   for item in items {
       do {
           try process(item)
       } catch {
           errors.append(error)
       }
   }
   if !errors.isEmpty {
       logger.errorWithSentry("Batch processing failed", error: errors.first!)
   }
   ```

3. **Don't forget to clear user context on logout**
   ```swift
   // ✅ Always clear on logout
   SentryService.shared.clearUser()
   ```

---

## Testing Your Integration

### Quick Test Checklist

1. ✅ Build and run the app
2. ✅ Check console for "Sentry initialized successfully"
3. ✅ Trigger a test error: `SentryService.shared.captureTestError()`
4. ✅ Check Sentry dashboard for the error
5. ✅ Verify user context is set after login
6. ✅ Verify breadcrumbs appear in error details
7. ✅ Check performance transactions in Sentry

---

**Last Updated**: January 2025  
**Related Files**: 
- `SentryService.swift`
- `AppLogger+Sentry.swift`
- `SENTRY_SETUP_GUIDE.md`
