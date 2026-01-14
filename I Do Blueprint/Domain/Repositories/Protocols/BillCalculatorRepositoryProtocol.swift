//
//  BillCalculatorRepositoryProtocol.swift
//  I Do Blueprint
//
//  Protocol for bill calculator data operations
//  Supports per-person, service fee, and flat fee items
//

import Foundation

/// Protocol for bill calculator data operations
///
/// This protocol defines the contract for all bill calculator operations including:
/// - CRUD operations for calculators
/// - CRUD operations for line items
/// - Tax info reference data access
///
/// ## Implementation Requirements
/// Implementations must handle:
/// - Multi-tenant data scoping (couple_id filtering)
/// - Proper error handling and propagation
/// - Cache invalidation on mutations
/// - Joined data from vendor_information, wedding_events, tax_info tables
///
/// ## Thread Safety
/// All methods are async and can be called from any actor context.
/// The protocol conforms to `Sendable` for safe concurrent access.
protocol BillCalculatorRepositoryProtocol: Sendable {

    // MARK: - Calculator Operations

    /// Fetches all bill calculators for the current couple
    ///
    /// Returns calculators with joined vendor, event, and tax info data.
    /// Results are sorted by creation date (newest first).
    ///
    /// - Returns: Array of bill calculators with items
    /// - Throws: Repository errors if fetch fails or tenant context is missing
    func fetchCalculators() async throws -> [BillCalculator]

    /// Fetches a single bill calculator by ID
    ///
    /// Returns the calculator with all items and joined data.
    ///
    /// - Parameter id: The calculator ID
    /// - Returns: The bill calculator if found
    /// - Throws: Repository errors if not found or unauthorized
    func fetchCalculator(id: UUID) async throws -> BillCalculator

    /// Fetches all bill calculators linked to a specific vendor
    ///
    /// Returns calculators with joined vendor, event, and tax info data.
    /// Results are sorted by creation date (newest first).
    ///
    /// - Parameter vendorId: The vendor ID to filter by
    /// - Returns: Array of bill calculators linked to the vendor
    /// - Throws: Repository errors if fetch fails or tenant context is missing
    func fetchCalculatorsByVendor(vendorId: Int64) async throws -> [BillCalculator]

    /// Creates a new bill calculator
    ///
    /// Creates the calculator and all its items in a transaction.
    ///
    /// - Parameter calculator: The calculator to create
    /// - Returns: The created calculator with server-assigned IDs
    /// - Throws: Repository errors if creation fails
    func createCalculator(_ calculator: BillCalculator) async throws -> BillCalculator

    /// Updates an existing bill calculator
    ///
    /// Updates calculator metadata only. Use item-specific methods for items.
    ///
    /// - Parameter calculator: The calculator with updated values
    /// - Returns: The updated calculator
    /// - Throws: Repository errors if update fails
    func updateCalculator(_ calculator: BillCalculator) async throws -> BillCalculator

    /// Deletes a bill calculator and all its items
    ///
    /// Uses cascade delete to remove all associated items.
    ///
    /// - Parameter id: The calculator ID to delete
    /// - Throws: Repository errors if deletion fails
    func deleteCalculator(id: UUID) async throws

    // MARK: - Item Operations

    /// Creates a new item for a calculator
    ///
    /// - Parameter item: The item to create
    /// - Returns: The created item with server-assigned ID
    /// - Throws: Repository errors if creation fails
    func createItem(_ item: BillCalculatorItem) async throws -> BillCalculatorItem

    /// Updates an existing item
    ///
    /// - Parameter item: The item with updated values
    /// - Returns: The updated item
    /// - Throws: Repository errors if update fails
    func updateItem(_ item: BillCalculatorItem) async throws -> BillCalculatorItem

    /// Deletes an item
    ///
    /// - Parameter id: The item ID to delete
    /// - Throws: Repository errors if deletion fails
    func deleteItem(id: UUID) async throws

    /// Creates multiple items in a batch
    ///
    /// - Parameter items: Array of items to create
    /// - Returns: Array of created items
    /// - Throws: Repository errors if creation fails
    func createItems(_ items: [BillCalculatorItem]) async throws -> [BillCalculatorItem]

    // MARK: - Reference Data

    /// Fetches all available tax info options
    ///
    /// Returns reference data from the tax_info table.
    ///
    /// - Returns: Array of tax info options
    /// - Throws: Repository errors if fetch fails
    func fetchTaxInfoOptions() async throws -> [TaxInfo]
}

// MARK: - Bill Calculator Error

/// Errors specific to bill calculator operations
enum BillCalculatorError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound(id: UUID)
    case itemCreateFailed(underlying: Error)
    case itemUpdateFailed(underlying: Error)
    case itemDeleteFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch bill calculators: \(error.localizedDescription)"
        case .createFailed(let error):
            return "Failed to create bill calculator: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update bill calculator: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete bill calculator: \(error.localizedDescription)"
        case .notFound(let id):
            return "Bill calculator not found: \(id)"
        case .itemCreateFailed(let error):
            return "Failed to create item: \(error.localizedDescription)"
        case .itemUpdateFailed(let error):
            return "Failed to update item: \(error.localizedDescription)"
        case .itemDeleteFailed(let error):
            return "Failed to delete item: \(error.localizedDescription)"
        }
    }
}
