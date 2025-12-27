//
//  PaymentTypeMigrationTests.swift
//  I Do BlueprintTests
//
//  Tests for payment_type migration from legacy values to new canonical values
//

import XCTest
@testable import I_Do_Blueprint

final class PaymentTypeMigrationTests: XCTestCase {
    
    // MARK: - Backward Compatibility Tests
    
    func test_fromDatabaseValue_newCanonicalValues() {
        // Test that new canonical values work correctly
        XCTAssertEqual(PaymentType(fromDatabaseValue: "individual"), .individual)
        XCTAssertEqual(PaymentType(fromDatabaseValue: "monthly"), .monthly)
        XCTAssertEqual(PaymentType(fromDatabaseValue: "interval"), .interval)
        XCTAssertEqual(PaymentType(fromDatabaseValue: "cyclical"), .cyclical)
    }
    
    func test_fromDatabaseValue_legacySingleValue() {
        // Test that legacy "single" maps to "individual"
        let result = PaymentType(fromDatabaseValue: "single")
        XCTAssertEqual(result, .individual, "Legacy 'single' should map to .individual")
    }
    
    func test_fromDatabaseValue_legacyCustomValue() {
        // Test that legacy "custom" maps to "interval" (simple fallback for backward compatibility)
        // Note: This is the simple fallback used by fromDatabaseValue
        // For proper migration with context, use migrationSuggestion which defaults to .cyclical
        let result = PaymentType(fromDatabaseValue: "custom")
        XCTAssertEqual(result, .interval, "Legacy 'custom' should fallback to .interval for backward compatibility")
    }
    
    func test_fromDatabaseValue_depositAndRetainer() {
        // Test that deposit/retainer map to individual
        XCTAssertEqual(PaymentType(fromDatabaseValue: "deposit"), .individual)
        XCTAssertEqual(PaymentType(fromDatabaseValue: "retainer"), .individual)
    }
    
    func test_fromDatabaseValue_caseInsensitive() {
        // Test case insensitivity
        XCTAssertEqual(PaymentType(fromDatabaseValue: "INDIVIDUAL"), .individual)
        XCTAssertEqual(PaymentType(fromDatabaseValue: "Single"), .individual)
        XCTAssertEqual(PaymentType(fromDatabaseValue: "CUSTOM"), .interval)
    }
    
    func test_fromDatabaseValue_invalidValue() {
        // Test that invalid values return nil
        XCTAssertNil(PaymentType(fromDatabaseValue: "invalid"))
        XCTAssertNil(PaymentType(fromDatabaseValue: ""))
        XCTAssertNil(PaymentType(fromDatabaseValue: "unknown"))
    }
    
    // MARK: - Legacy Value Detection Tests
    
    func test_isLegacyValue_detectsLegacyValues() {
        XCTAssertTrue(PaymentType.isLegacyValue("single"))
        XCTAssertTrue(PaymentType.isLegacyValue("custom"))
        XCTAssertTrue(PaymentType.isLegacyValue("SINGLE"))
        XCTAssertTrue(PaymentType.isLegacyValue("Custom"))
    }
    
    func test_isLegacyValue_rejectsNewValues() {
        XCTAssertFalse(PaymentType.isLegacyValue("individual"))
        XCTAssertFalse(PaymentType.isLegacyValue("monthly"))
        XCTAssertFalse(PaymentType.isLegacyValue("interval"))
        XCTAssertFalse(PaymentType.isLegacyValue("cyclical"))
    }
    
    // MARK: - Migration Suggestion Tests
    
    func test_migrationSuggestion_singleToIndividual() {
        let result = PaymentType.migrationSuggestion(for: "single")
        XCTAssertEqual(result, .individual, "'single' should always migrate to .individual")
    }
    
    func test_migrationSuggestion_customWithSinglePayment() {
        let result = PaymentType.migrationSuggestion(
            for: "custom",
            paymentCount: 1
        )
        XCTAssertEqual(result, .individual, "'custom' with 1 payment should migrate to .individual")
    }
    
    func test_migrationSuggestion_customWithUniformAmounts() {
        let result = PaymentType.migrationSuggestion(
            for: "custom",
            paymentCount: 5,
            hasUniformAmounts: true
        )
        XCTAssertEqual(result, .interval, "'custom' with uniform amounts should migrate to .interval")
    }
    
    func test_migrationSuggestion_customWithVaryingAmounts() {
        let result = PaymentType.migrationSuggestion(
            for: "custom",
            paymentCount: 5,
            hasUniformAmounts: false
        )
        XCTAssertEqual(result, .cyclical, "'custom' with varying amounts should migrate to .cyclical")
    }
    
    func test_migrationSuggestion_customWithNoContext() {
        let result = PaymentType.migrationSuggestion(for: "custom")
        XCTAssertEqual(result, .cyclical, "'custom' with no context should default to .cyclical")
    }
    
    // MARK: - Database Value Tests
    
    func test_databaseValue_returnsCanonicalValues() {
        XCTAssertEqual(PaymentType.individual.databaseValue, "individual")
        XCTAssertEqual(PaymentType.monthly.databaseValue, "monthly")
        XCTAssertEqual(PaymentType.interval.databaseValue, "interval")
        XCTAssertEqual(PaymentType.cyclical.databaseValue, "cyclical")
    }
    
