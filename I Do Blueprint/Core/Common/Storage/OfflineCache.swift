//
//  OfflineCache.swift
//  I Do Blueprint
//
//  Thread-safe offline cache with TTL and disk persistence
//

import Foundation

/// Thread-safe cache for offline mode with memory and disk storage
actor OfflineCache {
    // MARK: - Properties

    private var memoryCache: [String: CacheEntry] = [:]
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Types

    struct CacheEntry {
        let data: Data
        let timestamp: Date
        let expiresAt: Date?

        var isExpired: Bool {
            guard let expiresAt = expiresAt else { return false }
            return Date() > expiresAt
        }
    }

    // MARK: - Initialization

    init() {
        // Get cache directory
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("OfflineCache", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure encoder/decoder
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Public Methods

    /// Saves a value to the cache with optional TTL
    /// - Parameters:
    ///   - value: The value to cache (must be Codable)
    ///   - key: The cache key
    ///   - ttl: Time-to-live in seconds (nil for no expiration)
    func save<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) async throws {
        // Encode value
        let data = try encoder.encode(value)

        // Calculate expiration
        let expiresAt = ttl.map { Date().addingTimeInterval($0) }

        // Create cache entry
        let entry = CacheEntry(data: data, timestamp: Date(), expiresAt: expiresAt)

        // Save to memory cache
        memoryCache[key] = entry

        // Persist to disk
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try data.write(to: fileURL)

        AppLogger.cache.debug("Cached \(key) (TTL: \(ttl ?? 0)s)")
    }

    /// Loads a value from the cache
    /// - Parameters:
    ///   - type: The type to decode
    ///   - key: The cache key
    /// - Returns: The cached value, or nil if not found or expired
    func load<T: Codable>(_ type: T.Type, forKey key: String) async -> T? {
        // Check memory cache first
        if let entry = memoryCache[key] {
            // Check if expired
            if entry.isExpired {
                AppLogger.cache.debug("Cache expired for \(key)")
                memoryCache.removeValue(forKey: key)
                try? fileManager.removeItem(at: cacheDirectory.appendingPathComponent(key))
                return nil
            }

            // Decode from memory
            if let value = try? decoder.decode(T.self, from: entry.data) {
                AppLogger.cache.debug("Cache hit (memory) for \(key)")
                return value
            }
        }

        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL) else {
            AppLogger.cache.debug("Cache miss for \(key)")
            return nil
        }

        // Decode from disk
        guard let value = try? decoder.decode(T.self, from: data) else {
            AppLogger.cache.debug("Failed to decode cache for \(key)")
            return nil
        }

        // Restore to memory cache (no expiration info available from disk)
        let entry = CacheEntry(data: data, timestamp: Date(), expiresAt: nil)
        memoryCache[key] = entry

        AppLogger.cache.debug("Cache hit (disk) for \(key)")
        return value
    }

    /// Invalidates specific cache keys
    /// - Parameter keys: The keys to invalidate
    func invalidate(keys: [String]) async {
        for key in keys {
            memoryCache.removeValue(forKey: key)
            let fileURL = cacheDirectory.appendingPathComponent(key)
            try? fileManager.removeItem(at: fileURL)
        }
        AppLogger.cache.debug("Invalidated \(keys.count) cache keys")
    }

    /// Invalidates a single cache key
    /// - Parameter key: The key to invalidate
    func invalidate(key: String) async {
        await invalidate(keys: [key])
    }

    /// Clears all cached data
    func clear() async {
        memoryCache.removeAll()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        AppLogger.cache.info("Cleared all cache")
    }

    /// Returns cache statistics
    func stats() async -> CacheStats {
        let memoryCacheSize = memoryCache.count
        let diskCacheCount = (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil))?.count ?? 0

        let diskCacheSize: Int64 = {
            guard let urls = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
                return 0
            }
            return urls.reduce(0) { total, url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return total + Int64(size)
            }
        }()

        return CacheStats(
            memoryCacheCount: memoryCacheSize,
            diskCacheCount: diskCacheCount,
            diskCacheBytes: diskCacheSize
        )
    }
}

// MARK: - Cache Statistics

struct CacheStats {
    let memoryCacheCount: Int
    let diskCacheCount: Int
    let diskCacheBytes: Int64

    var diskCacheMB: Double {
        Double(diskCacheBytes) / 1_048_576.0
    }
}

