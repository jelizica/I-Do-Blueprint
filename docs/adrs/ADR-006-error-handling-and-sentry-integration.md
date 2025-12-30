# ADR-006: Error Handling and Sentry Integration

## Status
Accepted

## Context
The application needed comprehensive error handling and monitoring:
- Errors were handled inconsistently across the codebase
- No centralized error tracking for production issues
- Difficult to diagnose user-reported problems
- No visibility into error frequency or patterns
- User-facing error messages were often too technical
- No retry mechanisms for transient failures

## Decision
We implemented a multi-layered error handling strategy with Sentry integration:

1. **AppError Protocol**:
   ```swift
   protocol AppError: LocalizedError {
       var errorCode: String { get }
       var userMessage: String { get }
       var technicalDetails: String { get }
       var recoveryOptions: [ErrorRecoveryOption] { get }
       var severity: ErrorSeverity { get }
       var shouldReport: Bool { get }
   }
   ```

2. **Domain-Specific Error Types**:
   - Each domain has its own error enum
   - Implements `LocalizedError` for user-facing messages
   - Example:
     ```swift
     enum BudgetError: Error, LocalizedError {
         case fetchFailed(underlying: Error)
         case createFailed(underlying: Error)
         case tenantContextMissing
         
         var errorDescription: String? {
             switch self {
             case .fetchFailed(let error):
                 return "Failed to fetch budget data: \(error.localizedDescription)"
             case .tenantContextMissing:
                 return "No couple selected. Please sign in."
             }
         }
     }
     ```

3. **Centralized Error Handling**:
   - `ErrorHandler.shared` for global error management
   - `StoreErrorHandling` extension for consistent store errors
   - Logs technical errors with `AppLogger`
   - Captures errors with `SentryService`
   - Shows user-facing errors with `AlertPresenter`

4. **Store Error Handling Extension**:
   ```swift
   extension ObservableObject where Self: AnyObject {
       @MainActor
       func handleError(
           _ error: Error,
           operation: String,
           context: [String: Any]? = nil,
           retry: (() async -> Void)? = nil
       ) async {
           // Log, capture, and present error
       }
   }
   ```

5. **Sentry Integration**:
   - Automatic error capture with context
   - Performance monitoring
   - Breadcrumbs for debugging
   - User feedback collection
   - Release tracking

6. **Network Retry Logic**:
   - `NetworkRetry.withRetry()` for resilient network operations
   - Exponential backoff
   - Configurable retry attempts
   - Automatic retry for transient failures

## Consequences

### Positive
- **Visibility**: All production errors captured in Sentry
- **Consistency**: Uniform error handling across the app
- **User Experience**: Clear, actionable error messages
- **Debugging**: Rich context helps diagnose issues
- **Resilience**: Automatic retry for transient failures
- **Monitoring**: Track error trends and patterns
- **Proactive**: Catch issues before users report them

### Negative
- **Overhead**: Error handling adds code to every operation
- **Privacy**: Must be careful not to log sensitive data
- **Cost**: Sentry has usage-based pricing
- **Complexity**: Multiple error handling layers
- **Performance**: Error capture adds slight overhead

## Implementation Notes

### Error Handling Pattern

#### In Repositories
```swift
func fetchGuests() async throws -> [Guest] {
    do {
        let guests: [Guest] = try await supabase.database
            .from("guest_list")
            .select()
            .eq("couple_id", value: tenantId)
            .execute()
            .value
        return guests
    } catch {
        logger.error("Failed to fetch guests", error: error)
        throw GuestError.fetchFailed(underlying: error)
    }
}
```

#### In Stores
```swift
func loadGuests() async {
    loadingState = .loading
    do {
        let guests = try await NetworkRetry.withRetry {
            try await repository.fetchGuests()
        }
        loadingState = .loaded(guests)
    } catch {
        await handleError(error, operation: "loadGuests") { [weak self] in
            await self?.loadGuests() // Retry
        }
        loadingState = .error(error)
    }
}
```

#### With Context
```swift
await handleError(error, operation: "createGuest", context: [
    "guestName": guest.fullName,
    "guestCount": guests.count
]) { [weak self] in
    await self?.createGuest(guest)
}
```

### Sentry Configuration
- DSN configured in `Config.plist`
- Environment set based on build configuration
- User identification for better tracking
- Breadcrumbs for user actions
- Performance monitoring enabled

### Privacy Considerations
- Never log passwords or tokens
- Redact sensitive data in error messages
- Use `AppLogger`'s redaction methods
- Review Sentry data before release

### Testing
- Test error paths with mock failures
- Verify error messages are user-friendly
- Test retry logic with transient failures
- Verify Sentry capture in staging

## Migration Checklist
- [ ] Define domain-specific error types
- [ ] Implement `LocalizedError` for user messages
- [ ] Use `handleError` extension in stores
- [ ] Wrap network calls with `NetworkRetry.withRetry()`
- [ ] Add context to error captures
- [ ] Test error handling paths
- [ ] Verify Sentry integration
- [ ] Review error messages for clarity

## Related Documents
- `best_practices.md` - Section 4: Error Handling
- `Core/Common/Errors/` - Error types and handlers
- `Services/Stores/StoreErrorHandling.swift` - Store error extension
- `Services/Analytics/SentryService.swift` - Sentry integration
- `Utilities/NetworkRetry.swift` - Retry logic
