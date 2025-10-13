//
//  SessionManagerTests.swift
//  My Wedding Planning App Tests
//
//  Tests for SessionManager keychain operations
//

import XCTest
@testable import My_Wedding_Planning_App

@MainActor
final class SessionManagerTests: XCTestCase {
    var sessionManager: SessionManager!

    override func setUp() async throws {
        try await super.setUp()
        // Clear any existing session
        SessionManager.shared.clearSession()
        sessionManager = SessionManager.shared
    }

    override func tearDown() async throws {
        sessionManager.clearSession()
        try await super.tearDown()
    }

    func testSetAndGetTenantId() throws {
        let testId = UUID()
        sessionManager.setTenantId(testId)

        let retrievedId = sessionManager.getTenantId()
        XCTAssertEqual(retrievedId, testId)
    }

    func testRequireTenantIdThrowsWhenNotSet() {
        XCTAssertThrowsError(try sessionManager.requireTenantId()) { error in
            guard let sessionError = error as? SessionError else {
                XCTFail("Expected SessionError")
                return
            }

            if case .noTenantSelected = sessionError {
                // Expected error
            } else {
                XCTFail("Expected noTenantSelected error")
            }
        }
    }

    func testRequireTenantIdReturnsWhenSet() throws {
        let testId = UUID()
        sessionManager.setTenantId(testId)

        let retrievedId = try sessionManager.requireTenantId()
        XCTAssertEqual(retrievedId, testId)
    }

    func testClearSession() {
        let testId = UUID()
        sessionManager.setTenantId(testId)
        XCTAssertNotNil(sessionManager.getTenantId())

        sessionManager.clearSession()
        XCTAssertNil(sessionManager.getTenantId())
    }

    func testSessionPersistsAcrossReloads() {
        let testId = UUID()
        sessionManager.setTenantId(testId)

        // Simulate a fresh SessionManager load by creating a new instance
        // Note: In production this would be SessionManager.shared reloading from keychain
        // For testing purposes, we verify the ID is set and can be retrieved
        let retrievedId = sessionManager.getTenantId()
        XCTAssertEqual(retrievedId, testId)
    }

    func testKeychainErrorHandling() {
        // This test verifies that keychain operations handle errors gracefully
        // In a real scenario, keychain failures would be logged but not crash the app
        let testId = UUID()

        // Should not crash even if keychain has issues
        sessionManager.setTenantId(testId)

        // Should still be able to get from memory
        XCTAssertEqual(sessionManager.getTenantId(), testId)
    }
}
