import Foundation

/// Registry to track all repository caches for global clearing
actor RepositoryCacheRegistry {
    static let shared = RepositoryCacheRegistry()

    private var caches: [RepositoryCache] = []

    private init() {}

    /// Register a cache instance
    func register(_ cache: RepositoryCache) {
        caches.append(cache)
    }

    /// Clear all registered caches
    func clearAll() async {
        for cache in caches {
            await cache.clear()
        }
    }
}

/// Simple in-memory cache for repository data
/// Provides automatic expiration based on maxAge parameter
actor RepositoryCache {
    private struct CachedValue<T> {
        let value: T
        let timestamp: Date

        func isValid(maxAge: TimeInterval) -> Bool {
            Date().timeIntervalSince(timestamp) < maxAge
        }
    }

    private var storage: [String: Any] = [:]

    /// Initialize and register with the global registry
    init() {
        Task {
            await RepositoryCacheRegistry.shared.register(self)
        }
    }

    /// Get a cached value if it exists and is still valid
    /// - Parameters:
    ///   - key: Cache key
    ///   - maxAge: Maximum age in seconds (default: 300 = 5 minutes)
    /// - Returns: Cached value if valid, nil otherwise
    func get<T>(_ key: String, maxAge: TimeInterval = 300) -> T? {
        guard let cached = storage[key] as? CachedValue<T>,
              cached.isValid(maxAge: maxAge) else {
            return nil
        }
        return cached.value
    }

    /// Store a value in the cache with current timestamp
    /// - Parameters:
    ///   - key: Cache key
    ///   - value: Value to cache
    func set<T>(_ key: String, value: T) {
        storage[key] = CachedValue(value: value, timestamp: Date())
    }

    /// Remove a specific cached value
    /// - Parameter key: Cache key to remove
    func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }

    /// Clear all cached values in this instance
    func clear() {
        storage.removeAll()
    }

    /// Clear all cached values across all repository instances
    static func clearAll() async {
        await RepositoryCacheRegistry.shared.clearAll()
    }

    /// Get cache statistics for debugging
    func stats() -> (count: Int, keys: [String]) {
        (count: storage.count, keys: Array(storage.keys))
    }
}
