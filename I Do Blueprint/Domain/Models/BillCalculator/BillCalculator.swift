//
//  BillCalculator.swift
//  I Do Blueprint
//
//  Domain model for Bill Calculator - a per-person cost estimator
//  Supports per-person items, service fees (percentage-based), and flat fees
//
//  Database: bill_calculators + bill_calculator_items tables
//  FKs: vendor_id → vendor_information, event_id → wedding_events, tax_info_id → tax_info
//

import Foundation

// MARK: - Guest Count Mode

/// Mode for determining how item quantities are calculated
enum GuestCountMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case auto = "auto"
    case manual = "manual"
    case variable = "variable"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .manual: return "Manual"
        case .variable: return "Variable"
        }
    }

    var description: String {
        switch self {
        case .auto: return "Uses attending guest count from guest list"
        case .manual: return "Fixed guest count entered manually"
        case .variable: return "Each item has its own quantity"
        }
    }

    var icon: String {
        switch self {
        case .auto: return "person.3.fill"
        case .manual: return "pencil"
        case .variable: return "number.square"
        }
    }
}

// MARK: - Bill Calculator Item Types

/// Type of line item in a bill calculator
enum BillItemType: String, Codable, CaseIterable, Identifiable, Sendable {
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

    /// Display name when in variable item count mode
    var variableModeDisplayName: String {
        switch self {
        case .perPerson: return "Per-Item"
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

    /// Description when in variable item count mode
    var variableModeDescription: String {
        switch self {
        case .perPerson: return "Costs multiplied by item quantity"
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

    /// Icon when in variable item count mode
    var variableModeIcon: String {
        switch self {
        case .perPerson: return "number.square"
        case .serviceFee: return "percent"
        case .flatFee: return "tag.fill"
        }
    }
}

// MARK: - Bill Calculator Item (Database Model)

/// A single line item in a bill calculator (maps to bill_calculator_items table)
struct BillCalculatorItem: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let calculatorId: UUID
    let coupleId: UUID
    var type: BillItemType
    var name: String
    var amount: Double
    var quantity: Int
    var sortOrder: Int
    let createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case calculatorId = "calculator_id"
        case coupleId = "couple_id"
        case type
        case name
        case amount
        case quantity = "item_quantity"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        calculatorId: UUID,
        coupleId: UUID,
        type: BillItemType,
        name: String = "",
        amount: Double = 0,
        quantity: Int = 1,
        sortOrder: Int = 0,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.calculatorId = calculatorId
        self.coupleId = coupleId
        self.type = type
        self.name = name
        self.amount = amount
        self.quantity = quantity
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        calculatorId = try container.decode(UUID.self, forKey: .calculatorId)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        type = try container.decode(BillItemType.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        // Default to 1 if quantity is missing (backward compatibility)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    /// Calculates the total for a per-person item (uses guest count)
    func perPersonTotal(guestCount: Int) -> Double {
        guard type == .perPerson else { return 0 }
        return amount * Double(guestCount)
    }

    /// Calculates the total for a variable quantity item (uses item's own quantity)
    var variableItemTotal: Double {
        guard type == .perPerson else { return 0 }
        return amount * Double(quantity)
    }

    /// Calculates the total for a service fee item (percentage)
    func serviceFeeTotal(subtotal: Double) -> Double {
        guard type == .serviceFee else { return 0 }
        return subtotal * (amount / 100.0)
    }

    /// For flat fees, the total is just the amount
    var flatFeeTotal: Double {
        guard type == .flatFee else { return 0 }
        return amount
    }
}

// MARK: - Bill Calculator Item Insert Data

/// Data structure for inserting bill calculator items
struct BillCalculatorItemInsertData: Codable {
    let calculatorId: UUID
    let coupleId: UUID
    let type: String
    let name: String
    let amount: Double
    let quantity: Int
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case calculatorId = "calculator_id"
        case coupleId = "couple_id"
        case type
        case name
        case amount
        case quantity = "item_quantity"
        case sortOrder = "sort_order"
    }

    init(from item: BillCalculatorItem) {
        self.calculatorId = item.calculatorId
        self.coupleId = item.coupleId
        self.type = item.type.rawValue
        self.name = item.name
        self.amount = item.amount
        self.quantity = item.quantity
        self.sortOrder = item.sortOrder
    }
}

/// Data structure for updating bill calculator items (excludes immutable fields)
struct BillCalculatorItemUpdateData: Codable {
    let name: String
    let amount: Double
    let quantity: Int
    let sortOrder: Int
    let type: String

    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case quantity = "item_quantity"
        case sortOrder = "sort_order"
        case type
    }

    init(from item: BillCalculatorItem) {
        self.name = item.name
        self.amount = item.amount
        self.quantity = item.quantity
        self.sortOrder = item.sortOrder
        self.type = item.type.rawValue
    }
}

// MARK: - Bill Calculator

/// Main Bill Calculator model for per-person cost estimation
/// Maps to bill_calculators table with JOINs to vendor_information, wedding_events, tax_info
struct BillCalculator: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let coupleId: UUID
    var name: String
    var vendorId: Int64?
    var eventId: UUID?
    var taxInfoId: Int64?
    var guestCount: Int
    var guestCountMode: GuestCountMode
    var notes: String?
    let createdAt: Date?
    var updatedAt: Date?

    // Joined fields (from related tables, not stored in bill_calculators)
    var vendorName: String?
    var eventName: String?
    var taxRate: Double?
    var taxRegion: String?

    // Child items (from bill_calculator_items table)
    var items: [BillCalculatorItem]

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case name
        case vendorId = "vendor_id"
        case eventId = "event_id"
        case taxInfoId = "tax_info_id"
        case guestCount = "guest_count"
        case guestCountMode = "guest_count_mode"
        case useManualGuestCount = "use_manual_guest_count"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        // Joined fields
        case vendorName = "vendor_name"
        case eventName = "event_name"
        case taxRate = "tax_rate"
        case taxRegion = "tax_region"
        // Child items
        case items
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        name = try container.decode(String.self, forKey: .name)
        vendorId = try container.decodeIfPresent(Int64.self, forKey: .vendorId)
        eventId = try container.decodeIfPresent(UUID.self, forKey: .eventId)
        taxInfoId = try container.decodeIfPresent(Int64.self, forKey: .taxInfoId)
        guestCount = try container.decode(Int.self, forKey: .guestCount)

        // Decode guestCountMode with backward compatibility for useManualGuestCount
        if let mode = try? container.decodeIfPresent(GuestCountMode.self, forKey: .guestCountMode) {
            guestCountMode = mode
        } else {
            // Fallback: convert legacy useManualGuestCount boolean to new mode
            let useManual = try container.decodeIfPresent(Bool.self, forKey: .useManualGuestCount) ?? false
            guestCountMode = useManual ? .manual : .auto
        }

        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        vendorName = try container.decodeIfPresent(String.self, forKey: .vendorName)
        eventName = try container.decodeIfPresent(String.self, forKey: .eventName)
        taxRate = try container.decodeIfPresent(Double.self, forKey: .taxRate)
        taxRegion = try container.decodeIfPresent(String.self, forKey: .taxRegion)
        items = try container.decodeIfPresent([BillCalculatorItem].self, forKey: .items) ?? []
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coupleId, forKey: .coupleId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(vendorId, forKey: .vendorId)
        try container.encodeIfPresent(eventId, forKey: .eventId)
        try container.encodeIfPresent(taxInfoId, forKey: .taxInfoId)
        try container.encode(guestCount, forKey: .guestCount)
        try container.encode(guestCountMode, forKey: .guestCountMode)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(vendorName, forKey: .vendorName)
        try container.encodeIfPresent(eventName, forKey: .eventName)
        try container.encodeIfPresent(taxRate, forKey: .taxRate)
        try container.encodeIfPresent(taxRegion, forKey: .taxRegion)
        try container.encode(items, forKey: .items)
        // Note: useManualGuestCount is intentionally NOT encoded - it's only used for decoding legacy data
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        coupleId: UUID,
        name: String = "",
        vendorId: Int64? = nil,
        eventId: UUID? = nil,
        taxInfoId: Int64? = nil,
        guestCount: Int = 0,
        guestCountMode: GuestCountMode = .auto,
        notes: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        vendorName: String? = nil,
        eventName: String? = nil,
        taxRate: Double? = nil,
        taxRegion: String? = nil,
        items: [BillCalculatorItem] = []
    ) {
        self.id = id
        self.coupleId = coupleId
        self.name = name
        self.vendorId = vendorId
        self.eventId = eventId
        self.taxInfoId = taxInfoId
        self.guestCount = guestCount
        self.guestCountMode = guestCountMode
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.vendorName = vendorName
        self.eventName = eventName
        self.taxRate = taxRate
        self.taxRegion = taxRegion
        self.items = items
    }

