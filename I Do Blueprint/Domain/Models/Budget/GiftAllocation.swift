//
//  GiftAllocation.swift
//  I Do Blueprint
//
//  Model for gift allocation to budget items
//  Mirrors ExpenseAllocation structure for proportional gift distribution
//

import Foundation

struct GiftAllocation: Identifiable, Codable, Sendable {
    let id: String
    let giftId: String
    let budgetItemId: String
    let allocatedAmount: Double
    let percentage: Double?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    let coupleId: String
    let scenarioId: String
    let isTestData: Bool?

    private enum CodingKeys: String, CodingKey {
        case id
        case giftId = "gift_id"
        case budgetItemId = "budget_item_id"
        case allocatedAmount = "allocated_amount"
        case percentage
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case coupleId = "couple_id"
        case scenarioId = "scenario_id"
        case isTestData = "is_test_data"
    }

    init(
        id: String = UUID().uuidString,
        giftId: String,
        budgetItemId: String,
        allocatedAmount: Double,
        percentage: Double? = nil,
        notes: String? = nil,
        createdAt: Date? = Date(),
        updatedAt: Date? = nil,
        coupleId: String,
        scenarioId: String,
        isTestData: Bool? = nil
    ) {
        self.id = id
        self.giftId = giftId
        self.budgetItemId = budgetItemId
        self.allocatedAmount = allocatedAmount
        self.percentage = percentage
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.coupleId = coupleId
        self.scenarioId = scenarioId
        self.isTestData = isTestData
    }
}

// MARK: - Test Data

extension GiftAllocation {
    static func makeTest(
        id: String = UUID().uuidString,
        giftId: String = UUID().uuidString,
        budgetItemId: String = UUID().uuidString,
        allocatedAmount: Double = 500.0,
        percentage: Double? = nil,
        notes: String? = nil,
        coupleId: String = UUID().uuidString,
        scenarioId: String = UUID().uuidString,
        isTestData: Bool? = true
    ) -> GiftAllocation {
        GiftAllocation(
            id: id,
            giftId: giftId,
            budgetItemId: budgetItemId,
            allocatedAmount: allocatedAmount,
            percentage: percentage,
            notes: notes,
            createdAt: Date(),
            updatedAt: nil,
            coupleId: coupleId,
            scenarioId: scenarioId,
            isTestData: isTestData
        )
    }
}
