//
//  ExpenseAllocation.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for expense allocation to budget items
//

import Foundation

struct ExpenseAllocation: Identifiable, Codable {
    let id: String
    let expenseId: String
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
        case id = "id"
        case expenseId = "expense_id"
        case budgetItemId = "budget_item_id"
        case allocatedAmount = "allocated_amount"
        case percentage = "percentage"
        case notes = "notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case coupleId = "couple_id"
        case scenarioId = "scenario_id"
        case isTestData = "is_test_data"
    }
}
