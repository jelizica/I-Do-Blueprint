//
//  PerformanceFeatureFlags.swift
//  I Do Blueprint
//
//  Feature flags to control memory-intensive performance monitoring
//

import Foundation

/// Feature flags specifically for performance and memory-intensive operations
enum PerformanceFeatureFlags {
    /// Enable periodic analytics refresh (every 5 minutes)
    /// Disable this in production or when debugging memory issues
    static var enablePeriodicAnalytics: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: "enablePeriodicAnalytics") as? Bool ?? false
        #else
        return false
        #endif
    }

    /// Enable performance monitoring timers (every 30-60 seconds)
    /// Disable this when debugging memory issues
    static var enablePerformanceMonitoring: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: "enablePerformanceMonitoring") as? Bool ?? false
        #else
        return false
        #endif
    }

    /// Enable memory warning simulation/monitoring
    static var enableMemoryWarningMonitoring: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: "enableMemoryWarningMonitoring") as? Bool ?? false
        #else
        return false
        #endif
    }

    /// Enable image preloading for visual planning
    /// Can consume significant memory if many images are preloaded
    static var enableImagePreloading: Bool {
        #if DEBUG
        return UserDefaults.standard.object(forKey: "enableImagePreloading") as? Bool ?? false
        #else
        return true // Enable in production but with limits
        #endif
    }

    /// Maximum concurrent image loads
    static var maxConcurrentImageLoads: Int {
        #if DEBUG
        return UserDefaults.standard.object(forKey: "maxConcurrentImageLoads") as? Int ?? 2
        #else
        return 4
        #endif
    }

    // MARK: - Setters (Debug only)

    #if DEBUG
    static func setPeriodicAnalytics(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "enablePeriodicAnalytics")
    }

    static func setPerformanceMonitoring(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "enablePerformanceMonitoring")
    }

    static func setMemoryWarningMonitoring(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "enableMemoryWarningMonitoring")
    }

    static func setImagePreloading(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "enableImagePreloading")
    }

    static func setMaxConcurrentImageLoads(_ count: Int) {
        UserDefaults.standard.set(count, forKey: "maxConcurrentImageLoads")
    }

    /// Reset all performance flags to defaults
    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "enablePeriodicAnalytics")
        UserDefaults.standard.removeObject(forKey: "enablePerformanceMonitoring")
        UserDefaults.standard.removeObject(forKey: "enableMemoryWarningMonitoring")
        UserDefaults.standard.removeObject(forKey: "enableImagePreloading")
        UserDefaults.standard.removeObject(forKey: "maxConcurrentImageLoads")
    }
    #endif

    /// Get all current flag states (for debugging)
    static func currentState() -> [String: Any] {
        [
            "enablePeriodicAnalytics": enablePeriodicAnalytics,
            "enablePerformanceMonitoring": enablePerformanceMonitoring,
            "enableMemoryWarningMonitoring": enableMemoryWarningMonitoring,
            "enableImagePreloading": enableImagePreloading,
            "maxConcurrentImageLoads": maxConcurrentImageLoads
        ]
    }
}
