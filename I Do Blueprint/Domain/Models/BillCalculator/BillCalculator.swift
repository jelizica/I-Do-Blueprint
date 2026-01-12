//
//  BillCalculator.swift
//  I Do Blueprint
//
//  Domain model for Bill Calculator - a per-person cost estimator
//  Supports per-person items, service fees (percentage-based), and flat fees
//

import Foundation

// MARK: - Bill Calculator Item Types

/// Type of line item in a bill calculator
enum BillItemType: String, Codable, CaseIterable, Identifiable {
    case perPerson = "per_person"
    case serviceFee = "service_fee"
    case flatFee = "flat_fee"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .perPerson: return "Per-Person"
        case .serviceFee: return "Service Fee"
        case .flatFee: return "Flat Fee"
        }
    }

    var description: String {
        switch self {
        case .perPerson: return "Costs multiplied by guest count"
        case .serviceFee: return "Percentage-based fees on subtotal"
        case .flatFee: return "One-time fixed costs"
        }
    }

    var icon: String {
        switch self {
        case .perPerson: return "person.fill"
        case .serviceFee: return "percent"
        case .flatFee: return "tag.fill"
        }
    }
}

// MARK: - Bill Line Item

/// A single line item in a bill calculator
struct BillLineItem: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var amount: Double
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String = "",
        amount: Double = 0,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.sortOrder = sortOrder
    }

    /// Calculates the total for a per-person item
    func perPersonTotal(guestCount: Int) -> Double {
        return amount * Double(guestCount)
    }

    /// Calculates the total for a service fee item (percentage)
    func serviceFeeTotal(subtotal: Double) -> Double {
        return subtotal * (amount / 100.0)
    }

    /// For flat fees, the total is just the amount
    var flatFeeTotal: Double {
        return amount
    }
}

// MARK: - Tax Rate Option

/// Pre-defined tax rate options
struct TaxRateOption: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let rate: Double

    static let standard = TaxRateOption(name: "8.5% - Standard Rate", rate: 8.5)
    static let reduced = TaxRateOption(name: "7.0% - Reduced Rate", rate: 7.0)
    static let premium = TaxRateOption(name: "10.0% - Premium Rate", rate: 10.0)
    static let exempt = TaxRateOption(name: "0% - Tax Exempt", rate: 0.0)

    static let allOptions: [TaxRateOption] = [.standard, .reduced, .premium, .exempt]
}

// MARK: - Bill Calculator

