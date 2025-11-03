//
//  PaginatedResult.swift
//  I Do Blueprint
//
//  Generic pagination result wrapper
//  Part of JES-60: Performance Optimization
//

import Foundation

/// Generic wrapper for paginated API results
///
/// This model provides a consistent structure for paginated data across all repositories.
/// It includes metadata about the current page, total count, and whether more data is available.
///
/// ## Usage Example
/// ```swift
/// // In repository
/// func fetchGuests(page: Int, pageSize: Int) async throws -> PaginatedResult<Guest> {
///     let offset = page * pageSize
///     let guests = try await client
///         .from("guest_list")
///         .select()
///         .range(from: offset, to: offset + pageSize - 1)
///         .execute()
///         .value
///
///     let totalCount = try await fetchTotalCount()
///
///     return PaginatedResult(
///         items: guests,
///         page: page,
///         pageSize: pageSize,
///         totalCount: totalCount
///     )
/// }
///
/// // In store
/// let result = try await repository.fetchGuests(page: 0, pageSize: 50)
/// print("Loaded \(result.items.count) of \(result.totalCount) total")
/// if result.hasMore {
///     print("More data available")
/// }
/// ```
struct PaginatedResult<T: Codable & Sendable>: Codable, Sendable {

    // MARK: - Properties

    /// The items in the current page
    let items: [T]

    /// The current page number (0-indexed)
    let page: Int

    /// The number of items per page
    let pageSize: Int

    /// The total number of items across all pages
    let totalCount: Int

    // MARK: - Computed Properties

    /// Whether there are more pages available
    var hasMore: Bool {
        let loadedCount = (page + 1) * pageSize
        return loadedCount < totalCount
    }

    /// The total number of pages
    var totalPages: Int {
        guard totalCount > 0 else { return 0 }
        return (totalCount + pageSize - 1) / pageSize
    }

    /// Whether this is the first page
    var isFirstPage: Bool {
        page == 0
    }

    /// Whether this is the last page
    var isLastPage: Bool {
        !hasMore
    }

    /// The range of items in this page (e.g., "1-50 of 200")
    var rangeDescription: String {
        guard totalCount > 0 else { return "0 items" }

        let start = page * pageSize + 1
        let end = min((page + 1) * pageSize, totalCount)

        return "\(start)-\(end) of \(totalCount)"
    }

    // MARK: - Initializers

    /// Creates a paginated result
    ///
    /// - Parameters:
    ///   - items: The items in the current page
    ///   - page: The current page number (0-indexed)
    ///   - pageSize: The number of items per page
    ///   - totalCount: The total number of items across all pages
    init(items: [T], page: Int, pageSize: Int, totalCount: Int) {
        self.items = items
        self.page = page
        self.pageSize = pageSize
        self.totalCount = totalCount
    }

    /// Creates an empty paginated result
    ///
    /// Useful for initial states or error conditions.
    static func empty(pageSize: Int = 50) -> PaginatedResult<T> {
        PaginatedResult(items: [], page: 0, pageSize: pageSize, totalCount: 0)
    }

    // MARK: - Transformation

    /// Maps the items to a different type
    ///
    /// Useful for transforming paginated results while preserving pagination metadata.
    ///
    /// - Parameter transform: A closure that transforms each item
    /// - Returns: A new paginated result with transformed items
    func map<U: Codable & Sendable>(_ transform: (T) -> U) -> PaginatedResult<U> {
        PaginatedResult<U>(
            items: items.map(transform),
            page: page,
            pageSize: pageSize,
            totalCount: totalCount
        )
    }
}

// MARK: - Equatable

extension PaginatedResult: Equatable where T: Equatable {
    static func == (lhs: PaginatedResult<T>, rhs: PaginatedResult<T>) -> Bool {
        lhs.items == rhs.items &&
        lhs.page == rhs.page &&
        lhs.pageSize == rhs.pageSize &&
        lhs.totalCount == rhs.totalCount
    }
}

// MARK: - CustomStringConvertible

extension PaginatedResult: CustomStringConvertible {
    var description: String {
        "PaginatedResult(page: \(page), items: \(items.count), total: \(totalCount), hasMore: \(hasMore))"
    }
}
