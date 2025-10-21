# Loading State Pattern

This directory contains the unified loading state infrastructure for the I Do Blueprint app.

## Overview

The loading state pattern provides a consistent, type-safe way to handle data loading, errors, and retry logic across the entire application.

## Components

### LoadingState Enum

The core enum that represents all possible loading states:

```swift
enum LoadingState<T> {
    case idle       // Initial state, no data loaded yet
    case loading    // Currently fetching data
    case loaded(T)  // Data successfully loaded
    case error(Error) // An error occurred
}
```

**Computed Properties:**
- `isLoading: Bool` - True when in loading state
- `data: T?` - Returns loaded data if available
- `error: Error?` - Returns error if in error state
- `isIdle: Bool` - True when in idle state
- `isLoaded: Bool` - True when data is loaded
- `hasError: Bool` - True when in error state

### LoadingStateView

A SwiftUI view that automatically handles all loading states:

```swift
LoadingStateView(
    state: store.loadingState,
    loadingMessage: "Loading...",
    onRetry: { Task { await store.retryLoad() } }
) { data in
    // Your content view with loaded data
    ContentView(data: data)
}
```

**Features:**
- Displays Lottie loading animation during loading
- Shows error state with retry button
- Renders content when data is loaded
- Handles idle state automatically

### ErrorStateView

Displays errors with optional retry functionality:

```swift
ErrorStateView(
    error: error,
    onRetry: { Task { await store.retryLoad() } }
)
```

**Features:**
- Consistent error UI across the app
- Optional retry button
- Accessibility support

### InlineLoadingStateView

Compact loading indicator for inline use:

```swift
InlineLoadingStateView(
    state: store.loadingState
) { data in
    Text(data.value)
}
```

**Use Cases:**
- Small UI elements
- Table cells
- Inline data displays

## Usage Patterns

### Pattern 1: Simple View (Recommended for New Features)

Use `LoadingStateView` for straightforward loading scenarios:

```swift
struct MyFeatureView: View {
    @EnvironmentObject private var store: MyFeatureStoreV2
    
    var body: some View {
        LoadingStateView(
            state: store.loadingState,
            loadingMessage: "Loading features...",
            onRetry: {
                Task { await store.retryLoad() }
            }
        ) { features in
            List(features) { feature in
                FeatureRow(feature: feature)
            }
        }
        .task {
            await store.loadData()
        }
    }
}
```

### Pattern 2: Complex View with Skeleton Loaders

For sophisticated UX with skeleton screens:

```swift
struct ComplexFeatureView: View {
    @EnvironmentObject private var store: FeatureStoreV2
    
    var body: some View {
        Group {
            switch store.loadingState {
            case .idle:
                EmptyView()
                
            case .loading:
                if store.data.isEmpty {
                    SkeletonView()
                } else {
                    // Show content with loading indicator
                    ContentView(data: store.data)
                        .overlay(alignment: .top) {
                            ProgressView()
                        }
                }
                
            case .loaded(let data):
                ContentView(data: data)
                
            case .error(let error):
                ErrorStateView(error: error) {
                    Task { await store.retryLoad() }
                }
            }
        }
    }
}
```

### Pattern 3: Inline Loading

For small UI elements:

```swift
struct InlineDataView: View {
    @EnvironmentObject private var store: DataStoreV2
    
    var body: some View {
        HStack {
            Text("Status:")
            InlineLoadingStateView(state: store.loadingState) { data in
                Text(data.status)
                    .foregroundColor(.green)
            }
        }
    }
}
```

## Store Implementation

All V2 stores follow this pattern:

```swift
@MainActor
class MyFeatureStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<[MyData]> = .idle
    
    // Backward compatibility
    var data: [MyData] {
        loadingState.data ?? []
    }
    
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    var error: MyError? {
        if case .error(let err) = loadingState {
            return err as? MyError ?? .fetchFailed(underlying: err)
        }
        return nil
    }
    
    func loadData() async {
        guard loadingState.isIdle || loadingState.hasError else { return }
        
        loadingState = .loading
        
        do {
            let fetchedData = try await repository.fetchData()
            loadingState = .loaded(fetchedData)
        } catch {
            loadingState = .error(MyError.fetchFailed(underlying: error))
        }
    }
    
    func retryLoad() async {
        await loadData()
    }
}
```

## Benefits

### Type Safety
- Impossible to have invalid state combinations (e.g., loading + error)
- Compiler enforces proper state handling

### Consistency
- Single pattern across entire codebase
- Predictable behavior for developers and users

### Maintainability
- Easy to add loading states to new features
- Clear separation of concerns

### User Experience
- Consistent loading animations
- Unified error handling
- Built-in retry functionality

## Migration Guide

### For Existing Views

If a view already has sophisticated loading UX (skeleton screens, etc.), **keep it**! Just leverage the LoadingState enum:

```swift
// Before
if store.isLoading { ... }

// After
if store.loadingState.isLoading { ... }
```

### For New Views

Use `LoadingStateView` as the default pattern for simplicity and consistency.

### For Simple Views

Replace manual loading checks with `LoadingStateView`:

```swift
// Before
if store.isLoading {
    ProgressView()
} else if let error = store.error {
    Text("Error: \(error.localizedDescription)")
} else {
    ContentView(data: store.data)
}

// After
LoadingStateView(
    state: store.loadingState,
    onRetry: { Task { await store.retryLoad() } }
) { data in
    ContentView(data: data)
}
```

## Testing

### Testing LoadingState

```swift
func testLoadingState() {
    let state: LoadingState<[String]> = .loading
    XCTAssertTrue(state.isLoading)
    XCTAssertNil(state.data)
    XCTAssertNil(state.error)
}

func testLoadedState() {
    let data = ["Item 1", "Item 2"]
    let state: LoadingState<[String]> = .loaded(data)
    XCTAssertFalse(state.isLoading)
    XCTAssertEqual(state.data, data)
    XCTAssertNil(state.error)
}
```

### Testing Stores

```swift
func testStoreLoading() async {
    let store = MyFeatureStoreV2()
    XCTAssertTrue(store.loadingState.isIdle)
    
    await store.loadData()
    
    // Verify state transitions
    XCTAssertTrue(store.loadingState.isLoaded)
    XCTAssertFalse(store.data.isEmpty)
}
```

## Examples

See `LoadingStateViewExample.swift` for a complete working example.

## Related Files

- `LoadingState.swift` - Core enum definition
- `LoadingStateView.swift` - Main view component
- `ErrorStateView.swift` - Error display component
- `InlineLoadingStateView.swift` - Compact loading indicator
- `LoadingStateViewExample.swift` - Usage example

## Issue Reference

Created for [JES-47: Standardize Loading States with Unified LoadingStateView Pattern](https://linear.app/jessica-clark-256/issue/JES-47)
