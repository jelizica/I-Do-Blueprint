# I Do Blueprint - Task Completion Workflow

## When a Task is Completed

Follow this checklist before marking any implementation task as complete.

### 1. Code Quality Checks

#### Format & Style
- [ ] Code follows Swift naming conventions (camelCase variables, PascalCase types)
- [ ] MARK comments added for files over 100 lines
- [ ] File headers present with brief description
- [ ] No force unwrapping (`!`) without clear justification
- [ ] No magic numbers (use named constants)

#### Documentation
- [ ] Public APIs have DocString comments
- [ ] Complex logic has explanatory comments
- [ ] Error cases are documented

#### Type Safety
- [ ] Strong typing used (avoid `Any`)
- [ ] Enums used for constants (not strings)
- [ ] Sendable conformance for concurrent types
- [ ] MainActor annotation on UI classes

### 2. Architecture Compliance

#### Repository Pattern
- [ ] All data access goes through repositories
- [ ] Repository protocol defined in `Domain/Repositories/Protocols/`
- [ ] Live implementation in `Domain/Repositories/Live/`
- [ ] Mock implementation in test helpers
- [ ] Dependency injection configured

#### Store Pattern
- [ ] Store uses V2 suffix (e.g., `GuestStoreV2`)
- [ ] Store is @MainActor ObservableObject
- [ ] Uses @Dependency for repository injection
- [ ] Uses LoadingState<T> for async operations
- [ ] Implements optimistic updates with rollback

#### Error Handling
- [ ] Domain-specific error types defined
- [ ] Errors logged with AppLogger
- [ ] LoadingState updated on errors
- [ ] User-friendly error messages

### 3. Design System Compliance

#### UI Components
- [ ] Uses AppColors (not hardcoded colors)
- [ ] Uses Typography constants (not hardcoded fonts)
- [ ] Uses Spacing constants (not magic numbers)
- [ ] Colors meet WCAG AA contrast standards (4.5:1)

#### Accessibility
- [ ] Accessibility labels on interactive elements
- [ ] Accessibility hints provided
- [ ] Tested with VoiceOver (if UI change)
- [ ] Color contrast validated

### 4. Testing Requirements

#### Unit Tests
- [ ] Store tests written using mock repository
- [ ] Tests use .makeTest() factory methods
- [ ] Success cases tested
- [ ] Error cases tested
- [ ] Edge cases tested
- [ ] All tests pass (⌘U)

#### Test Coverage
- [ ] Core functionality tested (>80% coverage goal)
- [ ] @MainActor tests for stores
- [ ] withDependencies used for dependency injection

### 5. Build Verification

#### Clean Build
- [ ] Project builds without warnings
- [ ] No deprecation warnings
- [ ] Xcode Analyze passes (⇧⌘B)
- [ ] Clean build succeeds (⇧⌘K then ⌘B)

#### Run Verification
- [ ] App runs without crashes
- [ ] Feature works as expected
- [ ] No console errors or warnings

### 6. Logging Audit

#### Production Logging
- [ ] No excessive debug logging
- [ ] Info logs for important events
- [ ] Error logs for failures
- [ ] No sensitive data logged
- [ ] Run `./Scripts/audit_logging.sh` if adding logs

### 7. Code Review Checklist

#### Patterns & Best Practices
- [ ] Follows existing project patterns
- [ ] No code duplication (DRY principle)
- [ ] Single responsibility (functions do one thing)
- [ ] Proper separation of concerns

#### Performance
- [ ] Async operations use async/await
- [ ] Parallel operations used where appropriate
- [ ] No blocking main thread
- [ ] Caching implemented if needed

#### Security
- [ ] Multi-tenant filtering in repositories
- [ ] No hardcoded credentials
- [ ] Proper error handling (no data leaks)

### 8. Documentation Updates

#### Code Documentation
- [ ] README.md updated if architecture changes
- [ ] best_practices.md updated if new patterns
- [ ] Comments explain "why" not "what"

### 9. Git Workflow

#### Before Commit
- [ ] Run all tests (⌘U)
- [ ] Clean build succeeds
- [ ] No debugging code left behind
- [ ] Feature branch created (not on main)

#### Commit
```bash
# Example commit message format
git commit -m "feat(guests): Add guest filtering by RSVP status

- Implement filter state in GuestStoreV2
- Add filter UI in GuestListView
- Add repository method for filtered fetch
- Add unit tests for filtering logic"
```

### 10. Performance Considerations

#### Async Operations
- [ ] Loading states prevent multiple simultaneous requests
- [ ] Debouncing implemented for rapid user input
- [ ] Cancellation handled properly

#### Memory
- [ ] No retain cycles (use [weak self] in closures)
- [ ] Large data cached appropriately
- [ ] Images loaded efficiently (Kingfisher)

## Quick Checklist

**Before marking task complete:**
```
✅ Code builds without warnings
✅ All tests pass
✅ Follows repository pattern
✅ Uses LoadingState for async
✅ Uses design system constants
✅ Accessibility labels added
✅ Errors logged with AppLogger
✅ No hardcoded values
✅ Documentation updated
✅ Git branch created
```

## Common Mistakes to Avoid

❌ **Don't**:
- Access Supabase directly from views/stores
- Use hardcoded colors/spacing
- Skip error handling
- Use completion handlers (use async/await)
- Create singletons without consideration
- Skip accessibility labels
- Use force unwrapping without justification
- Mix UI and business logic
- Create massive files (>300 lines for views)
- Skip MARK comments
- Log sensitive data
- Bypass loading state pattern

✅ **Do**:
- Use repository pattern for all data
- Use design system constants
- Handle errors gracefully
- Use async/await
- Inject dependencies
- Add accessibility support
- Use optional chaining
- Keep views thin
- Break into components
- Organize with MARK
- Use AppLogger with redaction
- Follow loading state pattern