/// Main Bill Calculator model for per-person cost estimation
struct BillCalculator: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let coupleId: UUID
    var name: String
    var vendorId: Int64?
    var vendorName: String?
    var eventId: String?
    var eventName: String?
    var guestCount: Int
    var perPersonItems: [BillLineItem]
    var serviceFeeItems: [BillLineItem]
    var flatFeeItems: [BillLineItem]
    var taxRate: Double
    var notes: String?
    let createdAt: Date?
    var updatedAt: Date?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case name
        case vendorId = "vendor_id"
        case vendorName = "vendor_name"
        case eventId = "event_id"
        case eventName = "event_name"
        case guestCount = "guest_count"
        case perPersonItems = "per_person_items"
        case serviceFeeItems = "service_fee_items"
        case flatFeeItems = "flat_fee_items"
        case taxRate = "tax_rate"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        coupleId: UUID,
        name: String = "",
        vendorId: Int64? = nil,
        vendorName: String? = nil,
        eventId: String? = nil,
        eventName: String? = nil,
        guestCount: Int = 0,
        perPersonItems: [BillLineItem] = [],
        serviceFeeItems: [BillLineItem] = [],
        flatFeeItems: [BillLineItem] = [],
        taxRate: Double = 8.5,
        notes: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.coupleId = coupleId
        self.name = name
        self.vendorId = vendorId
        self.vendorName = vendorName
        self.eventId = eventId
        self.eventName = eventName
        self.guestCount = guestCount
        self.perPersonItems = perPersonItems
        self.serviceFeeItems = serviceFeeItems
        self.flatFeeItems = flatFeeItems
        self.taxRate = taxRate
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Total for all per-person items
    var perPersonTotal: Double {
        perPersonItems.reduce(0) { $0 + $1.perPersonTotal(guestCount: guestCount) }
    }

    /// Subtotal for service fee calculation (per-person items only, as per HTML design)
    var serviceFeeSubtotal: Double {
        perPersonTotal
    }

    /// Total for all service fee items
    var serviceFeeTotal: Double {
        serviceFeeItems.reduce(0) { $0 + $1.serviceFeeTotal(subtotal: serviceFeeSubtotal) }
    }

    /// Total for all flat fee items
    var flatFeeTotal: Double {
        flatFeeItems.reduce(0) { $0 + $1.flatFeeTotal }
    }

    /// Subtotal before tax
    var subtotal: Double {
        perPersonTotal + serviceFeeTotal + flatFeeTotal
    }

    /// Tax amount
    var taxAmount: Double {
        subtotal * (taxRate / 100.0)
    }

    /// Grand total including tax
    var grandTotal: Double {
        subtotal + taxAmount
    }

    /// Per-guest cost (grand total divided by guest count)
    var perGuestCost: Double {
        guard guestCount > 0 else { return 0 }
        return subtotal / Double(guestCount)
    }

    /// Total number of line items
    var totalItemCount: Int {
        perPersonItems.count + serviceFeeItems.count + flatFeeItems.count
    }

    /// Summary string for display
    var summaryDescription: String {
        "\(eventName ?? "Bill") - \(guestCount) guests"
    }

    // MARK: - Mutating Methods

    /// Adds a new per-person item
    mutating func addPerPersonItem(_ item: BillLineItem = BillLineItem()) {
        var newItem = item
        newItem.sortOrder = perPersonItems.count
        perPersonItems.append(newItem)
    }

    /// Adds a new service fee item
    mutating func addServiceFeeItem(_ item: BillLineItem = BillLineItem()) {
        var newItem = item
        newItem.sortOrder = serviceFeeItems.count
        serviceFeeItems.append(newItem)
    }

    /// Adds a new flat fee item
    mutating func addFlatFeeItem(_ item: BillLineItem = BillLineItem()) {
        var newItem = item
        newItem.sortOrder = flatFeeItems.count
        flatFeeItems.append(newItem)
    }

    /// Removes a per-person item
    mutating func removePerPersonItem(at index: Int) {
        guard perPersonItems.indices.contains(index) else { return }
        perPersonItems.remove(at: index)
        for i in perPersonItems.indices {
            perPersonItems[i].sortOrder = i
        }
    }

    /// Removes a service fee item
    mutating func removeServiceFeeItem(at index: Int) {
        guard serviceFeeItems.indices.contains(index) else { return }
        serviceFeeItems.remove(at: index)
        for i in serviceFeeItems.indices {
            serviceFeeItems[i].sortOrder = i
        }
    }

    /// Removes a flat fee item
    mutating func removeFlatFeeItem(at index: Int) {
        guard flatFeeItems.indices.contains(index) else { return }
        flatFeeItems.remove(at: index)
        for i in flatFeeItems.indices {
            flatFeeItems[i].sortOrder = i
        }
    }
}

// MARK: - Test Builder Extension

extension BillCalculator {
    /// Creates a test calculator with sample data for unit testing
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        name: String = "Test Bill",
        guestCount: Int = 150,
        taxRate: Double = 8.5
    ) -> BillCalculator {
        BillCalculator(
            id: id,
            coupleId: coupleId,
            name: name,
            guestCount: guestCount,
            perPersonItems: [
                BillLineItem(name: "Dinner", amount: 85.00, sortOrder: 0),
                BillLineItem(name: "Drinks", amount: 40.00, sortOrder: 1)
            ],
            serviceFeeItems: [
                BillLineItem(name: "Service Charge", amount: 20, sortOrder: 0)
            ],
            flatFeeItems: [
                BillLineItem(name: "Setup Fee", amount: 500, sortOrder: 0)
            ],
            taxRate: taxRate
        )
    }
}

// MARK: - Insert Data Model

/// Data structure for creating new bill calculators in the database
struct BillCalculatorInsertData: Codable {
    var coupleId: UUID
    var name: String
    var vendorId: Int64?
    var vendorName: String?
    var eventId: String?
    var eventName: String?
    var guestCount: Int
    var perPersonItems: [BillLineItem]
    var serviceFeeItems: [BillLineItem]
    var flatFeeItems: [BillLineItem]
    var taxRate: Double
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case name
        case vendorId = "vendor_id"
        case vendorName = "vendor_name"
        case eventId = "event_id"
        case eventName = "event_name"
        case guestCount = "guest_count"
        case perPersonItems = "per_person_items"
        case serviceFeeItems = "service_fee_items"
        case flatFeeItems = "flat_fee_items"
        case taxRate = "tax_rate"
        case notes
    }

    init(from calculator: BillCalculator) {
        self.coupleId = calculator.coupleId
        self.name = calculator.name
        self.vendorId = calculator.vendorId
        self.vendorName = calculator.vendorName
        self.eventId = calculator.eventId
        self.eventName = calculator.eventName
        self.guestCount = calculator.guestCount
        self.perPersonItems = calculator.perPersonItems
        self.serviceFeeItems = calculator.serviceFeeItems
        self.flatFeeItems = calculator.flatFeeItems
        self.taxRate = calculator.taxRate
        self.notes = calculator.notes
    }
}
