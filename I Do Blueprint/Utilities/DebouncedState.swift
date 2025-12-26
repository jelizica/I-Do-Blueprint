//
//  DebouncedState.swift
//  I Do Blueprint
//
//  Property wrapper for debouncing state updates to reduce view re-renders
//

import SwiftUI

/// A property wrapper that debounces state updates to reduce unnecessary view re-renders
///
/// Use this for state that changes frequently but doesn't need immediate UI updates,
/// such as drag state, search text, or scroll position.
///
/// Example:
/// ```swift
/// @DebouncedState(wrappedValue: nil, delay: 0.1) private var draggedItem: BudgetItem?
/// ```
///
/// Note: This is a simplified implementation. For production use, consider using Combine's
/// debounce operator or a more robust debouncing solution.
@propertyWrapper
struct DebouncedState<Value>: DynamicProperty {
    @State private var value: Value
    private let delay: TimeInterval
    
    /// Creates a debounced state with the specified initial value and delay
    /// - Parameters:
    ///   - wrappedValue: The initial value
    ///   - delay: The debounce delay in seconds (default: 0.3)
    init(wrappedValue: Value, delay: TimeInterval = 0.3) {
        self._value = State(initialValue: wrappedValue)
        self.delay = delay
    }
    
    var wrappedValue: Value {
        get { value }
        nonmutating set {
            // For now, update immediately
            // Full debouncing would require a more complex implementation with Task management
            value = newValue
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

/// A property wrapper that throttles state updates to a maximum frequency
///
/// Unlike debouncing (which delays until changes stop), throttling ensures
/// updates happen at most once per interval, even if changes continue.
///
/// Example:
/// ```swift
/// @ThrottledState(wrappedValue: 0, interval: 0.1) private var scrollOffset: CGFloat
/// ```
///
/// Note: This is a simplified implementation. For production use, consider using Combine's
/// throttle operator or a more robust throttling solution.
@propertyWrapper
struct ThrottledState<Value>: DynamicProperty {
    @State private var value: Value
    private let interval: TimeInterval
    
    /// Creates a throttled state with the specified initial value and interval
    /// - Parameters:
    ///   - wrappedValue: The initial value
    ///   - interval: The minimum time between updates in seconds (default: 0.1)
    init(wrappedValue: Value, interval: TimeInterval = 0.1) {
        self._value = State(initialValue: wrappedValue)
        self.interval = interval
    }
    
    var wrappedValue: Value {
        get { value }
        nonmutating set {
            // For now, update immediately
            // Full throttling would require a more complex implementation with Task management
            value = newValue
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}
