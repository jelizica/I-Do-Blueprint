//
//  RepositoryCacheTests.swift
//  I Do BlueprintTests
//
//  Tests for RepositoryCache
//  Part of JES-60: Performance Optimization
//

import XCTest
@testable import I_Do_Blueprint

final class RepositoryCacheTests: XCTestCase {
    
    var cache: RepositoryCache!
    
    override func setUp() async throws {
        cache = RepositoryCache.shared
        await cache.clear()
    }
    
    override func tearDown() async throws {
        await cache.clear()
    }
    
    // MARK: - Basic Caching Tests
    
    func test_setAndGet_StoresAndRetrievesValue() async throws {
        // Given
        let testData = ["item1", "item2", "item3"]
        
        // When
        await cache.set("test_key", value: testData, ttl: 60)
        let retrieved: [String]? = await cache.get("test_key")
        
        // Then
        XCTAssertEqual(retrieved, testData)
    }
    
    func test_get_ReturnsNilForNonexistentKey() async throws {
        // When
        let retrieved: [String]? = await cache.get("nonexistent_key")
        
        // Then
        XCTAssertNil(retrieved)
    }
    
    func test_get_ReturnsNilForExpiredEntry() async throws {
        // Given
        let testData = ["item1", "item2"]
        await cache.set("test_key", value: testData, ttl: 0.1) // 100ms TTL
        
        // When
        try await Task.sleep(nanoseconds: 200_000_000) // Sleep 200ms
        let retrieved: [String]? = await cache.get("test_key")
        
        // Then
        XCTAssertNil(retrieved, "Expired cache entry should return nil")
    }
    
    func test_get_WithMaxAge_OverridesTTL() async throws {
        // Given
        let testData = ["item1"]
        await cache.set("test_key", value: testData, ttl: 60) // 60s TTL
        
        // When - immediately check with 0s maxAge
        let retrieved: [String]? = await cache.get("test_key", maxAge: 0)
        
        // Then
        XCTAssertNil(retrieved, "maxAge of 0 should treat entry as expired")
    }
    
    // MARK: - Invalidation Tests
    
    func test_invalidate_RemovesSpecificKey() async throws {
        // Given
        await cache.set("key1", value: "value1", ttl: 60)
        await cache.set("key2", value: "value2", ttl: 60)
        
        // When
        await cache.invalidate("key1")
        
        // Then
        let retrieved1: String? = await cache.get("key1")
        let retrieved2: String? = await cache.get("key2")
        
        XCTAssertNil(retrieved1)
        XCTAssertEqual(retrieved2, "value2")
    }
    
    func test_invalidatePrefix_RemovesMatchingKeys() async throws {
        // Given
        await cache.set("guests_123", value: "guest1", ttl: 60)
        await cache.set("guests_456", value: "guest2", ttl: 60)
        await cache.set("vendors_789", value: "vendor1", ttl: 60)
        
        // When
        await cache.invalidatePrefix("guests_")
        
        // Then
        let guest1: String? = await cache.get("guests_123")
        let guest2: String? = await cache.get("guests_456")
        let vendor: String? = await cache.get("vendors_789")
        
        XCTAssertNil(guest1)
        XCTAssertNil(guest2)
        XCTAssertEqual(vendor, "vendor1")
    }
    
    func test_clear_RemovesAllEntries() async throws {
        // Given
        await cache.set("key1", value: "value1", ttl: 60)
        await cache.set("key2", value: "value2", ttl: 60)
        await cache.set("key3", value: "value3", ttl: 60)
        
        // When
        await cache.clear()
        
        // Then
        let retrieved1: String? = await cache.get("key1")
        let retrieved2: String? = await cache.get("key2")
        let retrieved3: String? = await cache.get("key3")
        
        XCTAssertNil(retrieved1)
        XCTAssertNil(retrieved2)
        XCTAssertNil(retrieved3)
    }
    
    // MARK: - Metrics Tests
    
    func test_hitRate_CalculatesCorrectly() async throws {
        // Given
        await cache.set("test_key", value: "test_value", ttl: 60)
        
        // When - 3 hits, 2 misses
        let _: String? = await cache.get("test_key") // hit
        let _: String? = await cache.get("test_key") // hit
        let _: String? = await cache.get("test_key") // hit
        let _: String? = await cache.get("nonexistent1") // miss
        let _: String? = await cache.get("nonexistent2") // miss
        
        // Then
        let hitRate = await cache.hitRate(for: "test_key")
        XCTAssertEqual(hitRate, 1.0, accuracy: 0.01) // 3/3 = 100%
        
        let missRate = await cache.hitRate(for: "nonexistent1")
        XCTAssertEqual(missRate, 0.0, accuracy: 0.01) // 0/1 = 0%
    }
    
    func test_statistics_ReturnsCorrectMetrics() async throws {
        // Given
        await cache.set("key1", value: "value1", ttl: 60)
        await cache.set("key2", value: "value2", ttl: 60)
        
        // Generate some cache activity
        let _: String? = await cache.get("key1") // hit
        let _: String? = await cache.get("key1") // hit
        let _: String? = await cache.get("key3") // miss
        
        // When
        let stats = await cache.statistics()
        
        // Then
        XCTAssertEqual(stats["totalHits"] as? Int, 2)
        XCTAssertEqual(stats["totalMisses"] as? Int, 1)
        XCTAssertEqual(stats["activeEntries"] as? Int, 2)
        
        let overallRate = stats["overallHitRate"] as? Double ?? 0
        XCTAssertEqual(overallRate, 2.0/3.0, accuracy: 0.01)
    }
    
    func test_performanceReport_GeneratesReport() async throws {
        // Given
        await cache.set("test_key", value: "test_value", ttl: 60)
        let _: String? = await cache.get("test_key")
        
        // When
        let report = await cache.performanceReport()
        
        // Then
        XCTAssertTrue(report.contains("Cache Performance Report"))
        XCTAssertTrue(report.contains("test_key"))
    }
    
    // MARK: - Type Safety Tests
    
    func test_get_ReturnsNilForWrongType() async throws {
        // Given
        await cache.set("test_key", value: ["string1", "string2"], ttl: 60)
        
        // When - try to retrieve as wrong type
        let retrieved: [Int]? = await cache.get("test_key")
        
        // Then
        XCTAssertNil(retrieved, "Should return nil when type doesn't match")
    }
    
    func test_cache_HandlesComplexTypes() async throws {
        // Given
        struct TestModel: Codable, Equatable {
            let id: String
            let name: String
            let count: Int
        }
        
        let testModel = TestModel(id: "123", name: "Test", count: 42)
        
        // When
        await cache.set("complex_key", value: testModel, ttl: 60)
        let retrieved: TestModel? = await cache.get("complex_key")
        
        // Then
        XCTAssertEqual(retrieved, testModel)
    }
    
    // MARK: - Cleanup Tests
    
    func test_cleanupExpired_RemovesExpiredEntries() async throws {
        // Given
        await cache.set("key1", value: "value1", ttl: 0.1) // 100ms
        await cache.set("key2", value: "value2", ttl: 60) // 60s
        
        // When
        try await Task.sleep(nanoseconds: 200_000_000) // Sleep 200ms
        await cache.cleanupExpired()
        
        // Then
        let retrieved1: String? = await cache.get("key1")
        let retrieved2: String? = await cache.get("key2")
        
        XCTAssertNil(retrieved1)
        XCTAssertEqual(retrieved2, "value2")
    }
}
