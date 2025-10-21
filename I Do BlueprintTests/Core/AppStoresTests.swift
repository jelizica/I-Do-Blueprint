//
//  AppStoresTests.swift
//  I Do BlueprintTests
//
//  Tests for AppStores lazy loading and memory management
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class AppStoresTests: XCTestCase {
    
    var stores: AppStores!
    
    override func setUp() async throws {
        try await super.setUp()
        stores = AppStores.shared
        
        // Clear all stores before each test
        await stores.clearAll()
    }
    
    override func tearDown() async throws {
        // Clean up after each test
        await stores.clearAll()
        try await super.tearDown()
    }
    
    // MARK: - Lazy Loading Tests
    
    func testLazyLoading_OnlySettingsCreatedOnInit() {
        // Given: AppStores is initialized
        // When: We check loaded stores
        let loaded = stores.loadedStores()
        
        // Then: Only settings should be loaded initially
        XCTAssertEqual(loaded.count, 1, "Only settings store should be loaded on init")
        XCTAssertTrue(loaded.contains("Settings"), "Settings store should be loaded")
    }
    
    func testLazyLoading_BudgetStoreCreatedOnAccess() {
        // Given: AppStores with only settings loaded
        var initialLoaded = stores.loadedStores()
        XCTAssertFalse(initialLoaded.contains("Budget"), "Budget store should not be loaded initially")
        
        // When: We access budget store
        _ = stores.budget
        
        // Then: Budget store should now be loaded
        let loaded = stores.loadedStores()
        XCTAssertTrue(loaded.contains("Budget"), "Budget store should be loaded after access")
    }
    
    func testLazyLoading_GuestStoreCreatedOnAccess() {
        // Given: AppStores with only settings loaded
        var initialLoaded = stores.loadedStores()
        XCTAssertFalse(initialLoaded.contains("Guest"), "Guest store should not be loaded initially")
        
        // When: We access guest store
        _ = stores.guest
        
        // Then: Guest store should now be loaded
        let loaded = stores.loadedStores()
        XCTAssertTrue(loaded.contains("Guest"), "Guest store should be loaded after access")
    }
    
    func testLazyLoading_VendorStoreCreatedOnAccess() {
        // Given: AppStores with only settings loaded
        var initialLoaded = stores.loadedStores()
        XCTAssertFalse(initialLoaded.contains("Vendor"), "Vendor store should not be loaded initially")
        
        // When: We access vendor store
        _ = stores.vendor
        
        // Then: Vendor store should now be loaded
        let loaded = stores.loadedStores()
        XCTAssertTrue(loaded.contains("Vendor"), "Vendor store should be loaded after access")
    }
    
    func testLazyLoading_DocumentStoreCreatedOnAccess() {
        // Given: AppStores with only settings loaded
        var initialLoaded = stores.loadedStores()
        XCTAssertFalse(initialLoaded.contains("Document"), "Document store should not be loaded initially")
        
        // When: We access document store
        _ = stores.document
        
        // Then: Document store should now be loaded
        let loaded = stores.loadedStores()
        XCTAssertTrue(loaded.contains("Document"), "Document store should be loaded after access")
    }
    
    func testLazyLoading_TaskStoreCreatedOnAccess() {
        // Given: AppStores with only settings loaded
        var initialLoaded = stores.loadedStores()
        XCTAssertFalse(initialLoaded.contains("Task"), "Task store should not be loaded initially")
        
        // When: We access task store
        _ = stores.task
        
        // Then: Task store should now be loaded
        let loaded = stores.loadedStores()
        XCTAssertTrue(loaded.contains("Task"), "Task store should be loaded after access")
    }
    
    func testLazyLoading_TimelineStoreCreatedOnAccess() {
        // Given: AppStores with only settings loaded
        var initialLoaded = stores.loadedStores()
        XCTAssertFalse(initialLoaded.contains("Timeline"), "Timeline store should not be loaded initially")
        
        // When: We access timeline store
        _ = stores.timeline
        
        // Then: Timeline store should now be loaded
        let loaded = stores.loadedStores()
        XCTAssertTrue(loaded.contains("Timeline"), "Timeline store should be loaded after access")
    }
    
    func testLazyLoading_NotesStoreCreatedOnAccess() {
        // Given: AppStores with only settings loaded
        var initialLoaded = stores.loadedStores()
        XCTAssertFalse(initialLoaded.contains("Notes"), "Notes store should not be loaded initially")
        
        // When: We access notes store
        _ = stores.notes
        
        // Then: Notes store should now be loaded
        let loaded = stores.loadedStores()
        XCTAssertTrue(loaded.contains("Notes"), "Notes store should be loaded after access")
    }
    
    func testLazyLoading_VisualPlanningStoreCreatedOnAccess() {
        // Given: AppStores with only settings loaded
        var initialLoaded = stores.loadedStores()
        XCTAssertFalse(initialLoaded.contains("VisualPlanning"), "VisualPlanning store should not be loaded initially")
        
        // When: We access visual planning store
        _ = stores.visualPlanning
        
        // Then: Visual planning store should now be loaded
        let loaded = stores.loadedStores()
        XCTAssertTrue(loaded.contains("VisualPlanning"), "VisualPlanning store should be loaded after access")
    }
    
    func testLazyLoading_MultipleStoresCreatedOnDemand() {
        // Given: AppStores with only settings loaded
        let initialLoaded = stores.loadedStores()
        XCTAssertEqual(initialLoaded.count, 1, "Only settings should be loaded initially")
        
        // When: We access multiple stores
        _ = stores.budget
        _ = stores.guest
        _ = stores.vendor
        
        // Then: All accessed stores should be loaded
        let loaded = stores.loadedStores()
        XCTAssertTrue(loaded.contains("Budget"), "Budget store should be loaded")
        XCTAssertTrue(loaded.contains("Guest"), "Guest store should be loaded")
        XCTAssertTrue(loaded.contains("Vendor"), "Vendor store should be loaded")
        XCTAssertTrue(loaded.contains("Settings"), "Settings store should still be loaded")
        XCTAssertEqual(loaded.count, 4, "Should have 4 stores loaded")
    }
    
    // MARK: - Clear All Tests
    
    func testClearAll_ReleasesAllStoresExceptSettings() async {
        // Given: Multiple stores loaded
        _ = stores.budget
        _ = stores.guest
        _ = stores.vendor
        
        let beforeClear = stores.loadedStores()
        XCTAssertTrue(beforeClear.count > 1, "Multiple stores should be loaded")
        
        // When: We clear all stores
        await stores.clearAll()
        
        // Then: Only settings should remain
        let afterClear = stores.loadedStores()
        XCTAssertEqual(afterClear.count, 1, "Only settings should remain after clearAll")
        XCTAssertTrue(afterClear.contains("Settings"), "Settings store should be retained")
        XCTAssertFalse(afterClear.contains("Budget"), "Budget store should be released")
        XCTAssertFalse(afterClear.contains("Guest"), "Guest store should be released")
        XCTAssertFalse(afterClear.contains("Vendor"), "Vendor store should be released")
    }
    
    func testClearAll_StoresCanBeReloadedAfterClear() async {
        // Given: Budget store loaded and then cleared
        _ = stores.budget
        XCTAssertTrue(stores.loadedStores().contains("Budget"))
        
        await stores.clearAll()
        XCTAssertFalse(stores.loadedStores().contains("Budget"))
        
        // When: We access budget store again
        _ = stores.budget
        
        // Then: Budget store should be loaded again
        XCTAssertTrue(stores.loadedStores().contains("Budget"), "Budget store should be reloadable after clear")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryPressure_ReleasesVisualPlanningStore() async {
        // Given: Visual planning store is loaded
        _ = stores.visualPlanning
        XCTAssertTrue(stores.loadedStores().contains("VisualPlanning"), "VisualPlanning should be loaded")
        
        // When: We simulate memory pressure
        await stores.handleMemoryPressure()
        
        // Then: Visual planning store should be released
        XCTAssertFalse(stores.loadedStores().contains("VisualPlanning"), "VisualPlanning should be released under memory pressure")
    }
    
    func testMemoryPressure_RetainsOtherStores() async {
        // Given: Multiple stores loaded including visual planning
        _ = stores.budget
        _ = stores.guest
        _ = stores.visualPlanning
        
        let beforePressure = stores.loadedStores()
        XCTAssertTrue(beforePressure.contains("Budget"))
        XCTAssertTrue(beforePressure.contains("Guest"))
        XCTAssertTrue(beforePressure.contains("VisualPlanning"))
        
        // When: We handle memory pressure
        await stores.handleMemoryPressure()
        
        // Then: Other stores should be retained (only visual planning released)
        let afterPressure = stores.loadedStores()
        XCTAssertTrue(afterPressure.contains("Budget"), "Budget store should be retained")
        XCTAssertTrue(afterPressure.contains("Guest"), "Guest store should be retained")
        XCTAssertFalse(afterPressure.contains("VisualPlanning"), "VisualPlanning should be released")
    }
    
    // MARK: - Memory Stats Tests
    
    func testGetMemoryStats_ReturnsCorrectFormat() {
        // Given: Some stores loaded
        _ = stores.budget
        _ = stores.guest
        
        // When: We get memory stats
        let stats = stores.getMemoryStats()
        
        // Then: Stats should contain expected information
        XCTAssertTrue(stats.contains("AppStores Memory Stats"), "Stats should have header")
        XCTAssertTrue(stats.contains("Loaded Stores:"), "Stats should list loaded stores")
        XCTAssertTrue(stats.contains("Total Loaded:"), "Stats should show total count")
        XCTAssertTrue(stats.contains("Memory Usage:"), "Stats should show memory usage")
    }
    
    func testLoadedStores_ReturnsCorrectStores() {
        // Given: Specific stores loaded
        _ = stores.budget
        _ = stores.vendor
        _ = stores.task
        
        // When: We get loaded stores
        let loaded = stores.loadedStores()
        
        // Then: Should return exactly the loaded stores
        XCTAssertTrue(loaded.contains("Budget"))
        XCTAssertTrue(loaded.contains("Vendor"))
        XCTAssertTrue(loaded.contains("Task"))
        XCTAssertTrue(loaded.contains("Settings"))
        XCTAssertFalse(loaded.contains("Guest"))
        XCTAssertFalse(loaded.contains("Document"))
        XCTAssertFalse(loaded.contains("Timeline"))
        XCTAssertFalse(loaded.contains("Notes"))
        XCTAssertFalse(loaded.contains("VisualPlanning"))
    }
    
    // MARK: - Store Identity Tests
    
    func testStoreIdentity_SameInstanceReturnedOnMultipleAccess() {
        // Given: First access to budget store
        let firstAccess = stores.budget
        
        // When: We access budget store again
        let secondAccess = stores.budget
        
        // Then: Should return the same instance
        XCTAssertTrue(firstAccess === secondAccess, "Should return same store instance")
    }
    
    func testStoreIdentity_NewInstanceAfterClear() async {
        // Given: Budget store loaded
        let firstInstance = stores.budget
        
        // When: We clear and reload
        await stores.clearAll()
        let secondInstance = stores.budget
        
        // Then: Should be a new instance
        XCTAssertFalse(firstInstance === secondInstance, "Should create new instance after clear")
    }
}