    // MARK: - Backward Compatibility

    /// Backward-compatible property that maps to the new guestCountMode
    var useManualGuestCount: Bool {
        get { guestCountMode == .manual }
        set { guestCountMode = newValue ? .manual : .auto }
    }

    /// Whether this calculator uses variable item counts (each item has its own quantity)
    var usesVariableItemCount: Bool {
        guestCountMode == .variable
    }

    // MARK: - Computed Properties (Filtered Items)

    /// Per-person items only
    var perPersonItems: [BillCalculatorItem] {
        items.filter { $0.type == .perPerson }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Service fee items only
    var serviceFeeItems: [BillCalculatorItem] {
        items.filter { $0.type == .serviceFee }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Flat fee items only
    var flatFeeItems: [BillCalculatorItem] {
        items.filter { $0.type == .flatFee }.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Computed Properties (Totals)

    /// Effective tax rate (from joined tax_info or default 0)
    var effectiveTaxRate: Double {
        taxRate ?? 0
    }

    /// Total for all per-person/per-item items (mode-aware)
    var perPersonTotal: Double {
        if usesVariableItemCount {
            // Variable mode: each item uses its own quantity
            return perPersonItems.reduce(0) { $0 + $1.variableItemTotal }
        } else {
            // Auto/Manual mode: all items use the shared guest count
            return perPersonItems.reduce(0) { $0 + $1.perPersonTotal(guestCount: guestCount) }
        }
    }

    /// Subtotal for service fee calculation (per-person/per-item items only)
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
        subtotal * (effectiveTaxRate / 100.0)
    }

    /// Grand total including tax
    var grandTotal: Double {
        subtotal + taxAmount
    }

    /// Per-guest cost (subtotal divided by guest count) - only meaningful in auto/manual mode
    var perGuestCost: Double {
        guard guestCount > 0 else { return 0 }
        return subtotal / Double(guestCount)
    }

    /// Total quantity across all per-person items (for variable mode display)
    var totalItemQuantity: Int {
        perPersonItems.reduce(0) { $0 + $1.quantity }
    }

    /// Total number of line items
    var totalItemCount: Int {
        items.count
    }

    /// Summary string for display
    var summaryDescription: String {
        let displayName = eventName ?? (name.isEmpty ? "Bill" : name)
        if usesVariableItemCount {
            return "\(displayName) - \(totalItemQuantity) items"
        }
        return "\(displayName) - \(guestCount) guests"
    }

    // MARK: - Mutating Methods

    /// Adds a new item of specified type
    mutating func addItem(_ item: BillCalculatorItem) {
        items.append(item)
    }

    /// Removes an item by ID
    mutating func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        // Re-index sort orders per type
        reindexSortOrders()
    }

    /// Removes a per-person item by index (for view compatibility)
    mutating func removePerPersonItem(at index: Int) {
        let perPerson = perPersonItems
        guard index >= 0 && index < perPerson.count else { return }
        removeItem(id: perPerson[index].id)
    }

    /// Removes a service fee item by index (for view compatibility)
    mutating func removeServiceFeeItem(at index: Int) {
        let serviceFees = serviceFeeItems
        guard index >= 0 && index < serviceFees.count else { return }
        removeItem(id: serviceFees[index].id)
    }

    /// Removes a flat fee item by index (for view compatibility)
    mutating func removeFlatFeeItem(at index: Int) {
        let flatFees = flatFeeItems
        guard index >= 0 && index < flatFees.count else { return }
        removeItem(id: flatFees[index].id)
    }

    /// Re-indexes sort orders for all item types
    private mutating func reindexSortOrders() {
        var perPersonIndex = 0
        var serviceFeeIndex = 0
        var flatFeeIndex = 0

        for i in items.indices {
            switch items[i].type {
            case .perPerson:
                items[i].sortOrder = perPersonIndex
                perPersonIndex += 1
            case .serviceFee:
                items[i].sortOrder = serviceFeeIndex
                serviceFeeIndex += 1
            case .flatFee:
                items[i].sortOrder = flatFeeIndex
                flatFeeIndex += 1
            }
        }
    }

    // MARK: - Mode Conversion

    /// Converts items when switching between guest count modes
    /// - When switching TO variable mode: Sets each item's quantity to the current guest count
    /// - When switching FROM variable mode: Items keep their quantities but calculation uses guest count
    mutating func convertToMode(_ newMode: GuestCountMode) {
        let oldMode = guestCountMode

        // No conversion needed if mode isn't changing
        guard oldMode != newMode else { return }

        // When switching TO variable mode from auto/manual,
        // set each per-person item's quantity to the current guest count
        if newMode == .variable && oldMode != .variable {
            for i in items.indices where items[i].type == .perPerson {
                items[i].quantity = guestCount > 0 ? guestCount : 1
            }
        }

        // When switching FROM variable mode to auto/manual,
        // optionally calculate a suggested guest count from item quantities
        // (items keep their quantities for potential conversion back)
        if oldMode == .variable && newMode != .variable {
            // Use the maximum quantity among items as suggested guest count
            let maxQuantity = perPersonItems.map(\.quantity).max() ?? guestCount
            if guestCount == 0 && maxQuantity > 0 {
                guestCount = maxQuantity
            }
        }

        guestCountMode = newMode
    }
}

// MARK: - Bill Calculator Insert Data

/// Data structure for inserting bill calculators (without joined/computed fields)
struct BillCalculatorInsertData: Codable {
    let coupleId: UUID
    var name: String
    var vendorId: Int64?
    var eventId: UUID?
    var taxInfoId: Int64?
    var guestCount: Int
    var guestCountMode: String
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case name
        case vendorId = "vendor_id"
        case eventId = "event_id"
        case taxInfoId = "tax_info_id"
        case guestCount = "guest_count"
        case guestCountMode = "guest_count_mode"
        case notes
    }

