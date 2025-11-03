import Foundation

// MARK: - Vendor Data Models

struct Vendor: Identifiable, Codable, Hashable {
    let id: Int64
    let createdAt: Date
    var updatedAt: Date?
    var vendorName: String
    var vendorType: String?
    var vendorCategoryId: String?
    var contactName: String?
    var phoneNumber: String?
    var email: String?
    var website: String?
    var notes: String?
    var quotedAmount: Double?
    var imageUrl: String?
    var isBooked: Bool?
    var dateBooked: Date?
    var budgetCategoryId: UUID?
    let coupleId: UUID
    var isArchived: Bool
    var archivedAt: Date?
    var includeInExport: Bool

    // Address fields (now stored in database)
    var streetAddress: String?
    var streetAddress2: String?
    var city: String?
    var state: String?
    var postalCode: String?
    var country: String?
    var latitude: Double?
    var longitude: Double?

    // Computed properties for compatibility with existing views
    var budgetCategoryName: String? {
        // This would need to be fetched from budget categories table
        // For now, return vendor_type as category
        vendorType
    }

    var businessDescription: String? {
        // Use notes as business description
        notes
    }

    /// Formatted address string
    var address: String? {
        var components: [String] = []

        if let street = streetAddress, !street.isEmpty {
            components.append(street)
        }
        if let street2 = streetAddress2, !street2.isEmpty {
            components.append(street2)
        }

        var cityStateZip: [String] = []
        if let city = city, !city.isEmpty {
            cityStateZip.append(city)
        }
        if let state = state, !state.isEmpty {
            cityStateZip.append(state)
        }
        if let zip = postalCode, !zip.isEmpty {
            cityStateZip.append(zip)
        }
        if !cityStateZip.isEmpty {
            components.append(cityStateZip.joined(separator: ", "))
        }

        return components.isEmpty ? nil : components.joined(separator: "\n")
    }

    var bookingDate: String? {
        guard let dateBooked = dateBooked else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateBooked)
    }

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case vendorName = "vendor_name"
        case vendorType = "vendor_type"
        case vendorCategoryId = "vendor_category_id"
        case contactName = "contact_name"
        case phoneNumber = "phone_number"
        case email = "email"
        case website = "website"
        case notes = "notes"
        case quotedAmount = "quoted_amount"
        case imageUrl = "image_url"
        case isBooked = "is_booked"
        case dateBooked = "date_booked"
        case budgetCategoryId = "budget_category_id"
        case coupleId = "couple_id"
        case isArchived = "is_archived"
        case archivedAt = "archived_at"
        case includeInExport = "include_in_export"
        case streetAddress = "street_address"
        case streetAddress2 = "street_address_2"
        case city = "city"
        case state = "state"
        case postalCode = "postal_code"
        case country = "country"
        case latitude = "latitude"
        case longitude = "longitude"
    }
}

/// Extended vendor details that include async-loaded data
struct VendorDetails {
    let vendor: Vendor
    var reviewStats: VendorReviewStats?
    var paymentSummary: VendorPaymentSummary?
    var contractInfo: VendorContract?

    // Convenience computed properties
    var avgRating: Double? { reviewStats?.avgRating }
    var reviewCount: Int? { reviewStats?.reviewCount }
    var contractStatus: ContractStatus { contractInfo?.contractStatus ?? .none }
    var contractSignedDate: Date? { contractInfo?.contractSignedDate }
    var contractExpiryDate: Date? { contractInfo?.contractExpiryDate }
    var nextPaymentDue: Date? { paymentSummary?.nextPaymentDue }
    var finalPaymentDue: Date? { paymentSummary?.finalPaymentDue }

    init(vendor: Vendor) {
        self.vendor = vendor
    }
}

enum ContractStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case pending = "pending"
    case signed = "signed"
    case expired = "expired"
    case none = "none"

    var displayName: String {
        switch self {
        case .draft: "Draft"
        case .pending: "Pending"
        case .signed: "Signed"
        case .expired: "Expired"
        case .none: "None"
        }
    }

    var colorName: String {
        switch self {
        case .draft: "gray"
        case .pending: "orange"
        case .signed: "green"
        case .expired: "red"
        case .none: "gray"
        }
    }
}

// MARK: - Filter and Sort Options

enum VendorSortOption: String, CaseIterable {
    case name = "name"
    case category = "category"
    case cost = "cost"
    case rating = "rating"
    case bookingDate = "booking_date"

    var displayName: String {
        switch self {
        case .name: "Name"
        case .category: "Category"
        case .cost: "Cost"
        case .rating: "Rating"
        case .bookingDate: "Booking Date"
        }
    }
}

enum VendorFilterOption: String, CaseIterable {
    case all = "all"
    case available = "available"
    case booked = "booked"
    case archived = "archived"

    var displayName: String {
        switch self {
        case .all: "All Vendors"
        case .available: "Available"
        case .booked: "Booked"
        case .archived: "Archived"
        }
    }
}

// MARK: - Vendor Statistics

struct VendorStats: Codable {
    let total: Int
    let booked: Int
    let available: Int
    let archived: Int
    let totalCost: Double
    let averageRating: Double
}
