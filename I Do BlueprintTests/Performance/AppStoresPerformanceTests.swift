//
//  AppStoresPerformanceTests.swift
//  I Do BlueprintTests
//
//  Performance tests for AppStores lazy loading
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class AppStoresPerformanceTests: XCTestCase {
    
    var stores: AppStores!
    
    override func setUp() async throws {
        try await super.setUp()
        stores = AppStores.shared
        await stores.clearAll()
    }
    
    override func tearDown() async throws {
        await stores.clearAll()
        try await super.tearDown()
    }
    
    // MARK: - Initialization Performance
    
    func testPerformance_AppStoresInitialization() {
        // Test that AppStores initialization is fast with lazy loading
        measure {
            // Access the singleton (should be very fast since stores are lazy)
            _ = AppStores.shared
        }
        
        // With lazy loading, initialization should complete in < 10ms
    }
    
    func testPerformance_SettingsStoreAccess() {
        // Test that accessing settings store is fast
        measure {
            _ = stores.settings
        }
        
        // Settings store is pre-loaded, so access should be instant
    }
    
    // MARK: - Store Creation Performance
    
    func testPerformance_BudgetStoreFirstAccess() async {
        // Clear to ensure fresh state
        await stores.clearAll()
        
        // Test first access to budget store
        measure {
            _ = stores.budget
        }
        
        // First access creates the store, should complete in < 100ms
    }
    
    func testPerformance_BudgetStoreSubsequentAccess() {
        // Given: Budget store already loaded
        _ = stores.budget
        
        // Test subsequent access
        measure {
            _ = stores.budget
        }
        
        // Subsequent access should be instant (< 1ms)
    }
    
    func testPerformance_MultipleStoreAccess() async {
        // Clear to ensure fresh state
        await stores.clearAll()
        
        // Test accessing multiple stores
        measure {
            _ = stores.budget
            _ = stores.guest
            _ = stores.vendor
            _ = stores.task
        }
        
        // Creating 4 stores should complete in < 400ms
    }
    
    // MARK: - Memory Management Performance
    
    func testPerformance_ClearAll() async {
        // Given: Multiple stores loaded
        _ = stores.budget
        _ = stores.guest
        _ = stores.vendor
        _ = stores.document
        _ = stores.task
        
        // Test clearAll performance
        measure {
            Task {
                await stores.clearAll()
            }
        }
        
        // Clearing all stores should complete in < 50ms
    }
    
    func testPerformance_HandleMemoryPressure() async {
        // Given: Visual planning store loaded
        _ = stores.visualPlanning
        
        // Test memory pressure handling
        measure {
            Task {
                await stores.handleMemoryPressure()
            }
        }
        
        // Handling memory pressure should complete in < 50ms
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsage_WithLazyLoading() async {
        // Given: Fresh AppStores
        await stores.clearAll()
        
        // Measure memory before loading stores
        let initialMemory = getMemoryUsage()
        
        // Load several stores
        _ = stores.budget
        _ = stores.guest
        _ = stores.vendor
        
        // Measure memory after loading
        let finalMemory = getMemoryUsage()
        let increase = finalMemory - initialMemory
        let increaseMB = increase / 1_000_000
        
        // Memory increase should be reasonable (< 100MB for 3 stores)
        XCTAssertLessThan(increaseMB, 100, "Memory increase should be less than 100MB for 3 stores")
        
        print("Memory increase: \(increaseMB) MB for 3 stores")
    }
    
    func testMemoryUsage_AfterClearAll() async {
        // Given: Multiple stores loaded
        _ = stores.budget
        _ = stores.guest
        _ = stores.vendor
        _ = stores.document
        
        let beforeClear = getMemoryUsage()
        
        // When: We clear all stores
        await stores.clearAll()
        
        // Give system time to reclaim memory
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        let afterClear = getMemoryUsage()
        
        // Then: Memory should be reduced (or at least not increased)
        XCTAssertLessThanOrEqual(afterClear, beforeClear + 10_000_000, "Memory should not increase significantly after clearAll")
        
        print("Memory before clear: \(beforeClear / 1_000_000) MB")
        print("Memory after clear: \(afterClear / 1_000_000) MB")
    }
    
    // MARK: - Comparison Tests
    
    func testMemoryComparison_LazyVsEager() async {
        // This test demonstrates the memory savings of lazy loading
        
        // Scenario 1: Lazy loading (current implementation)
        await stores.clearAll()
        let lazyMemory = getMemoryUsage()
        let lazyLoaded = stores.loadedStores().count
        
        // Scenario 2: Simulate eager loading by accessing all stores
        _ = stores.budget
        _ = stores.guest
        _ = stores.vendor
        _ = stores.document
        _ = stores.task
        _ = stores.timeline
        _ = stores.notes
        _ = stores.visualPlanning
        
        let eagerMemory = getMemoryUsage()
        let eagerLoaded = stores.loadedStores().count
        
        let memoryDifference = eagerMemory - lazyMemory
        let memoryDifferenceMB = memoryDifference / 1_000_000
        
        print("Lazy loading: \(lazyLoaded) stores, \(lazyMemory / 1_000_000) MB")
        print("Eager loading: \(eagerLoaded) stores, \(eagerMemory / 1_000_000) MB")
        print("Memory savings with lazy loading: \(memoryDifferenceMB) MB")
        
        // Lazy loading should use significantly less memory initially
        XCTAssertLessThan(lazyLoaded, eagerLoaded, "Lazy loading should have fewer stores loaded")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}
