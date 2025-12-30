//
//  BudgetSummary.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Summary/aggregate model for budget overview
//

import Foundation

struct BudgetSummary: Identifiable, Codable {
    let id: UUID
    let coupleId: UUID
    var totalBudget: Double
    var baseBudget: Double
    var currency: String
    var weddingDate: Date?
    var notes: String?
    var includesEngagementRings: Bool
    var engagementRingAmount: Double
    var createdAt: Date
    var updatedAt: Date?

    // Computed properties
    var totalSpent: Double {
        // This would be calculated from expenses
        0.0 // Placeholder - will be calculated in BudgetStore
    }

    var totalAllocated: Double {
        // This would be calculated from budget_categories
        0.0 // Placeholder - will be calculated in BudgetStore
    }

    var remainingBudget: Double {
        totalBudget - totalSpent
    }

    var percentageSpent: Double {
        guard totalBudget > 0 else { return 0 }
        return (totalSpent / totalBudget) * 100
    }

    var percentageAllocated: Double {
        guard totalBudget > 0 else { return 0 }
        return (totalAllocated / totalBudget) * 100
    }

    var isOverBudget: Bool {
        totalSpent > totalBudget
    }

    // Explicit memberwise initializer
    init(
        id: UUID,
        coupleId: UUID,
        totalBudget: Double,
        baseBudget: Double,
        currency: String,
        weddingDate: Date? = nil,
        notes: String? = nil,
        includesEngagementRings: Bool,
        engagementRingAmount: Double,
        createdAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.coupleId = coupleId
        self.totalBudget = totalBudget
        self.baseBudget = baseBudget
        self.currency = currency
        self.weddingDate = weddingDate
        self.notes = notes
        self.includesEngagementRings = includesEngagementRings
        self.engagementRingAmount = engagementRingAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoding to handle different date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        totalBudget = try container.decode(Double.self, forKey: .totalBudget)
        baseBudget = try container.decode(Double.self, forKey: .baseBudget)
        currency = try container.decode(String.self, forKey: .currency)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        includesEngagementRings = try container.decode(Bool.self, forKey: .includesEngagementRings)
        engagementRingAmount = try container.decode(Double.self, forKey: .engagementRingAmount)

        // Custom date decoding using shared DateDecodingHelpers (refactored from duplicated code)
        weddingDate = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .weddingDate)
        createdAt = try DateDecodingHelpers.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .updatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case totalBudget = "total_budget"
        case baseBudget = "base_budget"
        case currency = "currency"
        case weddingDate = "wedding_date"
        case notes = "notes"
        case includesEngagementRings = "includes_engagement_rings"
        case engagementRingAmount = "engagement_ring_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
