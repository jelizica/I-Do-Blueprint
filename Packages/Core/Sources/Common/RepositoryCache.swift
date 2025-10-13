import Foundation

/// Thread-safe caching layer for repository data
public actor RepositoryCache {
    private var storage: [String: CacheEntry] = [:]

    private struct CacheEntry {
        let data: Any
        let timestamp: Date
    }

    public init() {}

    /// Store a value in the cache
    public func set<T>(_ value: T, forKey key: String) {
        storage[key] = CacheEntry(data: value, timestamp: Date())
    }

    /// Retrieve a value from the cache if it exists and hasn't expired
    /// - Parameters:
    ///   - key: Cache key
    ///   - maxAge: Maximum age in seconds (default: 300 = 5 minutes)
    public func get<T>(_ key: String, maxAge: TimeInterval = 300) -> T? {
        guard let entry = storage[key] else {
            return nil
        }

        let age = Date().timeIntervalSince(entry.timestamp)
        guard age < maxAge else {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry.data as? T
    }

    /// Remove a specific key from the cache
    public func remove(_ key: String) {
        storage.removeValue(forKey: key)
    }

    /// Clear all cached data
    public func clear() {
        storage.removeAll()
    }

    /// Remove all expired entries
    public func cleanupExpired(maxAge: TimeInterval = 300) {
        let now = Date()
        storage = storage.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) < maxAge
        }
    }
}

// MARK: - Cache Key Helpers
extension RepositoryCache {
    /// Generate a cache key with optional parameters
    public static func key(_ components: String...) -> String {
        components.joined(separator: ":")
    }
}
