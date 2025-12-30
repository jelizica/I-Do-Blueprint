# ADR-003: V2 Store Pattern and State Management

## Status
Accepted

## Context
The original store implementations had several issues:
- Inconsistent error handling across stores
- No standardized loading state management
- Direct Supabase access from stores
- Difficult to test due to tight coupling
- No caching strategy at store level
- Memory leaks from creating multiple store instances

## Decision
We adopted the V2 Store Pattern with these characteristics:

1. **Store Structure**:
   - All stores are `@MainActor` and `ObservableObject`
   - Use `@Published` for observable state
   - Use `@Dependency` for injecting repositories
   - Naming convention: `{Feature}StoreV2`

2. **Loading State Pattern**:
   ```swift
   enum LoadingState<T> {
       case idle
       case loading
       case loaded(T)
       case error(Error)
   }
   ```

3. **Error Handling Extension**:
   - Centralized `handleError` extension for all stores
   - Logs technical errors with `AppLogger`
   - Captures errors with `SentryService`
   - Shows user-facing errors with `AlertPresenter`
   - Supports retry actions

4. **CacheableStore Protocol**:
   - Store-level caching with TTL
   - `lastLoadTime` tracking
   - `isCacheValid()` check before loading
   - `invalidateCache()` for manual refresh

5. **Singleton Pattern**:
   - All stores accessed via `AppStores.shared`
   - Environment values for convenient access
   - Never create new store instances in views

## Consequences

### Positive
- **Consistency**: All stores follow the same pattern
- **Testability**: Easy to test with mock repositories
- **Error Handling**: Centralized, consistent error management
- **User Experience**: Loading states provide clear feedback
- **Performance**: Store-level caching reduces unnecessary loads
- **Memory Efficiency**: Single store instances prevent memory leaks
- **Maintainability**: Clear patterns make code easier to understand

### Negative
- **Boilerplate**: Each store requires similar setup code
- **Migration Effort**: Existing stores need to be migrated to V2
- **Learning Curve**: Developers must learn the pattern
- **Singleton Constraints**: Global state can make testing harder

## Implementation Notes

### Store Access Patterns

#### ✅ Correct
```swift
// Option 1: Environment Access (Preferred)
@Environment(\.appStores) private var appStores
private var store: SettingsStoreV2 { appStores.settings }

// Option 2: Direct Environment Store
@Environment(\.budgetStore) private var store

// Option 3: Pass Store as Parameter
@ObservedObject var budgetStore: BudgetStoreV2

// Option 4: Direct Singleton (Last Resort)
private var store: SettingsStoreV2 { AppStores.shared.settings }
```

#### ❌ Anti-Patterns
```swift
// Never create new instances
@StateObject private var store = SettingsStoreV2()
let store = BudgetStoreV2()
```

### Error Handling Pattern
```swift
func createGuest(_ guest: Guest) async {
    do {
        let created = try await repository.createGuest(guest)
        showSuccess("Guest added successfully")
    } catch {
        await handleError(error, operation: "createGuest", context: [
            "guestName": guest.fullName
        ]) { [weak self] in
            await self?.createGuest(guest) // Retry
        }
    }
}
```

### CacheableStore Implementation
```swift
@MainActor
class GuestStoreV2: ObservableObject, CacheableStore {
    var lastLoadTime: Date?
    var cacheValidityDuration: TimeInterval { 60 }
    
    func loadGuests(force: Bool = false) async {
        guard force || !isCacheValid() else { return }
        // Load data...
        lastLoadTime = Date()
    }
}
```

## Migration Checklist
- [ ] Store is `@MainActor` and `ObservableObject`
- [ ] Uses `LoadingState<T>` for async operations
- [ ] Injects repository via `@Dependency`
- [ ] Uses `handleError` extension for errors
- [ ] Implements `CacheableStore` if appropriate
- [ ] Registered in `AppStores`
- [ ] Environment value created
- [ ] Tests use mock repositories
- [ ] Views access via environment or singleton

## Related Documents
- `best_practices.md` - Section 5: Store Access Patterns
- `Services/Stores/` - V2 store implementations
- `Core/Common/Common/AppStores.swift` - Store singleton
- `Services/Stores/StoreErrorHandling.swift` - Error handling extension
