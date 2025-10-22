//
//  RepositoryCache.swift
//  I Do Blueprint
//
//  Generic caching infrastructure for repository data
//  Part of JES-60: Performance Optimization
//

import Foundation

/// Thread-safe generic cache for repository data with TTL support
///
/// This cache provides:
/// - Generic type-safe caching for any Codable type
/// - Time-to-live (TTL) for automatic cache expiration
/// - Thread-safe access using actor isolation
/// - Cache metrics tracking (hits/misses)
/// - Memory-based storage (cleared on app termination)
///
/// ## Usage Example
/// ```swift
/// let cache = RepositoryCache.shared
///
/// // Store data with 60 second TTL
/// await cache.set("guests_123", value: guests, ttl: 60)
///
/// // Retrieve data (returns nil if expired or not found)
/// if let cached: [Guest] = await cache.get("guests_123") {
///     print("Cache hit!")
/// }
///
/// // Invalidate specific key
/// await cache.invalidate("guests_123")
///
/// // Clear all cache
/// await cache.clear()
/// ```
actor RepositoryCache {
    
    // MARK: - Singleton
    
    static let shared = RepositoryCache()
    
    private let logger = AppLogger.cache
    
    // MARK: - Private Properties
    
    /// Cache entry containing data and expiration time
    private struct CacheEntry {
        let data: Data
        let expiresAt: Date
        
        var isExpired: Bool {
            Date() > expiresAt
        }
    }
    
    /// In-memory cache storage
    private var cache: [String: CacheEntry] = [:]
    
    /// Cache metrics for monitoring
    private var hits: [String: Int] = [:]
    private var misses: [String: Int] = [:]
    
    // MARK: - Public Interface
    
    /// Retrieves a cached value if it exists and hasn't expired
    ///
    /// - Parameters:
    ///   - key: The cache key
    ///   - maxAge: Optional maximum age in seconds (overrides stored TTL)
    /// - Returns: The cached value if found and not expired, nil otherwise
    func get<T: Codable>(_ key: String, maxAge: TimeInterval? = nil) -> T? {
        // Check if entry exists
        guard let entry = cache[key] else {
            recordMiss(key)
            return nil
        }
        
        // Check if expired
        let isExpired: Bool
        if let maxAge = maxAge {
            let createdAt = entry.expiresAt.addingTimeInterval(-maxAge)
            isExpired = Date().timeIntervalSince(createdAt) > maxAge
        } else {
            isExpired = entry.isExpired
        }
        
        if isExpired {
            // Remove expired entry
            cache.removeValue(forKey: key)
            recordMiss(key)
            return nil
        }
        
        // Decode and return
        do {
            let value = try JSONDecoder().decode(T.self, from: entry.data)
            recordHit(key)
            return value
        } catch {
            // Remove corrupted entry
            cache.removeValue(forKey: key)
            recordMiss(key)
            return nil
        }
    }
    
    /// Stores a value in the cache with a time-to-live
    ///
    /// - Parameters:
    ///   - key: The cache key
    ///   - value: The value to cache (must be Codable)
    ///   - ttl: Time-to-live in seconds (default: 60)
    func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval = 60) {
        do {
            let data = try JSONEncoder().encode(value)
            let expiresAt = Date().addingTimeInterval(ttl)
            cache[key] = CacheEntry(data: data, expiresAt: expiresAt)
        } catch {
            // Silently fail - caching is optional
            logger.warning("Failed to cache value for key '\(key)': \(error.localizedDescription)")
        }
    }
    
    /// Invalidates a specific cache entry
    ///
    /// - Parameter key: The cache key to invalidate
    func invalidate(_ key: String) {
        cache.removeValue(forKey: key)
    }
    
    /// Removes a specific cache entry (alias for invalidate for backward compatibility)
    ///
    /// - Parameter key: The cache key to remove
    func remove(_ key: String) {
        invalidate(key)
    }
    
    /// Invalidates all cache entries matching a prefix
    ///
    /// Useful for invalidating all related cache entries at once.
    /// For example, invalidating all guest-related caches: `invalidatePrefix("guests_")`
    ///
    /// - Parameter prefix: The key prefix to match
    func invalidatePrefix(_ prefix: String) {
        let keysToRemove = cache.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
    }
    
    /// Clears all cache entries
    func clear() {
        cache.removeAll()
        hits.removeAll()
        misses.removeAll()
    }
    
    /// Clears all cache entries (alias for clear for backward compatibility)
    func clearAll() {
        clear()
    }
    
    /// Removes expired entries from the cache
    ///
    /// This is called automatically during get operations,
    /// but can be called manually for cleanup.
    func cleanupExpired() {
        let expiredKeys = cache.filter { $0.value.isExpired }.map { $0.key }
        for key in expiredKeys {
            cache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Cache Metrics
    
    /// Records a cache hit for metrics
    private func recordHit(_ key: String) {
        hits[key, default: 0] += 1
    }
    
    /// Records a cache miss for metrics
    private func recordMiss(_ key: String) {
        misses[key, default: 0] += 1
    }
    
    /// Calculates the hit rate for a specific key
    ///
    /// - Parameter key: The cache key
    /// - Returns: Hit rate as a percentage (0.0 to 1.0)
    func hitRate(for key: String) -> Double {
        let totalHits = hits[key, default: 0]
        let totalMisses = misses[key, default: 0]
        let total = totalHits + totalMisses
        
        guard total > 0 else { return 0 }
        return Double(totalHits) / Double(total)
    }
    
    /// Generates a cache performance report
    ///
    /// - Returns: A formatted string with cache statistics
    func performanceReport() -> String {
        var report = "📊 Cache Performance Report\n"
        report += "=" * 50 + "\n\n"
        
        let allKeys = Set(hits.keys).union(misses.keys).sorted()
        
        if allKeys.isEmpty {
            report += "No cache activity recorded.\n"
            return report
        }
        
        for key in allKeys {
            let totalHits = hits[key, default: 0]
            let totalMisses = misses[key, default: 0]
            let rate = hitRate(for: key)
            
            report += "Key: \(key)\n"
            report += "  Hits: \(totalHits)\n"
            report += "  Misses: \(totalMisses)\n"
            report += "  Hit Rate: \(String(format: "%.1f%%", rate * 100))\n\n"
        }
        
        // Overall statistics
        let totalHits = hits.values.reduce(0, +)
        let totalMisses = misses.values.reduce(0, +)
        let overallRate = Double(totalHits) / Double(totalHits + totalMisses)
        
        report += "=" * 50 + "\n"
        report += "Overall Statistics:\n"
        report += "  Total Hits: \(totalHits)\n"
        report += "  Total Misses: \(totalMisses)\n"
        report += "  Overall Hit Rate: \(String(format: "%.1f%%", overallRate * 100))\n"
        report += "  Active Entries: \(cache.count)\n"
        
        return report
    }
    
    /// Returns cache statistics as a dictionary
    ///
    /// - Returns: Dictionary with cache metrics
    func statistics() -> [String: Any] {
        let totalHits = hits.values.reduce(0, +)
        let totalMisses = misses.values.reduce(0, +)
        let total = totalHits + totalMisses
        let overallRate = total > 0 ? Double(totalHits) / Double(total) : 0
        
        return [
            "totalHits": totalHits,
            "totalMisses": totalMisses,
            "overallHitRate": overallRate,
            "activeEntries": cache.count,
            "trackedKeys": hits.keys.count + misses.keys.count
        ]
    }
    
    /// Returns cache keys (for backward compatibility)
    ///
    /// - Returns: Dictionary with cache keys
    func stats() -> [String: Any] {
        // Return a dictionary with keys property for backward compatibility
        return ["keys": Array(cache.keys)]
    }
}

// MARK: - String Extension for Report Formatting

private extension String {
    static func * (left: String, right: Int) -> String {
        String(repeating: left, count: right)
    }
}
