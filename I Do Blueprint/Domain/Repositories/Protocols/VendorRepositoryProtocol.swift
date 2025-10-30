//
//  VendorRepositoryProtocol.swift
//  I Do Blueprint
//
//  Created as part of JES-43: Create Missing Repository Protocols
//  Protocol for vendor-related data operations
//

import Foundation

/// Protocol for vendor-related data operations
///
/// This protocol defines the contract for all vendor management operations including:
/// - CRUD operations for vendor records
/// - Vendor statistics and analytics
/// - Extended vendor data (reviews, payments, contracts)
/// - Vendor details and summaries
///
/// ## Implementation Requirements
/// Implementations must handle:
/// - Multi-tenant data scoping (couple_id filtering)
/// - Proper error handling and propagation
/// - Cache invalidation on mutations
/// - Analytics tracking for performance monitoring
/// - Vendor booking status tracking
///
/// ## Thread Safety
/// All methods are async and can be called from any actor context.
/// The protocol conforms to `Sendable` for safe concurrent access.
///
/// ## Error Handling
/// Methods throw errors for:
/// - Network failures
/// - Database errors
/// - Authentication/authorization failures
/// - Validation errors (e.g., duplicate vendors, invalid data)
/// - Missing tenant context
///
/// ## Usage Example
/// ```swift
/// @Dependency(\.vendorRepository) var repository
///
/// // Fetch all vendors
/// let vendors = try await repository.fetchVendors()
///
/// // Create a new vendor
/// let newVendor = Vendor(vendorName: "Acme Catering", category: "Catering", ...)
/// let created = try await repository.createVendor(newVendor)
///
/// // Update booking status
/// var updated = created
/// updated.isBooked = true
/// updated.dateBooked = Date()
/// try await repository.updateVendor(updated)
/// ```
protocol VendorRepositoryProtocol: Sendable {
    
    // MARK: - Fetch Operations
    
    /// Fetches all vendors for the current couple
    ///
    /// Returns vendors sorted by creation date (newest first).
    /// Results are automatically scoped to the current couple's tenant ID.
    ///
    /// - Returns: Array of vendor records
    /// - Throws: Repository errors if fetch fails or tenant context is missing
    func fetchVendors() async throws -> [Vendor]
    
    /// Fetches vendor statistics for the current couple
    ///
    /// Calculates aggregate statistics including:
    /// - Total vendor count
    /// - Booked vendor count
    /// - Available vendor count
    /// - Archived vendor count
    /// - Total cost across all vendors
    /// - Average vendor rating
    ///
    /// - Returns: Vendor statistics object
    /// - Throws: Repository errors if fetch fails
    func fetchVendorStats() async throws -> VendorStats
    
    // MARK: - Create, Update, Delete Operations
    
    /// Creates a new vendor record
    ///
    /// The vendor will be automatically associated with the current couple's tenant ID.
    /// Server will assign ID and timestamps.
    ///
    /// - Parameter vendor: The vendor to create
    /// - Returns: The created vendor with server-assigned ID and timestamps
    /// - Throws: Repository errors if creation fails or validation errors
    func createVendor(_ vendor: Vendor) async throws -> Vendor
    
    /// Updates an existing vendor record
    ///
    /// Updates the vendor and sets the `updatedAt` timestamp.
    /// Only vendors belonging to the current couple can be updated.
    ///
    /// - Parameter vendor: The vendor with updated values
    /// - Returns: The updated vendor with new timestamp
    /// - Throws: Repository errors if update fails, vendor not found, or unauthorized
    func updateVendor(_ vendor: Vendor) async throws -> Vendor
    
    /// Deletes a vendor record
    ///
    /// Permanently removes the vendor from the database.
    /// Only vendors belonging to the current couple can be deleted.
    ///
    /// - Parameter id: The ID of the vendor to delete
    /// - Throws: Repository errors if deletion fails, vendor not found, or unauthorized
    func deleteVendor(id: Int64) async throws
    
    // MARK: - Extended Vendor Data Operations
    
