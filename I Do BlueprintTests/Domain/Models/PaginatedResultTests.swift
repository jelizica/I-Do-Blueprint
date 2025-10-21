//
//  PaginatedResultTests.swift
//  I Do BlueprintTests
//
//  Tests for PaginatedResult model
//  Part of JES-60: Performance Optimization
//

import XCTest
@testable import I_Do_Blueprint

final class PaginatedResultTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func test_init_CreatesResultWithCorrectProperties() {
        // Given
        let items = ["item1", "item2", "item3"]
        
        // When
        let result = PaginatedResult(
            items: items,
            page: 0,
            pageSize: 10,
            totalCount: 25
        )
        
        // Then
        XCTAssertEqual(result.items, items)
        XCTAssertEqual(result.page, 0)
        XCTAssertEqual(result.pageSize, 10)
        XCTAssertEqual(result.totalCount, 25)
    }
    
    func test_empty_CreatesEmptyResult() {
        // When
        let result = PaginatedResult<String>.empty(pageSize: 50)
        
        // Then
        XCTAssertTrue(result.items.isEmpty)
        XCTAssertEqual(result.page, 0)
        XCTAssertEqual(result.pageSize, 50)
        XCTAssertEqual(result.totalCount, 0)
    }
    
    // MARK: - Computed Properties Tests
    
    func test_hasMore_ReturnsTrueWhenMorePagesExist() {
        // Given - page 0 of 25 items with pageSize 10
        let result = PaginatedResult(
            items: Array(repeating: "item", count: 10),
            page: 0,
            pageSize: 10,
            totalCount: 25
        )
        
        // Then
        XCTAssertTrue(result.hasMore)
    }
    
    func test_hasMore_ReturnsFalseOnLastPage() {
        // Given - page 2 (last page) of 25 items with pageSize 10
        let result = PaginatedResult(
            items: Array(repeating: "item", count: 5),
            page: 2,
            pageSize: 10,
            totalCount: 25
        )
        
        // Then
        XCTAssertFalse(result.hasMore)
    }
    
    func test_totalPages_CalculatesCorrectly() {
        // Given
        let result1 = PaginatedResult<String>(items: [], page: 0, pageSize: 10, totalCount: 25)
        let result2 = PaginatedResult<String>(items: [], page: 0, pageSize: 10, totalCount: 30)
        let result3 = PaginatedResult<String>(items: [], page: 0, pageSize: 10, totalCount: 0)
        
        // Then
        XCTAssertEqual(result1.totalPages, 3) // 25 items / 10 per page = 3 pages
        XCTAssertEqual(result2.totalPages, 3) // 30 items / 10 per page = 3 pages
        XCTAssertEqual(result3.totalPages, 0) // 0 items = 0 pages
    }
    
    func test_isFirstPage_ReturnsTrueForPageZero() {
        // Given
        let result = PaginatedResult<String>(items: [], page: 0, pageSize: 10, totalCount: 25)
        
        // Then
        XCTAssertTrue(result.isFirstPage)
    }
    
    func test_isFirstPage_ReturnsFalseForOtherPages() {
        // Given
        let result = PaginatedResult<String>(items: [], page: 1, pageSize: 10, totalCount: 25)
        
        // Then
        XCTAssertFalse(result.isFirstPage)
    }
    
    func test_isLastPage_ReturnsTrueWhenNoMorePages() {
        // Given
        let result = PaginatedResult(
            items: Array(repeating: "item", count: 5),
            page: 2,
            pageSize: 10,
            totalCount: 25
        )
        
        // Then
        XCTAssertTrue(result.isLastPage)
    }
    
    func test_isLastPage_ReturnsFalseWhenMorePagesExist() {
        // Given
        let result = PaginatedResult(
            items: Array(repeating: "item", count: 10),
            page: 0,
            pageSize: 10,
            totalCount: 25
        )
        
        // Then
        XCTAssertFalse(result.isLastPage)
    }
    
    func test_rangeDescription_FormatsCorrectly() {
        // Given
        let result1 = PaginatedResult<String>(items: [], page: 0, pageSize: 10, totalCount: 25)
        let result2 = PaginatedResult<String>(items: [], page: 1, pageSize: 10, totalCount: 25)
        let result3 = PaginatedResult<String>(items: [], page: 2, pageSize: 10, totalCount: 25)
        let result4 = PaginatedResult<String>(items: [], page: 0, pageSize: 10, totalCount: 0)
        
        // Then
        XCTAssertEqual(result1.rangeDescription, "1-10 of 25")
        XCTAssertEqual(result2.rangeDescription, "11-20 of 25")
        XCTAssertEqual(result3.rangeDescription, "21-25 of 25")
        XCTAssertEqual(result4.rangeDescription, "0 items")
    }
    
    // MARK: - Transformation Tests
    
    func test_map_TransformsItems() {
        // Given
        let result = PaginatedResult(
            items: [1, 2, 3],
            page: 0,
            pageSize: 10,
            totalCount: 25
        )
        
        // When
        let mapped = result.map { String($0) }
        
        // Then
        XCTAssertEqual(mapped.items, ["1", "2", "3"])
        XCTAssertEqual(mapped.page, result.page)
        XCTAssertEqual(mapped.pageSize, result.pageSize)
        XCTAssertEqual(mapped.totalCount, result.totalCount)
    }
    
    // MARK: - Equatable Tests
    
    func test_equatable_ComparesCorrectly() {
        // Given
        let result1 = PaginatedResult(items: [1, 2, 3], page: 0, pageSize: 10, totalCount: 25)
        let result2 = PaginatedResult(items: [1, 2, 3], page: 0, pageSize: 10, totalCount: 25)
        let result3 = PaginatedResult(items: [1, 2, 4], page: 0, pageSize: 10, totalCount: 25)
        
        // Then
        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
    }
    
    // MARK: - CustomStringConvertible Tests
    
    func test_description_FormatsCorrectly() {
        // Given
        let result = PaginatedResult(
            items: [1, 2, 3],
            page: 0,
            pageSize: 10,
            totalCount: 25
        )
        
        // When
        let description = result.description
        
        // Then
        XCTAssertTrue(description.contains("page: 0"))
        XCTAssertTrue(description.contains("items: 3"))
        XCTAssertTrue(description.contains("total: 25"))
        XCTAssertTrue(description.contains("hasMore: true"))
    }
    
    // MARK: - Codable Tests
    
    func test_codable_EncodesAndDecodes() throws {
        // Given
        let original = PaginatedResult(
            items: ["item1", "item2", "item3"],
            page: 1,
            pageSize: 10,
            totalCount: 25
        )
        
        // When
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PaginatedResult<String>.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.items, original.items)
        XCTAssertEqual(decoded.page, original.page)
        XCTAssertEqual(decoded.pageSize, original.pageSize)
        XCTAssertEqual(decoded.totalCount, original.totalCount)
    }
    
    // MARK: - Edge Cases
    
    func test_hasMore_HandlesExactPageBoundary() {
        // Given - exactly 20 items with pageSize 10, on page 1 (last page)
        let result = PaginatedResult(
            items: Array(repeating: "item", count: 10),
            page: 1,
            pageSize: 10,
            totalCount: 20
        )
        
        // Then
        XCTAssertFalse(result.hasMore)
    }
    
    func test_totalPages_HandlesZeroPageSize() {
        // Given - edge case with pageSize 1
        let result = PaginatedResult<String>(items: [], page: 0, pageSize: 1, totalCount: 5)
        
        // Then
        XCTAssertEqual(result.totalPages, 5)
    }
}