    init(from calculator: BillCalculator) {
        self.coupleId = calculator.coupleId
        self.name = calculator.name
        self.vendorId = calculator.vendorId
        self.eventId = calculator.eventId
        self.taxInfoId = calculator.taxInfoId
        self.guestCount = calculator.guestCount
        self.guestCountMode = calculator.guestCountMode.rawValue
        self.notes = calculator.notes
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
        let calcId = id
        return BillCalculator(
            id: calcId,
            coupleId: coupleId,
            name: name,
            guestCount: guestCount,
            taxRate: taxRate,
            items: [
                BillCalculatorItem(
                    calculatorId: calcId,
                    coupleId: coupleId,
                    type: .perPerson,
                    name: "Dinner",
                    amount: 85.00,
                    sortOrder: 0
                ),
                BillCalculatorItem(
                    calculatorId: calcId,
                    coupleId: coupleId,
                    type: .perPerson,
                    name: "Drinks",
                    amount: 40.00,
                    sortOrder: 1
                ),
                BillCalculatorItem(
                    calculatorId: calcId,
                    coupleId: coupleId,
                    type: .serviceFee,
                    name: "Service Charge",
                    amount: 20,
                    sortOrder: 0
                ),
                BillCalculatorItem(
                    calculatorId: calcId,
                    coupleId: coupleId,
                    type: .flatFee,
                    name: "Setup Fee",
                    amount: 500,
                    sortOrder: 0
                )
            ]
        )
    }
}

