//
//  CacheableStore.swift
//  I Do Blueprint
//
//  Protocol and defaults for view-store level caching with TTL and manual invalidation.
//

import Foundation

/// Protocol for stores that support simple time-based caching
protocol CacheableStore: AnyObject {
    /// Last time data was successfully loaded
    var lastLoadTime: Date? { get set }
    /// How long cached data remains valid
    var cacheValidityDuration: TimeInterval { get }

    /// Returns true if cache is still considered fresh
    func isCacheValid() -> Bool
    /// Invalidates the cache so next load fetches fresh data
    func invalidateCache()
}

extension CacheableStore {
    func isCacheValid() -> Bool {
        guard let last = lastLoadTime else { return false }
        return Date().timeIntervalSince(last) < cacheValidityDuration
    }

    func invalidateCache() {
        lastLoadTime = nil
    }

    /// Helper: age of current cache in seconds
    func cacheAge() -> TimeInterval {
        guard let last = lastLoadTime else { return .infinity }
        return Date().timeIntervalSince(last)
    }
}