    func test_allDatabaseValues_includesLegacyValues() {
        let allValues = PaymentType.allDatabaseValues
        
        // Check new canonical values
        XCTAssertTrue(allValues.contains("individual"))
        XCTAssertTrue(allValues.contains("monthly"))
        XCTAssertTrue(allValues.contains("interval"))
        XCTAssertTrue(allValues.contains("cyclical"))
        
        // Check legacy values
        XCTAssertTrue(allValues.contains("single"))
        XCTAssertTrue(allValues.contains("custom"))
        
        // Check special types
        XCTAssertTrue(allValues.contains("deposit"))
        XCTAssertTrue(allValues.contains("retainer"))
    }
    
    // MARK: - Round-trip Tests
    
    func test_roundTrip_newValues() {
        // Test that new values can be written and read back
        let types: [PaymentType] = [.individual, .monthly, .interval, .cyclical]
        
        for type in types {
            let dbValue = type.databaseValue
            let decoded = PaymentType(fromDatabaseValue: dbValue)
            XCTAssertEqual(decoded, type, "Round-trip failed for \(type)")
        }
    }
    
    func test_roundTrip_legacyValues() {
        // Test that legacy values can be read and converted via fromDatabaseValue
        // Note: This tests the simple fallback behavior, not the context-aware migration
        let legacyMappings: [(String, PaymentType)] = [
            ("single", .individual),
            ("custom", .interval)  // fromDatabaseValue uses .interval as simple fallback
        ]
        
        for (legacyValue, expectedType) in legacyMappings {
            let decoded = PaymentType(fromDatabaseValue: legacyValue)
            XCTAssertEqual(decoded, expectedType, "Legacy value '\(legacyValue)' should map to \(expectedType)")
            
            // Verify the decoded type produces the correct new database value
            let newDbValue = decoded?.databaseValue
            XCTAssertNotEqual(newDbValue, legacyValue, "Should not produce legacy value")
        }
    }
    
    // MARK: - Migration Tracker Tests
    
    func test_migrationTracker_recordsLegacyValues() {
        let tracker = PaymentTypeMigrationTracker.shared
        tracker.reset()
        
        tracker.recordLegacyValue("single", paymentId: 1)
        tracker.recordLegacyValue("custom", paymentId: 2)
        tracker.recordLegacyValue("single", paymentId: 3)
        
        XCTAssertTrue(tracker.hasLegacyValues)
        
        let stats = tracker.getMigrationStats()
        let legacyValues = stats["legacyValuesFound"] as? [String] ?? []
        let counts = stats["migrationCounts"] as? [String: Int] ?? [:]
        
        XCTAssertTrue(legacyValues.contains("single"))
        XCTAssertTrue(legacyValues.contains("custom"))
        XCTAssertEqual(counts["single"], 2)
        XCTAssertEqual(counts["custom"], 1)
    }
    
    func test_migrationTracker_reset() {
        let tracker = PaymentTypeMigrationTracker.shared
        
        tracker.recordLegacyValue("single", paymentId: 1)
        XCTAssertTrue(tracker.hasLegacyValues)
        
        tracker.reset()
        XCTAssertFalse(tracker.hasLegacyValues)
        
        let stats = tracker.getMigrationStats()
        let total = stats["totalLegacyRecords"] as? Int ?? 0
        XCTAssertEqual(total, 0)
    }
    
    // MARK: - Edge Cases
    
    func test_edgeCases_emptyString() {
        XCTAssertNil(PaymentType(fromDatabaseValue: ""))
    }
    
    func test_edgeCases_whitespace() {
        XCTAssertNil(PaymentType(fromDatabaseValue: "   "))
    }
    
    func test_edgeCases_specialCharacters() {
        XCTAssertNil(PaymentType(fromDatabaseValue: "individual!"))
        XCTAssertNil(PaymentType(fromDatabaseValue: "single@"))
    }
    
    // MARK: - Integration Tests
    
    func test_integration_migrationWorkflow() {
        // Simulate a complete migration workflow
        
        // 1. Detect legacy value
        let legacyValue = "single"
        XCTAssertTrue(PaymentType.isLegacyValue(legacyValue))
        
        // 2. Convert to new type
        guard let newType = PaymentType(fromDatabaseValue: legacyValue) else {
            XCTFail("Failed to convert legacy value")
            return
        }
        XCTAssertEqual(newType, .individual)
        
        // 3. Get new database value
        let newDbValue = newType.databaseValue
        XCTAssertEqual(newDbValue, "individual")
        
        // 4. Verify new value is not legacy
        XCTAssertFalse(PaymentType.isLegacyValue(newDbValue))
        
        // 5. Verify new value can be read back
        let roundTrip = PaymentType(fromDatabaseValue: newDbValue)
        XCTAssertEqual(roundTrip, newType)
    }
    
    func test_integration_customDisambiguation() {
        // Test the full disambiguation workflow for "custom"
        
        let customValue = "custom"
        
        // Scenario 1: Single payment
        let suggestion1 = PaymentType.migrationSuggestion(
            for: customValue,
            paymentCount: 1
        )
        XCTAssertEqual(suggestion1, .individual)
        XCTAssertEqual(suggestion1.databaseValue, "individual")
        
        // Scenario 2: Multiple uniform payments
        let suggestion2 = PaymentType.migrationSuggestion(
            for: customValue,
            paymentCount: 5,
            hasUniformAmounts: true
        )
        XCTAssertEqual(suggestion2, .interval)
        XCTAssertEqual(suggestion2.databaseValue, "interval")
        
        // Scenario 3: Multiple varying payments
        let suggestion3 = PaymentType.migrationSuggestion(
            for: customValue,
            paymentCount: 5,
            hasUniformAmounts: false
        )
        XCTAssertEqual(suggestion3, .cyclical)
        XCTAssertEqual(suggestion3.databaseValue, "cyclical")
    }
}
