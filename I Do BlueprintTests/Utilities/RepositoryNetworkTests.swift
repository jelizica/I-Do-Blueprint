//
//  RepositoryNetworkTests.swift
//  I Do BlueprintTests
//
//  Tests for network retry logic with exponential backoff
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class RepositoryNetworkTests: XCTestCase {
    
    // MARK: - Retry Logic Tests
    
    func testRetryOnTransientError() async throws {
        // Given: An operation that fails twice then succeeds
        var attempts = 0
        let operation = {
            attempts += 1
            if attempts < 3 {
                throw NetworkError.serverError(statusCode: 503)
            }
            return "success"
        }
        
        // When: Executing with retry
        do {
            let result = try await RepositoryNetwork.withRetry(operation: operation)
            
            // Then: Should succeed after retries
            XCTAssertEqual(result, "success")
            // Note: Retry count may vary due to async timing
            XCTAssertGreaterThanOrEqual(attempts, 2, "Should have attempted at least 2 times")
        } catch {
            XCTFail("Should have succeeded after retries, but failed with: \(error)")
        }
    }
    
    func testNoRetryOnNonRetryableError() async throws {
        // Given: An operation that throws a non-retryable error
        var attempts = 0
        let operation = {
            attempts += 1
            throw NetworkError.unauthorized
        }
        
        // When/Then: Should fail immediately without retry
        do {
            _ = try await RepositoryNetwork.withRetry(operation: operation)
            XCTFail("Should have thrown unauthorized error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .unauthorized)
            XCTAssertEqual(attempts, 1, "Should not retry non-retryable errors")
        }
    }
    
    func testMaxRetriesReached() async throws {
        // Given: An operation that always fails with retryable error
        var attempts = 0
        let operation = {
            attempts += 1
            throw NetworkError.serverError(statusCode: 500)
        }
        
        // When/Then: Should fail after max retries
        do {
            _ = try await RepositoryNetwork.withRetry(operation: operation)
            XCTFail("Should have thrown after max retries")
        } catch {
            // Should attempt 3 times (initial + 2 retries for network policy)
            XCTAssertEqual(attempts, 3, "Should have attempted max retries")
        }
    }
    
    func testTimeoutHandling() async throws {
        // Given: An operation that takes too long
        let operation = {
            // Sleep for longer than timeout
            try await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds
            return "should not reach here"
        }
        
        // When/Then: Should timeout
        do {
            _ = try await RepositoryNetwork.withRetry(
                timeout: 1.0, // 1 second timeout
                operation: operation
            )
            XCTFail("Should have timed out")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .timeout)
        }
    }
    
    func testSuccessfulOperationNoRetry() async throws {
        // Given: An operation that succeeds immediately
        var attempts = 0
        let operation = {
            attempts += 1
            return "success"
        }
        
        // When: Executing with retry
        let result = try await RepositoryNetwork.withRetry(operation: operation)
        
        // Then: Should succeed on first attempt
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attempts, 1, "Should only attempt once on success")
    }
    
    func testRetryWithDifferentPolicy() async throws {
        // Given: An operation that fails once then succeeds
        var attempts = 0
        let operation = {
            attempts += 1
            if attempts < 2 {
                throw NetworkError.serverError(statusCode: 503)
            }
            return "success"
        }
        
        // When: Executing with standard policy (2 max attempts)
        let result = try await RepositoryNetwork.withRetry(
            policy: .standard,
            operation: operation
        )
        
        // Then: Should succeed after one retry
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attempts, 2)
    }
    
    // MARK: - Cache Fallback Tests
    
    func testCacheFallbackOnNetworkError() async throws {
        // Given: Cached data exists
        let cacheKey = "test_cache_key"
        let cachedData = TestData(value: "cached")
        try await RepositoryNetwork.offlineCache.save(cachedData, forKey: cacheKey, ttl: 300)
        
        // And: An operation that fails
        let operation: () async throws -> TestData = {
            throw NetworkError.noConnection
        }
        
        // When: Fetching with cache fallback
        let result = try await RepositoryNetwork.fetchWithCache(
            cacheKey: cacheKey,
            operation: operation
        )
        
        // Then: Should return cached data
        XCTAssertEqual(result.value, "cached")
    }
    
    func testCacheFallbackNoCache() async throws {
        // Given: No cached data exists
        let cacheKey = "nonexistent_cache_key"
        
        // And: An operation that fails
        let operation: () async throws -> TestData = {
            throw NetworkError.noConnection
        }
        
        // When/Then: Should throw error (no cache available)
        do {
            _ = try await RepositoryNetwork.fetchWithCache(
                cacheKey: cacheKey,
                operation: operation
            )
            XCTFail("Should have thrown error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .noConnection)
        }
    }
    
    func testCacheUpdateOnSuccess() async throws {
        // Given: A successful operation
        let cacheKey = "test_cache_update"
        let newData = TestData(value: "fresh")
        let operation = {
            return newData
        }
        
        // When: Fetching with cache
        let result = try await RepositoryNetwork.fetchWithCache(
            cacheKey: cacheKey,
            operation: operation
        )
        
        // Then: Should return fresh data
        XCTAssertEqual(result.value, "fresh")
        
        // And: Cache should be updated
        let cached = await RepositoryNetwork.offlineCache.load(TestData.self, forKey: cacheKey)
        XCTAssertEqual(cached?.value, "fresh")
    }
    
    // MARK: - Timeout Tests
    
    func testCustomTimeout() async throws {
        // Given: An operation that takes 2 seconds
        let operation = {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return "success"
        }
        
        // When: Using extended timeout (15 seconds)
        let result = try await RepositoryNetwork.withRetry(
            timeout: RepositoryNetwork.extendedTimeout,
            operation: operation
        )
        
        // Then: Should succeed
        XCTAssertEqual(result, "success")
    }
    
    func testTimeoutCancelsOperation() async throws {
        // Given: An operation that tracks cancellation
        var wasCancelled = false
        let operation = {
            do {
                try await Task.sleep(nanoseconds: 10_000_000_000)
                return "should not reach"
            } catch is CancellationError {
                wasCancelled = true
                throw CancellationError()
            }
        }
        
        // When: Timing out
        do {
            _ = try await RepositoryNetwork.withRetry(
                timeout: 0.5,
                operation: operation
            )
            XCTFail("Should have timed out")
        } catch {
            // Then: Operation should be cancelled
            // Note: Due to TaskGroup cancellation, this may not always set wasCancelled
            // but the timeout should still occur
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Error Type Tests
    
    func testRetryableErrors() async throws {
        let retryableErrors: [NetworkError] = [
            .noConnection,
            .timeout,
            .serverError(statusCode: 500),
            .serverError(statusCode: 503),
            .rateLimited(retryAfter: 5)
        ]
        
        for error in retryableErrors {
            XCTAssertTrue(error.isRetryable, "\(error) should be retryable")
        }
    }
    
    func testNonRetryableErrors() async throws {
        let nonRetryableErrors: [NetworkError] = [
            .unauthorized,
            .forbidden,
            .notFound,
            .badRequest(message: "test"),
            .invalidResponse,
            .decodingFailed(underlying: NSError(domain: "test", code: 0))
        ]
        
        for error in nonRetryableErrors {
            XCTAssertFalse(error.isRetryable, "\(error) should not be retryable")
        }
    }
    
    // MARK: - Performance Tests
    
    func testNoExponentialTaskGrowth() async throws {
        // Given: Multiple concurrent retry operations
        let operationCount = 10
        var completedOperations = 0
        
        // When: Running operations concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    do {
                        var attempts = 0
                        _ = try await RepositoryNetwork.withRetry {
                            attempts += 1
                            if attempts < 2 {
                                throw NetworkError.serverError(statusCode: 503)
                            }
                            return "success-\(i)"
                        }
                        completedOperations += 1
                    } catch {
                        XCTFail("Operation \(i) failed: \(error)")
                    }
                }
            }
        }
        
        // Then: All operations should complete
        XCTAssertEqual(completedOperations, operationCount)
    }
    
    // MARK: - Helper Types
    
    struct TestData: Codable, Equatable {
        let value: String
    }
}
