//
//  SavedScenario.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for saved budget scenarios
//

import Foundation

struct SavedScenario: Identifiable, Codable {
    let id: String
    var scenarioName: String
    var createdAt: Date
    var updatedAt: Date
    var totalWithoutTax: Double?
    var totalTax: Double?
    var totalWithTax: Double?
    var isPrimary: Bool
    var coupleId: UUID
    var isTestData: Bool

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case scenarioName = "scenario_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case totalWithoutTax = "total_without_tax"
        case totalTax = "total_tax"
        case totalWithTax = "total_with_tax"
        case isPrimary = "is_primary"
        case coupleId = "couple_id"
        case isTestData = "is_test_data"
    }
    
    // Explicit initializer for creating scenarios
    init(
        id: String,
        scenarioName: String,
        createdAt: Date,
        updatedAt: Date,
        totalWithoutTax: Double? = nil,
        totalTax: Double? = nil,
        totalWithTax: Double? = nil,
        isPrimary: Bool,
        coupleId: UUID,
        isTestData: Bool
    ) {
        self.id = id
        self.scenarioName = scenarioName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalWithoutTax = totalWithoutTax
        self.totalTax = totalTax
        self.totalWithTax = totalWithTax
        self.isPrimary = isPrimary
        self.coupleId = coupleId
        self.isTestData = isTestData
    }
}
