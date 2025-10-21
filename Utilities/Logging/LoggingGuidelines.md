# Logging Guidelines

## When to Log

### ✅ DO Log:
- **Errors** - All errors with context
- **Important State Changes** - User actions, data mutations
- **Performance Metrics** - Slow operations (>1s)
- **Security Events** - Auth failures, permission denials
- **Data Integrity Issues** - Validation failures, corruption

### ❌ DON'T Log:
- **Routine Operations** - Normal CRUD operations
- **Method Entry/Exit** - "Fetching...", "Loaded...", "Creating..."
- **Loop Iterations** - Logs inside loops
- **Cache Hits** - Normal cache behavior
- **Redundant Info** - Info already in error messages
- **State Tracking** - "Already loaded", "Skipping..."

## Log Levels

### `.error` - Production Issues
```swift
// ✅ Good - actionable error with context
logger.error("Failed to save budget category", error: error, metadata: [
    "categoryId": category.id.uuidString,
    "categoryName": category.categoryName
])
```

### `.info` - Important Events
```swift
// ✅ Good - significant state change
logger.info("User logged in successfully", metadata: [
    "userId": user.id.uuidString,
    "method": "google_oauth"
])

// ✅ Good - performance metric for slow operations
if duration > 1.0 {
    logger.info("Slow category fetch: \(duration)s for \(categories.count) items")
}

// ✅ Good - important mutation
logger.info("Created category: \(created.categoryName)")
```

### `.debug` - Development Only
```swift
// ✅ Good - actual debugging aid (wrapped in DEBUG)
#if DEBUG
logger.debug("Cache state: \(cache.stats())")
#endif

// ❌ Bad - routine operation
logger.debug("Fetching categories...")  // DELETE THIS

// ❌ Bad - state tracking
logger.debug("Budget data already loaded, skipping")  // DELETE THIS
```

## Performance Considerations

### Hot Paths

Never log in:
- Rendering loops
- Data transformation loops
- Frequently-called computed properties
- High-frequency timers
- View body computations

### String Interpolation

```swift
// ❌ Bad - string created even if not logged
logger.debug("Data: \(expensiveOperation())")

// ✅ Good - lazy evaluation
logger.debug("Data: \(expensiveOperation(), privacy: .private)")
```

## Common Patterns

### Pattern 1: Remove Routine Operation Logs

```swift
// BEFORE ❌
func fetchCategories() async throws -> [BudgetCategory] {
    logger.debug("Fetching budget categories from Supabase...")  // DELETE
    let categories: [BudgetCategory] = try await client
        .from("budget_categories")
        .select()
        .execute()
        .value
    logger.debug("Cached \(categories.count) budget categories")  // DELETE
    return categories
}

// AFTER ✅
func fetchCategories() async throws -> [BudgetCategory] {
    let startTime = Date()
    let categories: [BudgetCategory] = try await client
        .from("budget_categories")
        .select()
        .execute()
        .value
    
    let duration = Date().timeIntervalSince(startTime)
    // Only log if slow (performance issue)
    if duration > 1.0 {
        logger.info("Slow category fetch: \(duration)s for \(categories.count) items")
    }
    
    return categories
}
```

### Pattern 2: Keep Important Events

```swift
// BEFORE ❌
func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
    logger.debug("Creating budget category: \(category.categoryName)")  // Too verbose
    let created = try await client.from("budget_categories").insert(category).execute().value
    logger.debug("Created category")  // Redundant
    return created
}

// AFTER ✅
func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
    let created = try await client.from("budget_categories").insert(category).execute().value
    // Log important mutation
    logger.info("Created category: \(created.categoryName)")
    return created
}
```

### Pattern 3: Remove Loop Logging

```swift
// BEFORE ❌
func updateSeatingChart(_ chart: SeatingChart) async throws {
    logger.debug("[REPO] Saving \(chart.tables.count) tables")  // DELETE
    for (index, table) in chart.tables.enumerated() {
        logger.debug("[REPO] Saving table \(index + 1)")  // DELETE - in loop!
        try await saveTable(table)
        logger.debug("[REPO] Table \(index + 1) saved")  // DELETE - in loop!
    }
    logger.debug("[REPO] All tables saved")  // DELETE
}

// AFTER ✅
func updateSeatingChart(_ chart: SeatingChart) async throws {
    let startTime = Date()
    for table in chart.tables {
        try await saveTable(table)
    }
    let duration = Date().timeIntervalSince(startTime)
    // Single summary log
    logger.info("Saved \(chart.tables.count) tables in \(String(format: "%.2f", duration))s")
}
```

### Pattern 4: Remove State Tracking Logs

```swift
// BEFORE ❌
func loadBudgetData() async {
    guard loadingState.isIdle || loadingState.hasError else {
        logger.debug("Budget data already loaded, skipping")  // DELETE
        return
    }
    loadingState = .loading
    logger.debug("Loading budget data...")  // DELETE
    // ... fetch data ...
    logger.debug("Loaded \(categories.count) categories")  // DELETE
}

// AFTER ✅
func loadBudgetData() async {
    guard loadingState.isIdle || loadingState.hasError else {
        return
    }
    loadingState = .loading
    do {
        // ... fetch data ...
        // Only log summary
        logger.info("Loaded budget data: \(categories.count) categories, \(expenses.count) expenses")
    } catch {
        // Always log errors
        logger.error("Failed to load budget data", error: error)
    }
}
```

### Pattern 5: Remove Cache Hit Logs

```swift
// BEFORE ❌
if let cached: [BudgetCategory] = await cache.get(cacheKey, maxAge: 60) {
    logger.debug("Cache hit: budget_categories (\(cached.count) items)")  // DELETE
    return cached
}

// AFTER ✅
if let cached: [BudgetCategory] = await cache.get(cacheKey, maxAge: 60) {
    return cached
}
```

### Pattern 6: Remove Placeholder Warnings

```swift
// BEFORE ❌
#if DEBUG
logger.warning("Placeholder data being used: categoryBenchmarks, cashFlowData")  // DELETE
#endif
categoryBenchmarks = []
cashFlowData = []

// AFTER ✅
// Either implement the feature or remove the warning
categoryBenchmarks = []
cashFlowData = []
```

## Success Metrics

### Quantitative Goals
- **Debug logs:** Reduce from 350+ to <50 (85% reduction)
- **Repository logs:** Reduce from 150 to 30 (80% reduction)
- **Store logs:** Reduce from 100 to 20 (80% reduction)
- **Loop logs:** Reduce to 0 (100% elimination)

### Qualitative Goals
- ✅ No logs in hot paths (loops, rendering)
- ✅ All remaining logs provide actionable information
- ✅ Log levels used correctly (error, info, debug)
- ✅ Performance improvement measurable in Instruments

## Code Review Checklist

When reviewing code, check for:
- [ ] No debug logs for routine operations
- [ ] No logs inside loops
- [ ] No cache hit logs
- [ ] No state tracking logs
- [ ] Important mutations logged at `.info` level
- [ ] Errors logged with context
- [ ] Slow operations (>1s) logged with duration
- [ ] Debug logs wrapped in `#if DEBUG`

## References

- OSLog Best Practices: https://developer.apple.com/documentation/os/logging
- Project Best Practices: `/best_practices.md` Section 4 (Code Style)
