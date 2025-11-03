//
//  VendorType.swift
//  I Do Blueprint
//
//  Model for vendor type categories from vendor_types table
//

import Foundation

/// Vendor type category from the vendor_types reference table
struct VendorType: Identifiable, Codable, Hashable {
    let id: Int64
    let createdAt: Date
    let vendorType: String

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case createdAt = "created_at"
        case vendorType = "vendor_type"
    }
}

// MARK: - Test Helpers

extension VendorType {
    /// Create a test vendor type for previews and testing
    static func makeTest(
        id: Int64 = 1,
        vendorType: String = "Photographer"
    ) -> VendorType {
        VendorType(
            id: id,
            createdAt: Date(),
            vendorType: vendorType
        )
    }
}
