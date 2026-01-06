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

    // Social media
    var instagramHandle: String?

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
        case instagramHandle = "instagram_handle"
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

    /// SF Symbol icon for accessibility and visual clarity
    var icon: String {
        switch self {
        case .draft:
            return "doc.text"
        case .pending:
            return "clock.fill"
        case .signed:
            return "checkmark.seal.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        case .none:
            return "minus.circle"
        }
    }
}

// MARK: - Filter and Sort Options

enum VendorSortOption: String, CaseIterable, Identifiable {
    case nameAsc = "name_asc"
    case nameDesc = "name_desc"
    case typeAsc = "type_asc"
    case typeDesc = "type_desc"
    case costAsc = "cost_asc"
    case costDesc = "cost_desc"
    case dateAddedNewest = "date_added_newest"
    case dateAddedOldest = "date_added_oldest"
    case bookingDateNewest = "booking_date_newest"
    case bookingDateOldest = "booking_date_oldest"
    case bookingStatusBooked = "booking_status_booked"
    case bookingStatusAvailable = "booking_status_available"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nameAsc: "Name (A-Z)"
        case .nameDesc: "Name (Z-A)"
        case .typeAsc: "Type (A-Z)"
        case .typeDesc: "Type (Z-A)"
        case .costAsc: "Cost (Low to High)"
        case .costDesc: "Cost (High to Low)"
        case .dateAddedNewest: "Recently Added"
        case .dateAddedOldest: "Oldest First"
        case .bookingDateNewest: "Recently Booked"
        case .bookingDateOldest: "Earliest Booked"
        case .bookingStatusBooked: "Booked First"
        case .bookingStatusAvailable: "Available First"
        }
    }

    var iconName: String {
        switch self {
        case .nameAsc, .nameDesc: "textformat"
        case .typeAsc, .typeDesc: "tag"
        case .costAsc, .costDesc: "dollarsign.circle"
        case .dateAddedNewest, .dateAddedOldest: "calendar.badge.plus"
        case .bookingDateNewest, .bookingDateOldest: "calendar.badge.checkmark"
        case .bookingStatusBooked, .bookingStatusAvailable: "checkmark.seal"
        }
    }

    var groupLabel: String {
        switch self {
        case .nameAsc, .nameDesc: "Name"
        case .typeAsc, .typeDesc: "Vendor Type"
        case .costAsc, .costDesc: "Quoted Amount"
        case .dateAddedNewest, .dateAddedOldest: "Date Added"
        case .bookingDateNewest, .bookingDateOldest: "Booking Date"
        case .bookingStatusBooked, .bookingStatusAvailable: "Booking Status"
        }
    }

    /// Sort an array of vendors using this sort option
    func sort(_ vendors: [Vendor]) -> [Vendor] {
        switch self {
        case .nameAsc:
            return vendors.sorted { $0.vendorName.localizedCaseInsensitiveCompare($1.vendorName) == .orderedAscending }
        case .nameDesc:
            return vendors.sorted { $0.vendorName.localizedCaseInsensitiveCompare($1.vendorName) == .orderedDescending }
        case .typeAsc:
            return vendors.sorted { (v1, v2) in
                let type1 = v1.vendorType ?? ""
                let type2 = v2.vendorType ?? ""
                if type1 == type2 {
                    return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                }
                return type1.localizedCaseInsensitiveCompare(type2) == .orderedAscending
            }
        case .typeDesc:
            return vendors.sorted { (v1, v2) in
                let type1 = v1.vendorType ?? ""
                let type2 = v2.vendorType ?? ""
                if type1 == type2 {
                    return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                }
                return type1.localizedCaseInsensitiveCompare(type2) == .orderedDescending
            }
        case .costAsc:
            return vendors.sorted { (v1, v2) in
                switch (v1.quotedAmount, v2.quotedAmount) {
                case (.some(let cost1), .some(let cost2)):
                    if cost1 == cost2 {
                        return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                    }
                    return cost1 < cost2
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                }
            }
        case .costDesc:
            return vendors.sorted { (v1, v2) in
                switch (v1.quotedAmount, v2.quotedAmount) {
                case (.some(let cost1), .some(let cost2)):
                    if cost1 == cost2 {
                        return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                    }
                    return cost1 > cost2
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                }
            }
        case .dateAddedNewest:
            return vendors.sorted { $0.createdAt > $1.createdAt }
        case .dateAddedOldest:
            return vendors.sorted { $0.createdAt < $1.createdAt }
        case .bookingDateNewest:
            return vendors.sorted { (v1, v2) in
                // Vendors with booking dates come first, sorted newest to oldest
                // Vendors without booking dates come last
                switch (v1.dateBooked, v2.dateBooked) {
                case (.some(let date1), .some(let date2)):
                    return date1 > date2
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                }
            }
        case .bookingDateOldest:
            return vendors.sorted { (v1, v2) in
                // Vendors with booking dates come first, sorted oldest to newest
                // Vendors without booking dates come last
                switch (v1.dateBooked, v2.dateBooked) {
                case (.some(let date1), .some(let date2)):
                    return date1 < date2
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                }
            }
        case .bookingStatusBooked:
            return vendors.sorted { (v1, v2) in
                let booked1 = v1.isBooked ?? false
                let booked2 = v2.isBooked ?? false
                if booked1 == booked2 {
                    return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                }
                return booked1 && !booked2
            }
        case .bookingStatusAvailable:
            return vendors.sorted { (v1, v2) in
                let booked1 = v1.isBooked ?? false
                let booked2 = v2.isBooked ?? false
                if booked1 == booked2 {
                    return v1.vendorName.localizedCaseInsensitiveCompare(v2.vendorName) == .orderedAscending
                }
                return !booked1 && booked2
            }
        }
    }

    /// Grouped sort options for UI display
    static var grouped: [(String, [VendorSortOption])] {
        [
            ("Name", [.nameAsc, .nameDesc]),
            ("Vendor Type", [.typeAsc, .typeDesc]),
            ("Quoted Amount", [.costAsc, .costDesc]),
            ("Date Added", [.dateAddedNewest, .dateAddedOldest]),
            ("Booking Date", [.bookingDateNewest, .bookingDateOldest]),
            ("Booking Status", [.bookingStatusBooked, .bookingStatusAvailable])
        ]
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