extension BillCalculatorItem {
    /// Creates a test item for unit testing
    static func makeTest(
        id: UUID = UUID(),
        calculatorId: UUID = UUID(),
        coupleId: UUID = UUID(),
        type: BillItemType = .perPerson,
        name: String = "Test Item",
        amount: Double = 50.00,
        sortOrder: Int = 0
    ) -> BillCalculatorItem {
        BillCalculatorItem(
            id: id,
            calculatorId: calculatorId,
            coupleId: coupleId,
            type: type,
            name: name,
            amount: amount,
            sortOrder: sortOrder
        )
    }
}

// MARK: - Legacy BillLineItem (for view compatibility during migration)

/// Legacy line item struct for view compatibility
/// Will be removed once views are migrated to use BillCalculatorItem
struct BillLineItem: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var amount: Double
    var quantity: Int
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String = "",
        amount: Double = 0,
        quantity: Int = 1,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.quantity = quantity
        self.sortOrder = sortOrder
    }

    /// Calculates the total for a per-person item
    func perPersonTotal(guestCount: Int) -> Double {
        return amount * Double(guestCount)
    }

    /// Calculates the total for a variable quantity item
    var variableItemTotal: Double {
        return amount * Double(quantity)
    }

    /// Calculates the total for a service fee item (percentage)
    func serviceFeeTotal(subtotal: Double) -> Double {
        return subtotal * (amount / 100.0)
    }

    /// For flat fees, the total is just the amount
    var flatFeeTotal: Double {
        return amount
    }

    /// Convert to BillCalculatorItem
    func toBillCalculatorItem(calculatorId: UUID, coupleId: UUID, type: BillItemType) -> BillCalculatorItem {
        BillCalculatorItem(
            id: id,
            calculatorId: calculatorId,
            coupleId: coupleId,
            type: type,
            name: name,
            amount: amount,
            quantity: quantity,
            sortOrder: sortOrder
        )
    }
}
