//
//  BudgetDevelopmentScenario.swift
//  I Do Blueprint
//
//  Model for budget development scenarios from budget_development_scenarios table
//

import Foundation

/// Budget development scenario - represents a planned budget scenario
struct BudgetDevelopmentScenario: Identifiable, Codable, Equatable {
    let id: UUID
    let coupleId: UUID
    var scenarioName: String
    var totalWithoutTax: Double
    var totalTax: Double
    var totalWithTax: Double
    var isPrimary: Bool
    let createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case scenarioName = "scenario_name"
        case totalWithoutTax = "total_without_tax"
        case totalTax = "total_tax"
        case totalWithTax = "total_with_tax"
        case isPrimary = "is_primary"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Extension for test data
extension BudgetDevelopmentScenario {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        scenarioName: String = "Test Scenario",
        totalWithoutTax: Double = 75000.0,
        totalTax: Double = 9000.0,
        totalWithTax: Double = 84000.0,
        isPrimary: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) -> BudgetDevelopmentScenario {
        BudgetDevelopmentScenario(
            id: id,
            coupleId: coupleId,
            scenarioName: scenarioName,
            totalWithoutTax: totalWithoutTax,
            totalTax: totalTax,
            totalWithTax: totalWithTax,
            isPrimary: isPrimary,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
