//
//  BudgetItem.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Core budget item model for budget development and planning
//

import Foundation

struct BudgetItem: Identifiable, Codable, Equatable {
    let id: String
    var scenarioId: String?
    var itemName: String
    var category: String
    var subcategory: String?
    var vendorEstimateWithoutTax: Double
    var taxRate: Double
    var vendorEstimateWithTax: Double
    var personResponsible: String?
    var notes: String?
    var createdAt: Date?
    var updatedAt: Date?
    var eventId: String?
    var eventIds: [String]?
    var linkedExpenseId: String?
    var linkedGiftOwedId: String?
    var coupleId: UUID
    var isTestData: Bool?
    
    // Folder-related properties (backward-compatible with defaults)
    var parentFolderId: String?
    var isFolder: Bool
    var displayOrder: Int
    
    // Cached folder totals (Phase 2 optimization)
    var cachedTotalWithoutTax: Double?
    var cachedTotalTax: Double?
    var cachedTotalWithTax: Double?
    var cachedTotalsUpdatedAt: Date?

    // Computed properties for compatibility
    var eventNames: [String] {
        // This would need to be populated from actual event data
        []
    }
    
    // Explicit memberwise initializer
    init(
        id: String,
        scenarioId: String? = nil,
        itemName: String,
        category: String,
        subcategory: String? = nil,
        vendorEstimateWithoutTax: Double,
        taxRate: Double,
        vendorEstimateWithTax: Double,
        personResponsible: String? = nil,
        notes: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        eventId: String? = nil,
        eventIds: [String]? = nil,
        linkedExpenseId: String? = nil,
        linkedGiftOwedId: String? = nil,
        coupleId: UUID,
        isTestData: Bool? = nil,
        parentFolderId: String? = nil,
        isFolder: Bool = false,
        displayOrder: Int = 0,
        cachedTotalWithoutTax: Double? = nil,
        cachedTotalTax: Double? = nil,
        cachedTotalWithTax: Double? = nil,
        cachedTotalsUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.scenarioId = scenarioId
        self.itemName = itemName
        self.category = category
        self.subcategory = subcategory
        self.vendorEstimateWithoutTax = vendorEstimateWithoutTax
        self.taxRate = taxRate
        self.vendorEstimateWithTax = vendorEstimateWithTax
        self.personResponsible = personResponsible
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.eventId = eventId
        self.eventIds = eventIds
        self.linkedExpenseId = linkedExpenseId
        self.linkedGiftOwedId = linkedGiftOwedId
        self.coupleId = coupleId
        self.isTestData = isTestData
        self.parentFolderId = parentFolderId
        self.isFolder = isFolder
        self.displayOrder = displayOrder
        self.cachedTotalWithoutTax = cachedTotalWithoutTax
        self.cachedTotalTax = cachedTotalTax
        self.cachedTotalWithTax = cachedTotalWithTax
        self.cachedTotalsUpdatedAt = cachedTotalsUpdatedAt
    }
    
    /// Factory method for creating folders
    static func createFolder(
        name: String,
        scenarioId: String,
        parentFolderId: String? = nil,
        displayOrder: Int = 0,
        coupleId: UUID,
        personResponsible: String = "Both",
        isTestData: Bool = false
    ) -> BudgetItem {
        BudgetItem(
            id: UUID().uuidString,
            scenarioId: scenarioId,
            itemName: name,
            category: "",
            subcategory: nil,
            vendorEstimateWithoutTax: 0,
            taxRate: 0,
            vendorEstimateWithTax: 0,
            personResponsible: personResponsible,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date(),
            eventId: nil,
            eventIds: [],
            linkedExpenseId: nil,
            linkedGiftOwedId: nil,
            coupleId: coupleId,
            isTestData: isTestData,
            parentFolderId: parentFolderId,
            isFolder: true,
            displayOrder: displayOrder
        )
    }
    
    // Custom decoding for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        scenarioId = try container.decodeIfPresent(String.self, forKey: .scenarioId)
        itemName = try container.decode(String.self, forKey: .itemName)
        category = try container.decode(String.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        vendorEstimateWithoutTax = try container.decode(Double.self, forKey: .vendorEstimateWithoutTax)
        taxRate = try container.decode(Double.self, forKey: .taxRate)
        vendorEstimateWithTax = try container.decode(Double.self, forKey: .vendorEstimateWithTax)
        personResponsible = try container.decodeIfPresent(String.self, forKey: .personResponsible)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        eventId = try container.decodeIfPresent(String.self, forKey: .eventId)
        eventIds = try container.decodeIfPresent([String].self, forKey: .eventIds)
        linkedExpenseId = try container.decodeIfPresent(String.self, forKey: .linkedExpenseId)
        linkedGiftOwedId = try container.decodeIfPresent(String.self, forKey: .linkedGiftOwedId)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        isTestData = try container.decodeIfPresent(Bool.self, forKey: .isTestData)
        
        // Backward-compatible decoding with defaults for new properties
        parentFolderId = try container.decodeIfPresent(String.self, forKey: .parentFolderId)
        isFolder = try container.decodeIfPresent(Bool.self, forKey: .isFolder) ?? false
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 0
        
        // Phase 2: Cached folder totals (optional fields)
        cachedTotalWithoutTax = try container.decodeIfPresent(Double.self, forKey: .cachedTotalWithoutTax)
        cachedTotalTax = try container.decodeIfPresent(Double.self, forKey: .cachedTotalTax)
        cachedTotalWithTax = try container.decodeIfPresent(Double.self, forKey: .cachedTotalWithTax)
        cachedTotalsUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .cachedTotalsUpdatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case scenarioId = "scenario_id"
        case itemName = "item_name"
        case category = "category"
        case subcategory = "subcategory"
        case vendorEstimateWithoutTax = "vendor_estimate_without_tax"
        case taxRate = "tax_rate"
        case vendorEstimateWithTax = "vendor_estimate_with_tax"
        case personResponsible = "person_responsible"
        case notes = "notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case eventId = "event_id"
        case eventIds = "event_ids"
        case linkedExpenseId = "linked_expense_id"
        case linkedGiftOwedId = "linked_gift_owed_id"
        case coupleId = "couple_id"
        case isTestData = "is_test_data"
        case parentFolderId = "parent_folder_id"
        case isFolder = "is_folder"
        case displayOrder = "display_order"
        case cachedTotalWithoutTax = "cached_total_without_tax"
        case cachedTotalTax = "cached_total_tax"
        case cachedTotalWithTax = "cached_total_with_tax"
        case cachedTotalsUpdatedAt = "cached_totals_updated_at"
    }
}