    /// Fetches reviews for a specific vendor
    ///
    /// Returns all reviews associated with the vendor, sorted by date.
    ///
    /// - Parameter vendorId: The ID of the vendor
    /// - Returns: Array of vendor reviews
    /// - Throws: Repository errors if fetch fails or vendor not found
    func fetchVendorReviews(vendorId: Int64) async throws -> [VendorReview]
    
    /// Fetches review statistics for a specific vendor
    ///
    /// Calculates aggregate review statistics including:
    /// - Average rating
    /// - Total review count
    /// - Rating distribution
    ///
    /// - Parameter vendorId: The ID of the vendor
    /// - Returns: Optional review statistics (nil if no reviews)
    /// - Throws: Repository errors if fetch fails
    func fetchVendorReviewStats(vendorId: Int64) async throws -> VendorReviewStats?
    
    /// Fetches payment summary for a specific vendor
    ///
    /// Returns payment information including:
    /// - Total amount
    /// - Amount paid
    /// - Amount remaining
    /// - Payment schedule
    ///
    /// - Parameter vendorId: The ID of the vendor
    /// - Returns: Optional payment summary (nil if no payments)
    /// - Throws: Repository errors if fetch fails
    func fetchVendorPaymentSummary(vendorId: Int64) async throws -> VendorPaymentSummary?
    
    /// Fetches contract summary for a specific vendor
    ///
    /// Returns contract information including:
    /// - Contract status
    /// - Start and end dates
    /// - Terms and conditions
    ///
    /// - Parameter vendorId: The ID of the vendor
    /// - Returns: Optional contract (nil if no contract)
    /// - Throws: Repository errors if fetch fails
    func fetchVendorContractSummary(vendorId: Int64) async throws -> VendorContract?
    
    /// Fetches complete vendor details
    ///
    /// Returns comprehensive vendor information including:
    /// - Basic vendor data
    /// - Reviews and ratings
    /// - Payment information
    /// - Contract details
    ///
    /// - Parameter id: The ID of the vendor
    /// - Returns: Complete vendor details
    /// - Throws: Repository errors if fetch fails or vendor not found
    func fetchVendorDetails(id: Int64) async throws -> VendorDetails
    
    // MARK: - Vendor Types
    
    /// Fetches all vendor types from the vendor_types reference table
    ///
    /// Returns all available vendor type categories.
    /// This is system-wide reference data (not tenant-scoped).
    ///
    /// - Returns: Array of vendor types sorted alphabetically
    /// - Throws: Repository errors if fetch fails
    func fetchVendorTypes() async throws -> [VendorType]
    
    // MARK: - Bulk Import Operations
    
    /// Imports multiple vendors from CSV data in a single batch operation
    ///
    /// Performs a batch insert of vendor records with the following features:
    /// - Single database transaction for atomicity
    /// - Automatic `couple_id` assignment from current session
    /// - Duplicate detection by vendor name and email
    /// - Cache invalidation after successful import
    /// - Performance monitoring and analytics tracking
    /// - Network retry with exponential backoff
    ///
    /// ## Duplicate Handling
    /// Vendors are considered duplicates if they match on:
    /// - Vendor name (case-insensitive)
    /// - Email address (if provided, case-insensitive)
    ///
    /// Duplicate vendors are skipped and not imported.
    ///
    /// ## Transaction Behavior
    /// The import is atomic - either all vendors are imported successfully,
    /// or none are imported if any error occurs.
    ///
    /// ## Performance Considerations
    /// - Uses batch insert for optimal performance
    /// - Invalidates vendor cache after successful import
    /// - Tracks import duration for monitoring
    ///
    /// - Parameter vendors: Array of vendor import data to insert
    /// - Returns: Array of created vendors with server-assigned IDs and timestamps
    /// - Throws: Repository errors if:
    ///   - Import fails (network, database, validation)
    ///   - Tenant context is missing
    ///   - Transaction rollback occurs
    ///
    /// ## Usage Example
    /// ```swift
    /// let importData = [
    ///     VendorImportData(vendorName: "Acme Catering", ...),
    ///     VendorImportData(vendorName: "Elegant Flowers", ...)
    /// ]
    /// let imported = try await repository.importVendors(importData)
    /// print("Imported \(imported.count) vendors")
    /// ```
    func importVendors(_ vendors: [VendorImportData]) async throws -> [Vendor]
}
