//
//  NetworkRetryTests.swift
//  I Do BlueprintTests
//
//  Integration tests for NetworkRetry utility
//

import XCTest
@testable import I_Do_Blueprint

final class NetworkRetryTests: XCTestCase {

    // MARK: - Retry Behavior Tests

    func testRetrySucceedsOnThirdAttempt() async throws {
        var attemptCount = 0

        let result = try await NetworkRetry.withRetry(config: .default) {
            attemptCount += 1
            if attemptCount < 3 {
                throw NSError(domain: "Test", code: -1, userInfo: nil)
            }
            return "Success"
        }

        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attemptCount, 3)
    }

    func testRetryFailsAfterMaxAttempts() async {
        var attemptCount = 0

        do {
            _ = try await NetworkRetry.withRetry(
                config: RetryConfiguration(
                    maxAttempts: 3,
                    baseDelay: 0.1,
                    maxDelay: 1.0,
                    jitterFactor: 0.1
                )
            ) {
                attemptCount += 1
                throw NSError(domain: "Test", code: -1, userInfo: nil)
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual(attemptCount, 3)
        }
    }

    func testRetrySucceedsOnFirstAttempt() async throws {
        var attemptCount = 0

        let result = try await NetworkRetry.withRetry(config: .default) {
            attemptCount += 1
            return "Success"
        }

        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attemptCount, 1)
    }

    // MARK: - Timeout Behavior Tests

    func testTimeoutThrowsErrorAfterDelay() async {
        do {
            _ = try await NetworkRetry.withTimeout(seconds: 0.5) {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                return "Should not complete"
            }
            XCTFail("Should have thrown timeout error")
        } catch {
            XCTAssertTrue(error is NetworkError)
            if let networkError = error as? NetworkError {
                XCTAssertEqual(networkError, .timeout)
            }
        }
    }

    func testTimeoutSucceedsWithinDelay() async throws {
        let result = try await NetworkRetry.withTimeout(seconds: 2.0) {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            return "Success"
        }

        XCTAssertEqual(result, "Success")
    }

    // MARK: - Combined Retry and Timeout Tests

    func testRetryAndTimeoutSucceeds() async throws {
        var attemptCount = 0

        let result = try await NetworkRetry.withRetryAndTimeout(
            retryConfig: RetryConfiguration(
                maxAttempts: 3,
                baseDelay: 0.1,
                maxDelay: 1.0,
                jitterFactor: 0.1
            ),
            timeoutSeconds: 2.0
        ) {
            attemptCount += 1
            if attemptCount < 2 {
                throw NSError(domain: "Test", code: -1, userInfo: nil)
            }
            return "Success"
        }

        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attemptCount, 2)
    }

    func testRetryAndTimeoutFailsOnTimeout() async {
        do {
            _ = try await NetworkRetry.withRetryAndTimeout(
                retryConfig: RetryConfiguration(
                    maxAttempts: 3,
                    baseDelay: 0.1,
                    maxDelay: 1.0,
                    jitterFactor: 0.1
                ),
                timeoutSeconds: 0.3
            ) {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                return "Should not complete"
            }
            XCTFail("Should have thrown timeout error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Performance Tests

    func testRetryDelayIncrementsExponentially() async {
        let startTime = Date()
        var attemptCount = 0

        do {
            _ = try await NetworkRetry.withRetry(
                config: RetryConfiguration(
                    maxAttempts: 3,
                    baseDelay: 0.5,
                    maxDelay: 5.0,
                    jitterFactor: 0.0
                )
            ) {
                attemptCount += 1
                throw NSError(domain: "Test", code: -1, userInfo: nil)
            }
        } catch {
            // Expected to fail
        }

        let duration = Date().timeIntervalSince(startTime)

        // With base delay 0.5s and exponential backoff:
        // Attempt 1: immediate
        // Attempt 2: after 0.5s delay
        // Attempt 3: after 1.0s delay
        // Total minimum: 1.5s
        XCTAssertGreaterThanOrEqual(duration, 1.5)
        XCTAssertEqual(attemptCount, 3)
    }
}
